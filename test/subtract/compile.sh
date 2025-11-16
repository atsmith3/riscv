#!/bin/bash

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tmemory_map.ld -o subtract.elf entry.s subtract.c
if [ $? -ne 0 ]; then
  exit -1
fi

#riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tmemory_map.ld -o subtract.s subtract.c entry.s -S

if [ -e subtract.dump ]; then
  rm -f subtract.dump
fi
riscv64-unknown-elf-objdump -d subtract.elf > subtract.dump

# Format for init file in icarus Verilog
hexdump -v -e '/1 "%02X "' subtract.elf > subtract.ini
