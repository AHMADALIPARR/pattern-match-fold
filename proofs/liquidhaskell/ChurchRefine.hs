-- SOVEREIGN LEVIATHAN NODE LICENSE
-- License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
-- SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
-- Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.
--
-- Liquid Haskell refinement of real Church numeral operations.
-- Bounds checked against the native Data.Bits implementation.

{-# LANGUAGE DataKinds #-}

module ChurchRefine where

import ChurchLinear

-- ============================================================
-- Refined types
-- ============================================================

{-@ type Lane32 = {v:Int | 0 <= v && v < 4294967296} @-}
{-@ type CoeffQ = {v:Int | 0 <= v && v < 3329} @-}
{-@ type Byte8  = {v:Int | 0 <= v && v < 256} @-}
{-@ type Idx8   = {v:Int | 0 <= v && v < 8} @-}
{-@ type Idx16  = {v:Int | 0 <= v && v < 16} @-}

-- ============================================================
-- Refined wrappers around real operations
-- ============================================================

{-@ xor32R :: Lane32 -> Lane32 -> Lane32 @-}
xor32R :: Int -> Int -> Int
xor32R = xor32

{-@ shr32R :: Lane32 -> {k:Int | 0 <= k && k < 32} -> Lane32 @-}
shr32R :: Int -> Int -> Int
shr32R = shr32

{-@ shl32R :: Lane32 -> {k:Int | 0 <= k && k < 32} -> Lane32 @-}
shl32R :: Int -> Int -> Int
shl32R = shl32

{-@ addMod32R :: Lane32 -> Lane32 -> Lane32 @-}
addMod32R :: Int -> Int -> Int
addMod32R = addMod32

{-@ mulMod32R :: Lane32 -> Lane32 -> Lane32 @-}
mulMod32R :: Int -> Int -> Int
mulMod32R = mulMod32

{-@ mixStepR :: Lane32 -> Lane32 -> Lane32 -> Lane32
             -> (Lane32, Lane32, Lane32, Lane32) @-}
mixStepR :: Int -> Int -> Int -> Int -> (Int, Int, Int, Int)
mixStepR = mixStep

{-@ temporalPiR :: Idx8 -> Idx16 -> Idx16 @-}
temporalPiR :: Int -> Int -> Int
temporalPiR = temporalPi

{-@ encodeDigitR :: Byte8 -> Idx8 -> CoeffQ @-}
encodeDigitR :: Int -> Int -> Int
encodeDigitR = encodeDigit

{-@ matVecEntryR :: Idx16 -> Idx8 -> CoeffQ -> CoeffQ @-}
matVecEntryR :: Int -> Int -> Int -> Int
matVecEntryR = matVecEntry

-- ============================================================
-- Refinement coverage
-- ============================================================

{-@ measure inRange :: Int -> Int -> Bool @-}
inRange :: Int -> Int -> Bool
inRange v bound = 0 <= v && v < bound

{-@ refinementHolds :: v:Lane32 -> {b:Bool | b <=> inRange v 4294967296} @-}
refinementHolds :: Int -> Bool
refinementHolds v = inRange v 4294967296
