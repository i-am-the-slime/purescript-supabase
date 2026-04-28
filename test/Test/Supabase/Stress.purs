module Test.Supabase.Stress where

import Prelude

import Data.Array (length, sort, index, (!!))
import Data.Maybe (Maybe(..), isJust, isNothing)
import Supabase (from, select, selectColumns, single, singleWith, maybeSingle, maybeSingleWith, run, runWith, insert, delete, update, callRpc, callRpcWith, order, orderWith, limit, range, gt, lt, eq_, in_, or, is, not_, IsValue(..))
import Supabase.Filter (eqC, gtC, isNull)
import Supabase.Schema as S
import Data.Array.NonEmpty (cons') as NEA
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldSatisfy)
import Test.Supabase.Helpers (mkClient, unwrap)

spec :: Spec Unit
spec = describe "Stress tests" do

  describe "type_zoo: all column types round-trip" do
    it "reads all types correctly" do
      client <- mkClient
      rows <- client # from S.typeZoo # select # run >>= unwrap
      length rows `shouldEqual` 1
      let r = rows !! 0
      case r of
        Nothing -> pure unit
        Just row -> do
          row.col_int2 `shouldEqual` 1
          row.col_int4 `shouldEqual` 100
          row.col_int8 `shouldEqual` 1000000
          row.col_bool `shouldEqual` true
          row.col_text `shouldEqual` "hello"
          row.col_varchar `shouldEqual` "world"
          length row.col_text_arr `shouldEqual` 2
          length row.col_int_arr `shouldEqual` 3

  describe "optional_everything: nullable columns" do
    it "reads fully populated row" do
      client <- mkClient
      res <- client # from S.optionalEverything # select # eq_ @"name" "full" # single
      case res.data of
        Nothing -> pure unit
        Just row -> do
          row.name `shouldEqual` Just "full"
          row.count `shouldEqual` Just 42
          row.amount `shouldEqual` Just 99.9
          row.flag `shouldEqual` Just true
          row.tags `shouldSatisfy` isJust

    it "reads fully null row" do
      client <- mkClient
      rows <- client # from S.optionalEverything # select # is @"name" IsNull # run >>= unwrap
      length rows `shouldEqual` 1
      let r = rows !! 0
      case r of
        Nothing -> pure unit
        Just row -> do
          row.name `shouldSatisfy` isNothing
          row.count `shouldSatisfy` isNothing
          row.amount `shouldSatisfy` isNothing
          row.flag `shouldSatisfy` isNothing
          row.tags `shouldSatisfy` isNothing
          isNothing row.meta `shouldEqual` true
          row.stamp `shouldSatisfy` isNothing

    it "reads partial row" do
      client <- mkClient
      res <- client # from S.optionalEverything # select # eq_ @"name" "partial" # single
      case res.data of
        Nothing -> pure unit
        Just row -> do
          row.name `shouldEqual` Just "partial"
          row.count `shouldSatisfy` isNothing
          row.amount `shouldEqual` Just 50.0

  describe "orders: foreign key relationships" do
    it "reads orders with correct types" do
      client <- mkClient
      rows <- client # from S.orders # select # order @"id" # run >>= unwrap
      length rows `shouldEqual` 3
      let first = rows !! 0
      case first of
        Nothing -> pure unit
        Just o -> do
          o.product_id `shouldEqual` 1
          o.quantity `shouldEqual` 2
          o.total_price `shouldEqual` 20.0
          o.status `shouldEqual` "shipped"
          o.notes `shouldEqual` Just "Rush delivery"

    it "filters by status" do
      client <- mkClient
      rows <- client # from S.orders # selectColumns @"status, total_price" # eq_ @"status" "shipped" # order @"total_price" # runWith @(Array { status :: String, total_price :: Number }) >>= unwrap
      length rows `shouldEqual` 2
      (rows !! 0 <#> _.total_price) `shouldEqual` Just 20.0
      (rows !! 1 <#> _.total_price) `shouldEqual` Just 450.0

    it "filters orders by shipped_at is null (pending)" do
      client <- mkClient
      rows <- client # from S.orders # selectColumns @"status" # is @"shipped_at" IsNull # runWith @(Array { status :: String }) >>= unwrap
      map _.status rows `shouldEqual` ["pending"]

  describe "categories: UUID primary keys and self-reference" do
    it "reads categories with UUID ids" do
      client <- mkClient
      rows <- client # from S.categories # select # order @"sort_order" # run >>= unwrap
      length rows `shouldEqual` 4

    it "finds root categories (no parent)" do
      client <- mkClient
      rows <- client # from S.categories # selectColumns @"name" # is @"parent_id" IsNull # order @"name" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Electronics", "Home"]

    it "finds child categories" do
      client <- mkClient
      rows <- client # from S.categories # selectColumns @"name" # not_ @"parent_id" isNull # order @"name" # runWith @(Array { name :: String }) >>= unwrap
      map _.name rows `shouldEqual` ["Gadgets", "Kitchen"]

  describe "order_items: junction table queries" do
    it "reads items with discount" do
      client <- mkClient
      rows <- client # from S.orderItems # select # gt @"discount" 0.0 # run >>= unwrap
      length rows `shouldEqual` 1
      (rows !! 0 <#> _.discount) `shouldEqual` Just 10.0

    it "filters by order_id" do
      client <- mkClient
      rows <- client # from S.orderItems # selectColumns @"product_id, quantity" # eq_ @"order_id" 3 # order @"product_id" # runWith @(Array { product_id :: Int, quantity :: Int }) >>= unwrap
      length rows `shouldEqual` 2
      (rows !! 0 <#> _.product_id) `shouldEqual` Just 1
      (rows !! 1 <#> _.product_id) `shouldEqual` Just 4

  describe "product_categories: composite primary key + UUID FK" do
    it "reads product-category mappings" do
      client <- mkClient
      rows <- client # from S.productCategories # select # run >>= unwrap
      length rows `shouldEqual` 3

    it "filters by product_id" do
      client <- mkClient
      rows <- client # from S.productCategories # select # eq_ @"product_id" 4 # run >>= unwrap
      length rows `shouldEqual` 2

  describe "audit_log: jsonb nullable columns" do
    it "reads audit entries with json data" do
      client <- mkClient
      rows <- client # from S.auditLog # select # order @"id" # run >>= unwrap
      length rows `shouldEqual` 2
      (rows !! 0 <#> _.table_name) `shouldEqual` Just "products"
      (rows !! 0 <#> _.action) `shouldEqual` Just "UPDATE"
      (rows !! 0 <#> (_.old_data >>> isJust)) `shouldEqual` Just true

  describe "complex filters" do
    it "or with gt across tables" do
      client <- mkClient
      rows <- client # from S.orders # selectColumns @"total_price"
        # or (NEA.cons' (gtC @"total_price" 100.0) [eqC @"status" "pending"])
        # order @"total_price"
        # runWith @(Array { total_price :: Number }) >>= unwrap
      map _.total_price rows `shouldEqual` [25.5, 450.0]

    it "multiple filters chained" do
      client <- mkClient
      rows <- client # from S.orderItems # selectColumns @"unit_price"
        # gt @"quantity" 1
        # lt @"unit_price" 100.0
        # runWith @(Array { unit_price :: Number }) >>= unwrap
      map _.unit_price rows `shouldEqual` [10.0]

    it "in_ with multiple order IDs" do
      client <- mkClient
      rows <- client # from S.orderItems # selectColumns @"order_id"
        # in_ @"order_id" (NEA.cons' 1 [3])
        # order @"order_id"
        # runWith @(Array { order_id :: Int }) >>= unwrap
      map _.order_id rows `shouldEqual` [1, 3, 3]

  describe "insert + update + delete cycle on orders" do
    it "full lifecycle" do
      client <- mkClient
      -- insert
      _ <- client # from S.orders # insert { product_id: 1, quantity: 5, total_price: 50.0, status: "draft" } # runWith @(Array {})
      res <- client # from S.orders # selectColumns @"status, quantity" # eq_ @"status" "draft" # singleWith @{ status :: String, quantity :: Int }
      (res.data <#> _.quantity) `shouldEqual` Just 5

      -- update
      _ <- client # from S.orders # update { status: "confirmed" } # eq_ @"status" "draft" # runWith @(Array {})
      res2 <- client # from S.orders # selectColumns @"status" # eq_ @"status" "confirmed" # singleWith @{ status :: String }
      (res2.data <#> _.status) `shouldEqual` Just "confirmed"

      -- delete
      _ <- client # from S.orders # delete # eq_ @"status" "confirmed" # runWith @(Array {})
      res3 <- client # from S.orders # selectColumns @"status" # eq_ @"status" "confirmed" # maybeSingleWith @{ status :: String }
      res3.data `shouldSatisfy` isNothing

  describe "RPC: order_summary (join)" do
    it "returns joined order+product data" do
      client <- mkClient
      rows <- client # callRpc S.orderSummary # runWith @(Array { order_id :: Int, product_name :: String, quantity :: Int, total_price :: Number }) >>= unwrap
      length rows `shouldEqual` 3
      (rows !! 0 <#> _.product_name) `shouldEqual` Just "Widget A"

  describe "RPC: order_items_detail (parameterized join)" do
    it "returns detail for order 3" do
      client <- mkClient
      rows <- client # callRpcWith S.orderItemsDetail { p_order_id: 3 } # runWith @(Array { product_name :: String, quantity :: Int, unit_price :: Number, line_total :: Number }) >>= unwrap
      length rows `shouldEqual` 2
      sort (map _.product_name rows) `shouldEqual` ["Gadget X", "Widget A"]

  describe "embedded relations" do
    it "selects products with orders" do
      client <- mkClient
      rows <- client # from S.products # selectColumns @"name, orders(id, total_price)" # eq_ @"name" "Widget A" # singleWith @{ name :: String, orders :: Array { id :: Int, total_price :: Number } }
      (rows.data <#> _.name) `shouldEqual` Just "Widget A"
      (rows.data <#> (_.orders >>> length)) `shouldEqual` Just 1

    it "selects products with deeply nested orders(order_items(...))" do
      client <- mkClient
      rows <- client # from S.products
        # selectColumns @"name, orders(id, order_items(product_id))"
        # eq_ @"name" "Widget A"
        # singleWith @{ name :: String, orders :: Array { id :: Int, order_items :: Array { product_id :: Int } } }
      (rows.data <#> _.name) `shouldEqual` Just "Widget A"
      (rows.data <#> (_.orders >>> length)) `shouldEqual` Just 1

    it "selects orders with nested order_items" do
      client <- mkClient
      rows <- client # from S.orders # selectColumns @"id, order_items(product_id, quantity)" # order @"id" # runWith @(Array { id :: Int, order_items :: Array { product_id :: Int, quantity :: Int } }) >>= unwrap
      -- Order 3 has 2 items
      let order3 = rows !! 2
      (order3 <#> (_.order_items >>> length)) `shouldEqual` Just 2

  describe "range and limit on large-ish result" do
    it "range returns correct slice" do
      client <- mkClient
      rows <- client # from S.orders # select # order @"id" # range { from: 1, to: 1 } >>= unwrap
      length rows `shouldEqual` 1
      (rows !! 0 <#> _.quantity) `shouldEqual` Just 1

    it "limit + order on order_items" do
      client <- mkClient
      rows <- client # from S.orderItems # selectColumns @"unit_price" # orderWith @"unit_price" { ascending: false, nullsFirst: false } # limit 2 # runWith @(Array { unit_price :: Number }) >>= unwrap
      length rows `shouldEqual` 2
      (rows !! 0 <#> _.unit_price) `shouldEqual` Just 150.0

