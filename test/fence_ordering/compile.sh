#!/bin/bash

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tmemory_map.ld -o fence_ordering.elf fence_ordering.s
if [ $? -ne 0 ]; then
  exit -1
fi

if [ -e fence_ordering.dump ]; then
  rm -f fence_ordering.dump
fi
riscv64-unknown-elf-objdump -d fence_ordering.elf > fence_ordering.dump

# Format for init file in icarus Verilog
hexdump -v -e '/1 "%02X "' fence_ordering.elf > fence_ordering.ini
