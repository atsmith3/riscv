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
  # Auto-detect: go up one directory from simulation
  get_filename_component(WORKSPACE "${CMAKE_CURRENT_SOURCE_DIR}/.." ABSOLUTE)
  message(STATUS "WORKSPACE not set, auto-detected: ${WORKSPACE}")
endif()

set(RTL_ROOT ${WORKSPACE}/rtl)

#=============================================================================
# GLS Configuration
#=============================================================================
set(SYNTHESIS_ROOT ${WORKSPACE}/synthesis)
set(GLS_NETLIST ${SYNTHESIS_ROOT}/build/output/core_top_gf180.v)
set(GF180_MODELS_LIST ${SYNTHESIS_ROOT}/scripts/gf180mcu_fd_sc_mcu9t5v0_verilator.filelist)

# Function to load GF180 model files
function(load_gf180_models OUTPUT_VAR)
  if(NOT EXISTS ${GF180_MODELS_LIST})
    message(FATAL_ERROR "GF180 filelist not found: ${GF180_MODELS_LIST}")
  endif()

  # Read model paths (UDPs + functional models)
  # Filelist already contains UDPs at top, then all .functional.v files
  file(STRINGS ${GF180_MODELS_LIST} MODEL_FILES)

  set(${OUTPUT_VAR} ${MODEL_FILES} PARENT_SCOPE)
endfunction()

# RTL sources for core_top
set(RTL_SRC
  ${RTL_ROOT}/core_top.sv
  ${RTL_ROOT}/program_register.sv
  ${RTL_ROOT}/dff_init.sv
  ${RTL_ROOT}/regfile.sv
  ${RTL_ROOT}/mux4.sv
  ${RTL_ROOT}/control.sv
  ${RTL_ROOT}/alu/alu.sv
  ${RTL_ROOT}/control/imm_gen.sv
  ${RTL_ROOT}/control/decoder.sv
)

#=============================================================================
# RTL Verilated Library
#=============================================================================
message(STATUS "========================================")
message(STATUS "  Creating RTL verilated library")
message(STATUS "========================================")

add_library(verilated_rtl STATIC
  memory_model.cpp
  test_utils.cpp
  test_runner.cpp
)

verilate(verilated_rtl COVERAGE TRACE
  PREFIX Vcore_top
  INCLUDE_DIRS ${RTL_ROOT}
  VERILATOR_ARGS -f ./input.vc -O0 -x-assign 0
  SOURCES ${RTL_SRC}
)

target_include_directories(verilated_rtl PUBLIC
  ${CMAKE_CURRENT_SOURCE_DIR}/include
  ${Boost_INCLUDE_DIRS}
)

#=============================================================================
# GLS Verilated Library
#=============================================================================
if(EXISTS ${GLS_NETLIST})
  message(STATUS "========================================")
  message(STATUS "  Creating GLS verilated library")
  message(STATUS "========================================")
  message(STATUS "Netlist: ${GLS_NETLIST}")

  load_gf180_models(GF180_MODEL_FILES)
  set(GLS_SOURCES ${GLS_NETLIST} ${GF180_MODEL_FILES})

  add_library(verilated_gls STATIC
    memory_model.cpp
    test_utils.cpp
    test_runner.cpp
  )

  verilate(verilated_gls COVERAGE TRACE
    PREFIX Vcore_top
    INCLUDE_DIRS ${RTL_ROOT}
    VERILATOR_ARGS -O0 -x-assign 0 -Wno-UNOPTFLAT -Wno-IMPLICIT -Wno-MULTITOP -Wno-PINMISSING -error-limit 0
    SOURCES ${GLS_SOURCES}
  )

  target_include_directories(verilated_gls PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${Boost_INCLUDE_DIRS}
  )
else()
  message(STATUS "========================================")
  message(STATUS "  GLS netlist not found - skipping")
  message(STATUS "========================================")
  message(STATUS "Run: cd ${SYNTHESIS_ROOT} && make pdk-map")
endif()

#=============================================================================
# Pre-Techmap Synth Verilated Library
#=============================================================================
set(SYNTH_NETLIST ${SYNTHESIS_ROOT}/build/output/core_top_synth.v)
if(EXISTS ${SYNTH_NETLIST})
  message(STATUS "========================================")
  message(STATUS "  Creating Synth verilated library")
  message(STATUS "========================================")
  message(STATUS "Netlist: ${SYNTH_NETLIST}")

  add_library(verilated_synth STATIC
    memory_model.cpp
    test_utils.cpp
    test_runner.cpp
  )

  verilate(verilated_synth COVERAGE TRACE
    PREFIX Vcore_top
    INCLUDE_DIRS ${RTL_ROOT}
    VERILATOR_ARGS -O0 -x-assign 0 -Wno-UNOPTFLAT -Wno-IMPLICIT -error-limit 0
    SOURCES ${SYNTH_NETLIST}
  )

  target_include_directories(verilated_synth PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${Boost_INCLUDE_DIRS}
  )
else()
  message(STATUS "========================================")
  message(STATUS "  Pre-techmap synth netlist not found")
  message(STATUS "========================================")
  message(STATUS "Run: cd ${SYNTHESIS_ROOT} && make synth")
endif()

#=============================================================================
# RTL System Tests Executable
#=============================================================================
add_executable(riscv_tests_rtl
  tests/test_main.cpp
  tests/system_tests.cpp
  tests/csr_system_tests.cpp
)

target_link_libraries(riscv_tests_rtl
  verilated_rtl
  ${Boost_LIBRARIES}
)

#=============================================================================
# Synth System Tests Executable (if netlist exists)
#=============================================================================
if(TARGET verilated_synth)
  add_executable(riscv_tests_synth
    tests/test_main.cpp
    tests/system_tests.cpp
    tests/csr_system_tests.cpp
  )

  target_link_libraries(riscv_tests_synth
    verilated_synth
    ${Boost_LIBRARIES}
  )
endif()

#=============================================================================
# GLS System Tests Executable (if netlist exists)
#=============================================================================
if(TARGET verilated_gls)
  add_executable(riscv_tests_gls
    tests/test_main.cpp
    tests/system_tests.cpp
    tests/csr_system_tests.cpp
  )

  target_link_libraries(riscv_tests_gls
    verilated_gls
    ${Boost_LIBRARIES}
  )
endif()

#=============================================================================
# Status messages for created executables
#=============================================================================
message(STATUS "Created test executables:")
message(STATUS "  - riscv_tests_rtl (RTL simulation)")
if(TARGET verilated_synth)
  message(STATUS "  - riscv_tests_synth (Synth simulation)")
else()
  message(STATUS "  - riscv_tests_synth (skipped - no netlist)")
endif()
if(TARGET verilated_gls)
  message(STATUS "  - riscv_tests_gls (GLS simulation)")
else()
  message(STATUS "  - riscv_tests_gls (skipped - no netlist)")
endif()

# Backward compatibility: 'riscv_tests' points to RTL version
add_custom_target(riscv_tests DEPENDS riscv_tests_rtl)

# Enable CTest integration
enable_testing()
add_test(NAME SystemTests_RTL COMMAND riscv_tests_rtl)
if(TARGET riscv_tests_synth)
  add_test(NAME SystemTests_Synth COMMAND riscv_tests_synth)
endif()
if(TARGET riscv_tests_gls)
  add_test(NAME SystemTests_GLS COMMAND riscv_tests_gls)
endif()

# Module-level tests for ALU
add_library(verilated_alu STATIC)
verilate(verilated_alu COVERAGE TRACE
  PREFIX Valu
  INCLUDE_DIRS ${RTL_ROOT}
  VERILATOR_ARGS -O0
  SOURCES ${RTL_ROOT}/alu/alu.sv
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

# Module-level tests for CSR File
add_library(verilated_csr_file STATIC)
verilate(verilated_csr_file COVERAGE TRACE
  PREFIX Vcsr_file
  INCLUDE_DIRS ${RTL_ROOT}
  VERILATOR_ARGS -O0
  SOURCES ${RTL_ROOT}/csr_file.sv
)

# Module-level tests for CSR ALU
add_library(verilated_csr_alu STATIC)
verilate(verilated_csr_alu COVERAGE TRACE
  PREFIX Vcsr_alu
  INCLUDE_DIRS ${RTL_ROOT}
  VERILATOR_ARGS -O0
  SOURCES ${RTL_ROOT}/csr_alu.sv
)

add_executable(module_tests
  tests/test_main.cpp
  tests/module/alu_test.cpp
  tests/module/decoder_test.cpp
  tests/module/imm_gen_test.cpp
  tests/module/byte_lane_test.cpp
  tests/module/csr_file_test.cpp
  tests/module/csr_alu_test.cpp
)

target_link_libraries(module_tests
  verilated_alu
  verilated_decoder
  verilated_imm_gen
  verilated_byte_lane
  verilated_csr_file
  verilated_csr_alu
  ${Boost_LIBRARIES}
)

# Add module tests to CTest
add_test(NAME module_tests COMMAND module_tests)
#add_test(NAME module_tests_verbose COMMAND module_tests --log_level=all)
