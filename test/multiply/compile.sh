#!/bin/bash

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding \
  -Tmemory_map.ld -o multiply.elf entry.s multiply.c

if [ $? -ne 0 ]; then
  exit -1
fi

riscv64-unknown-elf-objdump -d multiply.elf > multiply.dump
hexdump -v -e '/1 "%02X "' multiply.elf > multiply.ini
