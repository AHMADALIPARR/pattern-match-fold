# Refinement Proofs

## ATS Lock-Step Refinement

[`ats/PatternMatchFold_refine.dats`](ats/PatternMatchFold_refine.dats)

- Encodes Lean `Vec8`, `mixStep`, `processBlock`, and `avx2PatternKernel` as ATS dependent types.
- Dense unrolling exceeds 800 lines.

## NATS Macro Expansion

[`nats/nats_expand.dats`](nats/nats_expand.dats)

- Macro layer (`LANE_UNROLL_8`, `PI_ROUND`, `A_ROW`, `STAGE_A`..`STAGE_F`, `FINALIZE`).

## Church Numeral Linear Types (real implementation)

[`church/ChurchLinear.hs`](church/ChurchLinear.hs)

- Church numerals and linear Church numerals (GHC linear types).
- Real bit operations via `Data.Bits` (`xor`, `shiftR`, `shiftL`, `.&.`).
- `mixStep`, `temporalPi`, `encodeDigit`, `matVecEntry` implemented natively.
- No Python stubs.

## Liquid Haskell Refinement

[`liquidhaskell/ChurchRefine.hs`](liquidhaskell/ChurchRefine.hs)

- Refinement types wrapping the real ChurchLinear operations.
- `Lane32`, `CoeffQ`, `Byte8`, `Idx8`, `Idx16`.
- `mixStepR`, `temporalPiR`, `encodeDigitR`, `matVecEntryR`.

## Stack

```
Lean models
    |
    v
ATS refinement
    |
    v
Church linear types (Data.Bits)  -->  Liquid Haskell
    |
    v
NATS macros
```

## Build

```bash
ghc -XLinearTypes proofs/church/ChurchLinear.hs
liquid proofs/liquidhaskell/ChurchRefine.hs
```
