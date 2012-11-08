module CodeGenerator.Common (
  getVariableNames, 
  getVariableSizes,
  getVariableInfo,
  socpToProb, 
  getAForCodegen,
  getBForCodegen,
  VarTable,
  getCoeffInfo,
  getCoeffSize,
  getCoeffRows,
  cones, affine_A, affine_b,
  module Expression.SOCP,
  module Data.List) where
  import Expression.SOCP
  import Data.List

  -- XXX/TODO: code generator is long overdue for a rewrite

  -- helper functions
  cones = conesK.constraints
  affine_A = matrixA.constraints
  affine_b = vectorB.constraints

  -- a VarTable is an associatiation list with (name, (start, len))
  type VarTable = [(String, (Int,Int))]
  
  getVariableNames :: SOCP -> [String]
  getVariableNames p = map vname (getVariableInfo p)
  
  getVariableSizes :: SOCP -> [Int]
  getVariableSizes p = map vrows (getVariableInfo p)
  
  -- gets the list of unique variable names for CVX
  -- starts with cone vars
  -- objective var is at the end
  getVariableInfo :: SOCP -> [Var]
  getVariableInfo p = 
    let objectiveVar = obj p
        aVars =  concat $ map variables (affine_A p)  -- gets the list of all variables in the affine constraints
        coneVars = concat $ map variables (cones p) -- get the list of all variables in the cones
        allVariables = [objectiveVar] ++ coneVars ++ aVars
        uniqueVarNames = nubBy (\x y-> vname x == vname y) allVariables
    in (tail uniqueVarNames) ++ [head uniqueVarNames]
    
  -- write out results
  socpToProb :: VarTable -> [String]
  socpToProb table = map (\(s,(i,l)) -> s ++ " = x_codegen(" ++ show i ++ ":" ++ show (i+l-1) ++ ");") table
  
  -- get A
  getAForCodegen = getAForCodegenWithIndx 1
  getAForCodegenC = getAForCodegenWithIndx 0

  getAForCodegenWithIndx :: Int -> SOCP -> VarTable -> String
  getAForCodegenWithIndx i p table = 
    let bsizes = map getCoeffRows (affine_b p)  -- height of each row
        startIdx = take (length bsizes) (scanl (+) i bsizes)  -- gives start index for each row
    in intercalate "\n" (map (createRow table) (zip (affine_A p) startIdx))
  
  -- XXX/TODO: the fact that i don't understand this function means it really needs to be rewritten...
  createRow :: VarTable -> (Row,Int) -> String
  createRow table (row,ind) = 
    let indices = map (flip lookup table) (varnames row)
        coefficients = coeffs row
        -- with our setup, the only time rowHeights aren't equal to the first one is when we are concatenating
        rowHeights = map getCoeffRows (tail coefficients)
        rowTotal = getCoeffRows (head coefficients)
        offsets
          | all (==rowTotal) rowHeights = 0:(map (rowTotal-) rowHeights)
          | otherwise = 0:rowHeights
        shifts = init $ scanl (+) 0 offsets
    in intercalate " " (zipWith (assignToA ind) shifts (zip (elems row) indices))
    
  -- get coeff size and value
  getCoeffInfo :: Coeff -> (Int,Int,String)
  getCoeffInfo (Matrix (m,n) s) = (m,n,s)
  getCoeffInfo (Vector n s) = (n,1,s)
  getCoeffInfo (OnesT n s)
    | s == "0" || s == "0.0" = (1,n,"0")
    | otherwise =  (1,n, s++"*ones(1, "++show n ++")")
  getCoeffInfo (Ones n s)
    | s == "0" || s == "0.0" = (n,1,"0")
    | otherwise = (n,1, s++"*ones("++show n ++", 1)")
  getCoeffInfo (Eye n s)
    | s == "0" || s == "0.0" = (n,n, "0")
    | otherwise = (n,n,s++"*speye("++show n++", "++show n++")")
  
  -- just get coeff size
  getCoeffSize :: Coeff -> (Int, Int)
  getCoeffSize x = let (m,n,s) = getCoeffInfo x
    in (m,n)
    
  -- just get coeff rows
  getCoeffRows :: Coeff -> Int
  getCoeffRows x = let (m,n,s) = getCoeffInfo x
    in m
  
  -- XXX: this is such a bizarre function type signature...
  assignToA :: Int -> Int -> ((Coeff, Var), Maybe (Int,Int)) -> String
  assignToA _ _ (_, Nothing) = ""
  assignToA x offset (row, Just (y,l)) = 
    let (m,n,val) = getCoeffInfo (fst row) -- n should equal l at this point!!
        rowExtent = show (x+offset) ++ ":" ++ show (x+offset+m-1)
        colExtent = show y ++ ":" ++ show (y+n-1)
    in case(val) of
      "0" -> ""
      otherwise -> "A_(" ++ rowExtent ++ ", " ++ colExtent ++ ") = " ++ val ++ ";"
  
  -- get b
  getBForCodegen = getBForCodegenWithIndx 1
  getBForCodegenC = getBForCodegenWithIndx 0

  getBForCodegenWithIndx :: Int -> SOCP -> String
  getBForCodegenWithIndx i p = 
    let b = affine_b p
        sizes = map getCoeffRows b
        startIdx = init $ scanl (+) i sizes -- start index changes for C code
    in concat $ map assignToB (zip b startIdx)
  
  assignToB :: (Coeff,Int) -> String
  assignToB (val, ind) = 
    let (m,n,s) = getCoeffInfo val
    in case (s) of
      "0" -> ""
      otherwise -> "b_("++ (show ind) ++ ":"++ show (ind+m-1)++") = " ++ s ++ ";\n"