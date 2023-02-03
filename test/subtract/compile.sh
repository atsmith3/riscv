#!/bin/bash

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tmemory_map.ld -o subtract.elf entry.s subtract.c
#riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tmemory_map.ld -o subtract.s subtract.c entry.s -S

if [ -e subtract.dump ]; then
  rm -f subtract.dump
fi
riscv64-unknown-elf-objdump -d subtract.elf > subtract.dump

# Format for init file in icarus Verilog
hexdump -v -e '/1 "%02X "' subtract.elf > subtract.ini

../pad.py subtract.ini 16
