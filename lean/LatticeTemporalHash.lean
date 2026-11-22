-- SOVEREIGN LEVIATHAN NODE LICENSE
-- License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
-- SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
-- Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.

namespace LatticeTemporalHash

/-- Small prime modulus (illustrative; replace by a larger safe prime for production) -/
def q : UInt32 := 3329

/-- Module rank (8 lanes) and ambient dimension -/
def n : Nat := 8
def m : Nat := 16
def T : Nat := 8 -- number of temporal rounds

/-- Coefficient vector of length m over Z/qZ -/
structure CoeffVec where
  data : Array UInt32 -- length m, each entry < q
  deriving Repr, Inhabited

namespace CoeffVec

def zero : CoeffVec := ⟨Array.replicate m 0⟩

def get (v : CoeffVec) (i : Fin m) : UInt32 :=
  v.data[i]!

def set (v : CoeffVec) (i : Fin m) (x : UInt32) : CoeffVec :=
  ⟨v.data.set i (x % q)⟩

def addMod (a b : CoeffVec) : CoeffVec :=
  let rec go (i : Nat) (acc : Array UInt32) : CoeffVec :=
    if h : i < m then
      go (i+1) (acc.set! i (((a.data[i]! + b.data[i]!) % q)))
    else
      ⟨acc⟩
  go 0 (Array.replicate m 0)

end CoeffVec

/-- Fixed public matrix A (m × n). Entries are deterministic for reproducibility. -/
def publicMatrix : Array (Array UInt32) :=
  let rec row (r : Nat) : Array UInt32 :=
    Array.ofFn (fun (c : Fin n) =>
      (((r.toUInt32 * 17 + c.val.toUInt32 * 31 + 7) % q)))
  Array.ofFn (fun (r : Fin m) => row r.val)

/-- Matrix-vector product y = A · x (mod q), x short of length n -/
def matVec (x : Array UInt32) : CoeffVec :=
  let rec col (j : Nat) (acc : CoeffVec) : CoeffVec :=
    if h : j < n then
      let xj := x[j]! % q
      let rec row (i : Nat) (acc' : CoeffVec) : CoeffVec :=
        if h' : i < m then
          let aij := publicMatrix[i]![j]!
          let new := (acc'.data[i]! + aij * xj) % q
          row (i+1) (CoeffVec.set acc' ⟨i, by omega⟩ new)
        else
          acc'
      col (j+1) (row 0 acc)
    else
      acc
  col 0 CoeffVec.zero

/-- Temporal-resistant permutation schedule (completely data-independent) -/
def pi (t i : Nat) : Nat :=
  ((13 * i + 7 * t + 5) % m)

/-- One temporal mixing round -/
def temporalRound (t : Nat) (z : CoeffVec) : CoeffVec :=
  let rec go (i : Nat) (acc : CoeffVec) : CoeffVec :=
    if h : i < m then
      let src := pi t i
      let val := (z.data[src]! + z.data[i]!) % q
      go (i+1) (CoeffVec.set acc ⟨i, by omega⟩ val)
    else
      acc
  go 0 CoeffVec.zero

/-- Apply T successive temporal rounds -/
def temporalPermute (z : CoeffVec) : CoeffVec :=
  let rec go (t : Nat) (z : CoeffVec) : CoeffVec :=
    match t with
    | 0 => z
    | t'+1 => go t' (temporalRound t' z)
  go T z

/-- Deterministic short encoding of a byte into an 8-lane ternary vector -/
def encodeByte (b : UInt8) : Array UInt32 :=
  let rec digits (x : Nat) (k : Nat) (acc : Array UInt32) : Array UInt32 :=
    if k = 0 then acc
    else
      let d := x % 3
      let signed : UInt32 := if d = 2 then (q-1) else d.toUInt32 -- -1 ≡ q-1
      digits (x / 3) (k-1) (acc.push signed)
  digits b.toNat n #[]

/-- Absorb a single short vector and apply the lattice + temporal step -/
def absorbShort (state : CoeffVec) (x : Array UInt32) : CoeffVec :=
  let y := matVec x
  let z := CoeffVec.addMod state y
  temporalPermute z

/-- Main hash entry point.
    Input is an array of bytes; output is a 256-bit digest packed from the final coefficient vector. -/
def hash (msg : Array UInt8) : Array UInt32 :=
  -- initialise state to zero
  let rec absorb (i : Nat) (st : CoeffVec) : CoeffVec :=
    if h : i < msg.size then
      let x := encodeByte msg[i]!
      absorb (i+1) (absorbShort st x)
    else
      st
  let st0 := absorb 0 CoeffVec.zero
  -- finalisation: absorb length and one extra temporal round
  let lenVec := encodeByte (msg.size.toUInt8) -- simplified length encoding
  let st1 := absorbShort st0 lenVec
  let final := temporalPermute st1
  -- pack the first eight coefficients into a 256-bit digest (low 32 bits each)
  Array.ofFn (fun (i : Fin 8) => final.data[i.val]! )

end LatticeTemporalHash
