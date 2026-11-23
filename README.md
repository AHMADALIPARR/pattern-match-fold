# Pattern Match & Fold

Zero-dependency AVX2 8-lane SIMD Pattern Match & Fold kernels, formalized in pure Lean 4, together with two custom post-quantum-oriented hashing constructions.

This is a **dual-linked repository**: the NASM assembly kernels and the Lean 4 models are intended to be kept in lock-step. The Lean code realises precisely the same lane-wise semantics as the assembly so that future refinement proofs can be constructed without external dependencies.

## License

Dual-licensed under:

- GNU Affero General Public License v3 (AGPL-3.0), and
- Sovereign Leviathan additional terms (License-ID: SL-AGPL3-001).

**There is no competing-use clause.** Unlike the Functional Source License (FSL), this work imposes no restriction on commercial use, SaaS offering, or substitution. You may freely compete with or embed the software provided you comply with AGPL-3.0 source-availability obligations for network users and retain the attribution / covenant notice.

See the [LICENSE](LICENSE) file for the full text. The custom Sovereign Leviathan header is preserved on every source file.

Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.

## Contents

```
asm/
  pattern_kernel.asm          # Core AVX2 pattern-match-and-fold kernel (Windows x64 ABI)
  bit_pattern_kernel.asm      # Intensive bit-pattern YMM mixing kernel
lean/
  PatternMatchFold.lean       # Zero-dependency Lean 4 model of the pattern kernel
  SimdPQHash.lean             # 512-bit state sponge-style ARX+MUL hash (12 rounds)
  LatticeTemporalHash.lean    # Lattice-based temporal hash over Z/qZ
host/
  pattern_host.c              # Minimal C test harness
  launch_cubin.c              # Verification launcher with deterministic C11 reference model
sourcepawn/
  LatticeTemporalHash.sp      # SourcePawn lowering of the lattice-temporal hash
zig/
  p3_sass_lowering.zig        # Zig 128-bit P3 ISA to SM87 SASS container lowering + pattern fold sequence
  emit_cubin.zig              # Zero-dependency comptime ELF64 .cubin builder (SM87)
  p3_mem_sm87.zig             # Comptime SASS load/store helpers + short sequences
  full_pattern_sass.zig       # Full 16-step pattern-fold SASS (LOP3/SHF/IMAD) matching AVX2 mix
cuda/
  pattern_fold.ptx            # Pure PTX kernel mirroring full_pattern_sass + warp barriers
  pattern_fold_inline.cu      # CUDA C++ with inline PTX (same sequence)
  warp_shuffle.cu             # Warp shuffle primitives (butterfly, up/down, XOR reduce)
bluespec/
  LatticeTemporalHash.bsv     # Synthesizable Bluespec module for the lattice-temporal hash
```

## Building the Assembly Kernel

```bash
nasm -f win64 asm/pattern_kernel.asm -o pattern_kernel.obj
gcc -O3 -mavx2 -mpopcnt -std=c11 host/pattern_host.c pattern_kernel.obj -o pattern_kernel.exe
./pattern_kernel.exe
```

(Linux: use `-f elf64` and adjust the calling convention / registers if needed.)

## SourcePawn Lowering

The lattice-temporal hash (`LatticeTemporalHash`) has been lowered into SourcePawn (`sourcepawn/LatticeTemporalHash.sp`) for use in SourceMod plugins. It preserves the modular arithmetic, public matrix, temporal permutation schedule, and byte encoding. Compile with a modern SourcePawn compiler supporting transitional syntax.

## Zig GPU Lowering & Cubin Builder

- `zig/p3_sass_lowering.zig` defines a 64-bit Sovereign P3 instruction word and lowers selected opcodes into 128-bit SM86/SM87 SASS containers.
- `zig/p3_mem_sm87.zig` provides comptime helpers and short streams (`p3_pattern_sass`, `warp_pattern_sass`).
- `zig/full_pattern_sass.zig` contains the complete 16-step pattern-fold sequence (shift-xor stages + nonlinear mul-add folds) that mirrors the AVX2 mix network, plus LOP3/SHF/IMAD helpers.
- `zig/emit_cubin.zig` is a zero-dependency ELF64 cubin builder. Swap in `full_pattern_sass` for the full kernel.
- `host/launch_cubin.c` is a verification launcher with an exact deterministic C11 reference model (`ref_fold_lane`) that matches the SASS sequence.

Generate and verify:
```bash
zig run zig/emit_cubin.zig
nvdisasm -hex p3_sm87.cubin
gcc -O2 -std=c11 host/launch_cubin.c -lcuda -o launch_cubin && ./launch_cubin
```

## CUDA / PTX Lowering (mirrors Zig SASS)

- `cuda/pattern_fold.ptx` is a pure PTX kernel (sm_87) that implements the identical 16-step sequence. Warp scheduling uses `bar.sync` where the SASS version used scoreboard barriers.
- `cuda/pattern_fold_inline.cu` is the same sequence expressed with inline PTX inside a CUDA C++ kernel, using `__syncwarp()` for the barrier points.
- `cuda/warp_shuffle.cu` adds warp shuffle primitives:
  - `warp_butterfly_xor`, `warp_shfl_up` / `warp_shfl_down`, `warp_shfl`
  - `warp_xor_reduce` (full butterfly reduction)
  - `pattern_fold_shuffle` kernel that inserts butterfly exchanges into the 16-step fold
  - `warp_shuffle_demo` kernel demonstrating the primitives

Both pure-PTX and inline kernels produce the same per-lane result as `full_pattern_sass` / the C reference model. The shuffle variants add inter-lane communication while preserving the local algebraic structure.

## Bluespec Hardware Module

`bluespec/LatticeTemporalHash.bsv` is a synthesizable Bluespec SystemVerilog implementation of the lattice-temporal hash. It exposes a Put/Get interface for byte absorption and 256-bit digest retrieval, with rules for absorb and finalisation. Parameters match the Lean specification (Q=3329, N=8, M=16, T=8). Finalisation includes the extra temporal permute to match Lean/SourcePawn.

## Mathematical Semantics (Pattern Kernel)

Let \( V = (\mathbb{Z}/2^{32}\mathbb{Z})^8 \).

Given a stream of blocks, a pattern \( p \in V \) and an initial accumulator, the kernel returns the total number of matching lanes together with a final folded 256-bit signature.

The Lean function `PatternMatchFold.avx2PatternKernel` realises exactly these semantics.

## Custom Hashing Algorithms

- **SimdPQHash**: 512-bit internal state, 256-bit digest, 12 rounds of ARX + modular multiplications. Designed so that Grover’s algorithm yields approximately 128-bit security against quantum pre-image/collision search. No number-theoretic assumptions.
- **LatticeTemporalHash**: Illustrative lattice-style construction over a small prime with a data-independent temporal permutation schedule. Intended as a starting point for further analysis. Available in Lean, SourcePawn, and synthesizable Bluespec.

Both are pure, zero-dependency Lean 4 and map directly onto SIMD instructions.

## Dual Linking

This repository is dual-linked to the formal-verification lineage maintained under the Bel Esprit D'Accord Trust / SnapKitty Research Lab. The Lean models are the specification; the assembly is the implementation. The SourcePawn, Zig, CUDA/PTX, and Bluespec lowerings provide additional targets. Contributions that add refinement proofs are welcome under the same dual license.

---

*Hark, though this node be but a spark, its covenant endureth through the dark.*
