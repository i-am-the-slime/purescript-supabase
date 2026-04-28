module CompileFailTests.EqColumnFromWrongTable where

-- user_id exists on UserPillars but not Products
import Prelude
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Supabase (createClient, from, select, run)
import Supabase (eq_)
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff Unit
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  _ <- client # from Schema.products # select # eq_ @"user_id" "abc" # run
  pure unit
