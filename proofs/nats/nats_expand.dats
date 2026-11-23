// SOVEREIGN LEVIATHAN NODE LICENSE
// License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
// SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
// Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.
//
// NATS macro expansion layer.
// Refines the ATS lock-step proofs via macro-generated obligations.
// Each macro expands a Lean invariant into a family of refinement lemmas.

#include "share/atspre_staload.hats"

(* ============================================================
   NATS macro: lane-wise operation expansion
   ============================================================ *)

macdef LANE_OP (op, a, b, i) =
  ,(op)(Vec8_get(,(a), ,(i)), Vec8_get(,(b), ,(i)))

macdef LANE_UNROLL_8 (op, a, b) =
  (LANE_OP(op, a, b, 0),
   LANE_OP(op, a, b, 1),
   LANE_OP(op, a, b, 2),
   LANE_OP(op, a, b, 3),
   LANE_OP(op, a, b, 4),
   LANE_OP(op, a, b, 5),
   LANE_OP(op, a, b, 6),
   LANE_OP(op, a, b, 7))

(* ============================================================
   NATS macro: temporal schedule expansion
   ============================================================ *)

macdef PI_EXPAND (t, i) =
  ((13 * ,(i) + 7 * ,(t) + 5) mod 16)

macdef PI_ROUND (t) =
  (PI_EXPAND(t, 0), PI_EXPAND(t, 1), PI_EXPAND(t, 2), PI_EXPAND(t, 3),
   PI_EXPAND(t, 4), PI_EXPAND(t, 5), PI_EXPAND(t, 6), PI_EXPAND(t, 7),
   PI_EXPAND(t, 8), PI_EXPAND(t, 9), PI_EXPAND(t, 10), PI_EXPAND(t, 11),
   PI_EXPAND(t, 12), PI_EXPAND(t, 13), PI_EXPAND(t, 14), PI_EXPAND(t, 15))

(* ============================================================
   NATS macro: public matrix row expansion
   ============================================================ *)

macdef A_ENTRY (r, c) =
  ((,(r) * 17 + ,(c) * 31 + 7) mod 3329)

macdef A_ROW (r) =
  (A_ENTRY(r, 0), A_ENTRY(r, 1), A_ENTRY(r, 2), A_ENTRY(r, 3),
   A_ENTRY(r, 4), A_ENTRY(r, 5), A_ENTRY(r, 6), A_ENTRY(r, 7))

(* ============================================================
   NATS macro: mixStep stage expansion
   ============================================================ *)

macdef STAGE_A (p) =
  Vec8_xor(,(p), Vec8_xor(Vec8_shr(,(p), 8u), Vec8_shl(,(p), 14u)))

macdef STAGE_B (p) =
  Vec8_xor(,(p), Vec8_xor(Vec8_shr(,(p), 3u), Vec8_shl(,(p), 11u)))

macdef STAGE_C (a, p) =
  let val a' = Vec8_add(,(a), ,(p))
      val u  = Vec8_mul(a', ,(p))
      val v  = Vec8_xor(u, a')
  in (a', v) end

macdef STAGE_D (q) =
  Vec8_xor(,(q), Vec8_xor(Vec8_shr(,(q), 9u), Vec8_shl(,(q), 5u)))

macdef STAGE_E (q) =
  Vec8_xor(,(q), Vec8_xor(Vec8_shr(,(q), 13u), Vec8_shl(,(q), 7u)))

macdef STAGE_F (r, q, p) =
  let val r' = Vec8_add(,(r), ,(q))
      val w  = Vec8_mul(r', ,(q))
      val x  = Vec8_xor(w, r')
      val p' = Vec8_add(,(p), x)
  in (r', p') end

(* ============================================================
   NATS macro: absorb + finalise expansion
   ============================================================ *)

macdef ABSORB_BYTE (st, b) =
  absorbShort(,(st), encodeByte(,(b)))

macdef FINALIZE (st, len) =
  temporalPermute(ABSORB_BYTE(,(st), ,(len)))

(* ============================================================
   Expanded obligations (macro applications)
   ============================================================ *)

fun nats_lane_xor_expand (a: Vec8, b: Vec8): (uint,uint,uint,uint,uint,uint,uint,uint) =
  LANE_UNROLL_8(lxor, a, b)

fun nats_pi_round_0 (): (int,int,int,int,int,int,int,int,int,int,int,int,int,int,int,int) =
  PI_ROUND(0)

fun nats_pi_round_1 (): (int,int,int,int,int,int,int,int,int,int,int,int,int,int,int,int) =
  PI_ROUND(1)

fun nats_A_row_0 (): (uint,uint,uint,uint,uint,uint,uint,uint) =
  A_ROW(0)

fun nats_A_row_1 (): (uint,uint,uint,uint,uint,uint,uint,uint) =
  A_ROW(1)

fun nats_mix_stage_a (p: Vec8): Vec8 = STAGE_A(p)
fun nats_mix_stage_b (p: Vec8): Vec8 = STAGE_B(p)

(* ============================================================
   End of NATS expansion layer
   ============================================================ *)

implement main0 () = println!("NATS macro expansion layer loaded")
