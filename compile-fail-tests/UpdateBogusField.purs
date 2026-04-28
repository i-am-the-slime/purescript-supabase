module CompileFailTests.UpdateBogusField where

-- updating a field that doesn't exist in the table should fail
import Prelude
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Supabase (createClient, from, update, runWith)
import Supabase (eq_)
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff Unit
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  _ <- client # from Schema.products # update { nonexistent: "x" } # eq_ @"name" "Widget A" # runWith @(Array {})
  pure unit
