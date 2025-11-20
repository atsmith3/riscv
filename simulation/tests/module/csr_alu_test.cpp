/*
 * CSR ALU Module-Level Tests
 *
 * Unit tests for the CSR ALU module.
 * Tests all 6 CSR operations (CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI)
 * and write suppression logic.
 */

#include "Vcsr_alu.h"
#include <boost/test/unit_test.hpp>
#include <cstdint>
#include <verilated.h>

// CSR operation encodings (funct3 values)
constexpr uint8_t CSR_RW = 0b001;  // CSRRW
constexpr uint8_t CSR_RS = 0b010;  // CSRRS
constexpr uint8_t CSR_RC = 0b011;  // CSRRC
constexpr uint8_t CSR_RWI = 0b101; // CSRRWI
constexpr uint8_t CSR_RSI = 0b110; // CSRRSI
constexpr uint8_t CSR_RCI = 0b111; // CSRRCI

BOOST_AUTO_TEST_SUITE(csr_alu_tests)

/**
 * Test: CSRRW operation (atomic read/write)
 * Should pass through rs1 value, always write
 */
BOOST_AUTO_TEST_CASE(test_csrrw_operation) {
  Vcsr_alu *dut = new Vcsr_alu();

  dut->csr_rdata = 0x12345678;
  dut->rs1_or_zimm = 0xABCDEF00;
  dut->funct3 = CSR_RW;
  dut->rs1_is_zero = 0;
  dut->eval();

  // Should write rs1 value
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0xABCDEF00);
  BOOST_CHECK_EQUAL(dut->csr_we, 1);

  // Test with rs1=x0 (CSRRW never suppresses writes)
  dut->rs1_is_zero = 1;
  dut->rs1_or_zimm = 0x00000000;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0x00000000);
  BOOST_CHECK_EQUAL(dut->csr_we, 1); // Still writes even if rs1=x0

  delete dut;
}

/**
 * Test: CSRRWI operation (atomic read/write immediate)
 * Should pass through zimm value, always write
 */
BOOST_AUTO_TEST_CASE(test_csrrwi_operation) {
  Vcsr_alu *dut = new Vcsr_alu();

  dut->csr_rdata = 0xFFFFFFFF;
  dut->rs1_or_zimm = 0x0000001F; // zimm = 31 (5-bit max)
  dut->funct3 = CSR_RWI;
  dut->rs1_is_zero = 0;
  dut->eval();

  // Should write zimm value
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0x0000001F);
  BOOST_CHECK_EQUAL(dut->csr_we, 1);

  // Test with zimm=0 (still writes)
  dut->rs1_or_zimm = 0x00000000;
  dut->rs1_is_zero = 1;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0x00000000);
  BOOST_CHECK_EQUAL(dut->csr_we, 1); // Still writes even if zimm=0

  delete dut;
}

/**
 * Test: CSRRS operation (atomic read and set bits)
 * Should perform bitwise OR, suppress write if rs1=x0
 */
BOOST_AUTO_TEST_CASE(test_csrrs_operation) {
  Vcsr_alu *dut = new Vcsr_alu();

  dut->csr_rdata = 0x0F0F0F0F;
  dut->rs1_or_zimm = 0xF0F0F0F0;
  dut->funct3 = CSR_RS;
  dut->rs1_is_zero = 0;
  dut->eval();

  // Should OR the values
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0xFFFFFFFF);
  BOOST_CHECK_EQUAL(dut->csr_we, 1);

  // Test with rs1=x0 (write suppressed)
  dut->rs1_or_zimm = 0x00000000;
  dut->rs1_is_zero = 1;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0x0F0F0F0F); // OR with 0 = no change
  BOOST_CHECK_EQUAL(dut->csr_we, 0);             // Write suppressed

  // Test setting specific bits
  dut->csr_rdata = 0x00000001;
  dut->rs1_or_zimm = 0x00000002;
  dut->rs1_is_zero = 0;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0x00000003);
  BOOST_CHECK_EQUAL(dut->csr_we, 1);

  delete dut;
}

/**
 * Test: CSRRSI operation (atomic read and set bits immediate)
 * Should perform bitwise OR with zimm, suppress write if zimm=0
 */
BOOST_AUTO_TEST_CASE(test_csrrsi_operation) {
  Vcsr_alu *dut = new Vcsr_alu();

  dut->csr_rdata = 0x00000000;
  dut->rs1_or_zimm = 0x00000015; // zimm = 21 (binary 10101)
  dut->funct3 = CSR_RSI;
  dut->rs1_is_zero = 0;
  dut->eval();

  // Should set bits 0, 2, 4
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0x00000015);
  BOOST_CHECK_EQUAL(dut->csr_we, 1);

  // Test with zimm=0 (write suppressed)
  dut->rs1_or_zimm = 0x00000000;
  dut->rs1_is_zero = 1;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_we, 0); // Write suppressed

  delete dut;
}

/**
 * Test: CSRRC operation (atomic read and clear bits)
 * Should perform bitwise AND with complement, suppress write if rs1=x0
 */
BOOST_AUTO_TEST_CASE(test_csrrc_operation) {
  Vcsr_alu *dut = new Vcsr_alu();

  dut->csr_rdata = 0xFFFFFFFF;
  dut->rs1_or_zimm = 0x0000000F; // Clear lower 4 bits
  dut->funct3 = CSR_RC;
  dut->rs1_is_zero = 0;
  dut->eval();

  // Should clear bits [3:0]
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0xFFFFFFF0);
  BOOST_CHECK_EQUAL(dut->csr_we, 1);

  // Test with rs1=x0 (write suppressed)
  dut->rs1_or_zimm = 0x00000000;
  dut->rs1_is_zero = 1;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0xFFFFFFFF); // AND with ~0 = all 1's
  BOOST_CHECK_EQUAL(dut->csr_we, 0);             // Write suppressed

  // Test clearing specific bits
  dut->csr_rdata = 0x00000007;   // bits [2:0] set
  dut->rs1_or_zimm = 0x00000003; // clear bits [1:0]
  dut->rs1_is_zero = 0;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0x00000004); // Only bit 2 remains
  BOOST_CHECK_EQUAL(dut->csr_we, 1);

  delete dut;
}

/**
 * Test: CSRRCI operation (atomic read and clear bits immediate)
 * Should perform bitwise AND with complement of zimm, suppress write if zimm=0
 */
BOOST_AUTO_TEST_CASE(test_csrrci_operation) {
  Vcsr_alu *dut = new Vcsr_alu();

  dut->csr_rdata = 0xFFFFFFFF;
  dut->rs1_or_zimm = 0x0000001F; // zimm = 31, clear bits [4:0]
  dut->funct3 = CSR_RCI;
  dut->rs1_is_zero = 0;
  dut->eval();

  // Should clear bits [4:0]
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0xFFFFFFE0);
  BOOST_CHECK_EQUAL(dut->csr_we, 1);

  // Test with zimm=0 (write suppressed)
  dut->rs1_or_zimm = 0x00000000;
  dut->rs1_is_zero = 1;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_we, 0); // Write suppressed

  delete dut;
}

/**
 * Test: Complex bit manipulation sequences
 * Test realistic CSR modification patterns
 */
BOOST_AUTO_TEST_CASE(test_complex_bit_operations) {
  Vcsr_alu *dut = new Vcsr_alu();

  // Start with some initial value
  uint32_t csr_value = 0x00FF00FF;

  // Operation 1: Set bits [31:24] using CSRRS
  dut->csr_rdata = csr_value;
  dut->rs1_or_zimm = 0xFF000000;
  dut->funct3 = CSR_RS;
  dut->rs1_is_zero = 0;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->csr_wdata, 0xFFFF00FF);
  BOOST_CHECK_EQUAL(dut->csr_we, 1);
  csr_value = dut->csr_wdata;

  // Operation 2: Clear bits [7:0] using CSRRC
  dut->csr_rdata = csr_value;
  dut->rs1_or_zimm = 0x000000FF;
  dut->funct3 = CSR_RC;
  dut->rs1_is_zero = 0;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->csr_wdata, 0xFFFF0000);
  BOOST_CHECK_EQUAL(dut->csr_we, 1);
  csr_value = dut->csr_wdata;

  // Operation 3: Write new value using CSRRW
  dut->csr_rdata = csr_value;
  dut->rs1_or_zimm = 0x12345678;
  dut->funct3 = CSR_RW;
  dut->rs1_is_zero = 0;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->csr_wdata, 0x12345678);
  BOOST_CHECK_EQUAL(dut->csr_we, 1);

  delete dut;
}

/**
 * Test: Write suppression for CSRRS with rs1=x0
 * Read-only access pattern
 */
BOOST_AUTO_TEST_CASE(test_readonly_access_pattern) {
  Vcsr_alu *dut = new Vcsr_alu();

  // CSRRS with rs1=x0 is the recommended way to read a CSR
  // without modifying it (CSRR pseudo-instruction)
  dut->csr_rdata = 0xABCD1234;
  dut->rs1_or_zimm = 0x00000000;
  dut->funct3 = CSR_RS;
  dut->rs1_is_zero = 1;
  dut->eval();

  // Should not write
  BOOST_CHECK_EQUAL(dut->csr_we, 0);
  // csr_wdata doesn't matter when csr_we=0, but should be unchanged
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0xABCD1234);

  delete dut;
}

/**
 * Test: Edge cases with all zeros and all ones
 */
BOOST_AUTO_TEST_CASE(test_edge_cases) {
  Vcsr_alu *dut = new Vcsr_alu();

  // Test CSRRS with all 1's
  dut->csr_rdata = 0x00000000;
  dut->rs1_or_zimm = 0xFFFFFFFF;
  dut->funct3 = CSR_RS;
  dut->rs1_is_zero = 0;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0xFFFFFFFF);
  BOOST_CHECK_EQUAL(dut->csr_we, 1);

  // Test CSRRC with all 1's (clears everything)
  dut->csr_rdata = 0xFFFFFFFF;
  dut->rs1_or_zimm = 0xFFFFFFFF;
  dut->funct3 = CSR_RC;
  dut->rs1_is_zero = 0;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0x00000000);
  BOOST_CHECK_EQUAL(dut->csr_we, 1);

  // Test CSRRW with 0 (writes 0)
  dut->csr_rdata = 0xFFFFFFFF;
  dut->rs1_or_zimm = 0x00000000;
  dut->funct3 = CSR_RW;
  dut->rs1_is_zero = 1; // Note: CSRRW doesn't care about this flag
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_wdata, 0x00000000);
  BOOST_CHECK_EQUAL(dut->csr_we, 1); // Always writes for CSRRW

  delete dut;
}

/**
 * Test: Invalid funct3 values
 * Test behavior with funct3 values that don't correspond to CSR ops
 */
BOOST_AUTO_TEST_CASE(test_invalid_funct3) {
  Vcsr_alu *dut = new Vcsr_alu();

  // Test with funct3 = 0b000 (ECALL/EBREAK, not a CSR op)
  dut->csr_rdata = 0x12345678;
  dut->rs1_or_zimm = 0xABCDEF00;
  dut->funct3 = 0b000;
  dut->rs1_is_zero = 0;
  dut->eval();

  // Should not write (default case)
  BOOST_CHECK_EQUAL(dut->csr_we, 0);

  // Test with funct3 = 0b100 (unused)
  dut->funct3 = 0b100;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->csr_we, 0);

  delete dut;
}

BOOST_AUTO_TEST_SUITE_END()
