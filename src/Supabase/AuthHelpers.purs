module Supabase.AuthHelpers
  ( ClientOptions
  , CookieOptions
  , Options
  , UseUser
  , createClient
  , createBrowserClient
  , createBrowserClientWithOptions
  ) where

import Prelude

import Data.Maybe (Maybe)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn2, runEffectFn1, runEffectFn2)
import Foreign (Foreign)
import Data.Newtype (un)
import Supabase.Types (Client, SupabaseAnonKey(..), SupabaseUrl(..))
import Yoga.JSON (class WriteForeign)
import Yoga.JSON as YogaJSON

foreign import data UseUser :: Type -> Type

foreign import createClientImpl :: EffectFn2 String String Client

createClient :: SupabaseUrl -> SupabaseAnonKey -> Effect Client
createClient url key = runEffectFn2 createClientImpl (un SupabaseUrl url) (un SupabaseAnonKey key)

foreign import createBrowserClientImpl :: EffectFn2 String String Client

createBrowserClient :: SupabaseUrl -> SupabaseAnonKey -> Effect Client
createBrowserClient url key = runEffectFn2 createBrowserClientImpl (un SupabaseUrl url) (un SupabaseAnonKey key)

type CookieOptions =
  { domain :: Maybe String
  , httpOnly :: Maybe Boolean
  , maxAge :: Maybe Int
  , name :: Maybe String
  , path :: Maybe String
  , sameSite :: Maybe String
  , secure :: Maybe Boolean
  }

type Options =
  { db :: Maybe String
  }

type ClientOptions r =
  { cookieOptions :: Maybe CookieOptions
  , options :: Maybe Options
  , supabaseKey :: Maybe String
  , supabaseUrl :: Maybe String
  | r
  }

foreign import createBrowserClientWithOptionsImpl :: EffectFn1 Foreign Client

createBrowserClientWithOptions :: forall r. WriteForeign (ClientOptions r) => ClientOptions r -> Effect Client
createBrowserClientWithOptions = YogaJSON.write >>> runEffectFn1 createBrowserClientWithOptionsImpl
