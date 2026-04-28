module CompileFailTests.InBadColumnName where

import Prelude
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Supabase (createClient, from, select, run, in_)
import Data.Array.NonEmpty (cons') as NEA
import Supabase.Schema as Schema
import Supabase.Types (SupabaseAnonKey(..), SupabaseUrl(..))

test :: Aff Unit
test = do
  client <- createClient (SupabaseUrl "x") (SupabaseAnonKey "y") # liftEffect
  _ <- client # from Schema.products # select # in_ @"fake_col" (NEA.cons' "a" []) # run
  pure unit
