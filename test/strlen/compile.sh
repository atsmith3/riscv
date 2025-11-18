#!/bin/bash

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding \
  -Tmemory_map.ld -o strlen.elf entry.s strlen.c

if [ $? -ne 0 ]; then
  exit -1
fi

riscv64-unknown-elf-objdump -d strlen.elf > strlen.dump
hexdump -v -e '/1 "%02X "' strlen.elf > strlen.ini
