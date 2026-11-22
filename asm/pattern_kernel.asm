; ========================================================================
; SOVEREIGN LEVIATHAN NODE LICENSE
; License-ID: SL-AGPL3-001 | Covenant-Version: 1.0
; SPDX-License-Identifier: LicenseRef-Sovereign-Leviathan-SL-AGPL3-001
; Copyright (C) 2026 SnapKittyWest. Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust.
; ========================================================================
;
; This file is a covered work under the GNU Affero General Public License,
; version 3, together with the Sovereign Leviathan additional terms.
;
; Hark, though this node be but a spark,
; Its covenant endureth through the dark.
;
; Ignorantia juris non excusat.
; ========================================================================

; pattern_kernel.asm — Zero-dependency AVX2 8-lane Pattern Match & Fold Kernel
; Windows x64 ABI:
; RCX = const uint32_t* stream (32-byte aligned token/redex stream)
; RDX = const uint32_t* pattern (32-byte aligned 8-lane target pattern)
; R8 = size_t blocks (number of 8-lane / 32-byte blocks)
; R9 = uint32_t* out_sig (32-byte aligned 8-lane state accumulator)
; Returns:
; RAX = total number of matched 32-bit lanes across all blocks

default rel
section .text
global avx2_pattern_kernel

avx2_pattern_kernel:
    vzeroupper
    xor rax, rax ; RAX = total match count
    test r8, r8
    jz .done

    vmovdqa ymm1, [rdx] ; ymm1 = 8-lane target pattern
    vmovdqa ymm6, [r9] ; ymm6 = running state accumulator
    vmovdqa ymm9, [r9] ; ymm9 = secondary mixing accumulator

.loop:
    vmovdqa ymm0, [rcx] ; Load 8 x uint32_t tokens from stream
    vpcmpeqd ymm2, ymm0, ymm1 ; 0xFFFFFFFF in matching lanes, 0 elsewhere
    vpmovmskb r10d, ymm2 ; Extract 32-bit byte mask (4 bits per lane)
    test r10d, r10d
    jz .advance ; Fast-skip block if 0 lanes matched

    popcnt r11d, r10d ; Count set mask bits
    shr r11d, 2 ; Divide by 4 -> exact matched lane count
    add rax, r11

    ; Isolate matched lane payloads and fold through AVX2 shift-xor-add-mul network
    vpand ymm3, ymm0, ymm2 ; Zero out non-matching lanes
    vpxor ymm1, ymm1, ymm3 ; Perturb pattern state with matched payload

    vpsrld ymm2, ymm1, 8
    vpxor ymm1, ymm1, ymm2
    vpslld ymm3, ymm1, 14
    vpxor ymm1, ymm1, ymm3
    vpsrld ymm4, ymm1, 3
    vpxor ymm1, ymm1, ymm4
    vpslld ymm5, ymm1, 11
    vpxor ymm1, ymm1, ymm5

    vpaddd ymm6, ymm6, ymm1
    vpmulld ymm7, ymm6, ymm1
    vpxor ymm8, ymm7, ymm6
    vpaddd ymm9, ymm9, ymm8

    vpsrld ymm10, ymm9, 9
    vpxor ymm9, ymm9, ymm10
    vpslld ymm11, ymm9, 5
    vpxor ymm9, ymm9, ymm11
    vpsrld ymm12, ymm9, 13
    vpxor ymm9, ymm9, ymm12
    vpslld ymm13, ymm9, 7
    vpxor ymm9, ymm9, ymm13

    vpaddd ymm14, ymm14, ymm9
    vpmulld ymm15, ymm14, ymm9
    vpxor ymm0, ymm15, ymm14
    vpaddd ymm1, ymm1, ymm0 ; Updated state feeds next block

.advance:
    add rcx, 32
    dec r8
    jnz .loop

    vmovdqa [r9], ymm1 ; Write back 256-bit cryptographic/state signature

.done:
    vzeroupper
    ret
