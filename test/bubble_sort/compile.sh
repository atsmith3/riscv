#!/bin/bash

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding \
  -Tmemory_map.ld -o bubble_sort.elf entry.s bubble_sort.c

if [ $? -ne 0 ]; then
  exit -1
fi

riscv64-unknown-elf-objdump -d bubble_sort.elf > bubble_sort.dump
hexdump -v -e '/1 "%02X "' bubble_sort.elf > bubble_sort.ini
