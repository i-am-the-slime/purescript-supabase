module Supabase.UUID
  ( UUID(..)
  ) where

import Prelude

import Data.Maybe (maybe)
import Data.Newtype (class Newtype)
import Data.UUID as UUID
import Foreign (ForeignError(..), readString, unsafeToForeign)
import Foreign (fail) as Foreign
import Yoga.JSON (class ReadForeign, class WriteForeign)

newtype UUID = UUID UUID.UUID

derive instance Newtype UUID _
derive newtype instance Eq UUID
derive newtype instance Ord UUID
derive newtype instance Show UUID

instance WriteForeign UUID where
  writeImpl (UUID u) = unsafeToForeign (UUID.toString u)

instance ReadForeign UUID where
  readImpl f = do
    s <- readString f
    maybe (Foreign.fail (ForeignError ("Invalid UUID: " <> s))) (pure <<< UUID) (UUID.parseUUID s)
