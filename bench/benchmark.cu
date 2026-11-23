// SOVEREIGN LEVIATHAN NODE LICENSE
// License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
// SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
// Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.
//
// Detailed performance benchmarks for the pattern-fold kernels.
// Measures device throughput (GB/s and Gops/s) and compares against a pure host reference.

#include <cuda.h>
#include <cuda_runtime.h>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <vector>
#include <chrono>

#define CHECK_CUDA(call) do { \
    cudaError_t err = (call); \
    if (err != cudaSuccess) { \
        fprintf(stderr, "CUDA error %s at %s:%d\n", cudaGetErrorString(err), __FILE__, __LINE__); \
        exit(1); \
    } \
} while (0)

// ---------------------------------------------------------------------------
// Device kernel (identical algebraic structure to full_pattern_sass / PTX)
// ---------------------------------------------------------------------------
__global__ void pattern_fold_kernel(const uint32_t* __restrict__ stream,
                                    uint32_t* __restrict__ sig,
                                    uint32_t n)
{
    const uint32_t tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid >= n) return;

    uint32_t r4 = stream[tid];
    uint32_t lane = threadIdx.x;          // local lane for seeding (matches warp kernels)

    r4 ^= lane;
    uint32_t r8 = r4;
    uint32_t r9 = lane;

    r4 ^= (r4 >> 8) ^ (r4 << 14);
    r4 ^= (r4 >> 3) ^ (r4 << 11);

    r8 += r4;
    uint32_t r10 = (r8 * r4) ^ r8;
    r9 += r10;

    r9 ^= (r9 >> 9) ^ (r9 << 5);
    r9 ^= (r9 >> 13) ^ (r9 << 7);

    r8 += r9;
    r10 = (r8 * r9) ^ r8;
    r4 += r10;

    sig[tid] = r4;
}

// ---------------------------------------------------------------------------
// Host reference (same arithmetic, single-threaded)
// ---------------------------------------------------------------------------
static uint32_t ref_fold(uint32_t token, uint32_t lane_id)
{
    uint32_t r4 = token ^ lane_id;
    uint32_t r8 = r4;
    uint32_t r9 = lane_id;

    r4 ^= (r4 >> 8) ^ (r4 << 14);
    r4 ^= (r4 >> 3) ^ (r4 << 11);

    r8 += r4;
    r9 += (r8 * r4) ^ r8;

    r9 ^= (r9 >> 9) ^ (r9 << 5);
    r9 ^= (r9 >> 13) ^ (r9 << 7);

    r8 += r9;
    r4 += (r8 * r9) ^ r8;
    return r4;
}

// ---------------------------------------------------------------------------
// Benchmark driver
// ---------------------------------------------------------------------------
struct BenchResult {
    double gbps;
    double gops;
    double ms;
    uint32_t mismatches;
};

BenchResult bench_device(uint32_t n, int iterations)
{
    std::vector<uint32_t> h_stream(n);
    std::vector<uint32_t> h_sig(n);
    for (uint32_t i = 0; i < n; ++i)
        h_stream[i] = 0x534E574Au ^ (i * 0x9E3779B9u);

    uint32_t *d_stream, *d_sig;
    CHECK_CUDA(cudaMalloc(&d_stream, n * sizeof(uint32_t)));
    CHECK_CUDA(cudaMalloc(&d_sig, n * sizeof(uint32_t)));
    CHECK_CUDA(cudaMemcpy(d_stream, h_stream.data(), n * sizeof(uint32_t), cudaMemcpyHostToDevice));

    const int block = 256;
    const int grid = (n + block - 1) / block;

    // Warm-up
    pattern_fold_kernel<<<grid, block>>>(d_stream, d_sig, n);
    CHECK_CUDA(cudaDeviceSynchronize());

    auto t0 = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < iterations; ++i)
        pattern_fold_kernel<<<grid, block>>>(d_stream, d_sig, n);
    CHECK_CUDA(cudaDeviceSynchronize());
    auto t1 = std::chrono::high_resolution_clock::now();

    double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
    double bytes = (double)n * sizeof(uint32_t) * 2 * iterations; // read + write
    double gbps = (bytes / 1e9) / (ms / 1e3);

    // Approximate ops: ~20 arithmetic ops per element
    double gops = ((double)n * 20 * iterations / 1e9) / (ms / 1e3);

    CHECK_CUDA(cudaMemcpy(h_sig.data(), d_sig, n * sizeof(uint32_t), cudaMemcpyDeviceToHost));

    uint32_t mismatches = 0;
    for (uint32_t i = 0; i < n; ++i) {
        uint32_t expected = ref_fold(h_stream[i], i & 255); // block-local lane approx
        if (h_sig[i] != expected) mismatches++;
    }

    cudaFree(d_stream);
    cudaFree(d_sig);

    return {gbps, gops, ms, mismatches};
}

BenchResult bench_host(uint32_t n, int iterations)
{
    std::vector<uint32_t> stream(n);
    std::vector<uint32_t> sig(n);
    for (uint32_t i = 0; i < n; ++i)
        stream[i] = 0x534E574Au ^ (i * 0x9E3779B9u);

    auto t0 = std::chrono::high_resolution_clock::now();
    for (int it = 0; it < iterations; ++it) {
        for (uint32_t i = 0; i < n; ++i)
            sig[i] = ref_fold(stream[i], i & 255);
    }
    auto t1 = std::chrono::high_resolution_clock::now();

    double ms = std::chrono::duration<double, std::milli>(t1 - t0).count();
    double bytes = (double)n * sizeof(uint32_t) * 2 * iterations;
    double gbps = (bytes / 1e9) / (ms / 1e3);
    double gops = ((double)n * 20 * iterations / 1e9) / (ms / 1e3);

    return {gbps, gops, ms, 0};
}

int main(void)
{
    const uint32_t sizes[] = {1 << 16, 1 << 20, 1 << 24}; // 64 Ki, 1 Mi, 16 Mi elements
    const int iters[] = {1000, 100, 10};

    printf("%-12s %12s %12s %12s %12s %s\n",
           "Elements", "Device GB/s", "Device Gops", "Host GB/s", "Host Gops", "Mismatches");
    printf("--------------------------------------------------------------------------------\n");

    for (int i = 0; i < 3; ++i) {
        auto d = bench_device(sizes[i], iters[i]);
        auto h = bench_host(sizes[i], iters[i]);
        printf("%-12u %12.2f %12.2f %12.2f %12.2f %u\n",
               sizes[i], d.gbps, d.gops, h.gbps, h.gops, d.mismatches);
    }

    return 0;
}
