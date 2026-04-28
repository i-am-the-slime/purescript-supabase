module CompileFailTests.OrBadColumn where

-- or with a condition referencing a nonexistent column should fail
import Prelude
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Data.Array.NonEmpty (cons') as NEA
import Supabase (createClient, from, select, or, run)
import Supabase.Filter (eqC)
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff Unit
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  _ <- client # from Schema.products # select # or (NEA.cons' (eqC @"bogus" "x") []) # run
  pure unit
