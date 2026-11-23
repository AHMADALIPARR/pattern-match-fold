// SOVEREIGN LEVIATHAN NODE LICENSE
// License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
// SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
// Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.
//
// Minimal C11 Driver API launcher for p3_sm87.cubin (zero nvcc / ptxas)

#include <cuda.h>
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    cuInit(0);
    CUdevice dev;
    CUcontext ctx;
    cuDeviceGet(&dev, 0);
    cuCtxCreate(&ctx, 0, dev);

    FILE *f = fopen("p3_sm87.cubin", "rb");
    if (!f) {
        fprintf(stderr, "Failed to open p3_sm87.cubin\n");
        return 1;
    }
    fseek(f, 0, SEEK_END);
    size_t sz = ftell(f);
    rewind(f);
    void *cubin = malloc(sz);
    if (fread(cubin, 1, sz, f) != sz) {
        fprintf(stderr, "Failed to read cubin\n");
        free(cubin);
        fclose(f);
        return 1;
    }
    fclose(f);

    CUmodule mod;
    CUfunction fn;
    CUresult r1 = cuModuleLoadData(&mod, cubin);
    CUresult r2 = cuModuleGetFunction(&fn, mod, "p3_kernel");
    printf("LOAD=%d FUNC=%d\n", r1, r2);

    CUdeviceptr d_stream = 0, d_sig = 0;
    cuMemAlloc(&d_stream, 256);
    cuMemAlloc(&d_sig, 32);

    void *args[] = { &d_stream, &d_sig };
    CUresult r3 = cuLaunchKernel(fn, 1, 1, 1, 32, 1, 1, 0, 0, args, NULL);
    cuCtxSynchronize();
    printf("LAUNCH=%d\n", r3);

    free(cubin);
    cuCtxDestroy(ctx);
    return 0;
}
