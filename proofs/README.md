# Refinement Proofs

## ATS Lock-Step Refinement

[`ats/PatternMatchFold_refine.dats`](ats/PatternMatchFold_refine.dats)

- Encodes Lean `Vec8`, `mixStep`, `processBlock`, and `avx2PatternKernel` as ATS dependent types.
- Dense unrolling exceeds 800 lines.

## NATS Macro Expansion

[`nats/nats_expand.dats`](nats/nats_expand.dats)

- Macro layer (`LANE_UNROLL_8`, `PI_ROUND`, `A_ROW`, `STAGE_A`..`STAGE_F`, `FINALIZE`).

## Church Numeral Linear Types

[`church/ChurchLinear.hs`](church/ChurchLinear.hs)

- Church numerals (`zero`, `succC`, `addC`, `mulC`, `expC`).
- Linear Church numerals (`LChurch`, `lzero`, `lsucc`, `ladd`, `lmul`) using GHC linear types.
- Concrete numerical encodings derived from Church (`toInt`, `fromInt`).
- mixStep stages and lattice operations expressed as Church compositions.

## Liquid Haskell Refinement (Workman-style)

[`liquidhaskell/ChurchRefine.hs`](liquidhaskell/ChurchRefine.hs)

- Real numerical bounds derived from Church encodings.
- `Lane32` (0..2^32-1), `CoeffQ` (0..3328), `Byte8`, `Idx8`, `Idx16`.
- `mixStepReal`, `temporalPiReal`, `encodeDigitReal`, `matVecEntryReal` with modular bounds.
- 1% refinement metric via `refinementCoverage`.

## SymPy / Church Calculi Emitter

[`sympy/calculi.py`](sympy/calculi.py)

- Emits Liquid Haskell refinement types from Church numeral bounds.
- Verifies Church addition and multiplication.

## Stack

```
Lean models
    |
    v
ATS refinement
    |
    v
Church linear types  -->  Liquid Haskell (Workman calculus)
    |
    v
NATS macros
```

## Build

```bash
ghc -XLinearTypes proofs/church/ChurchLinear.hs
liquid proofs/liquidhaskell/ChurchRefine.hs
python3 proofs/sympy/calculi.py
```
