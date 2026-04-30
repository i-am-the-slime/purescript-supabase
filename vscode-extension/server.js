// output/LSP.Server/foreign.js
var jsonParse = (s) => {
  try {
    return JSON.parse(s);
  } catch {
    return {};
  }
};
var field = (k) => (o) => o?.[k] ?? null;
var fieldStr = (k) => (o) => o?.[k] != null ? String(o[k]) : "";
var fieldInt = (k) => (o) => o?.[k] ?? 0;
var fieldArr = (k) => (o) => Array.isArray(o?.[k]) ? o[k] : [];
var isNull = (x) => x == null;
var stringify = (x) => JSON.stringify(x);
var byteLength = (s) => Buffer.byteLength(s, "utf-8");
var exit = (code) => () => process.exit(code);
var parseIntNullable = (s) => {
  const n = parseInt(s, 10);
  return isNaN(n) ? null : n;
};
var arraySlice = (start) => (arr) => arr.slice(start);

// output/Control.Apply/foreign.js
var arrayApply = function(fs) {
  return function(xs) {
    var l = fs.length;
    var k = xs.length;
    var result = new Array(l * k);
    var n = 0;
    for (var i = 0;i < l; i++) {
      var f = fs[i];
      for (var j = 0;j < k; j++) {
        result[n++] = f(xs[j]);
      }
    }
    return result;
  };
};

// output/Control.Semigroupoid/index.js
var semigroupoidFn = {
  compose: function(f) {
    return function(g) {
      return function(x) {
        return f(g(x));
      };
    };
  }
};

// output/Control.Category/index.js
var identity = function(dict) {
  return dict.identity;
};
var categoryFn = {
  identity: function(x) {
    return x;
  },
  Semigroupoid0: function() {
    return semigroupoidFn;
  }
};

// output/Data.Boolean/index.js
var otherwise = true;
// output/Data.Function/index.js
var flip = function(f) {
  return function(b) {
    return function(a) {
      return f(a)(b);
    };
  };
};
var $$const = function(a) {
  return function(v) {
    return a;
  };
};

// output/Data.Functor/foreign.js
var arrayMap = function(f) {
  return function(arr) {
    var l = arr.length;
    var result = new Array(l);
    for (var i = 0;i < l; i++) {
      result[i] = f(arr[i]);
    }
    return result;
  };
};

// output/Data.Unit/foreign.js
var unit = undefined;
// output/Data.Functor/index.js
var map = function(dict) {
  return dict.map;
};
var $$void = function(dictFunctor) {
  return map(dictFunctor)($$const(unit));
};
var functorArray = {
  map: arrayMap
};
// output/Control.Apply/index.js
var applyArray = {
  apply: arrayApply,
  Functor0: function() {
    return functorArray;
  }
};
var apply = function(dict) {
  return dict.apply;
};

// output/Control.Applicative/index.js
var pure = function(dict) {
  return dict.pure;
};
var when = function(dictApplicative) {
  var pure1 = pure(dictApplicative);
  return function(v) {
    return function(v1) {
      if (v) {
        return v1;
      }
      if (!v) {
        return pure1(unit);
      }
      throw new Error("Failed pattern match at Control.Applicative (line 63, column 1 - line 63, column 63): " + [v.constructor.name, v1.constructor.name]);
    };
  };
};
var liftA1 = function(dictApplicative) {
  var apply2 = apply(dictApplicative.Apply0());
  var pure1 = pure(dictApplicative);
  return function(f) {
    return function(a) {
      return apply2(pure1(f))(a);
    };
  };
};

// output/Data.Array/foreign.js
var replicateFill = function(count, value) {
  if (count < 1) {
    return [];
  }
  var result = new Array(count);
  return result.fill(value);
};
var replicatePolyfill = function(count, value) {
  var result = [];
  var n = 0;
  for (var i = 0;i < count; i++) {
    result[n++] = value;
  }
  return result;
};
var replicateImpl = typeof Array.prototype.fill === "function" ? replicateFill : replicatePolyfill;
var fromFoldableImpl = function() {
  function Cons(head, tail) {
    this.head = head;
    this.tail = tail;
  }
  var emptyList = {};
  function curryCons(head) {
    return function(tail) {
      return new Cons(head, tail);
    };
  }
  function listToArray(list) {
    var result = [];
    var count = 0;
    var xs = list;
    while (xs !== emptyList) {
      result[count++] = xs.head;
      xs = xs.tail;
    }
    return result;
  }
  return function(foldr, xs) {
    return listToArray(foldr(curryCons)(emptyList)(xs));
  };
}();
var length = function(xs) {
  return xs.length;
};
var indexImpl = function(just, nothing, xs, i) {
  return i < 0 || i >= xs.length ? nothing : just(xs[i]);
};
var findMapImpl = function(nothing, isJust, f, xs) {
  for (var i = 0;i < xs.length; i++) {
    var result = f(xs[i]);
    if (isJust(result))
      return result;
  }
  return nothing;
};
var filterImpl = function(f, xs) {
  return xs.filter(f);
};
var sortByImpl = function() {
  function mergeFromTo(compare, fromOrdering, xs1, xs2, from, to) {
    var mid;
    var i;
    var j;
    var k;
    var x;
    var y;
    var c;
    mid = from + (to - from >> 1);
    if (mid - from > 1)
      mergeFromTo(compare, fromOrdering, xs2, xs1, from, mid);
    if (to - mid > 1)
      mergeFromTo(compare, fromOrdering, xs2, xs1, mid, to);
    i = from;
    j = mid;
    k = from;
    while (i < mid && j < to) {
      x = xs2[i];
      y = xs2[j];
      c = fromOrdering(compare(x)(y));
      if (c > 0) {
        xs1[k++] = y;
        ++j;
      } else {
        xs1[k++] = x;
        ++i;
      }
    }
    while (i < mid) {
      xs1[k++] = xs2[i++];
    }
    while (j < to) {
      xs1[k++] = xs2[j++];
    }
  }
  return function(compare, fromOrdering, xs) {
    var out;
    if (xs.length < 2)
      return xs;
    out = xs.slice(0);
    mergeFromTo(compare, fromOrdering, out, xs.slice(0), 0, xs.length);
    return out;
  };
}();
var sliceImpl = function(s, e, l) {
  return l.slice(s, e);
};

// output/Data.Semigroup/foreign.js
var concatArray = function(xs) {
  return function(ys) {
    if (xs.length === 0)
      return ys;
    if (ys.length === 0)
      return xs;
    return xs.concat(ys);
  };
};
// output/Data.Semigroup/index.js
var semigroupArray = {
  append: concatArray
};
var append = function(dict) {
  return dict.append;
};
// output/Control.Bind/foreign.js
var arrayBind = typeof Array.prototype.flatMap === "function" ? function(arr) {
  return function(f) {
    return arr.flatMap(f);
  };
} : function(arr) {
  return function(f) {
    var result = [];
    var l = arr.length;
    for (var i = 0;i < l; i++) {
      var xs = f(arr[i]);
      var k = xs.length;
      for (var j = 0;j < k; j++) {
        result.push(xs[j]);
      }
    }
    return result;
  };
};
// output/Control.Bind/index.js
var bindArray = {
  bind: arrayBind,
  Apply0: function() {
    return applyArray;
  }
};
var bind = function(dict) {
  return dict.bind;
};
// output/Control.Monad/index.js
var ap = function(dictMonad) {
  var bind2 = bind(dictMonad.Bind1());
  var pure2 = pure(dictMonad.Applicative0());
  return function(f) {
    return function(a) {
      return bind2(f)(function(f$prime) {
        return bind2(a)(function(a$prime) {
          return pure2(f$prime(a$prime));
        });
      });
    };
  };
};

// output/Data.Bounded/foreign.js
var topChar = String.fromCharCode(65535);
var bottomChar = String.fromCharCode(0);
var topNumber = Number.POSITIVE_INFINITY;
var bottomNumber = Number.NEGATIVE_INFINITY;

// output/Data.Ord/foreign.js
var unsafeCompareImpl = function(lt) {
  return function(eq) {
    return function(gt) {
      return function(x) {
        return function(y) {
          return x < y ? lt : x === y ? eq : gt;
        };
      };
    };
  };
};
var ordCharImpl = unsafeCompareImpl;

// output/Data.Eq/foreign.js
var refEq = function(r1) {
  return function(r2) {
    return r1 === r2;
  };
};
var eqBooleanImpl = refEq;
var eqIntImpl = refEq;
var eqCharImpl = refEq;
var eqStringImpl = refEq;

// output/Data.Eq/index.js
var eqString = {
  eq: eqStringImpl
};
var eqInt = {
  eq: eqIntImpl
};
var eqChar = {
  eq: eqCharImpl
};
var eqBoolean = {
  eq: eqBooleanImpl
};
var eq = function(dict) {
  return dict.eq;
};
var eq2 = /* @__PURE__ */ eq(eqBoolean);
var notEq = function(dictEq) {
  var eq3 = eq(dictEq);
  return function(x) {
    return function(y) {
      return eq2(eq3(x)(y))(false);
    };
  };
};

// output/Data.Ordering/index.js
var LT = /* @__PURE__ */ function() {
  function LT2() {}
  LT2.value = new LT2;
  return LT2;
}();
var GT = /* @__PURE__ */ function() {
  function GT2() {}
  GT2.value = new GT2;
  return GT2;
}();
var EQ = /* @__PURE__ */ function() {
  function EQ2() {}
  EQ2.value = new EQ2;
  return EQ2;
}();

// output/Data.Ring/foreign.js
var intSub = function(x) {
  return function(y) {
    return x - y | 0;
  };
};

// output/Data.Semiring/foreign.js
var intAdd = function(x) {
  return function(y) {
    return x + y | 0;
  };
};
var intMul = function(x) {
  return function(y) {
    return x * y | 0;
  };
};

// output/Data.Semiring/index.js
var semiringInt = {
  add: intAdd,
  zero: 0,
  mul: intMul,
  one: 1
};
// output/Data.Ring/index.js
var ringInt = {
  sub: intSub,
  Semiring0: function() {
    return semiringInt;
  }
};
// output/Data.Ord/index.js
var ordChar = /* @__PURE__ */ function() {
  return {
    compare: ordCharImpl(LT.value)(EQ.value)(GT.value),
    Eq0: function() {
      return eqChar;
    }
  };
}();
// output/Data.Bounded/index.js
var top = function(dict) {
  return dict.top;
};
var boundedChar = {
  top: topChar,
  bottom: bottomChar,
  Ord0: function() {
    return ordChar;
  }
};
var bottom = function(dict) {
  return dict.bottom;
};

// output/Data.Show/foreign.js
var showIntImpl = function(n) {
  return n.toString();
};

// output/Data.Show/index.js
var showInt = {
  show: showIntImpl
};
var show = function(dict) {
  return dict.show;
};

// output/Data.Maybe/index.js
var identity2 = /* @__PURE__ */ identity(categoryFn);
var Nothing = /* @__PURE__ */ function() {
  function Nothing2() {}
  Nothing2.value = new Nothing2;
  return Nothing2;
}();
var Just = /* @__PURE__ */ function() {
  function Just2(value0) {
    this.value0 = value0;
  }
  Just2.create = function(value0) {
    return new Just2(value0);
  };
  return Just2;
}();
var maybe = function(v) {
  return function(v1) {
    return function(v2) {
      if (v2 instanceof Nothing) {
        return v;
      }
      if (v2 instanceof Just) {
        return v1(v2.value0);
      }
      throw new Error("Failed pattern match at Data.Maybe (line 237, column 1 - line 237, column 51): " + [v.constructor.name, v1.constructor.name, v2.constructor.name]);
    };
  };
};
var isNothing = /* @__PURE__ */ maybe(true)(/* @__PURE__ */ $$const(false));
var isJust = /* @__PURE__ */ maybe(false)(/* @__PURE__ */ $$const(true));
var functorMaybe = {
  map: function(v) {
    return function(v1) {
      if (v1 instanceof Just) {
        return new Just(v(v1.value0));
      }
      return Nothing.value;
    };
  }
};
var map2 = /* @__PURE__ */ map(functorMaybe);
var fromMaybe = function(a) {
  return maybe(a)(identity2);
};
var fromJust = function() {
  return function(v) {
    if (v instanceof Just) {
      return v.value0;
    }
    throw new Error("Failed pattern match at Data.Maybe (line 288, column 1 - line 288, column 46): " + [v.constructor.name]);
  };
};
var eqMaybe = function(dictEq) {
  var eq3 = eq(dictEq);
  return {
    eq: function(x) {
      return function(y) {
        if (x instanceof Nothing && y instanceof Nothing) {
          return true;
        }
        if (x instanceof Just && y instanceof Just) {
          return eq3(x.value0)(y.value0);
        }
        return false;
      };
    }
  };
};
var applyMaybe = {
  apply: function(v) {
    return function(v1) {
      if (v instanceof Just) {
        return map2(v.value0)(v1);
      }
      if (v instanceof Nothing) {
        return Nothing.value;
      }
      throw new Error("Failed pattern match at Data.Maybe (line 67, column 1 - line 69, column 30): " + [v.constructor.name, v1.constructor.name]);
    };
  },
  Functor0: function() {
    return functorMaybe;
  }
};
var bindMaybe = {
  bind: function(v) {
    return function(v1) {
      if (v instanceof Just) {
        return v1(v.value0);
      }
      if (v instanceof Nothing) {
        return Nothing.value;
      }
      throw new Error("Failed pattern match at Data.Maybe (line 125, column 1 - line 127, column 28): " + [v.constructor.name, v1.constructor.name]);
    };
  },
  Apply0: function() {
    return applyMaybe;
  }
};

// output/Data.Either/index.js
var Left = /* @__PURE__ */ function() {
  function Left2(value0) {
    this.value0 = value0;
  }
  Left2.create = function(value0) {
    return new Left2(value0);
  };
  return Left2;
}();
var Right = /* @__PURE__ */ function() {
  function Right2(value0) {
    this.value0 = value0;
  }
  Right2.create = function(value0) {
    return new Right2(value0);
  };
  return Right2;
}();

// output/Data.EuclideanRing/foreign.js
var intDegree = function(x) {
  return Math.min(Math.abs(x), 2147483647);
};
var intDiv = function(x) {
  return function(y) {
    if (y === 0)
      return 0;
    return y > 0 ? Math.floor(x / y) : -Math.floor(x / -y);
  };
};
var intMod = function(x) {
  return function(y) {
    if (y === 0)
      return 0;
    var yy = Math.abs(y);
    return (x % yy + yy) % yy;
  };
};
// output/Data.CommutativeRing/index.js
var commutativeRingInt = {
  Ring0: function() {
    return ringInt;
  }
};

// output/Data.EuclideanRing/index.js
var mod = function(dict) {
  return dict.mod;
};
var euclideanRingInt = {
  degree: intDegree,
  div: intDiv,
  mod: intMod,
  CommutativeRing0: function() {
    return commutativeRingInt;
  }
};
var div = function(dict) {
  return dict.div;
};

// output/Data.Monoid/index.js
var mempty = function(dict) {
  return dict.mempty;
};

// output/Effect/foreign.js
var pureE = function(a) {
  return function() {
    return a;
  };
};
var bindE = function(a) {
  return function(f) {
    return function() {
      return f(a())();
    };
  };
};

// output/Effect/index.js
var $runtime_lazy = function(name, moduleName, init) {
  var state = 0;
  var val;
  return function(lineNumber) {
    if (state === 2)
      return val;
    if (state === 1)
      throw new ReferenceError(name + " was needed before it finished initializing (module " + moduleName + ", line " + lineNumber + ")", moduleName, lineNumber);
    state = 1;
    val = init();
    state = 2;
    return val;
  };
};
var monadEffect = {
  Applicative0: function() {
    return applicativeEffect;
  },
  Bind1: function() {
    return bindEffect;
  }
};
var bindEffect = {
  bind: bindE,
  Apply0: function() {
    return $lazy_applyEffect(0);
  }
};
var applicativeEffect = {
  pure: pureE,
  Apply0: function() {
    return $lazy_applyEffect(0);
  }
};
var $lazy_functorEffect = /* @__PURE__ */ $runtime_lazy("functorEffect", "Effect", function() {
  return {
    map: liftA1(applicativeEffect)
  };
});
var $lazy_applyEffect = /* @__PURE__ */ $runtime_lazy("applyEffect", "Effect", function() {
  return {
    apply: ap(monadEffect),
    Functor0: function() {
      return $lazy_functorEffect(0);
    }
  };
});
var functorEffect = /* @__PURE__ */ $lazy_functorEffect(20);

// output/Effect.Ref/foreign.js
var _new = function(val) {
  return function() {
    return { value: val };
  };
};
var read = function(ref) {
  return function() {
    return ref.value;
  };
};
var modifyImpl = function(f) {
  return function(ref) {
    return function() {
      var t = f(ref.value);
      ref.value = t.state;
      return t.value;
    };
  };
};
var write = function(val) {
  return function(ref) {
    return function() {
      ref.value = val;
    };
  };
};

// output/Effect.Ref/index.js
var $$void2 = /* @__PURE__ */ $$void(functorEffect);
var $$new = _new;
var modify$prime = modifyImpl;
var modify = function(f) {
  return modify$prime(function(s) {
    var s$prime = f(s);
    return {
      state: s$prime,
      value: s$prime
    };
  });
};
var modify_ = function(f) {
  return function(s) {
    return $$void2(modify(f)(s));
  };
};
// output/Data.Array.ST/foreign.js
function unsafeFreezeThawImpl(xs) {
  return xs;
}
var unsafeFreezeImpl = unsafeFreezeThawImpl;
function copyImpl(xs) {
  return xs.slice();
}
var thawImpl = copyImpl;
var sortByImpl2 = function() {
  function mergeFromTo(compare2, fromOrdering, xs1, xs2, from, to) {
    var mid;
    var i;
    var j;
    var k;
    var x;
    var y;
    var c;
    mid = from + (to - from >> 1);
    if (mid - from > 1)
      mergeFromTo(compare2, fromOrdering, xs2, xs1, from, mid);
    if (to - mid > 1)
      mergeFromTo(compare2, fromOrdering, xs2, xs1, mid, to);
    i = from;
    j = mid;
    k = from;
    while (i < mid && j < to) {
      x = xs2[i];
      y = xs2[j];
      c = fromOrdering(compare2(x)(y));
      if (c > 0) {
        xs1[k++] = y;
        ++j;
      } else {
        xs1[k++] = x;
        ++i;
      }
    }
    while (i < mid) {
      xs1[k++] = xs2[i++];
    }
    while (j < to) {
      xs1[k++] = xs2[j++];
    }
  }
  return function(compare2, fromOrdering, xs) {
    if (xs.length < 2)
      return xs;
    mergeFromTo(compare2, fromOrdering, xs, xs.slice(0), 0, xs.length);
    return xs;
  };
}();
var pushImpl = function(a, xs) {
  return xs.push(a);
};

// output/Control.Monad.ST.Uncurried/foreign.js
var runSTFn1 = function runSTFn12(fn) {
  return function(a) {
    return function() {
      return fn(a);
    };
  };
};
var runSTFn2 = function runSTFn22(fn) {
  return function(a) {
    return function(b) {
      return function() {
        return fn(a, b);
      };
    };
  };
};
// output/Data.Array.ST/index.js
var unsafeFreeze = /* @__PURE__ */ runSTFn1(unsafeFreezeImpl);
var thaw = /* @__PURE__ */ runSTFn1(thawImpl);
var withArray = function(f) {
  return function(xs) {
    return function __do() {
      var result = thaw(xs)();
      f(result)();
      return unsafeFreeze(result)();
    };
  };
};
var push = /* @__PURE__ */ runSTFn2(pushImpl);

// output/Data.Foldable/foreign.js
var foldrArray = function(f) {
  return function(init) {
    return function(xs) {
      var acc = init;
      var len = xs.length;
      for (var i = len - 1;i >= 0; i--) {
        acc = f(xs[i])(acc);
      }
      return acc;
    };
  };
};
var foldlArray = function(f) {
  return function(init) {
    return function(xs) {
      var acc = init;
      var len = xs.length;
      for (var i = 0;i < len; i++) {
        acc = f(acc)(xs[i]);
      }
      return acc;
    };
  };
};
// output/Data.Tuple/index.js
var Tuple = /* @__PURE__ */ function() {
  function Tuple2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  Tuple2.create = function(value0) {
    return function(value1) {
      return new Tuple2(value0, value1);
    };
  };
  return Tuple2;
}();
var snd = function(v) {
  return v.value1;
};
var fst = function(v) {
  return v.value0;
};

// output/Unsafe.Coerce/foreign.js
var unsafeCoerce2 = function(x) {
  return x;
};
// output/Data.Foldable/index.js
var foldr = function(dict) {
  return dict.foldr;
};
var foldl = function(dict) {
  return dict.foldl;
};
var foldMapDefaultR = function(dictFoldable) {
  var foldr2 = foldr(dictFoldable);
  return function(dictMonoid) {
    var append2 = append(dictMonoid.Semigroup0());
    var mempty2 = mempty(dictMonoid);
    return function(f) {
      return foldr2(function(x) {
        return function(acc) {
          return append2(f(x))(acc);
        };
      })(mempty2);
    };
  };
};
var foldableArray = {
  foldr: foldrArray,
  foldl: foldlArray,
  foldMap: function(dictMonoid) {
    return foldMapDefaultR(foldableArray)(dictMonoid);
  }
};

// output/Data.Function.Uncurried/foreign.js
var runFn2 = function(fn) {
  return function(a) {
    return function(b) {
      return fn(a, b);
    };
  };
};
var runFn3 = function(fn) {
  return function(a) {
    return function(b) {
      return function(c) {
        return fn(a, b, c);
      };
    };
  };
};
var runFn4 = function(fn) {
  return function(a) {
    return function(b) {
      return function(c) {
        return function(d) {
          return fn(a, b, c, d);
        };
      };
    };
  };
};
// output/Data.Traversable/foreign.js
var traverseArrayImpl = function() {
  function array1(a) {
    return [a];
  }
  function array2(a) {
    return function(b) {
      return [a, b];
    };
  }
  function array3(a) {
    return function(b) {
      return function(c) {
        return [a, b, c];
      };
    };
  }
  function concat2(xs) {
    return function(ys) {
      return xs.concat(ys);
    };
  }
  return function(apply2) {
    return function(map3) {
      return function(pure2) {
        return function(f) {
          return function(array) {
            function go(bot, top2) {
              switch (top2 - bot) {
                case 0:
                  return pure2([]);
                case 1:
                  return map3(array1)(f(array[bot]));
                case 2:
                  return apply2(map3(array2)(f(array[bot])))(f(array[bot + 1]));
                case 3:
                  return apply2(apply2(map3(array3)(f(array[bot])))(f(array[bot + 1])))(f(array[bot + 2]));
                default:
                  var pivot = bot + Math.floor((top2 - bot) / 4) * 2;
                  return apply2(map3(concat2)(go(bot, pivot)))(go(pivot, top2));
              }
            }
            return go(0, array.length);
          };
        };
      };
    };
  };
}();
// output/Data.Unfoldable/foreign.js
var unfoldrArrayImpl = function(isNothing2) {
  return function(fromJust2) {
    return function(fst2) {
      return function(snd2) {
        return function(f) {
          return function(b) {
            var result = [];
            var value = b;
            while (true) {
              var maybe2 = f(value);
              if (isNothing2(maybe2))
                return result;
              var tuple = fromJust2(maybe2);
              result.push(fst2(tuple));
              value = snd2(tuple);
            }
          };
        };
      };
    };
  };
};

// output/Data.Unfoldable1/foreign.js
var unfoldr1ArrayImpl = function(isNothing2) {
  return function(fromJust2) {
    return function(fst2) {
      return function(snd2) {
        return function(f) {
          return function(b) {
            var result = [];
            var value = b;
            while (true) {
              var tuple = f(value);
              result.push(fst2(tuple));
              var maybe2 = snd2(tuple);
              if (isNothing2(maybe2))
                return result;
              value = fromJust2(maybe2);
            }
          };
        };
      };
    };
  };
};

// output/Data.Unfoldable1/index.js
var fromJust2 = /* @__PURE__ */ fromJust();
var unfoldable1Array = {
  unfoldr1: /* @__PURE__ */ unfoldr1ArrayImpl(isNothing)(fromJust2)(fst)(snd)
};
// output/Data.Unfoldable/index.js
var fromJust3 = /* @__PURE__ */ fromJust();
var unfoldr = function(dict) {
  return dict.unfoldr;
};
var unfoldableArray = {
  unfoldr: /* @__PURE__ */ unfoldrArrayImpl(isNothing)(fromJust3)(fst)(snd),
  Unfoldable10: function() {
    return unfoldable1Array;
  }
};
// output/Data.Array/index.js
var snoc = function(xs) {
  return function(x) {
    return withArray(push(x))(xs)();
  };
};
var slice = /* @__PURE__ */ runFn3(sliceImpl);
var singleton2 = function(a) {
  return [a];
};
var $$null = function(xs) {
  return length(xs) === 0;
};
var init = function(xs) {
  if ($$null(xs)) {
    return Nothing.value;
  }
  if (otherwise) {
    return new Just(slice(0)(length(xs) - 1 | 0)(xs));
  }
  throw new Error("Failed pattern match at Data.Array (line 351, column 1 - line 351, column 45): " + [xs.constructor.name]);
};
var index = /* @__PURE__ */ function() {
  return runFn4(indexImpl)(Just.create)(Nothing.value);
}();
var foldl2 = /* @__PURE__ */ foldl(foldableArray);
var findMap = /* @__PURE__ */ function() {
  return runFn4(findMapImpl)(Nothing.value)(isJust);
}();
var filter = /* @__PURE__ */ runFn2(filterImpl);
var concatMap = /* @__PURE__ */ flip(/* @__PURE__ */ bind(bindArray));
var mapMaybe = function(f) {
  return concatMap(function() {
    var $189 = maybe([])(singleton2);
    return function($190) {
      return $189(f($190));
    };
  }());
};

// output/Data.Nullable/foreign.js
function nullable(a, r, f) {
  return a == null ? r : f(a);
}
// output/Data.Nullable/index.js
var toMaybe = function(n) {
  return nullable(n, Nothing.value, Just.create);
};

// output/Data.String.CodePoints/foreign.js
var hasArrayFrom = typeof Array.from === "function";
var hasStringIterator = typeof Symbol !== "undefined" && Symbol != null && typeof Symbol.iterator !== "undefined" && typeof String.prototype[Symbol.iterator] === "function";
var hasFromCodePoint = typeof String.prototype.fromCodePoint === "function";
var hasCodePointAt = typeof String.prototype.codePointAt === "function";
var _unsafeCodePointAt0 = function(fallback) {
  return hasCodePointAt ? function(str) {
    return str.codePointAt(0);
  } : fallback;
};
var _singleton = function(fallback) {
  return hasFromCodePoint ? String.fromCodePoint : fallback;
};
var _take = function(fallback) {
  return function(n) {
    if (hasStringIterator) {
      return function(str) {
        var accum = "";
        var iter = str[Symbol.iterator]();
        for (var i = 0;i < n; ++i) {
          var o = iter.next();
          if (o.done)
            return accum;
          accum += o.value;
        }
        return accum;
      };
    }
    return fallback(n);
  };
};
var _toCodePointArray = function(fallback) {
  return function(unsafeCodePointAt0) {
    if (hasArrayFrom) {
      return function(str) {
        return Array.from(str, unsafeCodePointAt0);
      };
    }
    return fallback;
  };
};

// output/Data.Enum/foreign.js
function toCharCode(c) {
  return c.charCodeAt(0);
}
function fromCharCode(c) {
  return String.fromCharCode(c);
}
// output/Data.Enum/index.js
var bottom1 = /* @__PURE__ */ bottom(boundedChar);
var top1 = /* @__PURE__ */ top(boundedChar);
var toEnum = function(dict) {
  return dict.toEnum;
};
var fromEnum = function(dict) {
  return dict.fromEnum;
};
var toEnumWithDefaults = function(dictBoundedEnum) {
  var toEnum1 = toEnum(dictBoundedEnum);
  var fromEnum1 = fromEnum(dictBoundedEnum);
  var bottom2 = bottom(dictBoundedEnum.Bounded0());
  return function(low) {
    return function(high) {
      return function(x) {
        var v = toEnum1(x);
        if (v instanceof Just) {
          return v.value0;
        }
        if (v instanceof Nothing) {
          var $140 = x < fromEnum1(bottom2);
          if ($140) {
            return low;
          }
          return high;
        }
        throw new Error("Failed pattern match at Data.Enum (line 158, column 33 - line 160, column 62): " + [v.constructor.name]);
      };
    };
  };
};
var defaultSucc = function(toEnum$prime) {
  return function(fromEnum$prime) {
    return function(a) {
      return toEnum$prime(fromEnum$prime(a) + 1 | 0);
    };
  };
};
var defaultPred = function(toEnum$prime) {
  return function(fromEnum$prime) {
    return function(a) {
      return toEnum$prime(fromEnum$prime(a) - 1 | 0);
    };
  };
};
var charToEnum = function(v) {
  if (v >= toCharCode(bottom1) && v <= toCharCode(top1)) {
    return new Just(fromCharCode(v));
  }
  return Nothing.value;
};
var enumChar = {
  succ: /* @__PURE__ */ defaultSucc(charToEnum)(toCharCode),
  pred: /* @__PURE__ */ defaultPred(charToEnum)(toCharCode),
  Ord0: function() {
    return ordChar;
  }
};
var boundedEnumChar = /* @__PURE__ */ function() {
  return {
    cardinality: toCharCode(top1) - toCharCode(bottom1) | 0,
    toEnum: charToEnum,
    fromEnum: toCharCode,
    Bounded0: function() {
      return boundedChar;
    },
    Enum1: function() {
      return enumChar;
    }
  };
}();
// output/Data.String.CodeUnits/foreign.js
var toCharArray = function(s) {
  return s.split("");
};
var singleton3 = function(c) {
  return c;
};
var length2 = function(s) {
  return s.length;
};
var _indexOf = function(just) {
  return function(nothing) {
    return function(x) {
      return function(s) {
        var i = s.indexOf(x);
        return i === -1 ? nothing : just(i);
      };
    };
  };
};
var _lastIndexOf = function(just) {
  return function(nothing) {
    return function(x) {
      return function(s) {
        var i = s.lastIndexOf(x);
        return i === -1 ? nothing : just(i);
      };
    };
  };
};
var take = function(n) {
  return function(s) {
    return s.substr(0, n);
  };
};
var drop = function(n) {
  return function(s) {
    return s.substring(n);
  };
};
var splitAt = function(i) {
  return function(s) {
    return { before: s.substring(0, i), after: s.substring(i) };
  };
};

// output/Data.String.Unsafe/foreign.js
var charAt = function(i) {
  return function(s) {
    if (i >= 0 && i < s.length)
      return s.charAt(i);
    throw new Error("Data.String.Unsafe.charAt: Invalid index.");
  };
};
// output/Data.String.CodeUnits/index.js
var stripSuffix = function(v) {
  return function(str) {
    var v1 = splitAt(length2(str) - length2(v) | 0)(str);
    var $14 = v1.after === v;
    if ($14) {
      return new Just(v1.before);
    }
    return Nothing.value;
  };
};
var lastIndexOf = /* @__PURE__ */ function() {
  return _lastIndexOf(Just.create)(Nothing.value);
}();
var indexOf = /* @__PURE__ */ function() {
  return _indexOf(Just.create)(Nothing.value);
}();

// output/Data.String.Common/foreign.js
var split = function(sep) {
  return function(s) {
    return s.split(sep);
  };
};
var trim = function(s) {
  return s.trim();
};
// output/Data.String.CodePoints/index.js
var fromEnum2 = /* @__PURE__ */ fromEnum(boundedEnumChar);
var map3 = /* @__PURE__ */ map(functorMaybe);
var unfoldr2 = /* @__PURE__ */ unfoldr(unfoldableArray);
var div2 = /* @__PURE__ */ div(euclideanRingInt);
var mod2 = /* @__PURE__ */ mod(euclideanRingInt);
var unsurrogate = function(lead) {
  return function(trail) {
    return (((lead - 55296 | 0) * 1024 | 0) + (trail - 56320 | 0) | 0) + 65536 | 0;
  };
};
var isTrail = function(cu) {
  return 56320 <= cu && cu <= 57343;
};
var isLead = function(cu) {
  return 55296 <= cu && cu <= 56319;
};
var uncons = function(s) {
  var v = length2(s);
  if (v === 0) {
    return Nothing.value;
  }
  if (v === 1) {
    return new Just({
      head: fromEnum2(charAt(0)(s)),
      tail: ""
    });
  }
  var cu1 = fromEnum2(charAt(1)(s));
  var cu0 = fromEnum2(charAt(0)(s));
  var $43 = isLead(cu0) && isTrail(cu1);
  if ($43) {
    return new Just({
      head: unsurrogate(cu0)(cu1),
      tail: drop(2)(s)
    });
  }
  return new Just({
    head: cu0,
    tail: drop(1)(s)
  });
};
var unconsButWithTuple = function(s) {
  return map3(function(v) {
    return new Tuple(v.head, v.tail);
  })(uncons(s));
};
var toCodePointArrayFallback = function(s) {
  return unfoldr2(unconsButWithTuple)(s);
};
var unsafeCodePointAt0Fallback = function(s) {
  var cu0 = fromEnum2(charAt(0)(s));
  var $47 = isLead(cu0) && length2(s) > 1;
  if ($47) {
    var cu1 = fromEnum2(charAt(1)(s));
    var $48 = isTrail(cu1);
    if ($48) {
      return unsurrogate(cu0)(cu1);
    }
    return cu0;
  }
  return cu0;
};
var unsafeCodePointAt0 = /* @__PURE__ */ _unsafeCodePointAt0(unsafeCodePointAt0Fallback);
var toCodePointArray = /* @__PURE__ */ _toCodePointArray(toCodePointArrayFallback)(unsafeCodePointAt0);
var length3 = function($74) {
  return length(toCodePointArray($74));
};
var lastIndexOf2 = function(p) {
  return function(s) {
    return map3(function(i) {
      return length3(take(i)(s));
    })(lastIndexOf(p)(s));
  };
};
var indexOf2 = function(p) {
  return function(s) {
    return map3(function(i) {
      return length3(take(i)(s));
    })(indexOf(p)(s));
  };
};
var fromCharCode2 = /* @__PURE__ */ function() {
  var $75 = toEnumWithDefaults(boundedEnumChar)(bottom(boundedChar))(top(boundedChar));
  return function($76) {
    return singleton3($75($76));
  };
}();
var singletonFallback = function(v) {
  if (v <= 65535) {
    return fromCharCode2(v);
  }
  var lead = div2(v - 65536 | 0)(1024) + 55296 | 0;
  var trail = mod2(v - 65536 | 0)(1024) + 56320 | 0;
  return fromCharCode2(lead) + fromCharCode2(trail);
};
var singleton4 = /* @__PURE__ */ _singleton(singletonFallback);
var takeFallback = function(v) {
  return function(v1) {
    if (v < 1) {
      return "";
    }
    var v2 = uncons(v1);
    if (v2 instanceof Just) {
      return singleton4(v2.value0.head) + takeFallback(v - 1 | 0)(v2.value0.tail);
    }
    return v1;
  };
};
var take2 = /* @__PURE__ */ _take(takeFallback);
var drop2 = function(n) {
  return function(s) {
    return drop(length2(take2(n)(s)))(s);
  };
};

// output/Effect.Exception/foreign.js
function error(msg) {
  return new Error(msg);
}
function throwException(e) {
  return function() {
    throw e;
  };
}
function catchException(c) {
  return function(t) {
    return function() {
      try {
        return t();
      } catch (e) {
        if (e instanceof Error || Object.prototype.toString.call(e) === "[object Error]") {
          return c(e)();
        } else {
          return c(new Error(e.toString()))();
        }
      }
    };
  };
}

// output/Effect.Exception/index.js
var pure2 = /* @__PURE__ */ pure(applicativeEffect);
var map4 = /* @__PURE__ */ map(functorEffect);
var $$try = function(action) {
  return catchException(function($3) {
    return pure2(Left.create($3));
  })(map4(Right.create)(action));
};
var $$throw = function($4) {
  return throwException(error($4));
};
// output/Foreign/index.js
var unsafeToForeign = unsafeCoerce2;

// output/Foreign.Object/foreign.js
function _copyST(m) {
  return function() {
    var r = {};
    for (var k in m) {
      if (hasOwnProperty.call(m, k)) {
        r[k] = m[k];
      }
    }
    return r;
  };
}
var empty2 = {};
function runST(f) {
  return f();
}
function _lookup(no, yes, k, m) {
  return k in m ? yes(m[k]) : no;
}
function toArrayWithKey(f) {
  return function(m) {
    var r = [];
    for (var k in m) {
      if (hasOwnProperty.call(m, k)) {
        r.push(f(k)(m[k]));
      }
    }
    return r;
  };
}
var keys = Object.keys || toArrayWithKey(function(k) {
  return function() {
    return k;
  };
});

// output/Foreign.Object.ST/foreign.js
function poke2(k) {
  return function(v) {
    return function(m) {
      return function() {
        m[k] = v;
        return m;
      };
    };
  };
}
var deleteImpl = function(k) {
  return function(m) {
    return function() {
      delete m[k];
      return m;
    };
  };
};
// output/Foreign.Object/index.js
var values = /* @__PURE__ */ toArrayWithKey(function(v) {
  return function(v1) {
    return v1;
  };
});
var thawST = _copyST;
var mutate = function(f) {
  return function(m) {
    return runST(function __do() {
      var s = thawST(m)();
      f(s)();
      return s;
    });
  };
};
var lookup = /* @__PURE__ */ function() {
  return runFn4(_lookup)(Nothing.value)(Just.create);
}();
var insert = function(k) {
  return function(v) {
    return mutate(poke2(k)(v));
  };
};
var $$delete = function(k) {
  return mutate(deleteImpl(k));
};

// output/LSP.Context/index.js
var foldl3 = /* @__PURE__ */ foldl(foldableArray);
var bind2 = /* @__PURE__ */ bind(bindMaybe);
var SelectCtx = /* @__PURE__ */ function() {
  function SelectCtx2(value0) {
    this.value0 = value0;
  }
  SelectCtx2.create = function(value0) {
    return new SelectCtx2(value0);
  };
  return SelectCtx2;
}();
var FilterCtx = /* @__PURE__ */ function() {
  function FilterCtx2(value0) {
    this.value0 = value0;
  }
  FilterCtx2.create = function(value0) {
    return new FilterCtx2(value0);
  };
  return FilterCtx2;
}();
var parseSelectPosition = function(inside) {
  var go = function(state2) {
    return function(c) {
      if (c === "(") {
        return {
          depth: snoc(state2.depth)(trim(state2.current)),
          current: ""
        };
      }
      if (c === ")") {
        return {
          depth: fromMaybe(state2.depth)(init(state2.depth)),
          current: ""
        };
      }
      if (c === ",") {
        return {
          depth: state2.depth,
          current: ""
        };
      }
      if (otherwise) {
        return {
          depth: state2.depth,
          current: state2.current + singleton3(c)
        };
      }
      throw new Error("Failed pattern match at LSP.Context (line 54, column 3 - line 58, column 67): " + [state2.constructor.name, c.constructor.name]);
    };
  };
  var result = foldl3(go)({
    depth: [],
    current: ""
  })(toCharArray(inside));
  return {
    prefix: trim(result.current),
    depth: result.depth
  };
};
var findTableInPipeline = function(text) {
  return function(lineNum) {
    var takeUntilSep = function(s) {
      var v = indexOf2(" ")(s);
      if (v instanceof Just) {
        return take2(v.value0)(s);
      }
      if (v instanceof Nothing) {
        var v1 = indexOf2("#")(s);
        if (v1 instanceof Just) {
          return take2(v1.value0)(s);
        }
        if (v1 instanceof Nothing) {
          return trim(s);
        }
        throw new Error("Failed pattern match at LSP.Context (line 82, column 16 - line 84, column 24): " + [v1.constructor.name]);
      }
      throw new Error("Failed pattern match at LSP.Context (line 80, column 20 - line 84, column 24): " + [v.constructor.name]);
    };
    var findFromTable = function(line) {
      return bind2(indexOf2("from ")(line))(function(idx) {
        var after = drop2(idx + 5 | 0)(line);
        return bind2(indexOf2(".")(after))(function(dotIdx) {
          var afterDot = drop2(dotIdx + 1 | 0)(after);
          return new Just(takeUntilSep(afterDot));
        });
      });
    };
    var go = function($copy_lines) {
      return function($copy_i) {
        var $tco_var_lines = $copy_lines;
        var $tco_done = false;
        var $tco_result;
        function $tco_loop(lines2, i) {
          if (i < 0) {
            $tco_done = true;
            return Nothing.value;
          }
          if (otherwise) {
            var v = index(lines2)(i);
            if (v instanceof Nothing) {
              $tco_done = true;
              return Nothing.value;
            }
            if (v instanceof Just) {
              var v1 = findFromTable(v.value0);
              if (v1 instanceof Just) {
                $tco_done = true;
                return new Just(v1.value0);
              }
              if (v1 instanceof Nothing) {
                $tco_var_lines = lines2;
                $copy_i = i - 1 | 0;
                return;
              }
              throw new Error("Failed pattern match at LSP.Context (line 69, column 22 - line 71, column 38): " + [v1.constructor.name]);
            }
            throw new Error("Failed pattern match at LSP.Context (line 67, column 19 - line 71, column 38): " + [v.constructor.name]);
          }
          throw new Error("Failed pattern match at LSP.Context (line 65, column 3 - line 71, column 38): " + [lines2.constructor.name, i.constructor.name]);
        }
        while (!$tco_done) {
          $tco_result = $tco_loop($tco_var_lines, $copy_i);
        }
        return $tco_result;
      };
    };
    var lines = split(`
`)(text);
    return go(lines)(lineNum);
  };
};
var endsWith = function(suffix) {
  return function(s) {
    var sLen = length3(s);
    var suffLen = length3(suffix);
    return sLen >= suffLen && drop2(sLen - suffLen | 0)(s) === suffix;
  };
};
var isFilterFn = function(s) {
  return function(v) {
    if (v instanceof Just) {
      return true;
    }
    if (v instanceof Nothing) {
      return false;
    }
    throw new Error("Failed pattern match at LSP.Context (line 39, column 5 - line 41, column 23): " + [v.constructor.name]);
  }(findMap(function(fn) {
    var $32 = endsWith(fn)(s);
    if ($32) {
      return new Just(unit);
    }
    return Nothing.value;
  })(["eq_", "neq", "gt", "gte", "lt", "lte", "like", "ilike", "is", "not_", "in_", "order", "orderWith", "contains", "containedBy", "overlaps", "textSearch"]));
};
var isSelectFn = function(s) {
  return endsWith("selectColumns")(s) || endsWith("selectColumnsWithCount")(s);
};
var detectContext = function(line) {
  return function(col) {
    return function(fullText) {
      return function(lineNum) {
        var before = take2(col)(line);
        return bind2(lastIndexOf2('@"')(before))(function(atQuoteIdx) {
          var insideStr = drop2(atQuoteIdx + 2 | 0)(before);
          var beforeAt = trim(take2(atQuoteIdx)(before));
          return bind2(findTableInPipeline(fullText)(lineNum))(function(table) {
            var $35 = isSelectFn(beforeAt);
            if ($35) {
              var pos = parseSelectPosition(insideStr);
              return new Just(new SelectCtx({
                table,
                prefix: pos.prefix,
                depth: pos.depth
              }));
            }
            var $36 = isFilterFn(beforeAt);
            if ($36) {
              return new Just(new FilterCtx({
                table,
                prefix: insideStr
              }));
            }
            return Nothing.value;
          });
        });
      };
    };
  };
};

// output/LSP.SchemaParser/index.js
var map5 = /* @__PURE__ */ map(functorArray);
var bind3 = /* @__PURE__ */ bind(bindArray);
var notEq1 = /* @__PURE__ */ notEq(/* @__PURE__ */ eqMaybe(eqString));
var notEq2 = /* @__PURE__ */ notEq(/* @__PURE__ */ eqMaybe(eqInt));
var foldl4 = /* @__PURE__ */ foldl(foldableArray);
var takeWord = function(s) {
  var v = indexOf2(" ")(s);
  if (v instanceof Just) {
    return take2(v.value0)(s);
  }
  if (v instanceof Nothing) {
    return s;
  }
  throw new Error("Failed pattern match at LSP.SchemaParser (line 112, column 14 - line 114, column 15): " + [v.constructor.name]);
};
var stripOuterParens = function(s) {
  var v = indexOf2("(")(s);
  if (v instanceof Just && v.value0 === 0) {
    return take2(length3(s) - 2 | 0)(drop2(1)(s));
  }
  return s;
};
var splitFieldLines = function(body) {
  var cleaned = stripOuterParens(trim(body));
  return filter(function(v) {
    return v !== "";
  })(map5(trim)(bind3(split(`
`)(cleaned))(split(","))));
};
var parseRelations = function(body) {
  return mapMaybe(function(part) {
    var v = indexOf2("::")(part);
    if (v instanceof Nothing) {
      return Nothing.value;
    }
    if (v instanceof Just) {
      var name2 = trim(take2(v.value0)(part));
      var typePart = trim(drop2(v.value0 + 2 | 0)(part));
      var v1 = indexOf2("Rel ")(typePart);
      if (v1 instanceof Just && v1.value0 === 0) {
        var afterRel = trim(drop2(4)(typePart));
        return new Just({
          name: name2,
          target: takeWord(afterRel)
        });
      }
      return Nothing.value;
    }
    throw new Error("Failed pattern match at LSP.SchemaParser (line 88, column 3 - line 97, column 21): " + [v.constructor.name]);
  })(splitFieldLines(body));
};
var parseColumns = function(body) {
  return mapMaybe(function(part) {
    var v = indexOf2("::")(part);
    if (v instanceof Nothing) {
      return Nothing.value;
    }
    if (v instanceof Just) {
      var name2 = trim(take2(v.value0)(part));
      var typ = trim(drop2(v.value0 + 2 | 0)(part));
      var $40 = name2 === "";
      if ($40) {
        return Nothing.value;
      }
      return new Just({
        name: name2,
        type: typ
      });
    }
    throw new Error("Failed pattern match at LSP.SchemaParser (line 79, column 3 - line 84, column 65): " + [v.constructor.name]);
  })(splitFieldLines(body));
};
var hasSuffix = function(suffix) {
  return function(s) {
    return notEq1(stripSuffix(suffix)(s))(Nothing.value);
  };
};
var findTypeBlocks = function(src) {
  var parseTypeDeclStart = function(line) {
    var t = trim(line);
    var v = indexOf2("type ")(t);
    if (v instanceof Just && v.value0 === 0) {
      var v1 = indexOf2(" =")(t);
      if (v1 instanceof Just) {
        var name2 = trim(take2(v1.value0 - 5 | 0)(drop2(5)(t)));
        var $44 = name2 === "";
        if ($44) {
          return Nothing.value;
        }
        return new Just(name2);
      }
      if (v1 instanceof Nothing) {
        return Nothing.value;
      }
      throw new Error("Failed pattern match at LSP.SchemaParser (line 68, column 17 - line 72, column 27): " + [v1.constructor.name]);
    }
    return Nothing.value;
  };
  var containsClosingParen = function(s) {
    return notEq2(indexOf2(")")(s))(Nothing.value);
  };
  var go = function(state2) {
    return function(line) {
      if (state2.current instanceof Nothing) {
        var v = parseTypeDeclStart(line);
        if (v instanceof Just) {
          return {
            blocks: state2.blocks,
            current: new Just({
              name: v.value0,
              body: ""
            })
          };
        }
        if (v instanceof Nothing) {
          return state2;
        }
        throw new Error("Failed pattern match at LSP.SchemaParser (line 54, column 16 - line 56, column 23): " + [v.constructor.name]);
      }
      if (state2.current instanceof Just) {
        var newBody = state2.current.value0.body + (`
` + line);
        var $50 = containsClosingParen(trim(line));
        if ($50) {
          return {
            blocks: snoc(state2.blocks)({
              name: state2.current.value0.name,
              body: newBody
            }),
            current: Nothing.value
          };
        }
        return {
          blocks: state2.blocks,
          current: new Just({
            name: state2.current.value0.name,
            body: newBody
          })
        };
      }
      throw new Error("Failed pattern match at LSP.SchemaParser (line 53, column 19 - line 61, column 70): " + [state2.current.constructor.name]);
    };
  };
  var lines = split(`
`)(src);
  return foldl4(go)({
    blocks: [],
    current: Nothing.value
  })(lines).blocks;
};
var findTableValues = function(src) {
  return mapMaybe(function(line) {
    var t = trim(line);
    var v = indexOf2(":: Table ")(t);
    if (v instanceof Nothing) {
      return Nothing.value;
    }
    if (v instanceof Just) {
      return new Just({
        valueName: trim(take2(v.value0)(t)),
        typeName: takeWord(trim(drop2(v.value0 + 9 | 0)(t)))
      });
    }
    throw new Error("Failed pattern match at LSP.SchemaParser (line 124, column 3 - line 129, column 8): " + [v.constructor.name]);
  })(split(`
`)(src));
};
var parseSchema = function(src) {
  var blocks = findTypeBlocks(src);
  var tables = foldl4(function(acc) {
    return function(b) {
      var $54 = hasSuffix("Required")(b.name) || hasSuffix("Params")(b.name);
      if ($54) {
        return acc;
      }
      var $55 = hasSuffix("Relations")(b.name);
      if ($55) {
        var parentName = take2(length3(b.name) - 9 | 0)(b.name);
        var v = lookup(parentName)(acc);
        if (v instanceof Nothing) {
          return acc;
        }
        if (v instanceof Just) {
          return insert(parentName)({
            columns: v.value0.columns,
            name: v.value0.name,
            valueName: v.value0.valueName,
            relations: parseRelations(b.body)
          })(acc);
        }
        throw new Error("Failed pattern match at LSP.SchemaParser (line 33, column 11 - line 35, column 103): " + [v.constructor.name]);
      }
      return insert(b.name)({
        name: b.name,
        valueName: "",
        columns: parseColumns(b.body),
        relations: []
      })(acc);
    };
  })(empty2)(blocks);
  return foldl4(function(acc) {
    return function(v) {
      var v1 = lookup(v.typeName)(acc);
      if (v1 instanceof Nothing) {
        return acc;
      }
      if (v1 instanceof Just) {
        return insert(v.typeName)({
          columns: v1.value0.columns,
          name: v1.value0.name,
          relations: v1.value0.relations,
          valueName: v.valueName
        })(acc);
      }
      throw new Error("Failed pattern match at LSP.SchemaParser (line 39, column 5 - line 41, column 73): " + [v1.constructor.name]);
    };
  })(tables)(findTableValues(src));
};

// output/Node.Encoding/index.js
var ASCII = /* @__PURE__ */ function() {
  function ASCII2() {}
  ASCII2.value = new ASCII2;
  return ASCII2;
}();
var UTF8 = /* @__PURE__ */ function() {
  function UTF82() {}
  UTF82.value = new UTF82;
  return UTF82;
}();
var UTF16LE = /* @__PURE__ */ function() {
  function UTF16LE2() {}
  UTF16LE2.value = new UTF16LE2;
  return UTF16LE2;
}();
var UCS2 = /* @__PURE__ */ function() {
  function UCS22() {}
  UCS22.value = new UCS22;
  return UCS22;
}();
var Base64 = /* @__PURE__ */ function() {
  function Base642() {}
  Base642.value = new Base642;
  return Base642;
}();
var Base64Url = /* @__PURE__ */ function() {
  function Base64Url2() {}
  Base64Url2.value = new Base64Url2;
  return Base64Url2;
}();
var Latin1 = /* @__PURE__ */ function() {
  function Latin12() {}
  Latin12.value = new Latin12;
  return Latin12;
}();
var Binary = /* @__PURE__ */ function() {
  function Binary2() {}
  Binary2.value = new Binary2;
  return Binary2;
}();
var Hex = /* @__PURE__ */ function() {
  function Hex2() {}
  Hex2.value = new Hex2;
  return Hex2;
}();
var showEncoding = {
  show: function(v) {
    if (v instanceof ASCII) {
      return "ASCII";
    }
    if (v instanceof UTF8) {
      return "UTF8";
    }
    if (v instanceof UTF16LE) {
      return "UTF16LE";
    }
    if (v instanceof UCS2) {
      return "UCS2";
    }
    if (v instanceof Base64) {
      return "Base64";
    }
    if (v instanceof Base64Url) {
      return "Base64Url";
    }
    if (v instanceof Latin1) {
      return "Latin1";
    }
    if (v instanceof Binary) {
      return "Binary";
    }
    if (v instanceof Hex) {
      return "Hex";
    }
    throw new Error("Failed pattern match at Node.Encoding (line 22, column 1 - line 31, column 19): " + [v.constructor.name]);
  }
};
var encodingToNode = function(v) {
  if (v instanceof ASCII) {
    return "ascii";
  }
  if (v instanceof UTF8) {
    return "utf8";
  }
  if (v instanceof UTF16LE) {
    return "utf16le";
  }
  if (v instanceof UCS2) {
    return "ucs2";
  }
  if (v instanceof Base64) {
    return "base64";
  }
  if (v instanceof Base64Url) {
    return "base64url";
  }
  if (v instanceof Latin1) {
    return "latin1";
  }
  if (v instanceof Binary) {
    return "binary";
  }
  if (v instanceof Hex) {
    return "hex";
  }
  throw new Error("Failed pattern match at Node.Encoding (line 35, column 1 - line 35, column 37): " + [v.constructor.name]);
};

// output/Node.EventEmitter/foreign.js
var unsafeOn = (emitter, eventName, cb) => emitter.on(eventName, cb);

// output/Effect.Uncurried/foreign.js
var mkEffectFn1 = function mkEffectFn12(fn) {
  return function(x) {
    return fn(x)();
  };
};
// output/Node.EventEmitter/index.js
var EventHandle = /* @__PURE__ */ function() {
  function EventHandle2(value0, value1) {
    this.value0 = value0;
    this.value1 = value1;
  }
  EventHandle2.create = function(value0) {
    return function(value1) {
      return new EventHandle2(value0, value1);
    };
  };
  return EventHandle2;
}();
var on_ = function(v) {
  return function(psCb) {
    return function(eventEmitter) {
      return function() {
        return unsafeOn(eventEmitter, v.value0, v.value1(psCb));
      };
    };
  };
};

// output/Node.FS.Sync/foreign.js
import {
  accessSync,
  copyFileSync,
  mkdtempSync,
  renameSync,
  truncateSync,
  chownSync,
  chmodSync,
  statSync,
  lstatSync,
  linkSync,
  symlinkSync,
  readlinkSync,
  realpathSync,
  unlinkSync,
  rmdirSync,
  rmSync,
  mkdirSync,
  readdirSync,
  utimesSync,
  readFileSync,
  writeFileSync,
  appendFileSync,
  existsSync,
  openSync,
  readSync,
  writeSync,
  fsyncSync,
  closeSync
} from "node:fs";
// output/Node.FS.Constants/foreign.js
import { constants } from "node:fs";
var f_OK = constants.F_OK;
var r_OK = constants.R_OK;
var w_OK = constants.W_OK;
var x_OK = constants.X_OK;
var copyFile_EXCL = constants.COPYFILE_EXCL;
var copyFile_FICLONE = constants.COPYFILE_FICLONE;
var copyFile_FICLONE_FORCE = constants.COPYFILE_FICLONE_FORCE;
// output/Node.FS.Sync/index.js
var show2 = /* @__PURE__ */ show(showEncoding);
var readTextFile = function(encoding) {
  return function(file) {
    return function() {
      return readFileSync(file, {
        encoding: show2(encoding)
      });
    };
  };
};

// output/Node.Process/foreign.js
import process2 from "process";
var abortImpl = process2.abort ? () => process2.abort() : null;
var channelRefImpl = process2.channel && process2.channel.ref ? () => process2.channel.ref() : null;
var channelUnrefImpl = process2.channel && process2.channel.unref ? () => process2.channel.unref() : null;
var debugPort = process2.debugPort;
var disconnectImpl = process2.disconnect ? () => process2.disconnect() : null;
var pid = process2.pid;
var platformStr = process2.platform;
var ppid = process2.ppid;
var stdin = process2.stdin;
var stdout = process2.stdout;
var stderr = process2.stderr;
var stdinIsTTY = process2.stdinIsTTY;
var stdoutIsTTY = process2.stdoutIsTTY;
var stderrIsTTY = process2.stderrIsTTY;
var version = process2.version;
// output/Node.Stream/foreign.js
var setEncodingImpl = (s, enc) => s.setEncoding(enc);
var readChunkImpl = (useBuffer, useString, chunk) => {
  if (chunk instanceof Buffer) {
    return useBuffer(chunk);
  } else if (typeof chunk === "string") {
    return useString(chunk);
  } else {
    throw new Error("Node.Stream.readChunkImpl: Unrecognised " + "chunk type; expected String or Buffer, got: " + chunk);
  }
};
var writeStringImpl = (w, str, enc) => w.write(str, enc);

// output/Node.Stream/index.js
var show3 = /* @__PURE__ */ show(showEncoding);
var writeString = function(w) {
  return function(enc) {
    return function(str) {
      return function() {
        return writeStringImpl(w, str, encodingToNode(enc));
      };
    };
  };
};
var setEncoding = function(r) {
  return function(enc) {
    return function() {
      return setEncodingImpl(r, show3(enc));
    };
  };
};
var dataHStr = /* @__PURE__ */ function() {
  return new EventHandle("data", function(cb) {
    return function(chunk) {
      return readChunkImpl(function(v) {
        return $$throw("Got a Buffer, not String. Stream encoding must be set to get a String.")();
      }, mkEffectFn1(cb), chunk);
    };
  });
}();

// output/LSP.Server/index.js
var eq12 = /* @__PURE__ */ eq(/* @__PURE__ */ eqMaybe(eqInt));
var show4 = /* @__PURE__ */ show(showInt);
var pure3 = /* @__PURE__ */ pure(applicativeEffect);
var map6 = /* @__PURE__ */ map(functorArray);
var append1 = /* @__PURE__ */ append(semigroupArray);
var when2 = /* @__PURE__ */ when(applicativeEffect);
var tailArray = function(arr) {
  var v = index(arr)(0);
  if (v instanceof Nothing) {
    return Nothing.value;
  }
  if (v instanceof Just) {
    return new Just(arraySlice(1)(arr));
  }
  throw new Error("Failed pattern match at LSP.Server (line 162, column 17 - line 164, column 36): " + [v.constructor.name]);
};
var walkDepth = function($copy_schema) {
  return function($copy_tableDef) {
    return function($copy_depth) {
      var $tco_var_schema = $copy_schema;
      var $tco_var_tableDef = $copy_tableDef;
      var $tco_done = false;
      var $tco_result;
      function $tco_loop(schema, tableDef, depth) {
        var v = index(depth)(0);
        if (v instanceof Nothing) {
          $tco_done = true;
          return {
            columns: tableDef.columns,
            relations: tableDef.relations
          };
        }
        if (v instanceof Just) {
          var rest = fromMaybe([])(tailArray(depth));
          var v1 = foldl2(function(acc) {
            return function(r) {
              var $32 = r.name === v.value0;
              if ($32) {
                return new Just(r);
              }
              return acc;
            };
          })(Nothing.value)(tableDef.relations);
          if (v1 instanceof Nothing) {
            $tco_done = true;
            return {
              columns: [],
              relations: []
            };
          }
          if (v1 instanceof Just) {
            var v2 = lookup(v1.value0.target)(schema);
            if (v2 instanceof Nothing) {
              $tco_done = true;
              return {
                columns: [],
                relations: []
              };
            }
            if (v2 instanceof Just) {
              $tco_var_schema = schema;
              $tco_var_tableDef = v2.value0;
              $copy_depth = rest;
              return;
            }
            throw new Error("Failed pattern match at LSP.Server (line 151, column 19 - line 153, column 56): " + [v2.constructor.name]);
          }
          throw new Error("Failed pattern match at LSP.Server (line 149, column 5 - line 153, column 56): " + [v1.constructor.name]);
        }
        throw new Error("Failed pattern match at LSP.Server (line 145, column 35 - line 153, column 56): " + [v.constructor.name]);
      }
      while (!$tco_done) {
        $tco_result = $tco_loop($tco_var_schema, $tco_var_tableDef, $copy_depth);
      }
      return $tco_result;
    };
  };
};
var startsWith = function(prefix) {
  return function(s) {
    return eq12(indexOf2(prefix)(s))(new Just(0));
  };
};
var reply = function(id) {
  return function(result) {
    var body = stringify(unsafeToForeign({
      jsonrpc: "2.0",
      id,
      result
    }));
    var header = "Content-Length: " + (show4(byteLength(body)) + `\r
\r
`);
    return function __do() {
      writeString(stdout)(UTF8.value)(header + body)();
      return unit;
    };
  };
};
var parseContentLength = function(header) {
  return foldl2(function(acc) {
    return function(line) {
      var v = indexOf2("Content-Length:")(line);
      if (v instanceof Just && v.value0 === 0) {
        return toMaybe(parseIntNullable(trim(drop2(15)(line))));
      }
      return acc;
    };
  })(Nothing.value)(split(`\r
`)(header));
};
var loadSchema = function(path) {
  return function(ref) {
    return function __do() {
      var result = $$try(readTextFile(UTF8.value)(path))();
      if (result instanceof Left) {
        return unit;
      }
      if (result instanceof Right) {
        return write(parseSchema(result.value0))(ref)();
      }
      throw new Error("Failed pattern match at LSP.Server (line 115, column 3 - line 117, column 49): " + [result.constructor.name]);
    };
  };
};
var findByValueName = function(vn) {
  var $66 = foldl2(function(acc) {
    return function(t) {
      var $43 = t.valueName === vn;
      if ($43) {
        return new Just(t);
      }
      return acc;
    };
  })(Nothing.value);
  return function($67) {
    return $66(values($67));
  };
};
var completions = function(schema) {
  return function(v) {
    if (v instanceof Nothing) {
      return [];
    }
    if (v instanceof Just && v.value0 instanceof SelectCtx) {
      var v1 = findByValueName(v.value0.value0.table)(schema);
      if (v1 instanceof Nothing) {
        return [];
      }
      if (v1 instanceof Just) {
        var scope = walkDepth(schema)(v1.value0)(v.value0.value0.depth);
        var colItems = map6(function(c) {
          return unsafeToForeign({
            label: c.name,
            kind: 5,
            detail: c.type
          });
        })(filter(function(c) {
          return startsWith(v.value0.value0.prefix)(c.name);
        })(scope.columns));
        var relItems = map6(function(r) {
          return unsafeToForeign({
            label: r.name,
            kind: 19,
            detail: "→ " + r.target,
            insertText: r.name + "($1)",
            insertTextFormat: 2
          });
        })(filter(function(r) {
          return startsWith(v.value0.value0.prefix)(r.name);
        })(scope.relations));
        return append1(colItems)(relItems);
      }
      throw new Error("Failed pattern match at LSP.Server (line 125, column 5 - line 135, column 29): " + [v1.constructor.name]);
    }
    if (v instanceof Just && v.value0 instanceof FilterCtx) {
      var v1 = findByValueName(v.value0.value0.table)(schema);
      if (v1 instanceof Nothing) {
        return [];
      }
      if (v1 instanceof Just) {
        return map6(function(c) {
          return unsafeToForeign({
            label: c.name,
            kind: 5,
            detail: c.type
          });
        })(filter(function(c) {
          return startsWith(v.value0.value0.prefix)(c.name);
        })(v1.value0.columns));
      }
      throw new Error("Failed pattern match at LSP.Server (line 138, column 5 - line 142, column 81): " + [v1.constructor.name]);
    }
    throw new Error("Failed pattern match at LSP.Server (line 122, column 22 - line 142, column 81): " + [v.constructor.name]);
  };
};
var handleMessage = function(body) {
  return function(schemaRef) {
    return function(docsRef) {
      var msg = jsonParse(body);
      var id = field("id")(msg);
      var method = fieldStr("method")(msg);
      var params = field("params")(msg);
      if (method === "initialize") {
        var rootUri = fieldStr("rootUri")(params);
        var root = drop2(7)(rootUri);
        return function __do() {
          loadSchema(root + "/src/Supabase/Schema.purs")(schemaRef)();
          return reply(id)({
            capabilities: {
              textDocumentSync: 1,
              completionProvider: {
                triggerCharacters: ['"', ",", " ", "("]
              }
            }
          })();
        };
      }
      if (method === "textDocument/didOpen") {
        var td = field("textDocument")(params);
        return modify_(insert(fieldStr("uri")(td))(fieldStr("text")(td)))(docsRef);
      }
      if (method === "textDocument/didChange") {
        var td = field("textDocument")(params);
        var changes = fieldArr("contentChanges")(params);
        var v = index(changes)(0);
        if (v instanceof Nothing) {
          return pure3(unit);
        }
        if (v instanceof Just) {
          return modify_(insert(fieldStr("uri")(td))(fieldStr("text")(v.value0)))(docsRef);
        }
        throw new Error("Failed pattern match at LSP.Server (line 86, column 7 - line 88, column 104): " + [v.constructor.name]);
      }
      if (method === "textDocument/didClose") {
        var td = field("textDocument")(params);
        return modify_($$delete(fieldStr("uri")(td)))(docsRef);
      }
      if (method === "textDocument/completion") {
        var td = field("textDocument")(params);
        var pos = field("position")(params);
        var uri = fieldStr("uri")(td);
        var line = fieldInt("line")(pos);
        var col = fieldInt("character")(pos);
        return function __do() {
          var docs = read(docsRef)();
          var schema = read(schemaRef)();
          var text = fromMaybe("")(lookup(uri)(docs));
          var lineText = fromMaybe("")(index(split(`
`)(text))(line));
          var ctx = detectContext(lineText)(col)(text)(line);
          var items = completions(schema)(ctx);
          return reply(id)({
            isIncomplete: false,
            items
          })();
        };
      }
      if (method === "shutdown") {
        return reply(id)(unsafeToForeign(unit));
      }
      if (method === "exit") {
        return exit(0);
      }
      return when2(!isNull(id))(reply(id)(unsafeToForeign(unit)));
    };
  };
};
var processBuffer = function(bufferRef) {
  return function(schemaRef) {
    return function(docsRef) {
      return function __do() {
        var buf = read(bufferRef)();
        var v = indexOf2(`\r
\r
`)(buf);
        if (v instanceof Nothing) {
          return unit;
        }
        if (v instanceof Just) {
          var header = take2(v.value0)(buf);
          var v1 = parseContentLength(header);
          if (v1 instanceof Nothing) {
            write(drop2(v.value0 + 4 | 0)(buf))(bufferRef)();
            return processBuffer(bufferRef)(schemaRef)(docsRef)();
          }
          if (v1 instanceof Just) {
            var bodyStart = v.value0 + 4 | 0;
            var available = length3(buf) - bodyStart | 0;
            var $63 = available < v1.value0;
            if ($63) {
              return unit;
            }
            var body = take2(v1.value0)(drop2(bodyStart)(buf));
            write(drop2(bodyStart + v1.value0 | 0)(buf))(bufferRef)();
            handleMessage(body)(schemaRef)(docsRef)();
            return processBuffer(bufferRef)(schemaRef)(docsRef)();
          }
          throw new Error("Failed pattern match at LSP.Server (line 43, column 7 - line 55, column 54): " + [v1.constructor.name]);
        }
        throw new Error("Failed pattern match at LSP.Server (line 39, column 3 - line 55, column 54): " + [v.constructor.name]);
      };
    };
  };
};
var main = function __do() {
  var schemaRef = $$new(empty2)();
  var docsRef = $$new(empty2)();
  var bufferRef = $$new("")();
  setEncoding(stdin)(UTF8.value)();
  return on_(dataHStr)(function(chunk) {
    return function __do() {
      modify_(function(v) {
        return v + chunk;
      })(bufferRef)();
      return processBuffer(bufferRef)(schemaRef)(docsRef)();
    };
  })(stdin)();
};
export {
  walkDepth,
  tailArray,
  stringify,
  startsWith,
  reply,
  processBuffer,
  parseIntNullable,
  parseContentLength,
  main,
  loadSchema,
  jsonParse,
  isNull,
  handleMessage,
  findByValueName,
  fieldStr,
  fieldInt,
  fieldArr,
  field,
  exit,
  completions,
  byteLength,
  arraySlice
};
