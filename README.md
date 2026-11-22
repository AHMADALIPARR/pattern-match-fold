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
```

## Building the Assembly Kernel

```bash
nasm -f win64 asm/pattern_kernel.asm -o pattern_kernel.obj
gcc -O3 -mavx2 -mpopcnt -std=c11 host/pattern_host.c pattern_kernel.obj -o pattern_kernel.exe
./pattern_kernel.exe
```

(Linux: use `-f elf64` and adjust the calling convention / registers if needed.)

## Mathematical Semantics (Pattern Kernel)

Let \( V = (\mathbb{Z}/2^{32}\mathbb{Z})^8 \).

Given a stream of blocks, a pattern \( p \in V \) and an initial accumulator, the kernel returns the total number of matching lanes together with a final folded 256-bit signature.

The Lean function `PatternMatchFold.avx2PatternKernel` realises exactly these semantics.

## Custom Hashing Algorithms

- **SimdPQHash**: 512-bit internal state, 256-bit digest, 12 rounds of ARX + modular multiplications. Designed so that Grover’s algorithm yields approximately 128-bit security against quantum pre-image/collision search. No number-theoretic assumptions.
- **LatticeTemporalHash**: Illustrative lattice-style construction over a small prime with a data-independent temporal permutation schedule. Intended as a starting point for further analysis.

Both are pure, zero-dependency Lean 4 and map directly onto SIMD instructions.

## Dual Linking

This repository is dual-linked to the formal-verification lineage maintained under the Bel Esprit D'Accord Trust / SnapKitty Research Lab. The Lean models are the specification; the assembly is the implementation. Contributions that add refinement proofs are welcome under the same dual license.

---

*Hark, though this node be but a spark, its covenant endureth through the dark.*
