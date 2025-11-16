#!/bin/bash

riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding \
  -Tmemory_map.ld -o factorial.elf entry.s factorial.c

if [ $? -ne 0 ]; then
  exit -1
fi

riscv64-unknown-elf-objdump -d factorial.elf > factorial.dump
hexdump -v -e '/1 "%02X "' factorial.elf > factorial.ini
