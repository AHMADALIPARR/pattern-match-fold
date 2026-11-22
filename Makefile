# Simple Makefile for the AVX2 Pattern Match & Fold kernel
# Requires NASM and a GCC that supports AVX2 (MinGW-w64 recommended on Windows)

NASM ?= nasm
CC   ?= gcc

.PHONY: all clean

all: pattern_kernel.exe

pattern_kernel.obj: asm/pattern_kernel.asm
	$(NASM) -f win64 $< -o $@

pattern_kernel.exe: host/pattern_host.c pattern_kernel.obj
	$(CC) -O3 -mavx2 -mpopcnt -std=c11 $^ -o $@

clean:
	rm -f pattern_kernel.obj pattern_kernel.exe

# Note: for Linux ELF, change -f win64 to -f elf64 and adjust the ABI in the .asm if needed.
