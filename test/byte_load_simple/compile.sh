#!/bin/bash

# Use the same memory map as other tests
cp ../memcpy/memory_map.ld . 2>/dev/null || cp ../add/memory_map.ld .
cp ../memcpy/entry.s . 2>/dev/null || cp ../add/entry.s .

riscv64-unknown-elf-gcc -O0 -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding \
  -Tmemory_map.ld -o byte_load_simple.elf entry.s byte_load_simple.c

if [ $? -ne 0 ]; then
  exit -1
fi

riscv64-unknown-elf-objdump -d byte_load_simple.elf > byte_load_simple.dump
hexdump -v -e '/1 "%02X "' byte_load_simple.elf > byte_load_simple.ini
