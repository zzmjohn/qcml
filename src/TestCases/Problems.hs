module TestCases.Problems where
  import Expression.Expression
  import TestCases.TestExpressions
  import Rewriter.Atoms
  import Test.HUnit
  
  import Rewriter.ECOS
  
  -- minimize 1/sqrt(x) + x s.t. square(8*x - 1) <= 3
  p1 = CVXProblem expr16 [Leq expr15 (Leaf $ positiveParameter "3")]
  p2 = CVXProblem expr15 []