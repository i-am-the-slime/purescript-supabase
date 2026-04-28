module Supabase.Types
  ( BucketName(..)
  , Channel
  , ChannelName(..)
  , Rel
  , StoragePath(..)
  , Client
  , FunctionName(..)
  , Rpc
  , unRpc
  , SchemaName(..)
  , SupabaseAnonKey(..)
  , SupabaseUrl(..)
  , Table
  , unTable
  , TableName(..)
  , mkRpc
  , mkTable
  ) where

import Prelude

import Data.Newtype (class Newtype)

foreign import data Client :: Type

foreign import data Channel :: Type

newtype ChannelName = ChannelName String

derive instance Newtype ChannelName _
derive newtype instance Eq ChannelName
derive newtype instance Show ChannelName

newtype SupabaseUrl = SupabaseUrl String

derive instance Newtype SupabaseUrl _
derive newtype instance Eq SupabaseUrl
derive newtype instance Show SupabaseUrl

newtype SupabaseAnonKey = SupabaseAnonKey String

derive instance Newtype SupabaseAnonKey _
derive newtype instance Eq SupabaseAnonKey
derive newtype instance Show SupabaseAnonKey

newtype TableName = TableName String

derive instance Newtype TableName _
derive newtype instance Eq TableName
derive newtype instance Show TableName

data Rel :: Row Type -> Row Type -> Type
data Rel row rels

newtype Table :: Row Type -> Row Type -> Row Type -> Type
newtype Table row required relations = Table String

mkTable :: forall row required relations. String -> Table row required relations
mkTable = Table

unTable :: forall row required relations. Table row required relations -> String
unTable (Table s) = s

newtype Rpc :: Row Type -> Row Type -> Type
newtype Rpc params result = Rpc String

mkRpc :: forall params result. String -> Rpc params result
mkRpc = Rpc

unRpc :: forall params result. Rpc params result -> String
unRpc (Rpc s) = s

newtype BucketName = BucketName String

derive instance Newtype BucketName _
derive newtype instance Eq BucketName
derive newtype instance Show BucketName

newtype FunctionName = FunctionName String

derive instance Newtype FunctionName _
derive newtype instance Eq FunctionName
derive newtype instance Show FunctionName

newtype SchemaName = SchemaName String

derive instance Newtype SchemaName _
derive newtype instance Eq SchemaName
derive newtype instance Show SchemaName

newtype StoragePath = StoragePath String

derive instance Newtype StoragePath _
derive newtype instance Eq StoragePath
derive newtype instance Show StoragePath

