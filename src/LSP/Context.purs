module LSP.Context
  ( CompletionContext(..)
  , detectContext
  , parseSelectPosition
  ) where

import Prelude

import Data.Array (index, findMap, snoc, init)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (Pattern(..), indexOf, lastIndexOf, drop, take, trim, length, split)
import Data.String.CodeUnits (singleton, toCharArray)
import Data.Foldable (foldl)

data CompletionContext
  = SelectCtx { table :: String, prefix :: String, depth :: Array String }
  | FilterCtx { table :: String, prefix :: String }

detectContext :: String -> Int -> String -> Int -> Maybe CompletionContext
detectContext line col fullText lineNum = do
  let before = take col line
  atQuoteIdx <- lastIndexOf (Pattern "@\"") before
  let insideStr = drop (atQuoteIdx + 2) before
  let beforeAt = trim (take atQuoteIdx before)
  table <- findTableInPipeline fullText lineNum
  if isSelectFn beforeAt then do
    let pos = parseSelectPosition insideStr
    Just (SelectCtx { table, prefix: pos.prefix, depth: pos.depth })
  else if isFilterFn beforeAt then
    Just (FilterCtx { table, prefix: insideStr })
  else Nothing

isSelectFn :: String -> Boolean
isSelectFn s = endsWith "selectColumns" s || endsWith "selectColumnsWithCount" s

isFilterFn :: String -> Boolean
isFilterFn s = ["eq_", "neq", "gt", "gte", "lt", "lte", "like", "ilike", "is", "not_", "in_", "order", "orderWith", "contains", "containedBy", "overlaps", "textSearch"]
  # findMap (\fn -> if endsWith fn s then Just unit else Nothing)
  # case _ of
      Just _ -> true
      Nothing -> false

endsWith :: String -> String -> Boolean
endsWith suffix s = do
  let sLen = length s
  let suffLen = length suffix
  sLen >= suffLen && drop (sLen - suffLen) s == suffix

parseSelectPosition :: String -> { prefix :: String, depth :: Array String }
parseSelectPosition inside = do
  let result = toCharArray inside # foldl go { depth: [], current: "" }
  { prefix: trim result.current, depth: result.depth }
  where
  go state c
    | c == '(' = state { depth = snoc state.depth (trim state.current), current = "" }
    | c == ')' = state { depth = fromMaybe state.depth (init state.depth), current = "" }
    | c == ',' = state { current = "" }
    | otherwise = state { current = state.current <> singleton c }

findTableInPipeline :: String -> Int -> Maybe String
findTableInPipeline text lineNum = do
  let lines = split (Pattern "\n") text
  go lines lineNum
  where
  go lines i
    | i < 0 = Nothing
    | otherwise = case index lines i of
        Nothing -> Nothing
        Just line -> case findFromTable line of
          Just t -> Just t
          Nothing -> go lines (i - 1)

  findFromTable line = do
    idx <- indexOf (Pattern "from ") line
    let after = drop (idx + 5) line
    dotIdx <- indexOf (Pattern ".") after
    let afterDot = drop (dotIdx + 1) after
    Just (takeUntilSep afterDot)

  takeUntilSep s = case indexOf (Pattern " ") s of
    Just i -> take i s
    Nothing -> case indexOf (Pattern "#") s of
      Just i -> take i s
      Nothing -> trim s
