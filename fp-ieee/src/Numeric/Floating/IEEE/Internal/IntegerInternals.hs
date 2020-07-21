{-# LANGUAGE CPP #-}
{-# LANGUAGE MagicHash #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# OPTIONS_GHC -Wno-unused-imports #-}

#include "MachDeps.h"

module Numeric.Floating.IEEE.Internal.IntegerInternals where
import           Data.Bits
import           GHC.Exts
import           GHC.Int (Int (I#), Int64 (I64#))
import           GHC.Word (Word (W#), Word64 (W64#))
import           MyPrelude
import           Numeric.Natural
#if defined(MIN_VERSION_integer_gmp)
import qualified GHC.Integer
import           GHC.Integer.GMP.Internals (Integer (S#))
import           GHC.Natural (Natural (NatS#))
#endif

integerToIntMaybe :: Integer -> Maybe Int
integerToInt64Maybe :: Integer -> Maybe Int64
naturalToWordMaybe :: Natural -> Maybe Word
naturalToWord64Maybe :: Natural -> Maybe Word64

-- The instance 'Bits Integer' is not very optimized...
unsafeShiftLInteger :: Integer -> Int -> Integer
unsafeShiftRInteger :: Integer -> Int -> Integer

#if defined(MIN_VERSION_integer_gmp)

integerToIntMaybe (S# x#) = Just (I# x#)
integerToIntMaybe _       = Nothing -- relies on Integer's invariant

naturalToWordMaybe (NatS# x#) = Just (W# x#)
naturalToWordMaybe _          = Nothing

#if WORD_SIZE_IN_BITS == 64

integerToInt64Maybe  (S# x#) = Just (I64# x#)
integerToInt64Maybe  _       = Nothing
naturalToWord64Maybe (NatS# x#) = Just (W64# x#)
naturalToWord64Maybe _          = Nothing -- relies on Natural's invariant

#elif WORD_SIZE_IN_BITS < 64

integerToInt64Maybe  (S# x#) = Just (fromIntegral (I# x#))
integerToInt64Maybe  x       = toIntegralSized x
naturalToWord64Maybe (NatS# x#) = Just (fromIntegral (W# x#))
naturalToWord64Maybe x          = toIntegralSized x

#else

integerToInt64Maybe = toIntegralSized
naturalToWord64Maybe = toIntegralSized

#endif

unsafeShiftLInteger x (I# i#) = GHC.Integer.shiftLInteger x i#
unsafeShiftRInteger x (I# i#) = GHC.Integer.shiftRInteger x i#

#else

integerToIntMaybe = toIntegralSized
integerToInt64Maybe = toIntegralSized
naturalToWordMaybe = toIntegralSized
naturalToWord64Maybe = toIntegralSized

unsafeShiftLInteger = unsafeShiftL
unsafeShiftRInteger = unsafeShiftR

#endif

{-# INLINE integerToIntMaybe #-}
{-# INLINE integerToInt64Maybe #-}
{-# INLINE naturalToWordMaybe #-}
{-# INLINE naturalToWord64Maybe #-}

{-# INLINE unsafeShiftLInteger #-}
{-# INLINE unsafeShiftRInteger #-}
