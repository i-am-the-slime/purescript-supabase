module CompileFailTests.EqWrongValueType where

-- price is Number but we pass String — should fail
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
  _ <- client # from Schema.products # select # eq_ @"price" "ten" # run
  pure unit
