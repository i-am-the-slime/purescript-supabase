module Supabase.Filter
  ( Condition
  , unCondition
  , FilterOp(..)
  , class FilterVal
  , class ToPostgrest
  , eqC
  , eqOp
  , gtC
  , gtOp
  , gteC
  , gteOp
  , ilikeC
  , ilikeOp
  , isFalse
  , isNull
  , isNullC
  , isTrue
  , likeC
  , likeOp
  , ltC
  , ltOp
  , lteC
  , lteOp
  , neqC
  , neqOp
  , toPostgrest
  ) where

import Prelude

import Data.Maybe (Maybe)
import Data.Symbol (class IsSymbol, reflectSymbol)
import Prim.Row (class Cons)
import Type.Proxy (Proxy(..))

-- Condition: a typed filter expression for use in `or`
-- Carries the table row as a phantom type to ensure column validity

newtype Condition (table :: Row Type) = Condition String

unCondition :: forall table. Condition table -> String
unCondition (Condition s) = s

-- Convert value to PostgREST string representation
class ToPostgrest a where
  toPostgrest :: a -> String

instance ToPostgrest String where
  toPostgrest = identity

instance ToPostgrest Int where
  toPostgrest = show

instance ToPostgrest Number where
  toPostgrest = show

instance ToPostgrest Boolean where
  toPostgrest b = if b then "true" else "false"

-- Unwrap Maybe for filter types
class FilterVal :: Type -> Type -> Constraint
class FilterVal colType filterType | colType -> filterType

instance FilterVal (Maybe a) a
else instance FilterVal a a

-- Condition builders

eqC :: forall @col colType filterType table rest. IsSymbol col => Cons col colType rest table => FilterVal colType filterType => ToPostgrest filterType => filterType -> Condition table
eqC v = Condition (reflectSymbol (Proxy :: Proxy col) <> ".eq." <> toPostgrest v)

neqC :: forall @col colType filterType table rest. IsSymbol col => Cons col colType rest table => FilterVal colType filterType => ToPostgrest filterType => filterType -> Condition table
neqC v = Condition (reflectSymbol (Proxy :: Proxy col) <> ".neq." <> toPostgrest v)

gtC :: forall @col colType filterType table rest. IsSymbol col => Cons col colType rest table => FilterVal colType filterType => ToPostgrest filterType => filterType -> Condition table
gtC v = Condition (reflectSymbol (Proxy :: Proxy col) <> ".gt." <> toPostgrest v)

gteC :: forall @col colType filterType table rest. IsSymbol col => Cons col colType rest table => FilterVal colType filterType => ToPostgrest filterType => filterType -> Condition table
gteC v = Condition (reflectSymbol (Proxy :: Proxy col) <> ".gte." <> toPostgrest v)

ltC :: forall @col colType filterType table rest. IsSymbol col => Cons col colType rest table => FilterVal colType filterType => ToPostgrest filterType => filterType -> Condition table
ltC v = Condition (reflectSymbol (Proxy :: Proxy col) <> ".lt." <> toPostgrest v)

lteC :: forall @col colType filterType table rest. IsSymbol col => Cons col colType rest table => FilterVal colType filterType => ToPostgrest filterType => filterType -> Condition table
lteC v = Condition (reflectSymbol (Proxy :: Proxy col) <> ".lte." <> toPostgrest v)

likeC :: forall @col colType filterType table rest. IsSymbol col => Cons col colType rest table => FilterVal colType filterType => ToPostgrest filterType => filterType -> Condition table
likeC v = Condition (reflectSymbol (Proxy :: Proxy col) <> ".like." <> toPostgrest v)

ilikeC :: forall @col colType filterType table rest. IsSymbol col => Cons col colType rest table => FilterVal colType filterType => ToPostgrest filterType => filterType -> Condition table
ilikeC v = Condition (reflectSymbol (Proxy :: Proxy col) <> ".ilike." <> toPostgrest v)

isNullC :: forall @col colType table rest. IsSymbol col => Cons col colType rest table => Condition table
isNullC = Condition (reflectSymbol (Proxy :: Proxy col) <> ".is.null")

-- FilterOp: structured operator for `not`
-- Used as: not @"in_stock" isTrue

newtype FilterOp = FilterOp String

isTrue :: FilterOp
isTrue = FilterOp "is.true"

isFalse :: FilterOp
isFalse = FilterOp "is.false"

isNull :: FilterOp
isNull = FilterOp "is.null"

eqOp :: forall a. ToPostgrest a => a -> FilterOp
eqOp v = FilterOp ("eq." <> toPostgrest v)

neqOp :: forall a. ToPostgrest a => a -> FilterOp
neqOp v = FilterOp ("neq." <> toPostgrest v)

gtOp :: forall a. ToPostgrest a => a -> FilterOp
gtOp v = FilterOp ("gt." <> toPostgrest v)

gteOp :: forall a. ToPostgrest a => a -> FilterOp
gteOp v = FilterOp ("gte." <> toPostgrest v)

ltOp :: forall a. ToPostgrest a => a -> FilterOp
ltOp v = FilterOp ("lt." <> toPostgrest v)

lteOp :: forall a. ToPostgrest a => a -> FilterOp
lteOp v = FilterOp ("lte." <> toPostgrest v)

likeOp :: String -> FilterOp
likeOp v = FilterOp ("like." <> v)

ilikeOp :: String -> FilterOp
ilikeOp v = FilterOp ("ilike." <> v)
