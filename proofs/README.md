# Refinement Proofs

## ATS Lock-Step Refinement

[`ats/PatternMatchFold_refine.dats`](ats/PatternMatchFold_refine.dats)

- Encodes Lean `Vec8`, `mixStep`, `processBlock`, and `avx2PatternKernel` as ATS dependent types.
- Encodes `LatticeTemporalHash` parameters (`q=3329`, `n=8`, `m=16`, `T=8`).
- Dense unrolling exceeds 800 lines.

## NATS Macro Expansion

[`nats/nats_expand.dats`](nats/nats_expand.dats)

- Macro layer (`LANE_UNROLL_8`, `PI_ROUND`, `A_ROW`, `STAGE_A`..`STAGE_F`, `FINALIZE`).

## SymPy Calculi

[`sympy/calculi.py`](sympy/calculi.py)

- Symbolic computation of `mixStep` stages and `LatticeTemporalHash` operations.
- Emits Liquid Haskell refinement types from the calculated forms.
- Verifies deterministic reconstruction of pure functions.

## Liquid Haskell Refinement

[`liquidhaskell/MixStep.hs`](liquidhaskell/MixStep.hs)

- Refinement types for `Lane`, `Coeff`, `Byte`, and index bounds.
- `mixStep` with Liquid annotations matching the ATS/SymPy calculi.
- `temporalPi`, `encodeDigit`, `matVecEntry` with modular bounds.
- Derived from the ATS lock-step refinement via SymPy-calculated forms.

## Fiat ADT Refinement (Coq)

[`coq/Vec8_Fiat.v`](coq/Vec8_Fiat.v)

- Fiat-style ADT for `Vec8` and `mixStep` with `⊇` relation.

## Stack

```
Lean models
    |
    v
ATS refinement  -->  SymPy calculi  -->  Liquid Haskell
    |
    v
NATS macros
```

## Build

```bash
patscc -o refine proofs/ats/PatternMatchFold_refine.dats
python3 proofs/sympy/calculi.py
liquid proofs/liquidhaskell/MixStep.hs
```
