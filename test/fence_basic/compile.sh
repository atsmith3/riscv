#!/bin/bash

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tmemory_map.ld -o fence_basic.elf fence_basic.s
if [ $? -ne 0 ]; then
  exit -1
fi

if [ -e fence_basic.dump ]; then
  rm -f fence_basic.dump
fi
riscv64-unknown-elf-objdump -d fence_basic.elf > fence_basic.dump

# Format for init file in icarus Verilog
hexdump -v -e '/1 "%02X "' fence_basic.elf > fence_basic.ini
