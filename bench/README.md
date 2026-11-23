# Performance Benchmarks

## CUDA Device vs Host

```bash
nvcc -O3 -std=c++17 bench/benchmark.cu -o bench_cuda
./bench_cuda
```

Measures:
- Device throughput (GB/s and approximate Gops/s) for the 16-step pattern-fold
- Host single-threaded reference throughput
- Correctness (mismatches against the deterministic reference model)

Typical sizes: 64 Ki, 1 Mi, and 16 Mi elements.

## AVX2 Host Kernel

```bash
nasm -f elf64 asm/pattern_kernel.asm -o pattern_kernel.o   # or win64
gcc -O3 -mavx2 bench/bench_avx2.c pattern_kernel.o -o bench_avx2
./bench_avx2
```

Reports time per iteration and GB/s for the NASM AVX2 kernel on 1M blocks.

## Notes
- All benchmarks use the same algebraic structure as `full_pattern_sass` / the Lean model.
- Device numbers are for a single GPU; scale with occupancy and memory bandwidth.
- Host AVX2 numbers assume the kernel is compiled with the matching ABI.
