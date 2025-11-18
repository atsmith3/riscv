#!/bin/bash

mkdir -p build

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tld/memory_map.ld -o build/gcd.elf ld/entry.s src/gcd.c
if [ $? -ne 0 ]; then
  exit -1
fi

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tld/memory_map.ld -o build/gcd.s src/gcd.c -S

if [ -e build/gcd.dump ]; then
  rm -f build/gcd.dump
fi

riscv64-unknown-elf-objdump -d build/gcd.elf > build/gcd.dump

# Format for init file in icarus Verilog
hexdump -v -e '/1 "%02X "' build/gcd.elf > gcd.ini
