# Refinement Proofs

## ATS Lock-Step Refinement

[`ats/PatternMatchFold_refine.dats`](ats/PatternMatchFold_refine.dats)

- Encodes Lean `Vec8`, `mixStep`, `processBlock`, and `avx2PatternKernel` as ATS dependent types.
- Encodes `LatticeTemporalHash` parameters (`q=3329`, `n=8`, `m=16`, `T=8`).
- Provides lock-step refinement of:
  - `mixStep` stages (A/B shift-xor, C/F mul-add)
  - `processBlock` match counting
  - `avx2PatternKernel` iterative accumulation
  - `matVec`, `temporalRound`, `temporalPermute`, `encodeByte`, `absorbShort`
  - Finalisation (extra `temporalPermute` matching Lean/SourcePawn/Bluespec)
- Dense unrolling: per-lane operations, full `pi(t,i)` schedule expansion, full public matrix `A_{i,j}` expansion.
- Exceeds 800 lines of refinement obligations.

## NATS Macro Expansion

[`nats/nats_expand.dats`](nats/nats_expand.dats)

- Macro layer that expands the ATS refinement into families of lemmas.
- `LANE_UNROLL_8`, `PI_ROUND`, `A_ROW`, `STAGE_A`..`STAGE_F`, `FINALIZE`.
- Each macro application generates a lock-step obligation against the Lean invariant.

## Relationship to Lean

The ATS files are refinement targets. The Lean models remain the specification. The dual-link is preserved: any change to a Lean invariant requires a corresponding update to the ATS refinement and NATS macros.

## Build

```bash
patscc -o refine proofs/ats/PatternMatchFold_refine.dats
patscc -o nats   proofs/nats/nats_expand.dats
```
