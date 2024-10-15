#!/bin/bash

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tmemory_map.ld -o add.elf add.s
if [ $? -ne 0 ]; then
  exit -1
fi
#riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tmemory_map.ld -o add.s add.c -S

if [ -e add.dump ]; then
  rm -f add.dump
fi
riscv64-unknown-elf-objdump -d add.elf > add.dump

# Format for init file in icarus Verilog
hexdump -v -e '/1 "%02X "' add.elf > add.ini
