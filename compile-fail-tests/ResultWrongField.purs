module CompileFailTests.ResultWrongField where

-- Accessing a field on the result that doesn't exist in the schema
import Prelude
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Supabase (createClient, from, select, single)
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff Unit
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  res <- client # from Schema.products # select # single
  let _ = res.data <#> _.nonexistent
  pure unit
