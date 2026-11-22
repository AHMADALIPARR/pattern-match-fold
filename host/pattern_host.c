// SOVEREIGN LEVIATHAN NODE LICENSE
// License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
// SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
// Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.

#include <stdint.h>
#include <stddef.h>
#include <stdio.h>

extern uint64_t avx2_pattern_kernel(
    const uint32_t *stream,
    const uint32_t *pattern,
    size_t blocks,
    uint32_t *out_sig
);

int main(void) {
    _Alignas(32) uint32_t stream[16] = {
        0x534E574A, 0x41433031, 0x00000001, 0x00000002,
        0xDEADBEEF, 0xCAFEBABE, 0x1337C0DE, 0x8BADF00D,
        0x534E574A, 0x00000000, 0x00000001, 0x00000000,
        0xDEADBEEF, 0x00000000, 0x1337C0DE, 0x00000000
    };
    _Alignas(32) uint32_t pattern[8] = {
        0x534E574A, 0x41433031, 0x00000001, 0x00000002,
        0xDEADBEEF, 0xCAFEBABE, 0x1337C0DE, 0x8BADF00D
    };
    _Alignas(32) uint32_t sig[8] = {1, 2, 3, 4, 5, 6, 7, 8};

    uint64_t hits = avx2_pattern_kernel(stream, pattern, 2, sig);
    printf("MATCH_LANES=%llu SIG0=0x%08X SIG7=0x%08X\n",
           (unsigned long long)hits, sig[0], sig[7]);
    return 0;
}
