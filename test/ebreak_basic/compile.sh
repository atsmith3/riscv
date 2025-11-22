#!/bin/bash

riscv64-unknown-elf-gcc -O0 -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding \
  -Tmemory_map.ld -o ebreak_basic.elf entry.s ebreak_basic.c

if [ $? -ne 0 ]; then
  exit -1
fi

riscv64-unknown-elf-objdump -d ebreak_basic.elf > ebreak_basic.dump
hexdump -v -e '/1 "%02X "' ebreak_basic.elf > ebreak_basic.ini
