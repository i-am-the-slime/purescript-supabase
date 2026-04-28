module Test.Supabase.SSR where

import Prelude

import Data.Array (length, index)
import Data.Maybe (Maybe(..), isJust)
import Effect.Class (liftEffect)
import Effect.Ref as Ref
import Supabase (from, select, selectColumns, run, singleWith, schema, functionsSetAuth, createServerClient)
import Supabase (eq_)
import Supabase.SSR (parseCookieHeader, serializeCookieHeader)
import Supabase.Schema as Schema
import Data.Time.Duration (Seconds(..))
import Supabase.Auth.Types (AccessToken(..), CookieName(..), CookieValue(..))
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual, shouldSatisfy)
import Test.Supabase.Helpers (mkClient, unwrap)

spec :: Spec Unit
spec = describe "Supabase.SSR" do

  describe "createServerClient" do
    it "creates a working client with cookie adapters" do
      client <- createServerClient
        (SupabaseUrl "http://127.0.0.1:54321")
        (SupabaseAnonKey "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH")
        { getAll: pure []
        , setAll: \_ -> pure unit
        }
        # liftEffect
      rows <- client # from Schema.products # select # run >>= unwrap
      length rows `shouldEqual` 5

    it "calls getAll during auth operations" do
      getCalled <- Ref.new false # liftEffect
      client <- createServerClient
        (SupabaseUrl "http://127.0.0.1:54321")
        (SupabaseAnonKey "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH")
        { getAll: Ref.write true getCalled *> pure []
        , setAll: \_ -> pure unit
        }
        # liftEffect
      -- querying triggers cookie reads
      _ <- client # from Schema.products # selectColumns @"name" # eq_ @"name" "Widget A" # singleWith @{ name :: String }
      wasCalled <- Ref.read getCalled # liftEffect
      wasCalled `shouldEqual` true

  describe "parseCookieHeader" do
    it "parses empty string" do
      parseCookieHeader "" `shouldEqual` []

    it "parses single cookie" do
      let cookies = parseCookieHeader "session=abc123"
      length cookies `shouldEqual` 1
      (cookies !! 0 <#> _.name) `shouldEqual` Just (CookieName "session")
      (cookies !! 0 <#> _.value) `shouldEqual` Just (CookieValue "abc123")

    it "parses multiple cookies" do
      let cookies = parseCookieHeader "session=abc; theme=dark; lang=en"
      length cookies `shouldEqual` 3

    it "handles cookies with special characters" do
      let cookies = parseCookieHeader "token=eyJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSJ9.abc"
      length cookies `shouldEqual` 1
      (cookies !! 0 <#> _.value) `shouldSatisfy` case _ of
        Just v -> v == CookieValue "eyJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSJ9.abc"
        Nothing -> false

  describe "serializeCookieHeader" do
    it "serializes name and value" do
      result <- serializeCookieHeader (CookieName "session") (CookieValue "abc123") { path: Nothing, domain: Nothing, maxAge: Nothing, sameSite: Nothing, secure: Nothing, httpOnly: Nothing } # liftEffect
      result `shouldSatisfy` \s -> s == "session=abc123"

    it "serializes with path" do
      result <- serializeCookieHeader (CookieName "session") (CookieValue "abc") { path: Just "/", domain: Nothing, maxAge: Nothing, sameSite: Nothing, secure: Nothing, httpOnly: Nothing } # liftEffect
      result `shouldSatisfy` contains' "Path=/"

    it "serializes with maxAge" do
      result <- serializeCookieHeader (CookieName "session") (CookieValue "abc") { path: Nothing, domain: Nothing, maxAge: Just (Seconds 3600.0), sameSite: Nothing, secure: Nothing, httpOnly: Nothing } # liftEffect
      result `shouldSatisfy` contains' "Max-Age=3600"

  describe "schema" do
    it "queries the public schema by default" do
      client <- mkClient
      rows <- client # from Schema.products # select # run >>= unwrap
      length rows `shouldEqual` 5

    it "can explicitly switch to public schema" do
      client <- mkClient
      rows <- client # schema Schema.publicSchema # from Schema.products # select # run >>= unwrap
      length rows `shouldEqual` 5

  describe "functionsSetAuth" do
    it "does not throw" do
      client <- mkClient
      functionsSetAuth (AccessToken "fake-token") client # liftEffect

infixl 8 index as !!

foreign import indexOf :: String -> String -> Int

contains' :: String -> String -> Boolean
contains' needle s = indexOf needle s >= 0
