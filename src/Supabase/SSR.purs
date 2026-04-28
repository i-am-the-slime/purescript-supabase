module Supabase.SSR
  ( Cookie
  , CookieOptions
  , CookieMethods
  , CookieWithOptions
  , createServerClient
  , createBrowserClient
  , parseCookieHeader
  , serializeCookieHeader
  ) where

import Prelude

import Data.Maybe (Maybe)
import Data.Newtype (un)
import Data.Nullable (Nullable, toNullable)
import Effect (Effect)
import Effect.Uncurried (EffectFn1, EffectFn3, mkEffectFn1, runEffectFn3)
import Data.Newtype (un)
import Data.Time.Duration (Seconds(..))
import Supabase.Auth.Types (CookieName(..), CookieValue(..))
import Supabase.Types (Client, SupabaseAnonKey(..), SupabaseUrl(..))

type Cookie = { name :: CookieName, value :: CookieValue }

type CookieOptions =
  { path :: Maybe String
  , domain :: Maybe String
  , maxAge :: Maybe Seconds
  , sameSite :: Maybe String
  , secure :: Maybe Boolean
  , httpOnly :: Maybe Boolean
  }

type CookieWithOptions = { name :: CookieName, value :: CookieValue, options :: CookieOptions }

type CookieMethods =
  { getAll :: Effect (Array Cookie)
  , setAll :: Array CookieWithOptions -> Effect Unit
  }

-- createServerClient

foreign import createServerClientImpl :: EffectFn3 String String { cookies :: { getAll :: Effect (Array Cookie), setAll :: EffectFn1 (Array CookieWithOptions) Unit } } Client

createServerClient :: SupabaseUrl -> SupabaseAnonKey -> CookieMethods -> Effect Client
createServerClient url key methods =
  runEffectFn3 createServerClientImpl
    (un SupabaseUrl url)
    (un SupabaseAnonKey key)
    { cookies: { getAll: methods.getAll, setAll: mkEffectFn1 methods.setAll } }

-- createBrowserClient (re-export from SSR package)

foreign import createBrowserClientImpl :: EffectFn3 String String {} Client

createBrowserClient :: SupabaseUrl -> SupabaseAnonKey -> Effect Client
createBrowserClient url key =
  runEffectFn3 createBrowserClientImpl (un SupabaseUrl url) (un SupabaseAnonKey key) {}

-- parseCookieHeader

foreign import parseCookieHeaderImpl :: String -> Array Cookie

parseCookieHeader :: String -> Array Cookie
parseCookieHeader = parseCookieHeaderImpl

-- serializeCookieHeader

type JsCookieOptions =
  { path :: Nullable String
  , domain :: Nullable String
  , maxAge :: Nullable Number
  , sameSite :: Nullable String
  , secure :: Nullable Boolean
  , httpOnly :: Nullable Boolean
  }

foreign import serializeCookieHeaderImpl :: EffectFn3 String String JsCookieOptions String

serializeCookieHeader :: CookieName -> CookieValue -> CookieOptions -> Effect String
serializeCookieHeader (CookieName name) (CookieValue value) opts = runEffectFn3 serializeCookieHeaderImpl name value
  { path: toNullable opts.path
  , domain: toNullable opts.domain
  , maxAge: toNullable (opts.maxAge <#> un Seconds)
  , sameSite: toNullable opts.sameSite
  , secure: toNullable opts.secure
  , httpOnly: toNullable opts.httpOnly
  }
