#!/bin/bash
#
# Uses Icarus to simulate the testbench of the ALU.
#
# 2022-04-03

#if [ -e ./ram_test ]; then
#  rm ./ram_test
#fi
#
#iverilog -g2005-sv \
#  ./ram.sv \
#  -I ../ \
#  -D IVERILOG \
#  -D TESTBENCH \
#  -s tb \
#  -o ram_test
#
#if [ -e ./ram_test ]; then
#  ./ram_test 
#fi

if [ -e ./tb ]; then
  rm ./tb
fi

iverilog -g2005-sv \
  ./ram.sv \
  ../regfile.sv \
  ../alu/alu.sv \
  ../mux4.sv \
  ../datatypes.sv \
  ../control/branch_eval.sv \
  ../control/decoder.sv \
  ../control/imm_gen.sv \
  ../core_top.sv \
  ../register.sv \
  ./testbench.sv \
  ../control.sv \
  -I ../ \
  -D IVERILOG \
  -s tb \
  -o tb

if [ -e ./tb ]; then
  ./tb
fi
