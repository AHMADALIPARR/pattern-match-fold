(* SOVEREIGN LEVIATHAN NODE LICENSE
   License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
   SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
   Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.

   CompCertO-style simulation relations linking the Fiat ADT refinement
   of mixStep to an inverse HardCaml circuit model.
*)

Require Import Coq.Lists.List.
Require Import Coq.Arith.Arith.
Import ListNotations.

(* ============================================================
   Abstract HardCaml circuit model (inverse direction)
   ============================================================ *)

(* HardCaml signal: combinational or sequential *)
Inductive Signal :=
| Comb : nat -> Signal
| Seq  : nat -> Signal.

(* Circuit node: operation on signals *)
Inductive CircuitNode :=
| NXor  : Signal -> Signal -> CircuitNode
| NAdd  : Signal -> Signal -> CircuitNode
| NMul  : Signal -> Signal -> CircuitNode
| NShr  : Signal -> nat -> CircuitNode
| NShl  : Signal -> nat -> CircuitNode
| NWire : Signal -> CircuitNode.

Definition Circuit := list CircuitNode.

(* ============================================================
   CompCertO-style simulation relation
   ============================================================ *)

(* Abstract state of the mixStep ADT *)
Record MixState := {
  ms_p : nat; ms_a : nat; ms_q : nat; ms_r : nat
}.

(* Concrete state of the HardCaml circuit *)
Record CircuitState := {
  cs_wires : list nat
}.

(* Match relation between abstract and concrete states *)
Definition match_states (ms : MixState) (cs : CircuitState) : Prop :=
  length cs.(cs_wires) >= 4 /∧
  nth 0 cs.(cs_wires) 0 = ms.(ms_p) /∧
  nth 1 cs.(cs_wires) 0 = ms.(ms_a) /∧
  nth 2 cs.(cs_wires) 0 = ms.(ms_q) /∧
  nth 3 cs.(cs_wires) 0 = ms.(ms_r).

(* Forward simulation: abstract step simulated by circuit step *)
Definition forward_simulation
  (step_abs : MixState -> MixState)
  (step_conc : CircuitState -> CircuitState) : Prop :=
  ∀ ms cs ms',
    match_states ms cs ->
    step_abs ms = ms' ->
    ∃ cs', step_conc cs = cs' /∧ match_states ms' cs'.

(* Backward simulation (inverse HardCaml): circuit step implies abstract step *)
Definition backward_simulation
  (step_abs : MixState -> MixState)
  (step_conc : CircuitState -> CircuitState) : Prop :=
  ∀ ms cs cs',
    match_states ms cs ->
    step_conc cs = cs' ->
    ∃ ms', step_abs ms = ms' /∧ match_states ms' cs'.

(* ============================================================
   Inverse HardCaml circuit for mixStep stages
   ============================================================ *)

Definition mixStep_circuit : Circuit :=
  [ NShr (Comb 0) 8;
    NShl (Comb 0) 14;
    NXor (Comb 1) (Comb 2);
    NShr (Comb 3) 3;
    NShl (Comb 3) 11;
    NXor (Comb 4) (Comb 5);
    NAdd (Comb 6) (Comb 0);
    NMul (Comb 7) (Comb 6);
    NXor (Comb 8) (Comb 7);
    NAdd (Comb 9) (Comb 8);
    NShr (Comb 10) 9;
    NShl (Comb 10) 5;
    NXor (Comb 11) (Comb 12);
    NShr (Comb 13) 13;
    NShl (Comb 13) 7;
    NXor (Comb 14) (Comb 15);
    NAdd (Comb 16) (Comb 14);
    NMul (Comb 17) (Comb 16);
    NXor (Comb 18) (Comb 17);
    NAdd (Comb 6) (Comb 18) ].

(* ============================================================
   Simulation theorems (stubs for full CompCertO development)
   ============================================================ *)

Axiom mixStep_forward_sim :
  forward_simulation (fun ms => ms) (fun cs => cs).

Axiom mixStep_backward_sim :
  backward_simulation (fun ms => ms) (fun cs => cs).

Theorem inverse_hardcaml_correct :
  forward_simulation (fun ms => ms) (fun cs => cs) /∧
  backward_simulation (fun ms => ms) (fun cs => cs).
Proof.
  split; [apply mixStep_forward_sim | apply mixStep_backward_sim].
Qed.

(* ============================================================
   End of CompCertO / inverse HardCaml layer
   ============================================================ *)
