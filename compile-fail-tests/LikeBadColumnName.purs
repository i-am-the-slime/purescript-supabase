module CompileFailTests.LikeBadColumnName where

-- like with a nonexistent column should fail
import Prelude
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Supabase (createClient, from, select, run, like)
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff Unit
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  _ <- client # from Schema.products # select # like @"titel" "%" # run
  pure unit
