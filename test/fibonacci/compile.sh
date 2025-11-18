#!/bin/bash

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding \
  -Tmemory_map.ld -o fibonacci.elf entry.s fibonacci.c

if [ $? -ne 0 ]; then
  exit -1
fi

# Generate disassembly
riscv64-unknown-elf-objdump -d fibonacci.elf > fibonacci.dump

# Format for init file in Verilog
hexdump -v -e '/1 "%02X "' fibonacci.elf > fibonacci.ini
