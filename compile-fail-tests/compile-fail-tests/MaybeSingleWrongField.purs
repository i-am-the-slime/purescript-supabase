module CompileFailTests.MaybeSingleWrongField where

-- maybeSingle should also enforce the schema on results
import Prelude
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Supabase (createClient, from, select, maybeSingle)
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff Unit
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  res <- client # from Schema.products # select # maybeSingle
  let _ = res.data <#> _.not_a_column
  pure unit
