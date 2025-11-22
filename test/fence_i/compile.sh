#!/bin/bash

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tmemory_map.ld -o fence_i.elf fence_i.s
if [ $? -ne 0 ]; then
  exit -1
fi

if [ -e fence_i.dump ]; then
  rm -f fence_i.dump
fi
riscv64-unknown-elf-objdump -d fence_i.elf > fence_i.dump

# Format for init file in icarus Verilog
hexdump -v -e '/1 "%02X "' fence_i.elf > fence_i.ini
