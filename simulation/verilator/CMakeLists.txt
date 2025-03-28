######################################################################
#
# DESCRIPTION: Verilator CMake Register File Test
#
# This is an example cmake script to build a verilog to systemc project
# using cmake and verilator.
#
# This file ONLY is placed under the Creative Commons Public Domain, for
# any use, without warranty, 2020 by Wilson Snyder.
# SPDX-License-Identifier: CC0-1.0
#
######################################################################

# This example builds the make_tracing_c example using CMake
# To use it, run the following:

# cd /path/to/verilator/examples/cmake_tracing_c
# rm -rf build && mkdir build && cd build
# cmake ..
# cmake --build .

cmake_minimum_required(VERSION 3.8)
project(riscv_cpu)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

# Create a new executable target that will contain all your sources
add_executable(riscv ./sim_main.cpp)

set(WORKSPACE "$ENV{WORKSPACE}")
set(RTL_ROOT ${WORKSPACE}/rtl)

set(RTL_SRC 
  ${RTL_ROOT}/core_top.sv
  ${RTL_ROOT}/program_register.sv
  ${RTL_ROOT}/regfile.sv
  ${RTL_ROOT}/mux4.sv
  ${RTL_ROOT}/control.sv
  ${RTL_ROOT}/alu/alu.sv
  ${RTL_ROOT}/control/imm_gen.sv
  ${RTL_ROOT}/control/decoder.sv
)

# Add the Verilated circuit to the target
verilate(riscv COVERAGE TRACE
  VERILATOR_ARGS -f ./input.vc -O0 -x-assign 0
  SOURCES ${RTL_SRC})
