#!/bin/bash

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tmemory_map.ld -o gcd.elf entry.s gcd.c
#riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tmemory_map.ld -o gcd.s gcd.c entry.s -S

if [ -e gcd.dump ]; then
  rm -f gcd.dump
fi
riscv64-unknown-elf-objdump -d gcd.elf > gcd.dump

# Format for init file in icarus Verilog
hexdump -v -e '/1 "%02X "' gcd.elf > gcd.ini

../pad.py gcd.ini 16

gcc -DLOCAL_COMPILE gcd.c -o gcd_debug
