#!/bin/bash

riscv64-unknown-elf-gcc -O0 -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding \
  -Tmemory_map.ld -o memcpy.elf entry.s memcpy.c

if [ $? -ne 0 ]; then
  exit -1
fi

riscv64-unknown-elf-objdump -d memcpy.elf > memcpy.dump
hexdump -v -e '/1 "%02X "' memcpy.elf > memcpy.ini
