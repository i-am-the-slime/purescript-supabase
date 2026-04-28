module CompileFailTests.InsertBogusField where

-- inserting a field that doesn't exist in the table should fail
import Prelude
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Supabase (createClient, from, insert, runWith)
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff Unit
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  _ <- client # from Schema.products # insert { bogus_field: 42 } # runWith @(Array {})
  pure unit
