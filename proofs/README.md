# Refinement Proofs

## ATS Lock-Step Refinement

[`ats/PatternMatchFold_refine.dats`](ats/PatternMatchFold_refine.dats)

- Encodes Lean `Vec8`, `mixStep`, `processBlock`, and `avx2PatternKernel` as ATS dependent types.
- Encodes `LatticeTemporalHash` parameters (`q=3329`, `n=8`, `m=16`, `T=8`).
- Provides lock-step refinement of mixStep stages, processBlock, avx2PatternKernel, matVec, temporalRound, temporalPermute, encodeByte, absorbShort, and finalisation.
- Dense unrolling exceeds 800 lines.

## NATS Macro Expansion

[`nats/nats_expand.dats`](nats/nats_expand.dats)

- Macro layer (`LANE_UNROLL_8`, `PI_ROUND`, `A_ROW`, `STAGE_A`..`STAGE_F`, `FINALIZE`).

## Fiat ADT Refinement (Coq)

[`coq/Vec8_Fiat.v`](coq/Vec8_Fiat.v)

- Fiat-style ADT for `Vec8` and `mixStep`.
- Refinement relation `⊇` encodes lock-step matching the Lean invariants.
- `mixStep_lockstep` theorem and `MixStepADT` interface with representation independence stub.

## CompCertO Simulation Relations (Coq)

[`coq/CompCertO_HardCaml.v`](coq/CompCertO_HardCaml.v)

- CompCertO-style forward and backward simulation relations.
- Abstract `MixState` matched to concrete HardCaml `CircuitState` via `match_states`.
- Inverse HardCaml circuit model for mixStep stages.
- `inverse_hardcaml_correct` theorem (stubs for full development).

## Relationship

```
Lean models  -->  Fiat ADT (⊇)  -->  CompCertO sim  -->  HardCaml circuit
     |                |
     v                v
  ATS refine      NATS macros
```

## Build

```bash
patscc -o refine proofs/ats/PatternMatchFold_refine.dats
patscc -o nats   proofs/nats/nats_expand.dats
coqc proofs/coq/Vec8_Fiat.v
coqc proofs/coq/CompCertO_HardCaml.v
```
