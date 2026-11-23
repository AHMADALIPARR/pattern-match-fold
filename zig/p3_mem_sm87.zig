// SOVEREIGN LEVIATHAN NODE LICENSE
// License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
// SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
// Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.
//
// Drop-in Zig comptime Load/Store Helpers + Pattern-Fold SASS streams for SM87

const std = @import("std");

pub const Reg = u8;
pub const RZ: Reg = 0xFF;

// Load 32-bit word from constant bank c[0x0][offset] (offset must be 4-byte aligned)
pub fn movCbank0(comptime rd: Reg, comptime byte_offset: u16) u128 {
    const word_idx: u64 = byte_offset >> 2;
    const lo64: u64 = (word_idx << 40) | (@as(u64, rd) << 16) | 0x7a02;
    const hi64: u64 = 0x000fe40000000f00;
    return (@as(u128, hi64) << 64) | lo64;
}

// LDG.E.64 Rd, [Ra.64 + disp] with producer scoreboard barrier allocation (0..5, 7=none)
pub fn ldgE64(comptime rd: Reg, comptime ra_pair: Reg, comptime disp: i24, comptime wr_bar: u3) u128 {
    const disp_bits: u64 = @as(u24, @bitCast(disp));
    const lo64: u64 = (disp_bits << 40) | (@as(u64, ra_pair) << 24) | (@as(u64, rd) << 16) | 0x7981;
    const hi_base: u64 = 0x000ec0000c1e1900; // base control word with wr_bar cleared
    const hi64: u64 = hi_base | (@as(u64, wr_bar) << 45);
    return (@as(u128, hi64) << 64) | lo64;
}

// STG.E.64 [Ra.64 + disp], Rb with optional wait_mask (bitmask of SB0..SB5) & wr_bar
pub fn stgE64(comptime ra_pair: Reg, comptime rb_pair: Reg, comptime disp: i24, comptime wait_mask: u6, comptime wr_bar: u3) u128 {
    const disp_bits: u64 = @as(u24, @bitCast(disp));
    const lo64: u64 = (disp_bits << 40) | (@as(u64, rb_pair) << 32) | (@as(u64, ra_pair) << 24) | 0x7986;
    const hi_base: u64 = 0x000fc0000c101904;
    const hi64: u64 = hi_base | (@as(u64, wait_mask) << 52) | (@as(u64, wr_bar) << 45);
    return (@as(u128, hi64) << 64) | lo64;
}

// S2R Rd, SR_TID.X (0x21) — reads hardware threadIdx.x into Rd and signals wr_bar
pub fn s2rTidX(comptime rd: Reg, comptime wr_bar: u3) u128 {
    comptime std.debug.assert(rd < 255); // Invariant I2: [0, 254]
    const lo64: u64 = (@as(u64, rd) << 16) | 0x7919;
    const hi_base: u64 = 0x000e000000002100;
    const hi64: u64 = hi_base | (@as(u64, wr_bar) << 45);
    return (@as(u128, hi64) << 64) | lo64;
}

// IMAD.WIDE.U32 Rd_pair, Ra, stride_imm, c[0x0][cbank_offset]
// Computes 64-bit pointer {Rd, Rd+1} = c[0x0][cbank_offset] + (Ra * stride_imm)
pub fn imadWideCbank0(
    comptime rd_even: Reg,
    comptime ra: Reg,
    comptime stride_imm: u32,
    comptime cbank_offset: u16,
    comptime wait_mask: u6,
) u128 {
    comptime std.debug.assert(rd_even % 2 == 0 and rd_even < 254);
    const word_idx: u64 = cbank_offset >> 2;
    const lo64: u64 = (word_idx << 40) |
        (@as(u64, stride_imm & 0xFF) << 32) |
        (@as(u64, ra) << 24) |
        (@as(u64, rd_even) << 16) |
        0x7a25;
    const hi_base: u64 = 0x000fc400078e00ff;
    const hi64: u64 = hi_base | (@as(u64, wait_mask) << 52);
    return (@as(u128, hi64) << 64) | lo64;
}

// LDG.E.U32 Rd, [Ra_pair.64] (32-bit per-lane load)
pub fn ldgEU32(comptime rd: Reg, comptime ra_even: Reg, comptime wr_bar: u3) u128 {
    comptime std.debug.assert(ra_even % 2 == 0);
    const lo64: u64 = (@as(u64, ra_even) << 24) | (@as(u64, rd) << 16) | 0x7981;
    const hi_base: u64 = 0x000ec0000c1e1300;
    const hi64: u64 = hi_base | (@as(u64, wr_bar) << 45);
    return (@as(u128, hi64) << 64) | lo64;
}

// STG.E.U32 [Ra_pair.64], Rb (32-bit per-lane store)
pub fn stgEU32(comptime ra_even: Reg, comptime rb: Reg, comptime wait_mask: u6, comptime wr_bar: u3) u128 {
    comptime std.debug.assert(ra_even % 2 == 0);
    const lo64: u64 = (@as(u64, rb) << 32) | (@as(u64, ra_even) << 24) | 0x7986;
    const hi_base: u64 = 0x000fc0000c101304;
    const hi64: u64 = hi_base | (@as(u64, wait_mask) << 52) | (@as(u64, wr_bar) << 45);
    return (@as(u128, hi64) << 64) | lo64;
}

// Complete Comptime SASS Kernel Stream: Load -> Pattern Fold -> Store -> Exit
pub const p3_pattern_sass = [_]u128{
    // 1. Load 64-bit d_stream pointer into {R2, R3} and d_sig pointer into {R6, R7}
    movCbank0(2, 0x160),
    movCbank0(3, 0x164),
    movCbank0(6, 0x168),
    movCbank0(7, 0x16c),

    // 2. Load 64-bit input tokens from [R2.64 + 0] into {R4, R5}, signaling SB0 when ready
    ldgE64(4, 2, 0, 0),

    // 3. Example ALU op waiting on SB0 (wait_mask = 0x01): R4 = R4 ^ R5 ^ RZ (LOP3.LUT 0x96)
    (@as(u128, 0x001fe400078e96ff) << 64) | 0x0000000504047212,

    // 4. Store 64-bit result {R4, R5} to [R6.64 + 0], signaling SB1 on completion
    stgE64(6, 4, 0, 0x00, 1),

    // 5. Wait on SB1 (wait_mask = 0x02) and terminate warp cleanly
    (@as(u128, 0x002fe0000f000000) << 64) | 0x000000000000794d,
};

// Complete 32-Lane Parallel Warp Pattern-Fold SASS Stream
pub const warp_pattern_sass = [_]u128{
    // 1. R0 = SR_TID.X (lane_id 0..31), signals SB0 when ready
    s2rTidX(0, 0),

    // 2. Wait on SB0 (0x01): {R2, R3} = d_stream + R0 * 4; {R6, R7} = d_sig + R0 * 4
    imadWideCbank0(2, 0, 4, 0x160, 0x01),
    imadWideCbank0(6, 0, 4, 0x168, 0x00),

    // 3. Load 32-bit token stream[lane_id] into R4, signaling SB0 on completion
    ldgEU32(4, 2, 0),

    // 4. Wait on SB0 (0x01): Fold R4 via LOP3.LUT (0x96 = A ^ B ^ C) with lane_id (R0)
    (@as(u128, 0x001fe400078e96ff) << 64) | 0x0000000004047212,

    // 5. Store folded 32-bit state R4 -> sig[lane_id], signaling SB1 on completion
    stgEU32(6, 4, 0x00, 1),

    // 6. Wait on SB1 (0x02) and exit warp
    (@as(u128, 0x002fe0000f000000) << 64) | 0x000000000000794d,
};
