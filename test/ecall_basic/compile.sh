#!/bin/bash

riscv64-unknown-elf-gcc -O0 -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding \
  -Tmemory_map.ld -o ecall_basic.elf entry.s ecall_basic.c

if [ $? -ne 0 ]; then
  exit -1
fi

riscv64-unknown-elf-objdump -d ecall_basic.elf > ecall_basic.dump
hexdump -v -e '/1 "%02X "' ecall_basic.elf > ecall_basic.ini
