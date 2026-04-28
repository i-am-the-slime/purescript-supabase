module CompileFailTests.InsertMissingRequired where

-- insertInto without required "name" field should fail
import Prelude
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Supabase (createClient, insertInto, runWith)
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff Unit
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  _ <- client # insertInto Schema.products {} # runWith @(Array {})
  pure unit
