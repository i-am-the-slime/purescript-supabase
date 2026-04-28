module Codegen
  ( ColumnInfo
  , RelationInfo
  , RpcInfo
  , RpcParamInfo
  , TableInfo
  , columnPursType
  , main
  , mapType
  , renderRpc
  , renderTable
  , toCamelCase
  , toPascalCase
  ) where

import Prelude

import Data.Array (concat, drop, foldl, head, length, tail)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (Pattern(..), contains, joinWith, split, toUpper, trim)
import Data.String.CodeUnits (drop, length, take, uncons) as SCU
import Dodo (Doc, break, foldWithSeparator, indent, lines, plainText, print, text, twoSpaces)
import Dodo.Common (leadingComma, pursParens)
import Effect (Effect)
import Effect.Aff (launchAff_, try)
import Effect.Class (liftEffect)
import Effect.Class.Console (log)
import Effect.Exception (try) as Effect
import Fetch (fetch)
import Foreign (Foreign)
import Foreign.Object (Object)
import Foreign.Object as Object
import Node.Encoding (Encoding(..))
import Node.FS.Sync (writeTextFile)
import Node.Library.Execa (execaSync)
import Node.Process.Environment as Env
import Data.Nullable (Nullable, toMaybe)
import Unsafe.Coerce (unsafeCoerce)

-- Types

type ColumnInfo =
  { name :: String
  , format :: String
  , "type" :: String
  , itemFormat :: String
  , itemType :: String
  , isRequired :: Boolean
  , requiredForInsert :: Boolean
  }

type TableInfo =
  { name :: String
  , columns :: Array ColumnInfo
  , relations :: Array RelationInfo
  }

type RelationInfo =
  { name :: String          -- the related table name (e.g. "orders")
  , referencedTable :: String -- same as name for now
  }

type RpcParamInfo =
  { name :: String
  , format :: String
  , "type" :: String
  }

type RpcInfo =
  { name :: String
  , params :: Array RpcParamInfo
  , returnType :: String
  , returnsSet :: Boolean
  }

-- OpenAPI spec types (for yoga-json parsing)

type OpenAPIColumn =
  { format :: Nullable String
  , "type" :: Nullable String
  , items :: Nullable { format :: Nullable String, "type" :: Nullable String }
  }

type OpenAPITable =
  { required :: Nullable (Array String)
  , properties :: Nullable (Object OpenAPIColumn)
  }

type OpenAPIRpcParam = { format :: Nullable String, "type" :: Nullable String }
type OpenAPIRpcSchema = { properties :: Nullable (Object OpenAPIRpcParam) }
type OpenAPIRpcBody = { "in" :: String, schema :: Nullable OpenAPIRpcSchema }
type OpenAPIRpcPost = { parameters :: Nullable (Array OpenAPIRpcBody) }

type OpenAPISpec =
  { definitions :: Nullable (Object OpenAPITable)
  , paths :: Nullable (Object { post :: Nullable OpenAPIRpcPost })
  }

-- Parse OpenAPI spec into our types

parseSpec :: OpenAPISpec -> { tables :: Array TableInfo, rpcs :: Array RpcInfo }
parseSpec spec = do
  let tables = fromMaybe Object.empty (toMaybe spec.definitions) # Object.toArrayWithKey \name def -> do
        let required = fromMaybe [] (toMaybe def.required)
        let props = fromMaybe Object.empty (toMaybe def.properties)
        let columns = props # Object.toArrayWithKey \colName col ->
              { name: colName
              , format: fromMaybe "" (toMaybe col.format)
              , "type": fromMaybe "" (toMaybe col."type")
              , itemFormat: toMaybe col.items >>= (_.format >>> toMaybe) # fromMaybe ""
              , itemType: toMaybe col.items >>= (_."type" >>> toMaybe) # fromMaybe ""
              , isRequired: required # foldl (\acc r -> acc || r == colName) false
              , requiredForInsert: false
              }
        { name, columns, relations: [] }
  let rpcs = fromMaybe Object.empty (toMaybe spec.paths) # Object.toArrayWithKey parseRpcPath # concat
  { tables, rpcs }
  where
  parseRpcPath path methods =
    if not (contains (Pattern "/rpc/") path) then []
    else do
      let fnName = SCU.drop 5 path
      let params = case toMaybe methods.post >>= (_.parameters >>> toMaybe) of
            Nothing -> []
            Just ps -> ps >>= \p ->
              if p."in" /= "body" then []
              else case toMaybe p.schema >>= (_.properties >>> toMaybe) of
                Nothing -> []
                Just props -> Object.toArrayWithKey (\pName pCol ->
                  { name: pName, format: toMaybe pCol.format # fromMaybe "", "type": toMaybe pCol."type" # fromMaybe "" }
                ) props
      [{ name: fnName, params, returnType: "", returnsSet: false }]

-- Docker exec helper

dockerExec :: String -> String -> Effect (Maybe String)
dockerExec projectId query = do
  result <- Effect.try (execaSync "docker" ["exec", "supabase_db_" <> projectId, "psql", "-U", "postgres", "-t", "-A", "-F|", "-c", query] identity)
  pure case result of
    Right r -> Just (trim r.stdout)
    Left _ -> Nothing

-- Type mapping

mapType :: String -> String -> String
mapType format typ = case format of
  "bigint" -> "Int"
  "int64" -> "Int"
  "integer" -> "Int"
  "int4" -> "Int"
  "int8" -> "Int"
  "smallint" -> "Int"
  "int2" -> "Int"
  "numeric" -> "Number"
  "double precision" -> "Number"
  "real" -> "Number"
  "float4" -> "Number"
  "float8" -> "Number"
  "boolean" -> "Boolean"
  "bool" -> "Boolean"
  "text" -> "String"
  "character varying" -> "String"
  "varchar" -> "String"
  "uuid" -> "UUID"
  "timestamp with time zone" -> "Timestamp"
  "timestamptz" -> "Timestamp"
  "date" -> "Timestamp"
  "tsvector" -> "String"
  "jsonb" -> "Foreign"
  "json" -> "Foreign"
  _ ->
    if typ == "string" then "String"
    else if typ == "integer" then "Int"
    else if typ == "number" then "Number"
    else if typ == "boolean" then "Boolean"
    else "Foreign"

columnPursType :: ColumnInfo -> String
columnPursType col = do
  let base =
        if col."type" == "array" then "Array " <> mapType col.itemFormat col.itemType
        else mapType col.format col."type"
  if col.isRequired then base
  else if contains (Pattern " ") base then "Maybe (" <> base <> ")"
  else "Maybe " <> base

-- String helpers

toPascalCase :: String -> String
toPascalCase s = split (Pattern "_") s # map capitalize # joinWith ""

toCamelCase :: String -> String
toCamelCase s = do
  let parts = split (Pattern "_") s
  let first = fromMaybe "" (head parts)
  let rest = fromMaybe [] (tail parts) # map capitalize
  first <> joinWith "" rest

capitalize :: String -> String
capitalize s = case SCU.uncons s of
  Nothing -> ""
  Just { head: h, tail: t } -> toUpper (SCU.take 1 s) <> t

schemaNameToValue :: String -> String
schemaNameToValue s = do
  let stripped = if SCU.take 1 s == "_" then "internal" <> capitalize (SCU.drop 1 s) else s
  toCamelCase stripped <> "Schema"

-- Pretty printing

row :: Array (Doc Void) -> Doc Void
row fields = pursParens (foldWithSeparator leadingComma fields)

field :: String -> String -> Doc Void
field name typ = text (name <> " :: " <> typ)

typeAlias :: String -> Array (Doc Void) -> Doc Void
typeAlias name fields =
  text ("type " <> name <> " =") <> break <> indent (row fields)

valueDef :: String -> String -> String -> Doc Void
valueDef name typ val =
  text (name <> " :: " <> typ) <> break <> text (name <> " = " <> val)

-- Rendering

renderTable :: Array TableInfo -> TableInfo -> { docs :: Array (Doc Void), psName :: String, exports :: Array String }
renderTable allTables table = do
  let psName = toPascalCase table.name
  let valueName = toCamelCase table.name
  let colFields = table.columns # map \col -> field col.name (columnPursType col)
  let typDoc = typeAlias psName colFields
  let requiredCols = table.columns # foldl (\acc col ->
        if col.requiredForInsert then acc <> [field col.name (columnPursType col)]
        else acc) []
  let hasRequired = length requiredCols > 0
  let requiredDoc = if hasRequired then [typeAlias (psName <> "Required") requiredCols] else []
  let requiredType = if hasRequired then psName <> "Required" else "()"
  let hasRelations = length table.relations > 0
  let relFields = table.relations # map \rel -> do
        let relPsName = toPascalCase rel.referencedTable
        let relRelsType = allTables # foldl (\acc t ->
              if t.name == rel.referencedTable && length t.relations > 0
              then relPsName <> "Relations"
              else acc) "()"
        field rel.name ("Rel " <> relPsName <> " " <> relRelsType)
  let relDoc = if hasRelations then [typeAlias (psName <> "Relations") relFields] else []
  let relType = if hasRelations then psName <> "Relations" else "()"
  let tableDoc = valueDef valueName ("Table " <> psName <> " " <> requiredType <> " " <> relType) ("mkTable " <> show table.name)
  let exports = [psName] <> (if hasRequired then [psName <> "Required"] else []) <> (if hasRelations then [psName <> "Relations"] else [])
  { docs: [typDoc] <> requiredDoc <> relDoc <> [tableDoc], psName, exports }

renderRpc :: Array TableInfo -> RpcInfo -> { exports :: Array String, docs :: Array (Doc Void) }
renderRpc tables rpc = do
  let psName = toPascalCase rpc.name
  let valueName = toCamelCase rpc.name
  let hasParams = length rpc.params > 0
  let paramFields = rpc.params # map \p -> field p.name (mapType p.format p."type")
  let paramsDoc = if hasParams then [typeAlias (psName <> "Params") paramFields] else []
  let paramsType = if hasParams then psName <> "Params" else "()"
  let returnTable = tables # foldl (\acc t -> if t.name == rpc.returnType then toPascalCase t.name else acc) ""
  let resultType = if returnTable /= "" then returnTable else "()"
  let rpcDoc = valueDef valueName ("Rpc " <> paramsType <> " " <> resultType) ("mkRpc " <> show rpc.name)
  let exports = (if hasParams then [psName <> "Params"] else []) <> [valueName]
  { exports, docs: paramsDoc <> [rpcDoc] }

renderSchema :: String -> Doc Void
renderSchema s = valueDef (schemaNameToValue s) "SchemaName" ("SchemaName " <> show s)

renderModule :: String -> Array String -> Array String -> Array (Doc Void) -> Doc Void
renderModule source exports imports decls =
  lines
    [ text "-- Generated by Codegen — do not edit by hand"
    , text ("-- Source: " <> source)
    , text ""
    , text "module Supabase.Schema"
    , indent (row (exports # map text))
    , text "  where"
    , text ""
    , lines (imports # map \i -> text ("import " <> i))
    , text ""
    , foldWithSeparator (break <> break) decls
    , text ""
    ]

-- Main

main :: Effect Unit
main = launchAff_ do
  url <- Env.lookup "SUPABASE_URL" "http://127.0.0.1:54321"
  key <- Env.lookup "SUPABASE_KEY" "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"
  projectId <- Env.lookup "SUPABASE_PROJECT_ID" "stilthouse"

  { json: parseJson } <- fetch (url <> "/rest/v1/") { headers: { "apikey": key, "Authorization": "Bearer " <> key } }
  specForeign <- parseJson
  let spec = parseSpec (unsafeCoerce specForeign :: OpenAPISpec)

  -- Introspect Postgres for required-for-insert columns
  reqResult <- dockerExec projectId "SELECT c.table_name, c.column_name FROM information_schema.columns c WHERE c.table_schema = 'public' AND c.is_nullable = 'NO' AND c.column_default IS NULL AND c.is_identity = 'NO' AND c.is_generated = 'NEVER'" # liftEffect
  case reqResult of
    Nothing -> log "Warning: could not introspect database for required-for-insert columns"
    Just _ -> pure unit
  let tables = case reqResult of
        Nothing -> spec.tables
        Just output -> spec.tables # map \table -> table
          { columns = table.columns # map \col ->
              if isRequiredForInsert table.name col.name output then col { requiredForInsert = true } else col
          }

  -- Introspect Postgres for RPC return types
  rpcResult <- dockerExec projectId "SELECT p.proname, t.typname, p.proretset FROM pg_proc p JOIN pg_type t ON p.prorettype = t.oid JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public'" # liftEffect
  case rpcResult of
    Nothing -> log "Warning: could not introspect database for RPC return types"
    Just _ -> pure unit
  let rpcs = case rpcResult of
        Nothing -> spec.rpcs
        Just output -> spec.rpcs # map \rpc ->
          let returnInfo = findRpcReturn rpc.name output
          in rpc { returnType = returnInfo.typname, returnsSet = returnInfo.retset }

  -- Introspect Postgres for schemas
  schemaResult <- dockerExec projectId "SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast') ORDER BY 1" # liftEffect
  case schemaResult of
    Nothing -> log "Warning: could not introspect database for schemas"
    Just _ -> pure unit
  let schemas = case schemaResult of
        Nothing -> []
        Just output -> split (Pattern "\n") output # map trim >>= \s -> if s == "" then [] else [s]

  -- Introspect Postgres for foreign key relations
  fkResult <- dockerExec projectId "SELECT ccu.table_name AS referenced_table, kcu.table_name AS referencing_table FROM information_schema.table_constraints tc JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name AND tc.table_schema = ccu.table_schema WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'" # liftEffect
  case fkResult of
    Nothing -> log "Warning: could not introspect database for foreign key relations"
    Just _ -> pure unit
  let tablesWithRels = case fkResult of
        Nothing -> tables
        Just output -> tables # map \table -> table
          { relations = findRelations table.name output }

  -- Render
  let tableResults = tablesWithRels # map (renderTable tablesWithRels)
  let tableDocs = tableResults >>= _.docs
  let tableExports = tableResults >>= _.exports
  let valueNames = tablesWithRels # map \t -> toCamelCase t.name

  let rpcResults = rpcs # map (renderRpc tablesWithRels)
  let rpcExports = rpcResults >>= _.exports
  let rpcDocs = rpcResults >>= _.docs

  let schemaDocs = schemas # map renderSchema
  let schemaExports = schemas # map schemaNameToValue

  let allDocs = tableDocs <> rpcDocs <> schemaDocs
  let allExports = tableExports <> valueNames <> rpcExports <> schemaExports
  let rendered = allDocs # map (print plainText twoSpaces)
  let has t = rendered # foldl (\acc s -> acc || contains (Pattern t) s) false
  let hasForeign = has "Foreign"
  let hasTimestamp = has "Timestamp"
  let hasUUID = has "UUID"
  let hasRel = has "Rel "

  let imports = ["Data.Maybe (Maybe)"]
        <> (if hasForeign then ["Foreign (Foreign)"] else [])
        <> (if hasTimestamp then ["Supabase.Auth.Types (Timestamp)"] else [])
        <> (if hasUUID then ["Supabase.UUID (UUID)"] else [])
        <> (if hasRel then ["Supabase.Types (Rel, Rpc, SchemaName(..), Table, mkRpc, mkTable)"] else ["Supabase.Types (Rpc, SchemaName(..), Table, mkRpc, mkTable)"])

  let doc = renderModule url allExports imports allDocs
  let output = print plainText twoSpaces doc

  writeTextFile UTF8 "src/Supabase/Schema.purs" output # liftEffect

  log "Generated src/Supabase/Schema.purs"
  let relCount = tablesWithRels # foldl (\acc t -> acc + length t.relations) 0
  log ("  " <> show (length tablesWithRels) <> " table(s)")
  log ("  " <> show relCount <> " relation(s)")
  log ("  " <> show (length rpcExports) <> " RPC function(s)")
  log ("  " <> show (length schemaExports) <> " schema(s)")

  where
  isRequiredForInsert :: String -> String -> String -> Boolean
  isRequiredForInsert tableName colName output =
    split (Pattern "\n") output # foldl (\acc line ->
      case split (Pattern "|") line of
        [t, c] -> acc || trim t == tableName && trim c == colName
        _ -> acc
    ) false

  findRpcReturn :: String -> String -> { typname :: String, retset :: Boolean }
  findRpcReturn name output =
    split (Pattern "\n") output # foldl (\acc line ->
      case split (Pattern "|") line of
        [n, t, r] | trim n == name -> { typname: trim t, retset: trim r == "t" }
        _ -> acc
    ) { typname: "", retset: false }

  -- Find tables that reference this table via FK (i.e. children)
  findRelations :: String -> String -> Array RelationInfo
  findRelations tableName output =
    split (Pattern "\n") output # foldl (\acc line ->
      case split (Pattern "|") line of
        [referenced, referencing] | trim referenced == tableName && trim referencing /= tableName ->
          acc <> [{ name: trim referencing, referencedTable: trim referencing }]
        _ -> acc
    ) []
