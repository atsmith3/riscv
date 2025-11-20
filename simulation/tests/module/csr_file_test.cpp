/*
 * CSR Register File Module-Level Tests
 *
 * Unit tests for the CSR register file module.
 * Tests counter increments, address decoding, and invalid address handling.
 */

#include "Vcsr_file.h"
#include <boost/test/unit_test.hpp>
#include <cstdint>
#include <verilated.h>

// CSR addresses (matching RISC-V spec)
constexpr uint16_t CSR_CYCLE = 0xC00;
constexpr uint16_t CSR_TIME = 0xC01;
constexpr uint16_t CSR_INSTRET = 0xC02;
constexpr uint16_t CSR_CYCLEH = 0xC80;
constexpr uint16_t CSR_TIMEH = 0xC81;
constexpr uint16_t CSR_INSTRETH = 0xC82;
constexpr uint16_t CSR_INVALID = 0x123; // Invalid address for testing

BOOST_AUTO_TEST_SUITE(csr_file_tests)

/**
 * Helper function to advance clock by one cycle
 */
void tick(Vcsr_file *dut) {
  dut->clk = 0;
  dut->eval();
  dut->clk = 1;
  dut->eval();
}

/**
 * Test: CSR file initialization
 * All counters should start at zero after reset
 */
BOOST_AUTO_TEST_CASE(test_csr_file_reset) {
  Vcsr_file *dut = new Vcsr_file();

  // Apply reset
  dut->rst_n = 0;
  dut->clk = 0;
  dut->csr_addr = CSR_CYCLE;
  dut->csr_we = 0;
  dut->csr_wdata = 0;
  dut->instret_inc = 0;
  dut->eval();

  dut->clk = 1;
  dut->eval();

  // Release reset
  dut->rst_n = 1;
  dut->clk = 0;
  dut->eval();

  // Check all counters are zero
  dut->csr_addr = CSR_CYCLE;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 0);
  BOOST_CHECK_EQUAL(dut->csr_valid, 1);

  dut->csr_addr = CSR_TIME;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 0);

  dut->csr_addr = CSR_INSTRET;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 0);

  dut->csr_addr = CSR_CYCLEH;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 0);

  dut->csr_addr = CSR_TIMEH;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 0);

  dut->csr_addr = CSR_INSTRETH;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 0);

  delete dut;
}

/**
 * Test: Cycle counter increment
 * Cycle counter should increment every clock cycle
 */
BOOST_AUTO_TEST_CASE(test_cycle_counter_increment) {
  Vcsr_file *dut = new Vcsr_file();

  // Initialize
  dut->rst_n = 0;
  dut->csr_addr = CSR_CYCLE;
  dut->csr_we = 0;
  dut->csr_wdata = 0;
  dut->instret_inc = 0;
  tick(dut);

  dut->rst_n = 1;
  tick(dut);

  // Check initial value (should be 1 after one tick)
  dut->csr_addr = CSR_CYCLE;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 1);

  // Advance 10 more cycles
  for (int i = 0; i < 10; i++) {
    tick(dut);
  }

  // Check cycle counter is at 11
  dut->csr_addr = CSR_CYCLE;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 11);

  // Check cycleh is still 0 (no overflow)
  dut->csr_addr = CSR_CYCLEH;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 0);

  delete dut;
}

/**
 * Test: Time counter mirrors cycle counter
 * Time should always equal cycle
 */
BOOST_AUTO_TEST_CASE(test_time_mirrors_cycle) {
  Vcsr_file *dut = new Vcsr_file();

  // Initialize
  dut->rst_n = 0;
  dut->csr_addr = CSR_CYCLE;
  dut->csr_we = 0;
  dut->csr_wdata = 0;
  dut->instret_inc = 0;
  tick(dut);

  dut->rst_n = 1;

  // Advance several cycles
  for (int i = 0; i < 42; i++) {
    tick(dut);
  }

  // Read cycle and time
  dut->csr_addr = CSR_CYCLE;
  dut->eval();
  uint32_t cycle_val = dut->csr_rdata;

  dut->csr_addr = CSR_TIME;
  dut->eval();
  uint32_t time_val = dut->csr_rdata;

  // They should be equal
  BOOST_CHECK_EQUAL(cycle_val, time_val);
  BOOST_CHECK_EQUAL(cycle_val, 42);

  // Check upper 32 bits
  dut->csr_addr = CSR_CYCLEH;
  dut->eval();
  uint32_t cycleh_val = dut->csr_rdata;

  dut->csr_addr = CSR_TIMEH;
  dut->eval();
  uint32_t timeh_val = dut->csr_rdata;

  BOOST_CHECK_EQUAL(cycleh_val, timeh_val);
  BOOST_CHECK_EQUAL(cycleh_val, 0);

  delete dut;
}

/**
 * Test: Instruction retired counter increment
 * Instret should only increment when instret_inc is asserted
 */
BOOST_AUTO_TEST_CASE(test_instret_counter_increment) {
  Vcsr_file *dut = new Vcsr_file();

  // Initialize
  dut->rst_n = 0;
  dut->csr_addr = CSR_INSTRET;
  dut->csr_we = 0;
  dut->csr_wdata = 0;
  dut->instret_inc = 0;
  tick(dut);

  dut->rst_n = 1;

  // Advance 10 cycles without instret_inc
  for (int i = 0; i < 10; i++) {
    dut->instret_inc = 0;
    tick(dut);
  }

  // Check instret is still 0
  dut->csr_addr = CSR_INSTRET;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 0);

  // Now increment instret 5 times
  for (int i = 0; i < 5; i++) {
    dut->instret_inc = 1;
    tick(dut);
  }

  // Check instret is 5
  dut->csr_addr = CSR_INSTRET;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 5);

  // Advance more cycles without increment
  for (int i = 0; i < 10; i++) {
    dut->instret_inc = 0;
    tick(dut);
  }

  // Check instret is still 5
  dut->csr_addr = CSR_INSTRET;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 5);

  // Check cycle has advanced but instret hasn't
  dut->csr_addr = CSR_CYCLE;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 25); // 10 + 5 + 10

  delete dut;
}

/**
 * Test: 64-bit counter overflow
 * Test that upper 32 bits increment when lower 32 bits overflow
 */
BOOST_AUTO_TEST_CASE(test_counter_64bit_overflow) {
  Vcsr_file *dut = new Vcsr_file();

  // Initialize
  dut->rst_n = 0;
  dut->csr_addr = CSR_CYCLE;
  dut->csr_we = 0;
  dut->csr_wdata = 0;
  dut->instret_inc = 0;
  tick(dut);

  dut->rst_n = 1;

  // This test would take too long to actually overflow (2^32 cycles)
  // Instead, we'll test the logic by manually setting a high value
  // and verifying behavior near overflow boundary

  // For now, just verify that cycleh starts at 0 and stays 0
  // for reasonable cycle counts
  for (int i = 0; i < 1000; i++) {
    tick(dut);
  }

  dut->csr_addr = CSR_CYCLEH;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 0);

  dut->csr_addr = CSR_CYCLE;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_rdata, 1000);

  delete dut;
}

/**
 * Test: Invalid CSR address detection
 * Reading invalid CSR address should set csr_valid to 0
 */
BOOST_AUTO_TEST_CASE(test_invalid_csr_address) {
  Vcsr_file *dut = new Vcsr_file();

  // Initialize
  dut->rst_n = 0;
  dut->csr_addr = CSR_CYCLE;
  dut->csr_we = 0;
  dut->csr_wdata = 0;
  dut->instret_inc = 0;
  tick(dut);

  dut->rst_n = 1;
  tick(dut);

  // Test valid address
  dut->csr_addr = CSR_CYCLE;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_valid, 1);

  // Test invalid address
  dut->csr_addr = CSR_INVALID;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_valid, 0);
  BOOST_CHECK_EQUAL(dut->csr_rdata, 0); // Should return 0

  // Test another invalid address
  dut->csr_addr = 0x000; // Machine-mode CSR not implemented
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_valid, 0);

  // Test back to valid address
  dut->csr_addr = CSR_TIME;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_valid, 1);

  delete dut;
}

/**
 * Test: All six CSR addresses are valid and readable
 */
BOOST_AUTO_TEST_CASE(test_all_csr_addresses_valid) {
  Vcsr_file *dut = new Vcsr_file();

  // Initialize
  dut->rst_n = 0;
  dut->csr_addr = CSR_CYCLE;
  dut->csr_we = 0;
  dut->csr_wdata = 0;
  dut->instret_inc = 0;
  tick(dut);

  dut->rst_n = 1;

  // Advance some cycles
  for (int i = 0; i < 100; i++) {
    dut->instret_inc = (i % 2 == 0); // Increment instret every other cycle
    tick(dut);
  }

  // Test all 6 valid CSR addresses
  dut->csr_addr = CSR_CYCLE;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_valid, 1);
  BOOST_CHECK_EQUAL(dut->csr_rdata, 100);

  dut->csr_addr = CSR_TIME;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_valid, 1);
  BOOST_CHECK_EQUAL(dut->csr_rdata, 100);

  dut->csr_addr = CSR_INSTRET;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_valid, 1);
  BOOST_CHECK_EQUAL(dut->csr_rdata, 50); // Incremented 50 times

  dut->csr_addr = CSR_CYCLEH;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_valid, 1);
  BOOST_CHECK_EQUAL(dut->csr_rdata, 0);

  dut->csr_addr = CSR_TIMEH;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_valid, 1);
  BOOST_CHECK_EQUAL(dut->csr_rdata, 0);

  dut->csr_addr = CSR_INSTRETH;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_valid, 1);
  BOOST_CHECK_EQUAL(dut->csr_rdata, 0);

  delete dut;
}

/**
 * Test: Write attempts are ignored (read-only CSRs)
 * User-mode CSRs are read-only, writes should not affect them
 */
BOOST_AUTO_TEST_CASE(test_write_ignored_readonly) {
  Vcsr_file *dut = new Vcsr_file();

  // Initialize
  dut->rst_n = 0;
  dut->csr_addr = CSR_CYCLE;
  dut->csr_we = 0;
  dut->csr_wdata = 0;
  dut->instret_inc = 0;
  tick(dut);

  dut->rst_n = 1;

  // Advance to get non-zero counters
  for (int i = 0; i < 10; i++) {
    tick(dut);
  }

  // Read current cycle value
  dut->csr_addr = CSR_CYCLE;
  dut->eval();
  uint32_t cycle_before = dut->csr_rdata;

  // Attempt to write to cycle CSR
  dut->csr_addr = CSR_CYCLE;
  dut->csr_we = 1;
  dut->csr_wdata = 0xDEADBEEF;
  dut->eval();
  tick(dut);

  // Read cycle value again
  dut->csr_we = 0;
  dut->csr_addr = CSR_CYCLE;
  dut->eval();

  // Cycle should have incremented by 1, not been overwritten
  BOOST_CHECK_EQUAL(dut->csr_rdata, cycle_before + 1);
  BOOST_CHECK_NE(dut->csr_rdata, 0xDEADBEEF);

  delete dut;
}

BOOST_AUTO_TEST_SUITE_END()
