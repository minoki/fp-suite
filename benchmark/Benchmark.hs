{-# LANGUAGE BangPatterns #-}
import Numeric.Rounded.Hardware.Interval
import Gauge.Main
import Data.Array
import Data.Array.IArray (IArray)
import Data.Array.ST
import qualified Data.Vector as V
import qualified Data.Vector.Mutable as VM
import Control.Monad
import Control.Monad.ST
import Data.Ratio

thawST :: (Ix i, IArray a e) => a i e -> ST s (STArray s i e)
thawST = thaw

intervalGaussianElimination :: (Fractional a) => Array (Int,Int) a -> V.Vector a -> V.Vector a
intervalGaussianElimination a b
  | not (i0 == 0 && j0 == 0 && iN == n - 1 && jN == n - 1) = error "invalid size"
  | otherwise = V.create $ do
      a' <- thawST a
      b' <- V.thaw b

      -- elimination
      forM_ [0..n-2] $ \k -> do
        forM_ [k+1..n-1] $ \i -> do
          !t <- liftM2 (/) (readArray a' (i,k)) (readArray a' (k,k))
          forM_ [k+1..n-1] $ \j -> do
            a_ij <- readArray a' (i,j)
            a_kj <- readArray a' (k,j)
            writeArray a' (i,j) $! a_ij - t * a_kj
          b_k <- VM.read b' k
          modify' b' (subtract (t * b_k)) i

      -- backward substitution
      a_nn <- readArray a' (n-1,n-1)
      modify' b' (/ a_nn) (n-1)
      forM_ [n-2,n-3..0] $ \i -> do
        s <- sum <$> mapM (\j -> liftM2 (*) (readArray a' (i,j)) (VM.read b' j)) [i+1..n-1]
        a_ii <- readArray a' (i,i)
        modify' b' (\b_i -> (b_i - s) / a_ii) i
      return b'
        where
          ((i0,j0),(iN,jN)) = bounds a
          n = V.length b
          modify' vec f i = do
            x <- VM.read vec i
            VM.write vec i $! f x

main :: IO ()
main =
  defaultMain
    [ let smallInteger = -2^50+2^13+127 :: Integer
          largeInteger = -2^100-37*2^80+2^13+127 :: Integer
      in bgroup "fromInteger"
         [ bench "Double/small" $ nf (fromInteger :: Integer -> Double) smallInteger
         , bench "Double/large" $ nf (fromInteger :: Integer -> Double) largeInteger
         , bench "IntervalDouble/small" $ nf (fromInteger :: Integer -> IntervalDouble) smallInteger
         , bench "IntervalDouble/large" $ nf (fromInteger :: Integer -> IntervalDouble) largeInteger
         ]
    , let pi' = 3.14159265358979323846264338327950 :: Rational
          largeRational = 78326489123342523452342137498719847192 % 348912374981749170413424213275017 :: Rational
      in bgroup "fromRational"
         [ bench "Double/decimal" $ nf (fromRational :: Rational -> Double) pi'
         , bench "Double/large" $ nf (fromRational :: Rational -> Double) largeRational
         , bench "IntervalDouble/decimal" $ nf (fromRational :: Rational -> Double) pi'
         , bench "IntervalDouble/large" $ nf (fromRational :: Rational -> IntervalDouble) largeRational
         ]
    , let arr :: Fractional a => Array (Int,Int) a
          arr = listArray ((0,0),(4,4))
                [2,4,1,3,8
                ,-4,7,3.1,0,7
                ,9,7,54,1,0,1
                ,0,5,8,1e-10,7
                ,8,6,4,8,0
                ]
          vec :: Fractional a => V.Vector a
          vec = V.fromList [1,0,0,0,0]
      in bgroup "(Interval) Gaussian Elimination"
         [ bench "non-interval" $ nf (uncurry intervalGaussianElimination) (arr, vec :: V.Vector Double)
         , bench "naive" $ nf (uncurry intervalGaussianElimination) (arr, vec :: V.Vector IntervalDouble)
         ]
    ]