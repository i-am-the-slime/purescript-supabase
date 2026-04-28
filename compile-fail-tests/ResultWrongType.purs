module CompileFailTests.ResultWrongType where

-- Treating price (Number) as String should fail
import Prelude
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Supabase (createClient, from, select, single)
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff String
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  res <- client # from Schema.products # select # single
  pure case res.data of
    Nothing -> ""
    Just r -> r.price
