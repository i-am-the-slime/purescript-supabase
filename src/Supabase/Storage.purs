module Supabase.Storage
  ( FileOptions
  , ListOptions
  , ListOptionsR
  , Storage
  , StorageBucket
  , copy
  , createSignedUrl
  , createSignedUrls
  , download
  , exists
  , from
  , fromStorage
  , getPublicUrl
  , list
  , move
  , remove
  , storage
  , upload
  ) where

import Prelude

import Control.Promise (Promise)
import Control.Promise as Promise
import Data.Function.Uncurried (Fn1, Fn2, runFn1, runFn2)
import Data.Maybe (Maybe)
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Effect.Aff (Aff)
import Effect.Uncurried (EffectFn2, EffectFn3, EffectFn4, runEffectFn2, runEffectFn3, runEffectFn4)
import Foreign (Foreign)
import Prim.Row (class Union)
import Yoga.JSON (class WriteForeign, write)
import Supabase.Supabase (Response, ResultError)
import Data.Newtype (un)
import Supabase.Types (BucketName(..), Client, StoragePath(..))
import Supabase.Util as Util
import Web.File.Blob (Blob)
import Web.File.File as File
import Data.Time.Duration (Seconds)

foreign import data Storage :: Type
foreign import data StorageBucket :: Type

-- storage

foreign import storageImpl :: Fn1 Client Storage

storage :: Client -> Storage
storage = runFn1 storageImpl

-- from

foreign import fromImpl :: Fn2 Storage String StorageBucket

from :: BucketName -> Storage -> StorageBucket
from name s = runFn2 fromImpl s (un BucketName name)

fromStorage :: BucketName -> Client -> StorageBucket
fromStorage name client = from name (storage client)

-- upload

type FileOptions = { upsert :: Boolean }

foreign import uploadImpl :: EffectFn4 StorageBucket String File.File FileOptions (Promise Foreign)

upload :: StoragePath -> File.File -> FileOptions -> StorageBucket -> Aff (Response { path :: String })
upload (StoragePath filePath) file fileOptions bucket =
  runEffectFn4 uploadImpl bucket filePath file fileOptions # Promise.toAffE >>= Util.fromJSON

-- download

foreign import downloadImpl :: EffectFn2 StorageBucket String (Promise { "data" :: Nullable Blob, error :: Nullable ResultError, status :: Int })

download :: StoragePath -> StorageBucket -> Aff (Response Blob)
download (StoragePath file) bucket = runEffectFn2 downloadImpl bucket file # Promise.toAffE <#> convert
  where
  convert { "data": d, error: err, status } =
    { "data": Nullable.toMaybe d, error: Nullable.toMaybe err, status }

-- remove

foreign import removeImpl :: EffectFn2 StorageBucket (Array String) (Promise Foreign)

remove :: Array StoragePath -> StorageBucket -> Aff { error :: Maybe ResultError }
remove files bucket = runEffectFn2 removeImpl bucket (map (\(StoragePath s) -> s) files) # Promise.toAffE >>= Util.fromJSON

-- createSignedUrl

foreign import createSignedUrlImpl :: EffectFn3 StorageBucket String Seconds (Promise Foreign)

createSignedUrl :: StoragePath -> Seconds -> StorageBucket -> Aff (Response { signedUrl :: String })
createSignedUrl (StoragePath file) expiry bucket = runEffectFn3 createSignedUrlImpl bucket file expiry # Promise.toAffE >>= Util.fromJSON

-- createSignedUrls

foreign import createSignedUrlsImpl :: EffectFn3 StorageBucket (Array String) Seconds (Promise Foreign)

createSignedUrls :: Array StoragePath -> Seconds -> StorageBucket -> Aff (Response (Array { signedUrl :: String, path :: String, error :: Maybe String }))
createSignedUrls files expiry bucket = runEffectFn3 createSignedUrlsImpl bucket (map (\(StoragePath s) -> s) files) expiry # Promise.toAffE >>= Util.fromJSON

-- getPublicUrl

foreign import getPublicUrlImpl :: Fn2 StorageBucket String { "data" :: { publicUrl :: String } }

getPublicUrl :: StoragePath -> StorageBucket -> String
getPublicUrl (StoragePath file) bucket = (runFn2 getPublicUrlImpl bucket file)."data".publicUrl

-- list

type ListOptions = { limit :: Int, offset :: Int, sortBy :: { column :: String, order :: String } }

type ListOptionsR = (limit :: Int, offset :: Int, sortBy :: { column :: String, order :: String })

foreign import listImpl :: EffectFn3 StorageBucket String Foreign (Promise Foreign)

list :: forall opts thru. WriteForeign { | opts } => Union opts thru ListOptionsR => StoragePath -> { | opts } -> StorageBucket -> Aff { data :: Maybe (Array { name :: String, id :: Maybe String }), error :: Maybe ResultError }
list (StoragePath prefix) opts bucket = runEffectFn3 listImpl bucket prefix (write opts) # Promise.toAffE >>= Util.fromJSON

-- move

foreign import moveImpl :: EffectFn3 StorageBucket String String (Promise Foreign)

move :: StoragePath -> StoragePath -> StorageBucket -> Aff { error :: Maybe ResultError }
move (StoragePath fromPath) (StoragePath toPath) bucket = runEffectFn3 moveImpl bucket fromPath toPath # Promise.toAffE >>= Util.fromJSON

-- copy

foreign import copyImpl :: EffectFn3 StorageBucket String String (Promise Foreign)

copy :: StoragePath -> StoragePath -> StorageBucket -> Aff { error :: Maybe ResultError }
copy (StoragePath fromPath) (StoragePath toPath) bucket = runEffectFn3 copyImpl bucket fromPath toPath # Promise.toAffE >>= Util.fromJSON

-- exists

foreign import existsImpl :: EffectFn2 StorageBucket String (Promise Foreign)

exists :: StoragePath -> StorageBucket -> Aff { data :: Boolean, error :: Maybe ResultError }
exists (StoragePath file) bucket = runEffectFn2 existsImpl bucket file # Promise.toAffE >>= Util.fromJSON
