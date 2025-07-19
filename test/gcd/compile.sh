#!/bin/bash

DOCKER_IMAGE="ubuntu:riscv_compile"
DOCKER_LAUNCHER="docker run --rm -it --user $(id -u):$(id -g) -v $PWD:/workspace:z $DOCKER_IMAGE"

mkdir build

$DOCKER_LAUNCHER \
  riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tld/memory_map.ld -o build/gcd.elf ld/entry.s src/gcd.c

$DOCKER_LAUNCHER \
  riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -Tld/memory_map.ld -o build/gcd.s src/gcd.c -S

if [ -e build/gcd.dump ]; then
  rm -f build/gcd.dump
fi

$DOCKER_LAUNCHER \
  riscv64-unknown-elf-objdump -d build/gcd.elf > build/gcd.dump

# Format for init file in icarus Verilog
hexdump -v -e '/1 "%02X "' build/gcd.elf > gcd.ini

../pad.py gcd.ini 16

gcc -DLOCAL_COMPILE src/gcd.c -o build/gcd_debug
