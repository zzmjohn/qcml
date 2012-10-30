module Scratch where
  import Control.Applicative
  data Curvature
    = Convex
    | Concave
    | Affine
    | Nonconvex
    deriving (Show, Eq)

  data Monotonicity
    = Increasing
    | Decreasing
    | Nonmonotone
    deriving (Show, Eq)
  
  data Sign
    = Positive
    | Negative
    | Unknown
    deriving (Show, Eq)
  
  data Parameter = Parameter Sign
  
  data Problem 
    = Expr   -- defined as mini SOC problems
    | Variable
    deriving (Show) 
  
  -- a "thing" can be tagged as an expression with curvature and sign or 
  -- as an atom with curvature, monotonicity, and sign
  data Tag a 
    = Tag Curvature Monotonicity Sign a
    deriving (Show)
    
  data MonoTag a
    = MonoTag Monotonicity a
  
  instance Functor Tag where
    fmap f (Tag _ _ _ x) = Tag Nonconvex Nonmonotone Unknown (f x)
  
  instance Applicative Tag where
    pure x = Tag Nonconvex Nonmonotone Unknown x
    
    (Tag Convex Increasing _ f) <*> (Tag Convex _ _ e) 
      = Tag Convex Nonmonotone Unknown (f e)
    (Tag Convex Decreasing _ f) <*> (Tag Concave _ _ e)
      = Tag Concave Nonmonotone Unknown (f e)
    (Tag Concave Decreasing _ f) <*> (Tag Convex _ _ e)
      = Tag Convex Nonmonotone Unknown (f e)
    (Tag Concave Increasing _ f) <*> (Tag Concave _ _ e)
      = Tag Concave Nonmonotone Unknown (f e)
      
    (Tag Affine _ _ f) <*> (Tag Affine _ _ e)
      = Tag Affine Nonmonotone Unknown (f e)
    (Tag c _ _ f) <*> (Tag Affine _ _ e)
      = Tag c Nonmonotone Unknown (f e)
      
    (Tag _ _ _ f) <*> (Tag _ _ _ e) = Tag Nonconvex Nonmonotone Unknown (f e)
  
  -- class Vexable a where
  --   vexity :: a -> Curvature
  --   
  -- instance Vexable (Problem->Problem) where
  --   vexity square = Convex
  
  -- instance Functor Tagged where
  --   fmap f (Expr _ _ p) = Expr Nonconvex Unkonwn (f p)
  --   fmap f (Atom _ _ _ p) = Atom Nonconvex Nonmonotone Unknown (f p)
  -- 
  -- -- DCP rules
  -- instance Applicative Tagged where
  --   pure x = Expr Nonconvex Unknown x
  --   (Atom Convex Increasing s _ f) (<*>) (Expr Convex _ p) 
  --     = Expr Convex Unknown (f p)
  --   (Atom Convex Decreasing s _ f) (<*>) (Expr Concave _ p) 
  --     = Expr Concave Unknown (f p)
    
  -- A*x - b
  -- mult :: parameter -> expr -> expr
  
  -- (mult A) <*> x
  -- :t (mult A) => expr->expr
  
  -- pure x =
  -- Convex Increasing Positive x
  
  -- let's put this in a typeclass?
  class DCP a where
    
  
  -- these things don't even *check* DCP
  -- atoms just describe how to "compose" problems
  -- everything is represented as a problem
  
  smult :: Parameter -> Tag Problem -> Tag Problem
  smult a x = x
  
  -- i want some meta information / context on quad_over_lin
  quad_over_lin :: Tag Problem -> Tag Problem -> Tag Problem
  quad_over_lin x y = x
  
  square :: Tag Problem -> Tag Problem
  square x = x
  
  -- checks DCP rule
  -- apply :: Atom a -> Expr -> Expr
  --   apply (Atom curvature _ s _) (Expr Affine _) = Expr curvature s
  --   apply (Atom Convex Increasing s _) (Expr Convex _) = Expr Convex s
  --   apply (Atom Convex Decreasing s _) (Expr Concave _) = Expr Concave s
  --   apply (Atom Concave Decreasing s _) (Expr Convex _) = Expr Convex s
  --   apply (Atom Concave Increasing s _) (Expr Concave _) = Expr Concave s
  --   apply _ _ = Expr Nonconvex Unknown
  --
  -- Sign->Sign->
  -- (Monotonicity,Expr) -> (Monotonicity, Expr) -> Expr
  --   
  --   
  --   alist = 
  --     [
  --       ("square", Atom Convex Nonmonotone Positive square),
  --       ("quad_over_lin", Atom Convex Nonmonotone Positive quad_over_lin)
  --     ]
  --     
  --   -- square is an ATOM!!
  --   square :: Expr -> Expr
  --   square x = x
  --   
  --   quad_over_lin :: Expr -> Expr -> Expr
  --   quad_over_lin x y = y
  
  -- g :: Expr -> Int
  -- g x = val x
  
  -- f :: (Int,Int) -> Int
  -- f a = case (a) of
  --   (x,y) | x == y -> x 
  --   otherwise -> 1