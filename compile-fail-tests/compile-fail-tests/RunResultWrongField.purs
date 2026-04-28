module CompileFailTests.RunResultWrongField where

-- run returns Array { | Products }, accessing wrong field on elements
import Prelude
import Data.Maybe (Maybe(..))
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Supabase (createClient, from, select, run)
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff Unit
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  res <- client # from Schema.products # select # run
  case res.data of
    Just rows -> let _ = map _.bogus rows in pure unit
    _ -> pure unit
