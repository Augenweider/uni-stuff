{-# LANGUAGE DeriveGeneric #-}

module Main where

{- This is code pretty specific for an exercise in Logik.
 - I might however turn this into a lightweight logic-module on hackage one day.
 -}

import qualified Control.Parallel.Strategies as S
-- import qualified Data.Discrimination as D
import qualified Data.Map as M

import Data.Maybe (fromMaybe)
import Data.List (nub)
import GHC.Generics

import EqPred

{-
 - A Formel is either a simple A-variable,
 - the negation of a Formel,
 - the konjunction of two Formel or
 - the disjunction of two Formel.
 -}
data Formel a =
    Nil a
  | Neg (Formel a)
  | Kon (Formel a) (Formel a)
  | Dis (Formel a) (Formel a)
  deriving (Eq, Ord, Generic)

instance Show a => Show (Formel a) where
  show (Nil a)   = show a
  show (Neg f)   = "-" ++ show f
  show (Kon a b) = "(" ++ show a ++ " ∧ " ++ show b ++ ")"
  show (Dis a b) = "(" ++ show a ++ " v " ++ show b ++ ")"

-- instance D.Grouping a => D.Grouping (Formel a)

{- Explanation of difference between
 -    Data.List.nub :: Eq a => [a] -> [a]
 -        (runs in O(n^2) ), and
 -    Data.Discrimination.nub :: Grouping a => [a] -> [a]
 -        (runs in O(n) ).
 - However, it apparently requires huge amounts of RAM for that,
 - meaning the constant factor is quite high. It thus becomes
 - unperformant here for small lists as well as requiring too much
 - RAM for being applied on the big lists here (>15GiB).
 - Then again, it is quite possibly a lot faster than Data.List.nub here in total.
 -}


-- | The depth of a formulae
depth :: Formel a -> Int
depth (Nil a)   = 0
depth (Neg f)   = 1 + depth f
depth (Kon a b) = 1 + max (depth a) (depth b)
depth (Dis a b) = 1 + max (depth a) (depth b)


-- | the length of a formulae
lengthF :: Formel a -> Int
lengthF (Nil a)   = 1
lengthF (Neg f)   = 1 + lengthF f
lengthF (Kon a b) = 3 + lengthF a + lengthF b
lengthF (Dis a b) = 3 + lengthF a + lengthF b


-- | Evaluating the truth-value of an Boolean expression
eval :: Formel Bool -> Bool
eval (Nil a)   = a
eval (Neg f)   = not (eval f)
eval (Kon a b) = (eval a) && (eval b)
eval (Dis a b) = (eval a) || (eval b)


-- | setting specific truth values for variables, based on
-- the given valuator.
setVar :: Ord a => M.Map a Bool -> Formel a -> Formel Bool
setVar m (Nil a)   = Nil (fromMaybe False (M.lookup a m))
setVar m (Neg f)   = Neg (setVar m f)
setVar m (Kon a b) = Kon (setVar m a) (setVar m b)
setVar m (Dis a b) = Kon (setVar m a) (setVar m b)


-- | If a and b are valid formulae, then so are:
-- ~ depth + 1
gen1 :: Formel a -> Formel a -> [Formel a]
gen1 a b = [a, Neg a,
            Kon a b, Kon a a,
            Dis a b, Dis a a]


-- | combining the two lists of formulae to a new list of formulae
-- with all the possible combination of the both.
-- ~ depth + 1
gen1' :: [Formel a] -> [Formel a] -> [Formel a]
gen1' a b = a >>= (\a' -> b >>= (\b' -> gen1 a' b'))


-- | All possible formulas with these A-variables with depth n.
gen :: Eq a => [a] -> Int -> [Formel a]
gen []    _ = []
gen [a]   0 = [Nil a]
gen [a]   n = gen [a] (n-1) >>= \f -> [Neg f]
gen (a:c) 0 = gen [a] 0 ++ gen c 0
gen l     n = ans
  where
    btw = shift l (head l)
    red = reduce btw (head btw)
    ans = depthify red
    -- ~ depth + 1; possibly correct only for 0 < lenght l <= 3.
    shift :: [a] -> a -> [[Formel a]]
    shift [a]       b = [gen1 (Nil a) (Nil b)]
    shift l@(a:b:c) d = [gen1 (Nil a) (Nil b)] ++ shift (b:c) d
    -- ~ depth + 1
    reduce :: [[Formel a]] -> [Formel a] -> [Formel a]
    reduce [a]      d = gen1' a d
    reduce (a:b:c)  d = gen1' a b ++ reduce (b:c) d
    -- test for depth ...
    depthify :: Eq a => [Formel a] -> [Formel a]
    depthify f = if (foldr1 max (map depth f)) < n
      then depthify $ gen1' f f
      else nub $ filter (\g -> depth g == n) f

--    else D.nub $ filter (\g -> depth g == n) f
{- using D.nub here resulted in an '*** Exception: stack overflow' previously.
 -}


-- | returns all possible evaluations for these variables.
resKV :: Ord a => [a] -> [M.Map a Bool]
resKV [] = []
resKV l  = [M.fromList (l `zip` rotate n b) | n <- [1..a]]
  where
  a = 2 ^ (length l)
  b = replicate (length l) False


-- | Binarily adding one.
rotate :: Int -> [Bool] -> [Bool]
rotate 0 b = b
rotate n b = rotate (n-1) (add b)
  where
  add :: [Bool] -> [Bool]
  add []        = []
  add (b:be)
    | b         = False:add be
    | otherwise = True:be


-- | find all different A-variables in F
getAs :: Eq a => Formel a -> [a]
getAs (Nil a)   = [a]
getAs (Neg f)   = getAs f
getAs (Kon a b) = nub $ getAs a ++ getAs b -- D.nub here would only be faster for larger structures
getAs (Dis a b) = nub $ getAs a ++ getAs b -- D.nub here would only be faster for larger structures


-- | turning a usual formulae in a Predicate
-- p :: [Bool] -> Bool, which we can compare
-- for equality on the semantic level.
-- asPredicate :: (Ord a, D.Grouping a) => Formel a -> ([Bool] -> Bool)
asPredicate :: Ord a => Formel a -> ([Bool] -> Bool)
asPredicate f xs = eval $ setVar (M.fromList (getAs f `zip` xs)) f


-- | Testing a Formel for all possible valuators.
testF :: Ord a => [a] -> Formel a -> [([Bool], Bool)]
testF vars f = kvs >>= \v -> [(format v, eval $ setVar v f) ]
  where
    kvs      = resKV vars
    format v = map snd $ M.toList v


-------------------------------------------------------------------------------
--                 Actually solving the given problem
-------------------------------------------------------------------------------


-- The A-Vars
vars = ["A0", "A1", "A2"]
-- all valuators for them
kvs  = resKV vars
-- all the possible Formulae with depth 3
form = gen vars 3
-- the result of all formulaes with all evaluations.
ins  = do
  k <- kvs
  f <- form
  return $ setVar k f


-- (a) The Formulae equivalent to Top.
ver  = [f | f <- form, all eval (kvs >>= \k -> [setVar k f])]
-- (b) The Formulae equivalent to Bottom.
bot  = [f | f <- form, all (not . eval) (kvs >>= (\k -> [setVar k f]))]
-- (c) The Formulae equivalent to A0.
eqA0 = [f | f <- form, asPredicate f == asPredicate (Nil "A0")]
-- (d) The Formulae equivalent to (A0 ^ A1).
eq01 = [f | f <- form, asPredicate f == asPredicate (Kon (Nil "A0") (Nil "A1"))]


-- | printing the result(s)
main =
  print res
  where
  l = length
  res = [l ver, l bot, l eqA0, l eq01, l form] `S.using` S.parList S.rpar
