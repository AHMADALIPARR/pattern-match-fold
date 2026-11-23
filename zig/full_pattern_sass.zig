// SOVEREIGN LEVIATHAN NODE LICENSE
// License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
// SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
// Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.
//
// Full 16-Step Comptime Lowered SM87 Pattern-Fold Kernel
// Matches the AVX2 mix network (shift-xor stages + nonlinear mul-add folds)

const std = @import("std");

pub const Reg = u8;
pub const RZ: Reg = 0xFF;

// S2R Rd, SR_TID.X (0x21)
pub fn s2rTidX(comptime rd: Reg, comptime wr_bar: u3) u128 {
    const lo64: u64 = (@as(u64, rd) << 16) | 0x7919;
    const hi64: u64 = 0x000e000000002100 | (@as(u64, wr_bar) << 45);
    return (@as(u128, hi64) << 64) | lo64;
}

// IMAD.WIDE.U32 Rd_pair, Ra, stride_imm, c[0x0][cbank_offset]
pub fn imadWideCbank0(comptime rd_even: Reg, comptime ra: Reg, comptime stride: u32, comptime off: u16, comptime wait: u6) u128 {
    const word_idx: u64 = off >> 2;
    const lo64: u64 = (word_idx << 40) | (@as(u64, stride & 0xFF) << 32) | (@as(u64, ra) << 24) | (@as(u64, rd_even) << 16) | 0x7a25;
    const hi64: u64 = 0x000fc400078e00ff | (@as(u64, wait) << 52);
    return (@as(u128, hi64) << 64) | lo64;
}

// LDG.E.U32 Rd, [Ra_pair.64]
pub fn ldgEU32(comptime rd: Reg, comptime ra_even: Reg, comptime wr_bar: u3) u128 {
    const lo64: u64 = (@as(u64, ra_even) << 24) | (@as(u64, rd) << 16) | 0x7981;
    const hi64: u64 = 0x000ec0000c1e1300 | (@as(u64, wr_bar) << 45);
    return (@as(u128, hi64) << 64) | lo64;
}

// STG.E.U32 [Ra_pair.64], Rb
pub fn stgEU32(comptime ra_even: Reg, comptime rb: Reg, comptime wait: u6, comptime wr_bar: u3) u128 {
    const lo64: u64 = (@as(u64, rb) << 32) | (@as(u64, ra_even) << 24) | 0x7986;
    const hi64: u64 = 0x000fc0000c101304 | (@as(u64, wait) << 52) | (@as(u64, wr_bar) << 45);
    return (@as(u128, hi64) << 64) | lo64;
}

// LOP3.LUT Rd, Ra, Rb, Rc, imm8 (0x96 = Ra ^ Rb ^ Rc)
pub fn lop3(comptime rd: Reg, comptime ra: Reg, comptime rb: Reg, comptime rc: Reg, comptime lut: u8, comptime stall: u4, comptime wait: u6) u128 {
    const lo64: u64 = (@as(u64, lut) << 48) | (@as(u64, rb) << 32) | (@as(u64, ra) << 24) | (@as(u64, rd) << 16) | 0x7212;
    const hi64: u64 = 0x000fe000078e0000 | (@as(u64, wait) << 52) | (@as(u64, stall) << 41) | @as(u64, rc);
    return (@as(u128, hi64) << 64) | lo64;
}

// SHF.L.U32 Rd, Ra, shift_imm, RZ (32-bit logical shift left)
pub fn shlU32(comptime rd: Reg, comptime ra: Reg, comptime shift: u5, comptime stall: u4) u128 {
    const lo64: u64 = (@as(u64, shift) << 40) | (@as(u64, RZ) << 32) | (@as(u64, ra) << 24) | (@as(u64, rd) << 16) | 0x7819;
    const hi64: u64 = 0x000fe000000006ff | (@as(u64, stall) << 41);
    return (@as(u128, hi64) << 64) | lo64;
}

// SHF.R.U32 Rd, RZ, shift_imm, Ra (32-bit logical shift right)
pub fn shrU32(comptime rd: Reg, comptime ra: Reg, comptime shift: u5, comptime stall: u4) u128 {
    const lo64: u64 = (@as(u64, shift) << 40) | (@as(u64, ra) << 32) | (@as(u64, RZ) << 24) | (@as(u64, rd) << 16) | 0x7819;
    const hi64: u64 = 0x000fe000000016ff | (@as(u64, stall) << 41);
    return (@as(u128, hi64) << 64) | lo64;
}

// IMAD.U32 Rd, Ra, Rb, Rc -> Rd = Ra * Rb + Rc (set Rb = 1 for pure IADD: Ra + Rc)
pub fn imadU32(comptime rd: Reg, comptime ra: Reg, comptime rb: Reg, comptime rc: Reg, comptime stall: u4) u128 {
    const lo64: u64 = (@as(u64, rb) << 32) | (@as(u64, ra) << 24) | (@as(u64, rd) << 16) | 0x7224;
    const hi64: u64 = 0x000fe000078e0000 | (@as(u64, stall) << 41) | @as(u64, rc);
    return (@as(u128, hi64) << 64) | lo64;
}

// IMAD.IADD.U32 Rd, Ra, 1, Rc -> Rd = Ra + Rc
pub fn iaddU32(comptime rd: Reg, comptime ra: Reg, comptime rc: Reg, comptime stall: u4) u128 {
    const lo64: u64 = (1 << 32) | (@as(u64, ra) << 24) | (@as(u64, rd) << 16) | 0x7824;
    const hi64: u64 = 0x000fe000078e0000 | (@as(u64, stall) << 41) | @as(u64, rc);
    return (@as(u128, hi64) << 64) | lo64;
}

// Full 16-Step Comptime Lowered SM87 Pattern-Fold Kernel
pub const full_pattern_sass = [_]u128{
    // 1. Read lane_id into R0 (signals SB0)
    s2rTidX(0, 0),

    // 2. Compute 64-bit stream & sig lane addresses (waits on SB0 = 0x01)
    imadWideCbank0(2, 0, 4, 0x160, 0x01),
    imadWideCbank0(6, 0, 4, 0x168, 0x00),

    // 3. Load stream[lane_id] -> R4 (signals SB0)
    ldgEU32(4, 2, 0),

    // 4. Wait on SB0 (0x01): Seed R4 = R4 ^ R0; initialize accumulators R8 = R4, R9 = R0
    lop3(4, 4, 0, RZ, 0x96, 8, 0x01),
    iaddU32(8, 4, RZ, 8),
    iaddU32(9, 0, RZ, 8),

    // 5. Stage A: R4 ^= (R4 >> 8) ^ (R4 << 14)
    shrU32(10, 4, 8, 2),
    shlU32(11, 4, 14, 8),
    lop3(4, 4, 10, 11, 0x96, 8, 0x00),

    // 6. Stage B: R4 ^= (R4 >> 3) ^ (R4 << 11)
    shrU32(10, 4, 3, 2),
    shlU32(11, 4, 11, 8),
    lop3(4, 4, 10, 11, 0x96, 8, 0x00),

    // 7. Stage C (Nonlinear Mix): R8 += R4; R10 = (R8 * R4) ^ R8; R9 += R10
    iaddU32(8, 8, 4, 8),
    imadU32(10, 8, 4, RZ, 8),
    lop3(10, 10, 8, RZ, 0x96, 8, 0x00),
    iaddU32(9, 9, 10, 8),

    // 8. Stage D: R9 ^= (R9 >> 9) ^ (R9 << 5)
    shrU32(10, 9, 9, 2),
    shlU32(11, 9, 5, 8),
    lop3(9, 9, 10, 11, 0x96, 8, 0x00),

    // 9. Stage E: R9 ^= (R9 >> 13) ^ (R9 << 7)
    shrU32(10, 9, 13, 2),
    shlU32(11, 9, 7, 8),
    lop3(9, 9, 10, 11, 0x96, 8, 0x00),

    // 10. Stage F (Final Fold): R8 += R9; R10 = (R8 * R9) ^ R8; R4 += R10
    iaddU32(8, 8, 9, 8),
    imadU32(10, 8, 9, RZ, 8),
    lop3(10, 10, 8, RZ, 0x96, 8, 0x00),
    iaddU32(4, 4, 10, 8),

    // 11. Store R4 -> sig[lane_id] (signals SB1)
    stgEU32(6, 4, 0x00, 1),

    // 12. Wait on SB1 (0x02) and exit warp cleanly
    (@as(u128, 0x002fe0000f000000) << 64) | 0x000000000000794d,
};
