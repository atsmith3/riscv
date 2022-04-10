#!/bin/bash
#
# Uses Icarus to simulate the testbench of the ALU.
#
# 2022-04-10

if [ -e ./branch_eval_test ]; then
  rm ./branch_eval_test
fi

iverilog -g2005-sv \
  ./branch_eval.sv \
  ./branch_eval_tb.sv \
  -I ../ \
  -D IVERILOG \
  -s tb \
  -o branch_eval_test

if [ -e ./branch_eval_test ]; then
  ./branch_eval_test
fi
