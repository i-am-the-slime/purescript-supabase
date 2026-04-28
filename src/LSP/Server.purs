module LSP.Server where

import Prelude

import Data.Array (filter, foldl, index)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Nullable (Nullable, toMaybe)
import Data.String (Pattern(..), indexOf, drop, take, split, trim, length)
import Effect (Effect)
import Effect.Exception (try) as Effect
import Effect.Ref as Ref
import Foreign (Foreign, unsafeToForeign)
import Foreign.Object (Object)
import Foreign.Object as Object
import LSP.Context (CompletionContext(..), detectContext)
import LSP.SchemaParser (TableDef, parseSchema)
import Node.Encoding (Encoding(..))
import Node.EventEmitter (on_)
import Node.FS.Sync (readTextFile)
import Node.Process as Process
import Node.Stream (dataHStr, writeString, setEncoding)

main :: Effect Unit
main = do
  schemaRef <- Ref.new (Object.empty :: Object TableDef)
  docsRef <- Ref.new (Object.empty :: Object String)
  bufferRef <- Ref.new ""

  setEncoding Process.stdin UTF8

  Process.stdin # on_ dataHStr \chunk -> do
    Ref.modify_ (_ <> chunk) bufferRef
    processBuffer bufferRef schemaRef docsRef

processBuffer :: Ref.Ref String -> Ref.Ref (Object TableDef) -> Ref.Ref (Object String) -> Effect Unit
processBuffer bufferRef schemaRef docsRef = do
  buf <- Ref.read bufferRef
  case indexOf (Pattern "\r\n\r\n") buf of
    Nothing -> pure unit
    Just headerEnd -> do
      let header = take headerEnd buf
      case parseContentLength header of
        Nothing -> do
          Ref.write (drop (headerEnd + 4) buf) bufferRef
          processBuffer bufferRef schemaRef docsRef
        Just contentLength -> do
          let bodyStart = headerEnd + 4
          let available = length buf - bodyStart
          if available < contentLength then pure unit
          else do
            let body = take contentLength (drop bodyStart buf)
            Ref.write (drop (bodyStart + contentLength) buf) bufferRef
            handleMessage body schemaRef docsRef
            processBuffer bufferRef schemaRef docsRef

parseContentLength :: String -> Maybe Int
parseContentLength header =
  split (Pattern "\r\n") header # foldl (\acc line ->
    case indexOf (Pattern "Content-Length:") line of
      Just 0 -> toMaybe (parseIntNullable (trim (drop 15 line)))
      _ -> acc
  ) Nothing

handleMessage :: String -> Ref.Ref (Object TableDef) -> Ref.Ref (Object String) -> Effect Unit
handleMessage body schemaRef docsRef = do
  let msg = jsonParse body
  let id = field "id" msg
  let method = fieldStr "method" msg
  let params = field "params" msg

  case method of
    "initialize" -> do
      let rootUri = fieldStr "rootUri" params
      let root = drop 7 rootUri
      loadSchema (root <> "/src/Supabase/Schema.purs") schemaRef
      reply id { capabilities: { textDocumentSync: 1, completionProvider: { triggerCharacters: ["\"", ",", " ", "("] } } }

    "textDocument/didOpen" -> do
      let td = field "textDocument" params
      Ref.modify_ (Object.insert (fieldStr "uri" td) (fieldStr "text" td)) docsRef

    "textDocument/didChange" -> do
      let td = field "textDocument" params
      let changes = fieldArr "contentChanges" params
      case index changes 0 of
        Nothing -> pure unit
        Just change -> Ref.modify_ (Object.insert (fieldStr "uri" td) (fieldStr "text" change)) docsRef

    "textDocument/didClose" -> do
      let td = field "textDocument" params
      Ref.modify_ (Object.delete (fieldStr "uri" td)) docsRef

    "textDocument/completion" -> do
      let td = field "textDocument" params
      let pos = field "position" params
      let uri = fieldStr "uri" td
      let line = fieldInt "line" pos
      let col = fieldInt "character" pos
      docs <- Ref.read docsRef
      schema <- Ref.read schemaRef
      let text = fromMaybe "" (Object.lookup uri docs)
      let lineText = fromMaybe "" (index (split (Pattern "\n") text) line)
      let ctx = detectContext lineText col text line
      let items = completions schema ctx
      reply id { isIncomplete: false, items }

    "shutdown" -> reply id (unsafeToForeign unit)
    "exit" -> exit 0
    _ -> when (not (isNull id)) (reply id (unsafeToForeign unit))

loadSchema :: String -> Ref.Ref (Object TableDef) -> Effect Unit
loadSchema path ref = do
  result <- Effect.try (readTextFile UTF8 path)
  case result of
    Left _ -> pure unit
    Right src -> Ref.write (parseSchema src) ref

-- Completions

completions :: Object TableDef -> Maybe CompletionContext -> Array Foreign
completions schema = case _ of
  Nothing -> []
  Just (SelectCtx { table, prefix, depth }) ->
    case findByValueName table schema of
      Nothing -> []
      Just tableDef -> do
        let scope = walkDepth schema tableDef depth
        let colItems = scope.columns
              # filter (\c -> startsWith prefix c.name)
              # map \c -> unsafeToForeign { label: c.name, kind: 5, detail: c."type" }
        let relItems = scope.relations
              # filter (\r -> startsWith prefix r.name)
              # map \r -> unsafeToForeign { label: r.name, kind: 19, detail: "→ " <> r.target, insertText: r.name <> "($1)", insertTextFormat: 2 }
        colItems <> relItems

  Just (FilterCtx { table, prefix }) ->
    case findByValueName table schema of
      Nothing -> []
      Just tableDef -> tableDef.columns
        # filter (\c -> startsWith prefix c.name)
        # map \c -> unsafeToForeign { label: c.name, kind: 5, detail: c."type" }

walkDepth :: Object TableDef -> TableDef -> Array String -> { columns :: Array { name :: String, "type" :: String }, relations :: Array { name :: String, target :: String } }
walkDepth schema tableDef depth = case index depth 0 of
  Nothing -> { columns: tableDef.columns, relations: tableDef.relations }
  Just relName -> do
    let rest = fromMaybe [] (tailArray depth)
    case tableDef.relations # foldl (\acc r -> if r.name == relName then Just r else acc) Nothing of
      Nothing -> { columns: [], relations: [] }
      Just rel -> case Object.lookup rel.target schema of
        Nothing -> { columns: [], relations: [] }
        Just relTable -> walkDepth schema relTable rest

findByValueName :: String -> Object TableDef -> Maybe TableDef
findByValueName vn = Object.values >>> foldl (\acc t -> if t.valueName == vn then Just t else acc) Nothing

startsWith :: String -> String -> Boolean
startsWith prefix s = indexOf (Pattern prefix) s == Just 0

tailArray :: forall a. Array a -> Maybe (Array a)
tailArray arr = case index arr 0 of
  Nothing -> Nothing
  Just _ -> Just (arraySlice 1 arr)

-- Sending responses

reply :: forall a. Foreign -> a -> Effect Unit
reply id result = do
  let body = stringify (unsafeToForeign { jsonrpc: "2.0", id, result })
  let header = "Content-Length: " <> show (byteLength body) <> "\r\n\r\n"
  _ <- writeString Process.stdout UTF8 (header <> body)
  pure unit

-- Minimal FFI: only things with no PureScript equivalent

foreign import jsonParse :: String -> Foreign
foreign import field :: String -> Foreign -> Foreign
foreign import fieldStr :: String -> Foreign -> String
foreign import fieldInt :: String -> Foreign -> Int
foreign import fieldArr :: String -> Foreign -> Array Foreign
foreign import isNull :: Foreign -> Boolean
foreign import stringify :: Foreign -> String
foreign import byteLength :: String -> Int
foreign import exit :: Int -> Effect Unit
foreign import parseIntNullable :: String -> Nullable Int
foreign import arraySlice :: forall a. Int -> Array a -> Array a
