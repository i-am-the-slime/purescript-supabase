module Supabase.Supabase
  ( Count(..)
  , CountR
  , CountResponse
  , DataR
  , ErrorR
  , FilterBuilder
  , OrderOptions
  , QueryBuilder
  , Response
  , ResultError
  , StatusR
  , callRpc
  , callRpcWith
  , contains
  , containedBy
  , class FilterType
  , csv
  , delete
  , eq_
  , from
  , gt
  , gte
  , ilike
  , in_
  , insert
  , IsValue(..)
  , insertInto
  , is
  , like
  , limit
  , lt
  , lte
  , maybeSingle
  , maybeSingleWith
  , neq
  , not_
  , or
  , order
  , orderWith
  , overlaps
  , range
  , run
  , runWith
  , schema
  , select
  , selectColumns
  , selectColumnsWithCount
  , single
  , singleWith
  , textSearch
  , TextSearchType(..)
  , update
  , upsert
  , upsertWith
  ) where

import Prelude

import Control.Promise (Promise)
import Control.Promise as Promise
import Data.Array.NonEmpty (NonEmptyArray, toArray)
import Data.Function.Uncurried (Fn1, Fn2, Fn3, Fn4, runFn1, runFn2, runFn3, runFn4)
import Data.Maybe (Maybe)
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Data.Symbol (class IsSymbol, reflectSymbol)
import Effect.Aff (Aff)
import Effect.Uncurried (EffectFn1, runEffectFn1, EffectFn3, runEffectFn3)
import Foreign (Foreign, unsafeToForeign)
import Prim.Row (class Cons, class Union)
import Supabase.Filter (Condition, FilterOp(..), unCondition)
import Supabase.Select (class ParseSelect)

import Supabase.Types (Client, Rpc, SchemaName(..), Table, unRpc, unTable)
import Supabase.Util as Util
import Type.Proxy (Proxy(..))
import Type.Row (type (+))
import Yoga.JSON (class ReadForeign, class WriteForeign, write, writeImpl)

foreign import data QueryBuilder :: Row Type -> Row Type -> Type
foreign import data FilterBuilder :: Row Type -> Row Type -> Type

-- Restricted values for the `is` filter (PostgREST only allows null, true, false)
data IsValue = IsNull | IsTrue | IsFalse

isValueToForeign :: IsValue -> Foreign
isValueToForeign IsNull = unsafeToForeign (Nullable.null :: Nullable Unit)
isValueToForeign IsTrue = unsafeToForeign true
isValueToForeign IsFalse = unsafeToForeign false

data Count = Exact | Planned | Estimated

countToString :: Count -> String
countToString Exact = "exact"
countToString Planned = "planned"
countToString Estimated = "estimated"

-- Unwrap Maybe for filter value types: column Maybe String -> filter takes String
class FilterType :: Type -> Type -> Constraint
class FilterType colType filterType | colType -> filterType

instance FilterType (Maybe a) a
else instance FilterType a a

-- from

foreign import fromImpl :: forall a. Fn2 Client String a

from :: forall row required rels. Table row required rels -> Client -> QueryBuilder row rels
from table client = runFn2 fromImpl client (unTable table)

-- schema

foreign import schemaImpl :: Fn2 String Client Client

schema :: SchemaName -> Client -> Client
schema (SchemaName name) client = runFn2 schemaImpl name client

-- delete

foreign import deleteImpl :: forall a b. Fn2 a Unit b

delete :: forall row rels. QueryBuilder row rels -> FilterBuilder row row
delete qb = runFn2 deleteImpl qb unit

-- update (fields must be subset of table row)

foreign import updateImpl :: forall a b. Fn2 a Foreign b

update :: forall row rels d rest. WriteForeign { | d } => Union d rest row => { | d } -> QueryBuilder row rels -> FilterBuilder row row
update d qb = runFn2 updateImpl qb (write d)

-- upsert (fields must be subset of table row)

foreign import upsertImpl :: forall a b. Fn2 a Foreign b

upsert :: forall row rels @d rest. WriteForeign { | d } => Union d rest row => { | d } -> QueryBuilder row rels -> FilterBuilder row row
upsert v qb = runFn2 upsertImpl qb (writeImpl v)

type UpsertOptions = { onConflict :: String }

foreign import upsertWithImpl :: forall a b. Fn3 Foreign UpsertOptions a b

upsertWith :: forall row rels d rest. WriteForeign { | d } => Union d rest row => { | d } -> UpsertOptions -> QueryBuilder row rels -> FilterBuilder row row
upsertWith v = runFn3 upsertWithImpl (writeImpl v)

-- insert (fields subset of table row + includes all required fields)
-- The QueryBuilder carries the row type. We need the required type from Table.
-- Solution: insertInto takes Table directly instead of using the builder.

foreign import insertImpl :: forall a b. Fn2 a Foreign b

-- insert into a QueryBuilder (doesn't check required - use insertInto for that)
insert :: forall row rels @d rest. WriteForeign { | d } => Union d rest row => { | d } -> QueryBuilder row rels -> FilterBuilder row row
insert v qb = runFn2 insertImpl qb (writeImpl v)

-- insertInto: takes Table directly, checks required fields
insertInto :: forall row required rels @d rest reqRest. WriteForeign { | d } => Union d rest row => Union required reqRest d => Table row required rels -> { | d } -> Client -> FilterBuilder row row
insertInto table v client = do
  let qb = runFn2 fromImpl client (unTable table)
  runFn2 insertImpl qb (writeImpl v)

-- select

foreign import selectImpl :: forall a b. Fn2 a String b

select :: forall row rels. QueryBuilder row rels -> FilterBuilder row row
select qb = runFn2 selectImpl qb "*"

-- selectColumns (type-level validated, supports embedded relations)

selectColumns :: forall @cols row rels result. IsSymbol cols => ParseSelect cols row rels result => QueryBuilder row rels -> FilterBuilder row result
selectColumns qb = runFn2 selectImpl qb (reflectSymbol (Proxy :: Proxy cols))

-- selectColumnsWithCount

foreign import selectColumnsWithCountImpl :: forall a b. Fn3 a String String b

selectColumnsWithCount :: forall @cols row rels result. IsSymbol cols => ParseSelect cols row rels result => Count -> QueryBuilder row rels -> FilterBuilder row result
selectColumnsWithCount count qb = runFn3 selectColumnsWithCountImpl qb (reflectSymbol (Proxy :: Proxy cols)) (countToString count)

-- run

foreign import runImpl :: forall a. EffectFn1 a (Promise Foreign)

run :: forall table result. ReadForeign { | result } => FilterBuilder table result -> Aff (Response (Array { | result }))
run fb = runEffectFn1 runImpl fb # Promise.toAffE >>= Util.fromJSON

runWith :: forall @t table result. ReadForeign t => FilterBuilder table result -> Aff (Response t)
runWith fb = runEffectFn1 runImpl fb # Promise.toAffE >>= Util.fromJSON

-- Typed filters: column checked + value type derived from column type

foreign import eqImpl :: forall a. Fn3 String Foreign a a

eq_ :: forall @col colType filterType table result rest. IsSymbol col => Cons col colType rest table => FilterType colType filterType => WriteForeign filterType => filterType -> FilterBuilder table result -> FilterBuilder table result
eq_ v fb = runFn3 eqImpl (reflectSymbol (Proxy :: Proxy col)) (writeImpl v) fb

foreign import neqImpl :: forall a. Fn3 String Foreign a a

neq :: forall @col colType filterType table result rest. IsSymbol col => Cons col colType rest table => FilterType colType filterType => WriteForeign filterType => filterType -> FilterBuilder table result -> FilterBuilder table result
neq v fb = runFn3 neqImpl (reflectSymbol (Proxy :: Proxy col)) (writeImpl v) fb

foreign import gtImpl :: forall a. Fn3 String Foreign a a

gt :: forall @col colType filterType table result rest. IsSymbol col => Cons col colType rest table => FilterType colType filterType => WriteForeign filterType => filterType -> FilterBuilder table result -> FilterBuilder table result
gt v fb = runFn3 gtImpl (reflectSymbol (Proxy :: Proxy col)) (writeImpl v) fb

foreign import gteImpl :: forall a. Fn3 String Foreign a a

gte :: forall @col colType filterType table result rest. IsSymbol col => Cons col colType rest table => FilterType colType filterType => WriteForeign filterType => filterType -> FilterBuilder table result -> FilterBuilder table result
gte v fb = runFn3 gteImpl (reflectSymbol (Proxy :: Proxy col)) (writeImpl v) fb

foreign import ltImpl :: forall a. Fn3 String Foreign a a

lt :: forall @col colType filterType table result rest. IsSymbol col => Cons col colType rest table => FilterType colType filterType => WriteForeign filterType => filterType -> FilterBuilder table result -> FilterBuilder table result
lt v fb = runFn3 ltImpl (reflectSymbol (Proxy :: Proxy col)) (writeImpl v) fb

foreign import lteImpl :: forall a. Fn3 String Foreign a a

lte :: forall @col colType filterType table result rest. IsSymbol col => Cons col colType rest table => FilterType colType filterType => WriteForeign filterType => filterType -> FilterBuilder table result -> FilterBuilder table result
lte v fb = runFn3 lteImpl (reflectSymbol (Proxy :: Proxy col)) (writeImpl v) fb

foreign import likeImpl :: forall a. Fn3 String Foreign a a

like :: forall @col colType filterType table result rest. IsSymbol col => Cons col colType rest table => FilterType colType filterType => WriteForeign filterType => filterType -> FilterBuilder table result -> FilterBuilder table result
like v fb = runFn3 likeImpl (reflectSymbol (Proxy :: Proxy col)) (writeImpl v) fb

foreign import ilikeImpl :: forall a. Fn3 String Foreign a a

ilike :: forall @col colType filterType table result rest. IsSymbol col => Cons col colType rest table => FilterType colType filterType => WriteForeign filterType => filterType -> FilterBuilder table result -> FilterBuilder table result
ilike v fb = runFn3 ilikeImpl (reflectSymbol (Proxy :: Proxy col)) (writeImpl v) fb

foreign import isImpl :: forall a. Fn3 String Foreign a a

is :: forall @col colType table result rest. IsSymbol col => Cons col colType rest table => IsValue -> FilterBuilder table result -> FilterBuilder table result
is v fb = runFn3 isImpl (reflectSymbol (Proxy :: Proxy col)) (isValueToForeign v) fb

foreign import notImpl :: forall a. Fn3 String String a a

not_ :: forall @col colType table result rest. IsSymbol col => Cons col colType rest table => FilterOp -> FilterBuilder table result -> FilterBuilder table result
not_ (FilterOp op) fb = runFn3 notImpl (reflectSymbol (Proxy :: Proxy col)) op fb

foreign import orImpl :: forall a. Fn2 (Array String) a a

or :: forall table result. NonEmptyArray (Condition table) -> FilterBuilder table result -> FilterBuilder table result
or conditions fb = runFn2 orImpl (toArray conditions # map unCondition) fb

foreign import inImpl :: forall a. Fn3 String (Array Foreign) a a

in_ :: forall @col colType filterType table result rest. IsSymbol col => Cons col colType rest table => FilterType colType filterType => WriteForeign filterType => NonEmptyArray filterType -> FilterBuilder table result -> FilterBuilder table result
in_ vals fb = runFn3 inImpl (reflectSymbol (Proxy :: Proxy col)) (toArray (map writeImpl vals)) fb

foreign import containsImpl :: forall a. Fn3 String Foreign a a

contains :: forall @col colType filterType table result rest. IsSymbol col => Cons col colType rest table => FilterType colType filterType => WriteForeign filterType => filterType -> FilterBuilder table result -> FilterBuilder table result
contains v fb = runFn3 containsImpl (reflectSymbol (Proxy :: Proxy col)) (writeImpl v) fb

foreign import containedByImpl :: forall a. Fn3 String Foreign a a

containedBy :: forall @col colType filterType table result rest. IsSymbol col => Cons col colType rest table => FilterType colType filterType => WriteForeign filterType => filterType -> FilterBuilder table result -> FilterBuilder table result
containedBy v fb = runFn3 containedByImpl (reflectSymbol (Proxy :: Proxy col)) (writeImpl v) fb

foreign import overlapsImpl :: forall a. Fn3 String Foreign a a

overlaps :: forall @col colType filterType table result rest. IsSymbol col => Cons col colType rest table => FilterType colType filterType => WriteForeign filterType => filterType -> FilterBuilder table result -> FilterBuilder table result
overlaps v fb = runFn3 overlapsImpl (reflectSymbol (Proxy :: Proxy col)) (writeImpl v) fb

foreign import textSearchImpl :: forall a. Fn4 String Foreign Foreign a a

data TextSearchType = Plain | Phrase | Websearch

textSearchTypeToString :: TextSearchType -> String
textSearchTypeToString = case _ of
  Plain -> "plain"
  Phrase -> "phrase"
  Websearch -> "websearch"

textSearch :: forall @col colType filterType table result rest. IsSymbol col => Cons col colType rest table => FilterType colType filterType => WriteForeign filterType => filterType -> { config :: String, "type" :: TextSearchType } -> FilterBuilder table result -> FilterBuilder table result
textSearch query opts fb = runFn4 textSearchImpl (reflectSymbol (Proxy :: Proxy col)) (writeImpl query) (writeImpl { config: opts.config, "type": textSearchTypeToString opts."type" }) fb

-- order

foreign import orderImpl :: forall a. Fn2 String a a

order :: forall @col val table result rest. IsSymbol col => Cons col val rest table => FilterBuilder table result -> FilterBuilder table result
order fb = runFn2 orderImpl (reflectSymbol (Proxy :: Proxy col)) fb

type OrderOptions = { ascending :: Boolean, nullsFirst :: Boolean }

foreign import orderWithImpl :: forall a. Fn3 String OrderOptions a a

orderWith :: forall @col val table result rest. IsSymbol col => Cons col val rest table => OrderOptions -> FilterBuilder table result -> FilterBuilder table result
orderWith opts fb = runFn3 orderWithImpl (reflectSymbol (Proxy :: Proxy col)) opts fb

-- limit

foreign import limitImpl :: forall a. Fn2 Int a a

limit :: forall table result. Int -> FilterBuilder table result -> FilterBuilder table result
limit = runFn2 limitImpl

-- csv

foreign import csvImpl :: forall a. Fn1 a a

csv :: forall table result. FilterBuilder table result -> FilterBuilder table result
csv = runFn1 csvImpl

-- callRpc (typed)

foreign import rpcImpl :: forall a. Fn2 Client String a

callRpc :: forall params result. Rpc params result -> Client -> FilterBuilder result result
callRpc rpc client = runFn2 rpcImpl client (unRpc rpc)

foreign import rpcWithImpl :: forall a. Fn3 Client String Foreign a

callRpcWith :: forall params result. WriteForeign { | params } => Rpc params result -> { | params } -> Client -> FilterBuilder result result
callRpcWith rpc params client = runFn3 rpcWithImpl client (unRpc rpc) (writeImpl params)

-- single

foreign import singleImpl :: forall a. EffectFn1 a (Promise Foreign)

single :: forall table result. ReadForeign { | result } => FilterBuilder table result -> Aff (Response { | result })
single fb = runEffectFn1 singleImpl fb # Promise.toAffE >>= Util.fromJSON

singleWith :: forall @t table result. ReadForeign t => FilterBuilder table result -> Aff (Response t)
singleWith fb = runEffectFn1 singleImpl fb # Promise.toAffE >>= Util.fromJSON

-- maybeSingle

foreign import maybeSingleImpl :: forall a. EffectFn1 a (Promise Foreign)

maybeSingle :: forall table result. ReadForeign { | result } => FilterBuilder table result -> Aff (Response { | result })
maybeSingle fb = runEffectFn1 maybeSingleImpl fb # Promise.toAffE >>= Util.fromJSON

maybeSingleWith :: forall @t table result. ReadForeign t => FilterBuilder table result -> Aff (Response t)
maybeSingleWith fb = runEffectFn1 maybeSingleImpl fb # Promise.toAffE >>= Util.fromJSON

-- range

foreign import rangeImpl :: forall a. EffectFn3 Int Int a (Promise Foreign)

range :: forall table result. ReadForeign { | result } => { from :: Int, to :: Int } -> FilterBuilder table result -> Aff (Response (Array { | result }))
range { from: f, to } fb = runEffectFn3 rangeImpl f to fb # Promise.toAffE >>= Util.fromJSON

-- Response types

type ResultError = { code :: Maybe String, details :: Maybe String, message :: String }

type DataR d r = (data :: Maybe d | r)
type ErrorR r = (error :: Maybe ResultError | r)
type CountR r = (count :: Int | r)
type StatusR r = (status :: Int | r)

type Response d = { | DataR d + ErrorR + StatusR + () }

type CountResponse t = { | DataR t + ErrorR + CountR + StatusR + () }
