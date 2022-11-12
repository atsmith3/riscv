#!/bin/bash
#
# Uses Icarus to simulate the testbench of the ALU.
#
# 2022-04-03

if [ -e ./ram_test ]; then
  rm ./ram_test
fi

iverilog -g2005-sv \
  ./ram.sv \
  -I ../ \
  -D IVERILOG \
  -D TESTBENCH \
  -s tb \
  -o ram_test

if [ -e ./ram_test ]; then
  ./ram_test 
fi
