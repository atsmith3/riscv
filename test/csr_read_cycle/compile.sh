#!/bin/bash

riscv64-unknown-elf-gcc -O0 -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding \
  -Tmemory_map.ld -o csr_read_cycle.elf entry.s csr_read_cycle.c

if [ $? -ne 0 ]; then
  exit -1
fi

riscv64-unknown-elf-objdump -d csr_read_cycle.elf > csr_read_cycle.dump
hexdump -v -e '/1 "%02X "' csr_read_cycle.elf > csr_read_cycle.ini
