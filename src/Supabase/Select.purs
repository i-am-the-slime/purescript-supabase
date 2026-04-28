module Supabase.Select where

import Prim.Row (class Cons)
import Prim.RowList (class RowToList, RowList)
import Prim.RowList (Cons, Nil) as RL
import Prim.Symbol (class Cons, class Append) as Symbol
import Prim.TypeError (class Fail, Above, Beside, Quote, Text)
import Supabase.Types (Rel)
import Type.RowList (class ListToRow)

-- Parse a comma-separated select string against a row (and optional relations) to compute the result row.
-- e.g. ParseSelect "name, price" (name :: String, price :: Number, id :: Int) () (name :: String, price :: Number)
-- e.g. ParseSelect "name, orders(id, total)" Products ProductsRels (name :: String, orders :: Array { id :: Int, total :: Number })

class ParseSelect :: Symbol -> Row Type -> Row Type -> Row Type -> Constraint
class ParseSelect sym row rels result | sym row rels -> result

instance ParseSelect "" row rels ()
else instance
  ( Symbol.Cons h t sym
  , ParseSelectGo h t "" row rels RL.Nil outRL
  , ListToRow outRL result
  ) =>
  ParseSelect sym row rels result

-- State machine: character by character

class ParseSelectGo :: Symbol -> Symbol -> Symbol -> Row Type -> Row Type -> RowList Type -> RowList Type -> Constraint
class ParseSelectGo head tail acc row rels accRL outRL | head tail acc row rels accRL -> outRL

-- Star: pass through all columns (not relations)
instance
  ( RowToList row rl
  , ListToRow rl result
  , RowToList result resultRL
  , SkipRest tail
  ) =>
  ParseSelectGo "*" tail acc row rels accRL resultRL

-- Open paren: resolve accumulated name as a relation, parse inner columns (supports nesting)
else instance
  ( ResolveRelation acc rels relatedRow relatedRels
  , ParseRelationColumns tail relatedRow relatedRels innerRL rest
  , ListToRow innerRL innerRow
  , ParseSelectAfterRelation rest row rels (RL.Cons acc (Array { | innerRow }) accRL) outRL
  ) =>
  ParseSelectGo "(" tail acc row rels accRL outRL

-- Comma: resolve accumulated column, continue
else instance
  ( ResolveColumn acc row typ
  , SkipSpaces tail rest
  , ParseSelectContinue rest row rels (RL.Cons acc typ accRL) outRL
  ) =>
  ParseSelectGo "," tail acc row rels accRL outRL

-- Space: resolve accumulated column (might be followed by comma or end)
else instance
  ( ResolveColumn acc row typ
  , SkipSpaces tail rest
  , ParseSelectAfterCol rest row rels (RL.Cons acc typ accRL) outRL
  ) =>
  ParseSelectGo " " tail acc row rels accRL outRL

-- End of string: resolve final column
else instance
  ( Symbol.Append acc h acc'
  , ResolveColumn acc' row typ
  ) =>
  ParseSelectGo h "" acc row rels accRL (RL.Cons acc' typ accRL)

-- Regular character: accumulate
else instance
  ( Symbol.Append acc h acc'
  , Symbol.Cons nextH nextT tail
  , ParseSelectGo nextH nextT acc' row rels accRL outRL
  ) =>
  ParseSelectGo h tail acc row rels accRL outRL

-- After resolving a column, check what comes next

class ParseSelectAfterCol :: Symbol -> Row Type -> Row Type -> RowList Type -> RowList Type -> Constraint
class ParseSelectAfterCol sym row rels accRL outRL | sym row rels accRL -> outRL

-- End of string
instance ParseSelectAfterCol "" row rels accRL accRL

-- Comma or more: continue to next column
else instance
  ( SkipSpaces tail rest
  , ParseSelectContinue rest row rels accRL outRL
  ) =>
  ParseSelectAfterCol sym row rels accRL outRL

-- After closing a relation paren, check what comes next

class ParseSelectAfterRelation :: Symbol -> Row Type -> Row Type -> RowList Type -> RowList Type -> Constraint
class ParseSelectAfterRelation sym row rels accRL outRL | sym row rels accRL -> outRL

instance ParseSelectAfterRelation "" row rels accRL accRL

else instance
  ( Symbol.Cons h t sym
  , ParseSelectAfterRelationGo h t row rels accRL outRL
  ) =>
  ParseSelectAfterRelation sym row rels accRL outRL

class ParseSelectAfterRelationGo :: Symbol -> Symbol -> Row Type -> Row Type -> RowList Type -> RowList Type -> Constraint
class ParseSelectAfterRelationGo head tail row rels accRL outRL | head tail row rels accRL -> outRL

-- Comma after relation: continue
instance
  ( SkipSpaces tail rest
  , ParseSelectContinue rest row rels accRL outRL
  ) =>
  ParseSelectAfterRelationGo "," tail row rels accRL outRL

-- Space after relation: skip then check
else instance
  ( SkipSpaces tail rest
  , ParseSelectAfterRelation rest row rels accRL outRL
  ) =>
  ParseSelectAfterRelationGo " " tail row rels accRL outRL

-- Continue parsing after a comma

class ParseSelectContinue :: Symbol -> Row Type -> Row Type -> RowList Type -> RowList Type -> Constraint
class ParseSelectContinue sym row rels accRL outRL | sym row rels accRL -> outRL

instance ParseSelectContinue "" row rels accRL accRL
else instance
  ( Symbol.Cons h t sym
  , ParseSelectGo h t "" row rels accRL outRL
  ) =>
  ParseSelectContinue sym row rels accRL outRL

-- Parse columns inside relation parentheses: "id, total_price)"
-- Returns the parsed RowList and the remaining string after ")"

class ParseRelationColumns :: Symbol -> Row Type -> Row Type -> RowList Type -> Symbol -> Constraint
class ParseRelationColumns sym row rels outRL rest | sym row rels -> outRL rest

instance
  ( SkipSpaces sym trimmed
  , Symbol.Cons h t trimmed
  , ParseRelColsGo h t "" row rels RL.Nil outRL rest
  ) =>
  ParseRelationColumns sym row rels outRL rest

class ParseRelColsGo :: Symbol -> Symbol -> Symbol -> Row Type -> Row Type -> RowList Type -> RowList Type -> Symbol -> Constraint
class ParseRelColsGo head tail acc row rels accRL outRL rest | head tail acc row rels accRL -> outRL rest

-- Close paren: resolve final column, done
instance
  ( ResolveColumn acc row typ
  ) =>
  ParseRelColsGo ")" tail acc row rels accRL (RL.Cons acc typ accRL) tail

-- Open paren inside relation: nested relation
else instance
  ( ResolveRelation acc rels nestedRow nestedRels
  , ParseRelationColumns tail nestedRow nestedRels innerRL rest1
  , ListToRow innerRL innerRow
  , ParseRelColsAfterNested rest1 row rels (RL.Cons acc (Array { | innerRow }) accRL) outRL rest
  ) =>
  ParseRelColsGo "(" tail acc row rels accRL outRL rest

-- Comma: resolve column, continue
else instance
  ( ResolveColumn acc row typ
  , SkipSpaces tail trimmed
  , Symbol.Cons nextH nextT trimmed
  , ParseRelColsGo nextH nextT "" row rels (RL.Cons acc typ accRL) outRL rest
  ) =>
  ParseRelColsGo "," tail acc row rels accRL outRL rest

-- Space before comma or paren: resolve column, skip spaces
else instance
  ( ResolveColumn acc row typ
  , SkipSpaces tail trimmed
  , Symbol.Cons nextH nextT trimmed
  , ParseRelColsAfterSpace nextH nextT row rels (RL.Cons acc typ accRL) outRL rest
  ) =>
  ParseRelColsGo " " tail acc row rels accRL outRL rest

-- End of string inside parens: error
else instance
  ( Symbol.Append acc h acc'
  , ResolveColumn acc' row typ
  ) =>
  ParseRelColsGo h "" acc row rels accRL (RL.Cons acc' typ accRL) ""

-- Regular character: accumulate
else instance
  ( Symbol.Append acc h acc'
  , Symbol.Cons nextH nextT tail
  , ParseRelColsGo nextH nextT acc' row rels accRL outRL rest
  ) =>
  ParseRelColsGo h tail acc row rels accRL outRL rest

-- After closing nested relation paren inside relation columns

class ParseRelColsAfterNested :: Symbol -> Row Type -> Row Type -> RowList Type -> RowList Type -> Symbol -> Constraint
class ParseRelColsAfterNested sym row rels accRL outRL rest | sym row rels accRL -> outRL rest

instance ParseRelColsAfterNested "" row rels accRL accRL ""
else instance
  ( Symbol.Cons h t sym
  , ParseRelColsAfterNestedGo h t row rels accRL outRL rest
  ) =>
  ParseRelColsAfterNested sym row rels accRL outRL rest

class ParseRelColsAfterNestedGo :: Symbol -> Symbol -> Row Type -> Row Type -> RowList Type -> RowList Type -> Symbol -> Constraint
class ParseRelColsAfterNestedGo head tail row rels accRL outRL rest | head tail row rels accRL -> outRL rest

instance ParseRelColsAfterNestedGo ")" tail row rels accRL accRL tail
else instance
  ( SkipSpaces tail trimmed
  , Symbol.Cons nextH nextT trimmed
  , ParseRelColsGo nextH nextT "" row rels accRL outRL rest
  ) =>
  ParseRelColsAfterNestedGo "," tail row rels accRL outRL rest
else instance
  ( SkipSpaces tail rest
  , ParseRelColsAfterNested rest row rels accRL outRL rest2
  ) =>
  ParseRelColsAfterNestedGo " " tail row rels accRL outRL rest2

-- After space inside relation columns

class ParseRelColsAfterSpace :: Symbol -> Symbol -> Row Type -> Row Type -> RowList Type -> RowList Type -> Symbol -> Constraint
class ParseRelColsAfterSpace head tail row rels accRL outRL rest | head tail row rels accRL -> outRL rest

instance ParseRelColsAfterSpace ")" tail row rels accRL accRL tail

else instance
  ( SkipSpaces tail trimmed
  , Symbol.Cons nextH nextT trimmed
  , ParseRelColsGo nextH nextT "" row rels accRL outRL rest
  ) =>
  ParseRelColsAfterSpace "," tail row rels accRL outRL rest

-- Skip leading spaces

class SkipSpaces :: Symbol -> Symbol -> Constraint
class SkipSpaces sym result | sym -> result

instance SkipSpaces "" ""
else instance
  ( Symbol.Cons h t sym
  , SkipSpacesGo h t result
  ) =>
  SkipSpaces sym result

class SkipSpacesGo :: Symbol -> Symbol -> Symbol -> Constraint
class SkipSpacesGo head tail result | head tail -> result

instance SkipSpaces tail result => SkipSpacesGo " " tail result
else instance Symbol.Cons head tail result => SkipSpacesGo head tail result

-- Skip rest of string (for "*")

class SkipRest :: Symbol -> Constraint
class SkipRest sym

instance SkipRest ""
else instance SkipRest tail => SkipRest sym

-- Resolve a column name against the row

class ResolveColumn :: Symbol -> Row Type -> Type -> Constraint
class ResolveColumn col row typ | col row -> typ

instance
  ( Cons col typ rest row
  ) =>
  ResolveColumn col row typ

else instance
  Fail
    ( Above
        (Beside (Text "Column ") (Beside (Quote col) (Text " does not exist in the table")))
        (Text "")
    ) =>
  ResolveColumn col row typ

-- Resolve a relation name against the relations row

class ResolveRelation :: Symbol -> Row Type -> Row Type -> Row Type -> Constraint
class ResolveRelation name rels relatedRow relatedRels | name rels -> relatedRow relatedRels

instance
  ( Cons name (Rel relatedRow relatedRels) rest rels
  ) =>
  ResolveRelation name rels relatedRow relatedRels

else instance
  Fail
    ( Above
        (Beside (Text "Relation ") (Beside (Quote name) (Text " does not exist on this table")))
        (Text "")
    ) =>
  ResolveRelation name rels relatedRow relatedRels
