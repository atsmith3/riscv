#!/bin/bash

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding \
  -Tmemory_map.ld -o bitops.elf entry.s bitops.c

if [ $? -ne 0 ]; then
  exit -1
fi

riscv64-unknown-elf-objdump -d bitops.elf > bitops.dump
hexdump -v -e '/1 "%02X "' bitops.elf > bitops.ini
