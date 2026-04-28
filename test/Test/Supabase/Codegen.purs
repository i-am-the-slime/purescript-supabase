module Test.Supabase.Codegen where

import Prelude

import Codegen (mapType, columnPursType, toPascalCase, toCamelCase, renderTable, renderRpc)
import Data.Array (elem)
import Dodo (plainText, print, twoSpaces)
import Data.String (joinWith) as Str
import Data.String (Pattern(..), contains) as Str
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldSatisfy)

mkCol :: String -> String -> Boolean -> _
mkCol format typ isRequired =
  { name: "test", format, "type": typ, itemFormat: "", itemType: "", isRequired, requiredForInsert: false }

mkArrayCol :: String -> String -> String -> String -> Boolean -> _
mkArrayCol format typ itemFormat itemType isRequired =
  { name: "test", format, "type": typ, itemFormat, itemType, isRequired, requiredForInsert: false }

contains' :: String -> String -> Boolean
contains' needle = Str.contains (Str.Pattern needle)

spec :: Spec Unit
spec = describe "Codegen" do

  describe "mapType" do
    it "maps integer types" do
      mapType "bigint" "" `shouldEqual` "Int"
      mapType "int64" "" `shouldEqual` "Int"
      mapType "integer" "" `shouldEqual` "Int"
      mapType "int4" "" `shouldEqual` "Int"
      mapType "int8" "" `shouldEqual` "Int"
      mapType "smallint" "" `shouldEqual` "Int"

    it "maps numeric types" do
      mapType "numeric" "" `shouldEqual` "Number"
      mapType "double precision" "" `shouldEqual` "Number"
      mapType "real" "" `shouldEqual` "Number"
      mapType "float4" "" `shouldEqual` "Number"

    it "maps boolean" do
      mapType "boolean" "" `shouldEqual` "Boolean"
      mapType "bool" "" `shouldEqual` "Boolean"

    it "maps string types" do
      mapType "text" "" `shouldEqual` "String"
      mapType "character varying" "" `shouldEqual` "String"
      mapType "varchar" "" `shouldEqual` "String"
      mapType "uuid" "" `shouldEqual` "UUID"

    it "maps timestamp types" do
      mapType "timestamp with time zone" "" `shouldEqual` "Timestamp"
      mapType "timestamptz" "" `shouldEqual` "Timestamp"
      mapType "date" "" `shouldEqual` "Timestamp"

    it "maps json types to Foreign" do
      mapType "jsonb" "" `shouldEqual` "Foreign"
      mapType "json" "" `shouldEqual` "Foreign"

    it "falls back to type field" do
      mapType "" "string" `shouldEqual` "String"
      mapType "" "integer" `shouldEqual` "Int"
      mapType "" "number" `shouldEqual` "Number"
      mapType "" "boolean" `shouldEqual` "Boolean"

    it "unknown types become Foreign" do
      mapType "" "" `shouldEqual` "Foreign"
      mapType "custom_type" "custom" `shouldEqual` "Foreign"

  describe "columnPursType" do
    it "required column has no Maybe" do
      columnPursType (mkCol "text" "string" true) `shouldEqual` "String"

    it "optional column wrapped in Maybe" do
      columnPursType (mkCol "text" "string" false) `shouldEqual` "Maybe String"

    it "optional array wrapped with parens" do
      columnPursType (mkArrayCol "" "array" "" "string" false) `shouldEqual` "Maybe (Array String)"

    it "required array has no Maybe" do
      columnPursType (mkArrayCol "" "array" "" "string" true) `shouldEqual` "Array String"

    it "array with format on items" do
      columnPursType (mkArrayCol "text[]" "array" "text" "string" true) `shouldEqual` "Array String"

  describe "toPascalCase" do
    it "converts snake_case" do
      toPascalCase "user_pillars" `shouldEqual` "UserPillars"
      toPascalCase "products" `shouldEqual` "Products"
      toPascalCase "a_b_c" `shouldEqual` "ABC"

  describe "toCamelCase" do
    it "converts snake_case" do
      toCamelCase "user_pillars" `shouldEqual` "userPillars"
      toCamelCase "products" `shouldEqual` "products"

  describe "renderTable" do
    it "generates row type and Table value" do
      let table = { name: "my_items", relations: [], columns: [
              { name: "id", format: "int64", "type": "integer", itemFormat: "", itemType: "", isRequired: true, requiredForInsert: false }
            , { name: "title", format: "text", "type": "string", itemFormat: "", itemType: "", isRequired: true, requiredForInsert: true }
            , { name: "note", format: "text", "type": "string", itemFormat: "", itemType: "", isRequired: false, requiredForInsert: false }
            ] }
      let result = renderTable [] table
      let rendered = result.docs # map (print plainText twoSpaces) # Str.joinWith "\n"
      result.psName `shouldEqual` "MyItems"
      rendered `shouldSatisfy` contains' "id :: Int"
      rendered `shouldSatisfy` contains' "title :: String"
      rendered `shouldSatisfy` contains' "note :: Maybe String"
      rendered `shouldSatisfy` contains' "MyItemsRequired"
      rendered `shouldSatisfy` contains' "myItems :: Table MyItems MyItemsRequired ()"
      rendered `shouldSatisfy` contains' "Table \"my_items\""

  describe "renderRpc" do
    it "generates params type and Rpc value" do
      let tables = [{ name: "items", relations: [], columns: [{ name: "id", format: "int64", "type": "integer", itemFormat: "", itemType: "", isRequired: true, requiredForInsert: false }] }]
      let rpc = { name: "get_by_price", params: [
              { name: "min_price", format: "numeric", "type": "number" }
            , { name: "max_price", format: "numeric", "type": "number" }
            ], returnType: "items", returnsSet: true }
      let result = renderRpc tables rpc
      result.exports `shouldSatisfy` \e -> elem "GetByPriceParams" e
      result.exports `shouldSatisfy` \e -> elem "getByPrice" e
      let rendered = result.docs # map (print plainText twoSpaces) # Str.joinWith "\n"
      rendered `shouldSatisfy` contains' "min_price :: Number"
      rendered `shouldSatisfy` contains' "Rpc GetByPriceParams Items"
      rendered `shouldSatisfy` contains' "Rpc \"get_by_price\""

    it "generates Rpc with () params when no params" do
      let tables = []
      let rpc = { name: "count_all", params: [], returnType: "int8", returnsSet: false }
      let result = renderRpc tables rpc
      let rendered = result.docs # map (print plainText twoSpaces) # Str.joinWith "\n"
      rendered `shouldSatisfy` contains' "Rpc () ()"
      result.exports `shouldSatisfy` \e -> elem "countAll" e
