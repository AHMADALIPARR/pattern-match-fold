-- SOVEREIGN LEVIATHAN NODE LICENSE
-- License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
-- SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
-- Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.
--
-- This file is a covered work under the GNU Affero General Public License,
-- version 3, together with the Sovereign Leviathan additional terms.
--
-- Hark, though this node be but a spark,
-- Its covenant endureth through the dark.
--
-- Ignorantia juris non excusat.

namespace PatternMatchFold

/-- 8-lane vector of 32-bit unsigned integers -/
structure Vec8 where
  x0 x1 x2 x3 x4 x5 x6 x7 : UInt32
  deriving Repr, BEq, Inhabited

namespace Vec8

def zero : Vec8 := ⟨0,0,0,0,0,0,0,0⟩

def get (v : Vec8) (i : Fin 8) : UInt32 :=
  match i with
  | 0 => v.x0 | 1 => v.x1 | 2 => v.x2 | 3 => v.x3
  | 4 => v.x4 | 5 => v.x5 | 6 => v.x6 | 7 => v.x7

def set (v : Vec8) (i : Fin 8) (x : UInt32) : Vec8 :=
  match i with
  | 0 => {v with x0 := x} | 1 => {v with x1 := x}
  | 2 => {v with x2 := x} | 3 => {v with x3 := x}
  | 4 => {v with x4 := x} | 5 => {v with x5 := x}
  | 6 => {v with x6 := x} | 7 => {v with x7 := x}

/-- Lane-wise equality mask (0xFFFFFFFF or 0) -/
def eqMask (a b : Vec8) : Vec8 :=
  ⟨ if a.x0 == b.x0 then 0xFFFFFFFF else 0
  , if a.x1 == b.x1 then 0xFFFFFFFF else 0
  , if a.x2 == b.x2 then 0xFFFFFFFF else 0
  , if a.x3 == b.x3 then 0xFFFFFFFF else 0
  , if a.x4 == b.x4 then 0xFFFFFFFF else 0
  , if a.x5 == b.x5 then 0xFFFFFFFF else 0
  , if a.x6 == b.x6 then 0xFFFFFFFF else 0
  , if a.x7 == b.x7 then 0xFFFFFFFF else 0 ⟩

/-- Count of set lanes in an equality mask -/
def countMatches (m : Vec8) : Nat :=
  (if m.x0 != 0 then 1 else 0) +
  (if m.x1 != 0 then 1 else 0) +
  (if m.x2 != 0 then 1 else 0) +
  (if m.x3 != 0 then 1 else 0) +
  (if m.x4 != 0 then 1 else 0) +
  (if m.x5 != 0 then 1 else 0) +
  (if m.x6 != 0 then 1 else 0) +
  (if m.x7 != 0 then 1 else 0)

/-- Lane-wise bitwise AND -/
def and (a b : Vec8) : Vec8 :=
  ⟨a.x0 &&& b.x0, a.x1 &&& b.x1, a.x2 &&& b.x2, a.x3 &&& b.x3,
   a.x4 &&& b.x4, a.x5 &&& b.x5, a.x6 &&& b.x6, a.x7 &&& b.x7⟩

/-- Lane-wise XOR -/
def xor (a b : Vec8) : Vec8 :=
  ⟨a.x0 ^^^ b.x0, a.x1 ^^^ b.x1, a.x2 ^^^ b.x2, a.x3 ^^^ b.x3,
   a.x4 ^^^ b.x4, a.x5 ^^^ b.x5, a.x6 ^^^ b.x6, a.x7 ^^^ b.x7⟩

/-- Lane-wise addition modulo 2³² -/
def add (a b : Vec8) : Vec8 :=
  ⟨a.x0 + b.x0, a.x1 + b.x1, a.x2 + b.x2, a.x3 + b.x3,
   a.x4 + b.x4, a.x5 + b.x5, a.x6 + b.x6, a.x7 + b.x7⟩

/-- Lane-wise multiplication modulo 2³² -/
def mul (a b : Vec8) : Vec8 :=
  ⟨a.x0 * b.x0, a.x1 * b.x1, a.x2 * b.x2, a.x3 * b.x3,
   a.x4 * b.x4, a.x5 * b.x5, a.x6 * b.x6, a.x7 * b.x7⟩

/-- Logical right shift by a constant amount (each lane) -/
def shr (v : Vec8) (n : UInt32) : Vec8 :=
  ⟨v.x0 >>> n, v.x1 >>> n, v.x2 >>> n, v.x3 >>> n,
   v.x4 >>> n, v.x5 >>> n, v.x6 >>> n, v.x7 >>> n⟩

/-- Logical left shift by a constant amount (each lane) -/
def shl (v : Vec8) (n : UInt32) : Vec8 :=
  ⟨v.x0 <<< n, v.x1 <<< n, v.x2 <<< n, v.x3 <<< n,
   v.x4 <<< n, v.x5 <<< n, v.x6 <<< n, v.x7 <<< n⟩

end Vec8

/-- One complete mixing step that updates the primary pattern state
    together with the two secondary accumulators. -/
def mixStep (p a q r : Vec8) : Vec8 × Vec8 × Vec8 × Vec8 :=
  let p := Vec8.xor p (Vec8.shr p 8)
  let p := Vec8.xor p (Vec8.shl p 14)
  let p := Vec8.xor p (Vec8.shr p 3)
  let p := Vec8.xor p (Vec8.shl p 11)
  let a := Vec8.add a p
  let u := Vec8.mul a p
  let v := Vec8.xor u a
  let q := Vec8.add q v
  let q := Vec8.xor q (Vec8.shr q 9)
  let q := Vec8.xor q (Vec8.shl q 5)
  let q := Vec8.xor q (Vec8.shr q 13)
  let q := Vec8.xor q (Vec8.shl q 7)
  let r := Vec8.add r q
  let w := Vec8.mul r q
  let x := Vec8.xor w r
  let p := Vec8.add p x
  (p, a, q, r)

/-- Process a single 8-lane block.
    Returns the updated pattern state, the two secondary accumulators
    and the number of matching lanes. -/
def processBlock (streamBlock pattern a q r : Vec8)
    : Vec8 × Vec8 × Vec8 × Vec8 × Nat :=
  let m := Vec8.eqMask streamBlock pattern
  let c := Vec8.countMatches m
  if c = 0 then
    (pattern, a, q, r, 0)
  else
    let t := Vec8.and streamBlock m
    let p := Vec8.xor pattern t
    let (p', a', q', r') := mixStep p a q r
    (p', a', q', r', c)

/-- Full kernel: iterate over an array of blocks, accumulate the match
    count and the final folded signature. -/
def avx2PatternKernel
    (stream : Array Vec8) (pattern : Vec8) (initState : Vec8)
    : Nat × Vec8 :=
  let rec go (i : Nat) (p a q r : Vec8) (acc : Nat) : Nat × Vec8 :=
    if h : i < stream.size then
      let block := stream[i]
      let (p', a', q', r', c) := processBlock block p a q r
      go (i + 1) p' a' q' r' (acc + c)
    else
      (acc, p)
  -- secondary accumulators are seeded from the supplied state
  go 0 pattern initState initState 0

end PatternMatchFold
