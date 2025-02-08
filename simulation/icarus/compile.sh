#!/bin/bash

iverilog -g2005-sv \
  ../../rtl/program_register.sv \
  ../../rtl/regfile.sv \
  ../../rtl/mux4.sv \
  ../../rtl/control.sv \
  ../../rtl/core_top.sv \
  ../../rtl/alu/alu.sv \
  ../../rtl/control/imm_gen.sv \
  ../../rtl/control/decoder.sv \
  ../../rtl/control/branch_eval.sv \
  ./core_top_tb.sv \
  -I ../../rtl \
  -D IVERILOG \
  -s tb \
  -o core_top_test

