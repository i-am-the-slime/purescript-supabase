module CompileFailTests.ContainsWrongValueType where

-- contains with wrong value type should fail (tags :: Array String but passing Int)
import Prelude
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Supabase (createClient, from, select, contains, run)
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff Unit
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  _ <- client # from Schema.products # select # contains @"tags" (42 :: Int) # run
  pure unit
