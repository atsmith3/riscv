#!/bin/bash
#
# Uses Icarus to simulate the testbench of the ALU.
#
# 2022-04-03

if [ -e ./alu_test ]; then
  rm ./alu_test
fi

iverilog -g2005-sv \
  ./alu.sv \
  ./alu_tb.sv \
  -I ../ \
  -D IVERILOG \
  -s tb \
  -o alu_test

if [ -e ./alu_test ]; then
  ./alu_test
fi
