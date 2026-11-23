// SOVEREIGN LEVIATHAN NODE LICENSE
// License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
// SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
// Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.
//
// Bluespec SystemVerilog synthesizable implementation of LatticeTemporalHash

package LatticeTemporalHash;

import Vector::*;
import FIFO::*;
import GetPut::*;
import ClientServer::*;

// ---------------------------------------------------------------------------
// Parameters (must match the mathematical specification)
// ---------------------------------------------------------------------------
typedef 3329 Q;
typedef 8 N; // module rank / short-vector length
typedef 16 M; // ambient dimension
typedef 8 T; // temporal rounds
typedef Bit#(12) Coeff; // coefficients fit in 12 bits (q < 2^12)
typedef Vector#(N, Coeff) ShortVec;
typedef Vector#(M, Coeff) CoeffVec;

// ---------------------------------------------------------------------------
// Public matrix A (m × n). Deterministic elaboration.
// ---------------------------------------------------------------------------
function Coeff publicA(Integer row, Integer col);
   return fromInteger((row * 17 + col * 31 + 7) % valueOf(Q));
endfunction

// ---------------------------------------------------------------------------
// Modular arithmetic helpers
// ---------------------------------------------------------------------------
function Coeff addMod(Coeff a, Coeff b);
   let s = a + b;
   return (s >= fromInteger(valueOf(Q))) ? (s - fromInteger(valueOf(Q))) : s;
endfunction

function Coeff mulMod(Coeff a, Coeff b);
   UInt#(24) p = zeroExtend(a) * zeroExtend(b);
   return truncate(p % fromInteger(valueOf(Q)));
endfunction

// ---------------------------------------------------------------------------
// Matrix-vector product y = A · x (mod q)
// ---------------------------------------------------------------------------
function CoeffVec matVec(ShortVec x);
   CoeffVec y = replicate(0);
   for (Integer j = 0; j < valueOf(N); j = j + 1) begin
      for (Integer i = 0; i < valueOf(M); i = i + 1) begin
         let aij = publicA(i, j);
         let term = mulMod(aij, x[j]);
         y[i] = addMod(y[i], term);
      end
   end
   return y;
endfunction

// ---------------------------------------------------------------------------
// Temporal-resistant permutation schedule (data-independent)
// ---------------------------------------------------------------------------
function Integer pi(Integer t, Integer i);
   return (13 * i + 7 * t + 5) % valueOf(M);
endfunction

function CoeffVec temporalRound(Integer t, CoeffVec z);
   CoeffVec acc = replicate(0);
   for (Integer i = 0; i < valueOf(M); i = i + 1) begin
      let src = pi(t, i);
      acc[i] = addMod(z[src], z[i]);
   end
   return acc;
endfunction

function CoeffVec temporalPermute(CoeffVec z);
   CoeffVec cur = z;
   for (Integer t = 0; t < valueOf(T); t = t + 1)
      cur = temporalRound(t, cur);
   return cur;
endfunction

// ---------------------------------------------------------------------------
// Short encoding of a single byte into an N-lane ternary vector
// ---------------------------------------------------------------------------
function ShortVec encodeByte(Bit#(8) b);
   ShortVec x = replicate(0);
   UInt#(8) val = unpack(b);
   for (Integer k = 0; k < valueOf(N); k = k + 1) begin
      let d = val % 3;
      x[k] = (d == 2) ? fromInteger(valueOf(Q)-1) : truncate(pack(d)); // -1 ≡ q-1
      val = val / 3;
   end
   return x;
endfunction

// ---------------------------------------------------------------------------
// Hardware module
// ---------------------------------------------------------------------------
interface LatticeHashIfc;
   interface Put#(Bit#(8)) putByte; // absorb one message byte
   method Action finalize; // signal end of message
   interface Get#(Bit#(256)) getDigest; // retrieve 256-bit digest
   method Bool done;
endinterface

(* synthesize *)
module mkLatticeTemporalHash(LatticeHashIfc);

   // State
   Reg#(CoeffVec) state <- mkReg(replicate(0));
   Reg#(UInt#(32)) byteCount <- mkReg(0);
   Reg#(Bool) finalizing <- mkReg(False);
   Reg#(Bool) finished <- mkReg(False);
   FIFO#(Bit#(8)) inQ <- mkFIFO;
   FIFO#(Bit#(256)) outQ <- mkFIFO;

   // Absorb a short vector and apply lattice + temporal step
   function Action absorbShort(ShortVec x);
      action
         let y = matVec(x);
         let z = zipWith(addMod, state, y);
         state <= temporalPermute(z);
      endaction
   endfunction

   // Rule: process one input byte
   rule doAbsorb (!finalizing && !finished);
      let b <- toGet(inQ).get;
      let x = encodeByte(b);
      absorbShort(x);
      byteCount <= byteCount + 1;
   endrule

   // Rule: finalisation after length absorption
   rule doFinalize (finalizing && !finished);
      // simplified length encoding (low 8 bits of byte count)
      let lenByte = pack(truncate(byteCount));
      let x = encodeByte(lenByte);
      absorbShort(x);
      // one extra temporal permutation already performed inside absorbShort
      // Pack first 8 coefficients into 256-bit digest
      Bit#(256) digest = 0;
      for (Integer i = 0; i < 8; i = i + 1)
         digest[i*32 + 31 : i*32] = zeroExtend(state[i]);
      outQ.enq(digest);
      finished <= True;
      finalizing <= False;
   endrule

   // Interface methods
   interface putByte = toPut(inQ);

   method Action finalize if (!finalizing && !finished);
      finalizing <= True;
   endmethod

   interface getDigest = toGet(outQ);

   method Bool done = finished;

endmodule

endpackage
