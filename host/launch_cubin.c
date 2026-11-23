// SOVEREIGN LEVIATHAN NODE LICENSE
// License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
// SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
// Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.
//
// Verification launcher for p3_sm87.cubin
// Includes exact deterministic C11 reference model matching full_pattern_sass

#include <cuda.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define CHECK_CU(call) do { \
    CUresult err = (call); \
    if (err != CUDA_SUCCESS) { \
        const char *str = NULL; \
        cuGetErrorString(err, &str); \
        fprintf(stderr, "CUDA Driver Error %d (%s) at %s:%d\n", err, str ? str : "?", __FILE__, __LINE__); \
        exit(1); \
    } \
} while (0)

// Exact deterministic C11 reference model matching full_pattern_sass
static uint32_t ref_fold_lane(uint32_t token, uint32_t lane_id) {
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

int main(void) {
    CHECK_CU(cuInit(0));
    CUdevice dev;
    CUcontext ctx;
    CHECK_CU(cuDeviceGet(&dev, 0));
    CHECK_CU(cuCtxCreate(&ctx, 0, dev));

    FILE *f = fopen("p3_sm87.cubin", "rb");
    if (!f) { perror("p3_sm87.cubin"); return 1; }
    fseek(f, 0, SEEK_END);
    size_t sz = (size_t)ftell(f);
    rewind(f);
    void *cubin = malloc(sz);
    if (fread(cubin, 1, sz, f) != sz) { perror("fread"); free(cubin); fclose(f); return 1; }
    fclose(f);

    CUmodule mod;
    CUfunction fn;
    CHECK_CU(cuModuleLoadData(&mod, cubin));
    CHECK_CU(cuModuleGetFunction(&fn, mod, "p3_kernel"));

    uint32_t h_stream[32];
    uint32_t h_sig[32] = {0};
    for (uint32_t i = 0; i < 32; ++i) {
        h_stream[i] = 0x534E574Au ^ (i * 0x9E3779B9u);
    }

    CUdeviceptr d_stream = 0, d_sig = 0;
    CHECK_CU(cuMemAlloc(&d_stream, sizeof(h_stream)));
    CHECK_CU(cuMemAlloc(&d_sig, sizeof(h_sig)));
    CHECK_CU(cuMemcpyHtoD(d_stream, h_stream, sizeof(h_stream)));

    void *args[] = { &d_stream, &d_sig };
    CHECK_CU(cuLaunchKernel(fn, 1, 1, 1, 32, 1, 1, 0, 0, args, NULL));
    CHECK_CU(cuCtxSynchronize());
    CHECK_CU(cuMemcpyDtoH(h_sig, d_sig, sizeof(h_sig)));

    uint32_t mismatches = 0;
    for (uint32_t lane = 0; lane < 32; ++lane) {
        uint32_t expected = ref_fold_lane(h_stream[lane], lane);
        if (h_sig[lane] != expected) {
            fprintf(stderr, "MISMATCH lane %2u: gpu=0x%08X ref=0x%08X\n", lane, h_sig[lane], expected);
            mismatches++;
        }
    }

    printf("SM87_WARP_VERIFY: lanes=32 mismatches=%u lane0=0x%08X lane31=0x%08X\n",
           mismatches, h_sig[0], h_sig[31]);

    cuMemFree(d_stream);
    cuMemFree(d_sig);
    free(cubin);
    cuCtxDestroy(ctx);
    return mismatches == 0 ? 0 : 1;
}
