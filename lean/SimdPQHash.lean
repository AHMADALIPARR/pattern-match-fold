-- SOVEREIGN LEVIATHAN NODE LICENSE
-- License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
-- SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
-- Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.

namespace SimdPQHash

/-- 8-lane 32-bit vector -/
structure Vec8 where
  x0 x1 x2 x3 x4 x5 x6 x7 : UInt32
  deriving Repr, BEq, Inhabited

namespace Vec8

def zero : Vec8 := ⟨0,0,0,0,0,0,0,0⟩

def xor (a b : Vec8) : Vec8 :=
  ⟨a.x0 ^^^ b.x0, a.x1 ^^^ b.x1, a.x2 ^^^ b.x2, a.x3 ^^^ b.x3,
   a.x4 ^^^ b.x4, a.x5 ^^^ b.x5, a.x6 ^^^ b.x6, a.x7 ^^^ b.x7⟩

def add (a b : Vec8) : Vec8 :=
  ⟨a.x0 + b.x0, a.x1 + b.x1, a.x2 + b.x2, a.x3 + b.x3,
   a.x4 + b.x4, a.x5 + b.x5, a.x6 + b.x6, a.x7 + b.x7⟩

def mul (a b : Vec8) : Vec8 :=
  ⟨a.x0 * b.x0, a.x1 * b.x1, a.x2 * b.x2, a.x3 * b.x3,
   a.x4 * b.x4, a.x5 * b.x5, a.x6 * b.x6, a.x7 * b.x7⟩

def shr (v : Vec8) (n : UInt32) : Vec8 :=
  ⟨v.x0 >>> n, v.x1 >>> n, v.x2 >>> n, v.x3 >>> n,
   v.x4 >>> n, v.x5 >>> n, v.x6 >>> n, v.x7 >>> n⟩

def shl (v : Vec8) (n : UInt32) : Vec8 :=
  ⟨v.x0 <<< n, v.x1 <<< n, v.x2 <<< n, v.x3 <<< n,
   v.x4 <<< n, v.x5 <<< n, v.x6 <<< n, v.x7 <<< n⟩

end Vec8

/-- One mixing round (ARX + multiplication) -/
def mixRound (p a : Vec8) : Vec8 × Vec8 :=
  let p := Vec8.xor p (Vec8.shr p 8)
  let p := Vec8.xor p (Vec8.shl p 14)
  let p := Vec8.xor p (Vec8.shr p 3)
  let p := Vec8.xor p (Vec8.shl p 11)
  let a := Vec8.add a p
  let u := Vec8.mul a p
  let v := Vec8.xor u a
  let a := Vec8.xor a (Vec8.shr v 9)
  let a := Vec8.xor a (Vec8.shl v 5)
  let a := Vec8.xor a (Vec8.shr v 13)
  let a := Vec8.xor a (Vec8.shl v 7)
  let p := Vec8.add p a
  (p, a)

/-- Twelve successive rounds -/
def mix12 (p a : Vec8) : Vec8 × Vec8 :=
  let rec go (n : Nat) (p a : Vec8) : Vec8 × Vec8 :=
    match n with
    | 0 => (p, a)
    | n+1 =>
      let (p', a') := mixRound p a
      go n p' a'
  go 12 p a

/-- Absorb a single 256-bit block and apply the full mixing function -/
def absorbBlock (s0 s1 block : Vec8) : Vec8 × Vec8 :=
  let s0 := Vec8.xor s0 block
  mix12 s0 s1

/-- Convert a list of UInt32 into an array of Vec8 blocks (little-endian lanes) -/
def toBlocks (data : Array UInt32) : Array Vec8 :=
  let rec go (i : Nat) (acc : Array Vec8) : Array Vec8 :=
    if h : i + 8 ≤ data.size then
      let v : Vec8 :=
        ⟨ data[i]!, data[i+1]!, data[i+2]!, data[i+3]!,
          data[i+4]!, data[i+5]!, data[i+6]!, data[i+7]! ⟩
      go (i + 8) (acc.push v)
    else
      -- final partial block is zero-padded
      let remaining := data.size - i
      let get (k : Nat) : UInt32 := if k < remaining then data[i+k]! else 0
      let v : Vec8 := ⟨ get 0, get 1, get 2, get 3, get 4, get 5, get 6, get 7 ⟩
      acc.push v
  go 0 #[]

/-- Domain-separation constants (arbitrary but fixed) -/
def IV0 : Vec8 := ⟨0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A,
                    0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19⟩
def IV1 : Vec8 := ⟨0xC1059ED8, 0x367CD507, 0x3070DD17, 0xF70E5939,
                    0xFFC00B31, 0x68581511, 0x64F98FA7, 0xBEFA4FA4⟩

/-- Main hash function.
    Input is an array of 32-bit words; output is a 256-bit digest (Vec8). -/
def hash (data : Array UInt32) : Vec8 :=
  let blocks := toBlocks data
  let rec absorb (i : Nat) (s0 s1 : Vec8) : Vec8 × Vec8 :=
    if h : i < blocks.size then
      let (s0', s1') := absorbBlock s0 s1 blocks[i]!
      absorb (i + 1) s0' s1'
    else
      (s0, s1)
  let (s0, s1) := absorb 0 IV0 IV1
  -- finalisation: absorb length (in bytes) and a domain-separation flag
  let lenBytes : UInt32 := (data.size.toUInt32) * 4
  let finalBlock : Vec8 := ⟨lenBytes, 0x80000000, 0, 0, 0, 0, 0, 1⟩ -- flag = 1
  let (s0', _) := absorbBlock s0 s1 finalBlock
  s0' -- 256-bit digest

end SimdPQHash
