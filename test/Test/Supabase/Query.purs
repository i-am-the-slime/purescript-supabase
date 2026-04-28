module Test.Supabase.Query where

import Prelude

import Data.Array (length, sort, filter)
import Data.Array.NonEmpty (cons') as NEA
import Data.Maybe (Maybe(..), isJust, isNothing)
import Data.String (Pattern(..), contains) as Str
import Supabase (Count(..), IsValue(..), TextSearchType(..), from, select, selectColumns, selectColumnsWithCount, single, singleWith, maybeSingle, maybeSingleWith, run, runWith, insert, delete, update, upsert, callRpc, callRpcWith, range, csv, textSearch, neq, gt, gte, lt, lte, like, ilike, is, contains, containedBy, overlaps, in_, or, order, orderWith, limit)
import Supabase (eq_, not_)
import Supabase.Filter (eqC, gtC, isTrue)
import Supabase.Schema as Schema
import Supabase.Types (Rpc, Table, mkRpc, mkTable)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldSatisfy)
import Test.Supabase.Helpers (mkClient, unwrap)

findBy :: forall a. (a -> String) -> String -> Array a -> Maybe a
findBy f target arr = case filter (\x -> f x == target) arr of
  [x] -> Just x
  _ -> Nothing

spec :: Spec Unit
spec = describe "Supabase.Query" do

  describe "run (phantom typed)" do
    it "returns all rows with correct schema type" do
      client <- mkClient
      rows <- client # from Schema.products # select # run >>= unwrap
      length rows `shouldEqual` 5
      sort (map _.name rows) `shouldEqual` ["Gadget X", "Gadget Y", "Widget A", "Widget B", "Widget C"]

    it "returns correct field types from schema" do
      client <- mkClient
      rows <- client # from Schema.products # select # run >>= unwrap
      let widget = findBy _.name "Widget A" rows
      (widget <#> _.price) `shouldEqual` Just 10.0
      (widget <#> _.in_stock) `shouldEqual` Just true
      (widget <#> _.tags) `shouldEqual` Just ["small", "metal"]
      (widget <#> _.description) `shouldEqual` Just (Just "A small widget")

  describe "eq" do
    it "finds exact match with correct data" do
      client <- mkClient
      res <- client # from Schema.products # select # eq_ @"name" "Widget A" # single
      (res.data <#> _.name) `shouldEqual` Just "Widget A"
      (res.data <#> _.price) `shouldEqual` Just 10.0
      res.error `shouldSatisfy` isNothing

  describe "neq" do
    it "excludes matching rows" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # neq @"name" "Widget A" # order @"name" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Gadget X", "Gadget Y", "Widget B", "Widget C"]

  describe "gt / gte / lt / lte" do
    it "gt filters strictly greater" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # gt @"price" 100.0 # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Gadget X"]

    it "gte includes boundary" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # gte @"price" 99.99 # order @"price" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Widget C", "Gadget X"]

    it "lt filters strictly less" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # lt @"price" 10.0 # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Gadget Y"]

    it "lte includes boundary" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # lte @"price" 10.0 # order @"price" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Gadget Y", "Widget A"]

  describe "like / ilike" do
    it "like is case-sensitive" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # like @"name" "Widget%" # order @"name" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Widget A", "Widget B", "Widget C"]

    it "ilike is case-insensitive" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # ilike @"name" "widget%" # order @"name" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Widget A", "Widget B", "Widget C"]

  describe "is" do
    it "finds null values" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # is @"description" IsNull # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Gadget Y"]

  describe "not" do
    it "negates a filter" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # not_ @"in_stock" isTrue # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Widget C"]

  describe "in_" do
    it "matches values in set" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # in_ @"name" (NEA.cons' "Widget A" ["Gadget X"]) # order @"name" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Gadget X", "Widget A"]

  describe "or" do
    it "combines conditions" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # or (NEA.cons' (eqC @"name" "Widget A") [eqC @"name" "Gadget X"]) # order @"name" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Gadget X", "Widget A"]

  describe "contains / containedBy / overlaps" do
    it "contains checks superset" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # contains @"tags" (["metal"] :: Array String) # order @"name" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Widget A", "Widget C"]

    it "containedBy checks subset" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # containedBy @"tags" (["small", "metal", "plastic"] :: Array String) # order @"name" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Gadget Y", "Widget A"]

    it "overlaps checks intersection" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # overlaps @"tags" (["electronic", "metal"] :: Array String) # order @"name" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Gadget X", "Widget A", "Widget C"]

  describe "gt with typed value" do
    it "filters by number value" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # gt @"price" 50.0 # order @"name" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Gadget X", "Widget C"]

  describe "order / orderWith" do
    it "ascending by default" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # order @"price" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Gadget Y", "Widget A", "Widget B", "Widget C", "Gadget X"]

    it "descending with options" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # orderWith @"price" { ascending: false, nullsFirst: false } # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Gadget X", "Widget C", "Widget B", "Widget A", "Gadget Y"]

  describe "limit" do
    it "limits and preserves order" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # order @"price" # limit 2 # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Gadget Y", "Widget A"]

  describe "range" do
    it "returns offset slice" do
      client <- mkClient
      rows <- client # from Schema.products # select # order @"price" # range { from: 1, to: 2 } >>= unwrap
      map _.name rows `shouldEqual` ["Widget A", "Widget B"]

  describe "single" do
    it "returns one row" do
      client <- mkClient
      res <- client # from Schema.products # select # eq_ @"name" "Widget A" # single
      (res.data <#> _.name) `shouldEqual` Just "Widget A"
      res.error `shouldSatisfy` isNothing

    it "returns error when multiple rows match" do
      client <- mkClient
      res <- client # from Schema.products # selectColumns @"name" # singleWith @{ name :: String }
      res.error # isJust # shouldEqual true
      res.data # isNothing # shouldEqual true

  describe "maybeSingle" do
    it "returns Nothing for no match" do
      client <- mkClient
      res <- client # from Schema.products # selectColumns @"name" # eq_ @"name" "NOPE" # maybeSingleWith @{ name :: String }
      res.data `shouldEqual` Nothing
      res.error `shouldSatisfy` isNothing

    it "returns data for a match" do
      client <- mkClient
      res <- client # from Schema.products # select # eq_ @"name" "Widget A" # maybeSingle
      (res.data <#> _.name) `shouldEqual` Just "Widget A"

  describe "insert + delete" do
    it "creates then removes a row" do
      client <- mkClient
      _ <- client # from Schema.products # insert { name: "Temp", price: 1.0, tags: ([] :: Array String), in_stock: true } # runWith @(Array {})
      rows <- client # from Schema.products # selectColumns @"name" # eq_ @"name" "Temp" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Temp"]
      _ <- client # from Schema.products # delete # eq_ @"name" "Temp" # runWith @(Array {})
      rows2 <- client # from Schema.products # selectColumns @"name" # eq_ @"name" "Temp" # runWith @(Array { name :: String }) >>= unwrap
      length rows2 `shouldEqual` 0

  describe "update" do
    it "modifies and restores a row" do
      client <- mkClient
      _ <- client # from Schema.products # update { price: 11.0 } # eq_ @"name" "Widget A" # runWith @(Array {})
      res <- client # from Schema.products # selectColumns @"price" # eq_ @"name" "Widget A" # singleWith @{ price :: Number }
      (res.data <#> _.price) `shouldEqual` Just 11.0
      _ <- client # from Schema.products # update { price: 10.0 } # eq_ @"name" "Widget A" # runWith @(Array {})
      pure unit

  describe "upsert" do
    it "inserts then cleans up" do
      client <- mkClient
      _ <- client # from Schema.products # upsert { name: "Upsert Test", price: 42.0, tags: ([] :: Array String), in_stock: true } # runWith @(Array {})
      res <- client # from Schema.products # selectColumns @"price" # eq_ @"name" "Upsert Test" # singleWith @{ price :: Number }
      (res.data <#> _.price) `shouldEqual` Just 42.0
      _ <- client # from Schema.products # delete # eq_ @"name" "Upsert Test" # runWith @(Array {})
      pure unit

  describe "selectColumnsWithCount" do
    it "returns data" do
      client <- mkClient
      res <- client # from Schema.products # selectColumnsWithCount @"*" Exact # run
      isJust res.data `shouldEqual` true

  describe "textSearch" do
    it "finds matching documents" do
      client <- mkClient
      rows <- client # from Schema.products # selectColumns @"name" # textSearch @"fts" "widget" { config: "english", "type": Plain } # order @"name" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Widget A", "Widget B", "Widget C"]

  describe "callRpc" do
    it "calls procedure without params" do
      client <- mkClient
      res <- client # callRpc Schema.productCount # singleWith @Int
      res.data `shouldEqual` Just 5

  describe "callRpcWith" do
    it "calls procedure with typed params" do
      client <- mkClient
      rows <- client # callRpcWith Schema.productsCheaperThan { max_price: 20.0 } # run >>= unwrap
      sort (map _.name rows) `shouldEqual` ["Gadget Y", "Widget A"]

  describe "csv" do
    it "returns CSV with header and data" do
      client <- mkClient
      res <- client # from Schema.products # selectColumns @"name" # order @"name" # limit 2 # csv # runWith @String >>= unwrap
      res `shouldSatisfy` \s -> Str.contains (Str.Pattern "name") s
      res `shouldSatisfy` \s -> Str.contains (Str.Pattern "Gadget") s

  describe "error cases" do
    it "run returns error for nonexistent table" do
      client <- mkClient
      res <- client # from (mkTable "nonexistent_table" :: Table () () ()) # select # runWith @(Array {})
      res.error # isJust # shouldEqual true
      res.data # isNothing # shouldEqual true

    it "rpc returns error for nonexistent function" do
      client <- mkClient
      let badRpc = mkRpc "nonexistent_function" :: Rpc () ()
      res <- client # callRpc badRpc # runWith @(Array {})
      res.error # isJust # shouldEqual true

    it "single returns error when zero rows match" do
      client <- mkClient
      res <- client # from Schema.products # selectColumns @"name" # eq_ @"name" "DOES_NOT_EXIST" # singleWith @{ name :: String }
      res.error # isJust # shouldEqual true
      res.data # isNothing # shouldEqual true

    it "insert with defaults succeeds and cleans up" do
      client <- mkClient
      -- price, tags, in_stock all have defaults so this succeeds
      _ <- client # from Schema.products # insert { name: "DefaultsTest" } # runWith @(Array {})
      _ <- client # from Schema.products # delete # eq_ @"name" "DefaultsTest" # runWith @(Array {})
      pure unit

    it "update with no matching rows returns empty data" do
      client <- mkClient
      res <- client # from Schema.products # update { price: 999.0 } # eq_ @"name" "NOBODY" # runWith @(Array { name :: String })
      res.error # isNothing # shouldEqual true
      case res.data of
        Just rows -> length rows `shouldEqual` 0
        Nothing -> pure unit

    it "delete with no matching rows returns empty data" do
      client <- mkClient
      res <- client # from Schema.products # delete # eq_ @"name" "NOBODY" # runWith @(Array { name :: String })
      res.error # isNothing # shouldEqual true
      case res.data of
        Just rows -> length rows `shouldEqual` 0
        Nothing -> pure unit
