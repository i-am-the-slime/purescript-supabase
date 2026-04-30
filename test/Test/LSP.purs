module Test.LSP where

import Prelude

import Data.Array (length, filter)
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), contains)
import Effect.Class (liftEffect)
import Foreign (Foreign)
import Foreign.Object as Object
import LSP.Context (CompletionContext(..), detectContext, parseSelectPosition)
import LSP.SchemaParser (parseSchema)
import Node.Encoding (Encoding(..))
import Node.FS.Sync (readTextFile)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldSatisfy)

spec :: Spec Unit
spec = describe "LSP" do

  describe "SchemaParser" do
    it "parses all tables" do
      src <- readTextFile UTF8 "test/Supabase/Schema.purs" # liftEffect
      let schema = parseSchema src
      Object.size schema `shouldSatisfy` (_ > 0)

    it "parses columns for Products" do
      src <- readTextFile UTF8 "test/Supabase/Schema.purs" # liftEffect
      let schema = parseSchema src
      case Object.lookup "Products" schema of
        Nothing -> "Products not found" `shouldEqual` ""
        Just t -> do
          t.columns `shouldSatisfy` \cs -> length cs > 0
          t.columns `shouldSatisfy` \cs -> cs # filter (\c -> c.name == "name") # length # (_ == 1)
          t.columns `shouldSatisfy` \cs -> cs # filter (\c -> c.name == "price") # length # (_ == 1)

    it "parses value names" do
      src <- readTextFile UTF8 "test/Supabase/Schema.purs" # liftEffect
      let schema = parseSchema src
      case Object.lookup "Products" schema of
        Nothing -> "Products not found" `shouldEqual` ""
        Just t -> t.valueName `shouldEqual` "products"

  describe "Context" do
    it "detects selectColumns context" do
      let line = "x = client # from S.products # selectColumns @\"na"
      case detectContext line 50 line 0 of
        Just (SelectCtx { table, prefix }) -> do
          table `shouldEqual` "products"
          prefix `shouldEqual` "na"
        _ -> "no context" `shouldEqual` ""

    it "detects filter context" do
      let line = "x = client # from S.products # select # eq_ @\"pr"
      case detectContext line 49 line 0 of
        Just (FilterCtx { table, prefix }) -> do
          table `shouldEqual` "products"
          prefix `shouldEqual` "pr"
        _ -> "no context" `shouldEqual` ""

    it "detects nested relation depth" do
      let pos = parseSelectPosition "name, orders(tot"
      pos.prefix `shouldEqual` "tot"
      pos.depth `shouldEqual` ["orders"]

    it "handles double nesting" do
      let pos = parseSelectPosition "name, orders(id, order_items(pr"
      pos.prefix `shouldEqual` "pr"
      pos.depth `shouldEqual` ["orders", "order_items"]

    it "resets after closing paren" do
      let pos = parseSelectPosition "name, orders(id), pr"
      pos.prefix `shouldEqual` "pr"
      pos.depth `shouldEqual` []

    it "detects context on multiline pipeline" do
      let fullText = "test = do\n  client <- mkClient\n  client # from S.orders # selectColumns @\"sta"
      let line = "  client # from S.orders # selectColumns @\"sta"
      case detectContext line 46 fullText 2 of
        Just (SelectCtx { table, prefix }) -> do
          table `shouldEqual` "orders"
          prefix `shouldEqual` "sta"
        _ -> "no context" `shouldEqual` ""

    it "finds table from earlier line" do
      let fullText = "test = client\n  # from S.products\n  # selectColumns @\"na"
      let line = "  # selectColumns @\"na"
      case detectContext line 22 fullText 2 of
        Just (SelectCtx { table, prefix }) -> do
          table `shouldEqual` "products"
          prefix `shouldEqual` "na"
        _ -> "no context" `shouldEqual` ""

    it "returns Nothing outside @\"...\"" do
      let line = "x = client # from S.products # select"
      detectContext line 37 line 0 `shouldEqual` Nothing

    it "detects order context" do
      let line = "x = client # from S.products # select # order @\"pr"
      case detectContext line 51 line 0 of
        Just (FilterCtx { table, prefix }) -> do
          table `shouldEqual` "products"
          prefix `shouldEqual` "pr"
        _ -> "no context" `shouldEqual` ""
