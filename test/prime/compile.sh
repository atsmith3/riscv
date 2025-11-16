#!/bin/bash

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding \
  -Tmemory_map.ld -o prime.elf entry.s prime.c

if [ $? -ne 0 ]; then
  exit -1
fi

riscv64-unknown-elf-objdump -d prime.elf > prime.dump
hexdump -v -e '/1 "%02X "' prime.elf > prime.ini
