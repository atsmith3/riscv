#!/bin/bash
#
# Uses Icarus to simulate the testbench of the ALU.
#
# 2025-02-08

if [ -z ${WORKSPACE} ]; then
  echo "ERROR: WORKSPACE environment variable is not set"
  exit 1
fi

FILELIST="${WORKSPACE}/rtl/program_register.sv \
  ${WORKSPACE}/rtl/regfile.sv \
  ${WORKSPACE}/rtl/mux4.sv \
  ${WORKSPACE}/rtl/control.sv \
  ${WORKSPACE}/rtl/core_top.sv \
  ${WORKSPACE}/rtl/alu/alu.sv \
  ${WORKSPACE}/rtl/control/imm_gen.sv \
  ${WORKSPACE}/rtl/control/decoder.sv \
  ${WORKSPACE}/rtl/control/branch_eval.sv \
  ${WORKSPACE}/rtl/tb/testbench.sv \
  ${WORKSPACE}/rtl/tb/ram.sv"

INCLUDES="${WORKSPACE}/rtl"

if [ -e ./tb ]; then
  rm ./tb
fi

iverilog -g2005-sv \
  ${FILELIST} \
  -I ${INCLUDES} \
  -D IVERILOG \
  -s tb \
  -o tb

if [ -e ./tb ]; then
  ./tb
fi
