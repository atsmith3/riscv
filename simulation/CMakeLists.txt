######################################################################
#
# DESCRIPTION: RISC-V Core Verification CMake Configuration
#
# Builds Verilator testbench with Boost.Test integration for
# automated system-level and module-level testing.
#
######################################################################

cmake_minimum_required(VERSION 3.8)
project(riscv_verification)

# Find required packages
find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

find_package(Boost 1.65 REQUIRED COMPONENTS unit_test_framework)
if (NOT Boost_FOUND)
  message(FATAL_ERROR "Boost.Test was not found. Install with: sudo apt-get install libboost-test-dev")
endif()

# Set WORKSPACE - either from environment or auto-detect
if(DEFINED ENV{WORKSPACE})
  set(WORKSPACE "$ENV{WORKSPACE}")
else()
  # Auto-detect: go up two directories from simulation/verilator
  get_filename_component(WORKSPACE "${CMAKE_CURRENT_SOURCE_DIR}/../.." ABSOLUTE)
  message(STATUS "WORKSPACE not set, auto-detected: ${WORKSPACE}")
endif()

set(RTL_ROOT ${WORKSPACE}/rtl)

# RTL sources for core_top
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

# Verilated core library - contains verilated RTL + test infrastructure
add_library(verilated_core STATIC
  memory_model.cpp
  test_utils.cpp
  test_runner.cpp
)

# Verilate the RTL into the library
verilate(verilated_core COVERAGE TRACE
  PREFIX Vcore_top
  INCLUDE_DIRS ${RTL_ROOT}
  VERILATOR_ARGS -f ./input.vc -O0 -x-assign 0
  SOURCES ${RTL_SRC}
)

target_include_directories(verilated_core PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  ${Boost_INCLUDE_DIRS}
)

# Test executable with Boost.Test
add_executable(riscv_tests
  tests/test_main.cpp
  tests/system_tests.cpp
)

target_link_libraries(riscv_tests
  verilated_core
  ${Boost_LIBRARIES}
)

# Enable CTest integration
enable_testing()
add_test(NAME system_tests COMMAND riscv_tests)
#add_test(NAME system_tests_verbose COMMAND riscv_tests --log_level=all)

# Module-level tests for ALU
add_library(verilated_alu STATIC)
verilate(verilated_alu COVERAGE TRACE
  PREFIX Valu
  INCLUDE_DIRS ${RTL_ROOT}
  VERILATOR_ARGS -O0
  SOURCES ${RTL_ROOT}/alu/alu.sv
)

# Module-level tests for Branch Evaluator
add_library(verilated_branch_eval STATIC)
verilate(verilated_branch_eval COVERAGE TRACE
  PREFIX Vbranch_eval
  INCLUDE_DIRS ${RTL_ROOT}
  VERILATOR_ARGS -O0
  SOURCES ${RTL_ROOT}/control/branch_eval.sv ${RTL_ROOT}/datatypes.sv
)

# Module-level tests for Instruction Decoder
add_library(verilated_decoder STATIC)
verilate(verilated_decoder COVERAGE TRACE
  PREFIX Vir_decoder
  INCLUDE_DIRS ${RTL_ROOT}
  VERILATOR_ARGS -O0
  SOURCES ${RTL_ROOT}/control/decoder.sv ${RTL_ROOT}/control/imm_gen.sv ${RTL_ROOT}/datatypes.sv
)

# Module-level tests for Immediate Generator
add_library(verilated_imm_gen STATIC)
verilate(verilated_imm_gen COVERAGE TRACE
  PREFIX Vimm_gen_32
  INCLUDE_DIRS ${RTL_ROOT}
  VERILATOR_ARGS -O0
  SOURCES ${RTL_ROOT}/control/imm_gen.sv ${RTL_ROOT}/datatypes.sv
)

# Module-level tests for Byte Lane
add_library(verilated_byte_lane STATIC)
verilate(verilated_byte_lane COVERAGE TRACE
  PREFIX Vbyte_lane
  INCLUDE_DIRS ${RTL_ROOT}
  VERILATOR_ARGS -O0
  SOURCES ${RTL_ROOT}/byte_lane.sv ${RTL_ROOT}/datatypes.sv
)

add_executable(module_tests
  tests/test_main.cpp
  tests/module/alu_test.cpp
  tests/module/branch_eval_test.cpp
  tests/module/decoder_test.cpp
  tests/module/imm_gen_test.cpp
  tests/module/byte_lane_test.cpp
)

target_link_libraries(module_tests
  verilated_alu
  verilated_branch_eval
  verilated_decoder
  verilated_imm_gen
  verilated_byte_lane
  ${Boost_LIBRARIES}
)

# Add module tests to CTest
add_test(NAME module_tests COMMAND module_tests)
#add_test(NAME module_tests_verbose COMMAND module_tests --log_level=all)
