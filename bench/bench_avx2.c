// SOVEREIGN LEVIATHAN NODE LICENSE
// License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
// SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
// Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.
//
// AVX2 performance benchmark for the pattern-match-and-fold kernel.
// Links against the NASM object (pattern_kernel.obj).

#include <immintrin.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// External NASM kernel (Windows x64 ABI example; adjust for SysV if needed)
extern void avx2_pattern_kernel(
    const uint32_t* blocks,
    const uint32_t* pattern,
    uint32_t* accumulator,
    uint64_t nblocks,
    uint64_t* match_count
);

static double now_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000.0 + ts.tv_nsec / 1e6;
}

int main(void)
{
    const size_t nblocks = 1 << 20; // 1M blocks of 8 lanes = 32 MB
    const size_t lanes = nblocks * 8;

    uint32_t* blocks = aligned_alloc(32, lanes * sizeof(uint32_t));
    uint32_t* pattern = aligned_alloc(32, 8 * sizeof(uint32_t));
    uint32_t* acc = aligned_alloc(32, 8 * sizeof(uint32_t));
    if (!blocks || !pattern || !acc) {
        fprintf(stderr, "alloc failed\n");
        return 1;
    }

    for (size_t i = 0; i < lanes; ++i)
        blocks[i] = (uint32_t)(i * 0x9E3779B9u);
    for (int i = 0; i < 8; ++i) {
        pattern[i] = 0xDEADBEEFu;
        acc[i] = 0;
    }

    uint64_t matches = 0;
    const int iterations = 50;

    // Warm-up
    avx2_pattern_kernel(blocks, pattern, acc, nblocks, &matches);

    double t0 = now_ms();
    for (int i = 0; i < iterations; ++i)
        avx2_pattern_kernel(blocks, pattern, acc, nblocks, &matches);
    double t1 = now_ms();

    double ms = (t1 - t0) / iterations;
    double bytes = (double)lanes * sizeof(uint32_t) * 2; // read blocks + write acc (approx)
    double gbps = (bytes / 1e9) / (ms / 1e3);

    printf("AVX2 Pattern Kernel\n");
    printf("  Blocks:     %zu (%.2f MB)\n", nblocks, bytes / 1e6);
    printf("  Time/iter:  %.3f ms\n", ms);
    printf("  Throughput: %.2f GB/s\n", gbps);
    printf("  Matches:    %llu\n", (unsigned long long)matches);

    free(blocks);
    free(pattern);
    free(acc);
    return 0;
}
