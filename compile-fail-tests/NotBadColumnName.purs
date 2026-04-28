module CompileFailTests.NotBadColumnName where

-- not with a nonexistent column should fail
import Prelude
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Supabase (createClient, from, select, run)
import Supabase (not_)
import Supabase.Filter (isTrue)
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff Unit
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  _ <- client # from Schema.products # select # not_ @"missing" isTrue # run
  pure unit
