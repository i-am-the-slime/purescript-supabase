-- Test schema for compile-fail golden tests
module Supabase.Schema
  ( Products
  , ProductsRequired
  , products
  ) where

import Data.Maybe (Maybe)
import Supabase.Types (Table, mkTable)

type Products =
  ( id :: Int
  , name :: String
  , description :: Maybe String
  , price :: Number
  , tags :: Array String
  , in_stock :: Boolean
  )

type ProductsRequired =
  (name :: String)

products :: Table Products ProductsRequired ()
products = mkTable "products"
