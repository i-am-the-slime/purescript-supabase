module Test.Supabase.Helpers where

import Prelude

import Data.Maybe (Maybe(..))
import Effect (Effect)
import Effect.Aff (Aff, throwError)
import Effect.Class (liftEffect)
import Effect.Exception (error)
import Supabase (Response, createClient)
import Supabase.Types (Client, SupabaseAnonKey(..), SupabaseUrl(..))
import Node.Process.Environment as Env

mkClient :: Aff Client
mkClient = do
  url <- Env.lookup "SUPABASE_URL" "http://127.0.0.1:54321"
  key <- Env.lookup "SUPABASE_KEY" "sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH"
  createClient (SupabaseUrl url) (SupabaseAnonKey key) # liftEffect

unwrap :: forall a. Response a -> Aff a
unwrap res = case res.data, res.error of
  Just d, _ -> pure d
  _, Just err -> throwError (error ("Supabase error: " <> err.message))
  _, _ -> throwError (error "Response had no data and no error")

foreign import nowMs :: Effect Number
