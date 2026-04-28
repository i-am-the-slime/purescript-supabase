module CompileFailTests.RpcWrongParamType where

-- callRpcWith with wrong param type should fail
import Prelude
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Supabase (createClient, callRpcWith, run)
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff Unit
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  -- max_price :: Number but passing String
  _ <- client # callRpcWith Schema.productsCheaperThan { max_price: "ten" } # run
  pure unit
