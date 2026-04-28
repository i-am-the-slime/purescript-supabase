module LSP.SchemaParser
  ( Column
  , Relation
  , TableDef
  , parseSchema
  ) where

import Prelude

import Data.Array (filter, mapMaybe, snoc)
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), indexOf, drop, take, length, trim, split, stripSuffix)
import Data.Foldable (foldl)
import Foreign.Object (Object)
import Foreign.Object as Object

type Column = { name :: String, "type" :: String }
type Relation = { name :: String, target :: String }
type TableDef =
  { name :: String
  , valueName :: String
  , columns :: Array Column
  , relations :: Array Relation
  }

parseSchema :: String -> Object TableDef
parseSchema src = do
  let blocks = findTypeBlocks src
  let tables = blocks # foldl (\acc b ->
        if hasSuffix "Required" b.name || hasSuffix "Params" b.name then acc
        else if hasSuffix "Relations" b.name then do
          let parentName = take (length b.name - 9) b.name
          case Object.lookup parentName acc of
            Nothing -> acc
            Just parent -> Object.insert parentName (parent { relations = parseRelations b.body }) acc
        else Object.insert b.name { name: b.name, valueName: "", columns: parseColumns b.body, relations: [] } acc
        ) Object.empty
  findTableValues src # foldl (\acc { valueName, typeName } ->
    case Object.lookup typeName acc of
      Nothing -> acc
      Just t -> Object.insert typeName (t { valueName = valueName }) acc
    ) tables

-- Block extraction: find `type Foo =\n  (...)` blocks

type Block = { name :: String, body :: String }

findTypeBlocks :: String -> Array Block
findTypeBlocks src = do
  let lines = split (Pattern "\n") src
  (foldl go { blocks: [], current: Nothing } lines).blocks
  where
  go state line = case state.current of
    Nothing -> case parseTypeDeclStart line of
      Just name -> state { current = Just { name, body: "" } }
      Nothing -> state
    Just cur -> do
      let newBody = cur.body <> "\n" <> line
      if containsClosingParen (trim line)
      then state { blocks = snoc state.blocks { name: cur.name, body: newBody }, current = Nothing }
      else state { current = Just { name: cur.name, body: newBody } }

  containsClosingParen s = indexOf (Pattern ")") s /= Nothing

  parseTypeDeclStart line = do
    let t = trim line
    case indexOf (Pattern "type ") t of
      Just 0 -> case indexOf (Pattern " =") t of
        Just eqIdx -> do
          let name = trim (take (eqIdx - 5) (drop 5 t))
          if name == "" then Nothing else Just name
        Nothing -> Nothing
      _ -> Nothing

-- Parse field declarations from a type body

parseColumns :: String -> Array Column
parseColumns body = splitFieldLines body # mapMaybe \part -> do
  case indexOf (Pattern "::") part of
    Nothing -> Nothing
    Just i -> do
      let name = trim (take i part)
      let typ = trim (drop (i + 2) part)
      if name == "" then Nothing else Just { name, "type": typ }

parseRelations :: String -> Array Relation
parseRelations body = splitFieldLines body # mapMaybe \part -> do
  case indexOf (Pattern "::") part of
    Nothing -> Nothing
    Just i -> do
      let name = trim (take i part)
      let typePart = trim (drop (i + 2) part)
      case indexOf (Pattern "Rel ") typePart of
        Just 0 -> do
          let afterRel = trim (drop 4 typePart)
          Just { name, target: takeWord afterRel }
        _ -> Nothing

splitFieldLines :: String -> Array String
splitFieldLines body = do
  let cleaned = stripOuterParens (trim body)
  split (Pattern "\n") cleaned >>= split (Pattern ",")
    # map trim
    # filter (_ /= "")

stripOuterParens :: String -> String
stripOuterParens s = case indexOf (Pattern "(") s of
  Just 0 -> take (length s - 2) (drop 1 s)
  _ -> s

takeWord :: String -> String
takeWord s = case indexOf (Pattern " ") s of
  Just i -> take i s
  Nothing -> s

hasSuffix :: String -> String -> Boolean
hasSuffix suffix s = stripSuffix (Pattern suffix) s /= Nothing

-- Find `valueName :: Table TypeName ...` bindings

findTableValues :: String -> Array { valueName :: String, typeName :: String }
findTableValues src = split (Pattern "\n") src # mapMaybe \line -> do
  let t = trim line
  case indexOf (Pattern ":: Table ") t of
    Nothing -> Nothing
    Just i -> Just
      { valueName: trim (take i t)
      , typeName: takeWord (trim (drop (i + 9) t))
      }
