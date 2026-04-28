module CompileFailTests.ChainedBadColumns where

-- Multiple bad columns in a chain should all fail
import Prelude
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Supabase (createClient, from, select, run, gt, order)
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff Unit
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  _ <- client # from Schema.products # select # gt @"bad1" "5" # order @"bad2" # run
  pure unit
