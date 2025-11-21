/*
 * CSR System-Level Test Cases for RISC-V Core
 *
 * These tests verify CSR (Control and Status Register) functionality
 * including reading counters, atomic operations, and write suppression.
 *
 * Test programs use inline assembly to execute CSR instructions directly.
 */

#include "../include/test_runner.h"
#include "../include/test_utils.h"
#include <boost/test/unit_test.hpp>
#include <iostream>

BOOST_AUTO_TEST_SUITE(CSRSystemTests)

/**
 * Test: CSR read operation (CSRRS with rs1=x0)
 * Verifies that cycle counter can be read and is incrementing
 */
BOOST_AUTO_TEST_CASE(test_csr_read_cycle) {
  TestRunner runner("csr_read_cycle", false);

  std::string ini_file = get_test_program_path("csr_read_cycle");
  BOOST_REQUIRE_MESSAGE(runner.load_program(ini_file),
                        "Failed to load csr_read_cycle.ini");

  TestResult result = runner.run(10000);

  BOOST_CHECK_EQUAL(result, TestResult::PASS);
  BOOST_CHECK_LT(runner.get_cycle_count(), 5000);

  std::cout << "CSR_READ_CYCLE test completed in " << runner.get_cycle_count()
            << " cycles\n";
  std::cout << "Memory accesses: " << runner.get_memory().get_read_count()
            << " reads, " << runner.get_memory().get_write_count()
            << " writes\n";
}

/**
 * Test: CSR counter increment validation
 * Verifies that cycle and instret counters increment correctly
 */
BOOST_AUTO_TEST_CASE(test_csr_counters_increment) {
  TestRunner runner("csr_counters", false);

  // Test will read cycle and instret counters multiple times
  // and verify they increment appropriately

  BOOST_TEST_MESSAGE("CSR counter increment test - requires test program");
  // TODO: Implement when test program infrastructure is ready
}

/**
 * Test: CSR write suppression
 * Verifies that CSRRS/CSRRC with rs1=x0 doesn't write to CSR
 * and that CSRRSI/CSRRCI with zimm=0 doesn't write to CSR
 */
BOOST_AUTO_TEST_CASE(test_csr_write_suppression) {
  TestRunner runner("csr_write_suppress", false);

  // Test will attempt writes with rs1=x0/zimm=0 and verify
  // counters don't get corrupted

  BOOST_TEST_MESSAGE("CSR write suppression test - requires test program");
  // TODO: Implement when test program infrastructure is ready
}

/**
 * Test: CSR invalid address handling
 * Verifies that accessing an invalid CSR address causes an error
 */
BOOST_AUTO_TEST_CASE(test_csr_invalid_address) {
  TestRunner runner("csr_invalid_addr", false);

  // Test will attempt to read an invalid CSR address
  // and verify processor enters error state

  BOOST_TEST_MESSAGE("CSR invalid address test - requires test program");
  // TODO: Implement when test program infrastructure is ready
}

/**
 * Test: CSR atomic operations
 * Verifies CSRRW, CSRRS, CSRRC operations work correctly
 * Note: User-mode CSRs are read-only, so writes are ignored
 */
BOOST_AUTO_TEST_CASE(test_csr_atomic_operations) {
  TestRunner runner("csr_atomic_ops", false);

  // Test will perform various CSR operations
  // For read-only CSRs, writes should be ignored but reads should work

  BOOST_TEST_MESSAGE("CSR atomic operations test - requires test program");
  // TODO: Implement when test program infrastructure is ready
}

/**
 * Test: CSR time counter matches cycle counter
 * Verifies that time counter mirrors cycle counter as configured
 */
BOOST_AUTO_TEST_CASE(test_csr_time_matches_cycle) {
  TestRunner runner("csr_time_cycle", false);

  // Test will read both cycle and time counters
  // and verify they have the same value

  BOOST_TEST_MESSAGE("CSR time=cycle test - requires test program");
  // TODO: Implement when test program infrastructure is ready
}

/**
 * Test: CSR instret counter tracks instructions
 * Verifies that instret counter increments only when instructions complete
 */
BOOST_AUTO_TEST_CASE(test_csr_instret_tracking) {
  TestRunner runner("csr_instret", false);

  // Test will execute a known number of instructions
  // and verify instret counter matches

  BOOST_TEST_MESSAGE("CSR instret tracking test - requires test program");
  // TODO: Implement when test program infrastructure is ready
}

/**
 * Test: CSR 64-bit counter upper/lower word access
 * Verifies that cycle/cycleh, time/timeh, instret/instreth work correctly
 */
BOOST_AUTO_TEST_CASE(test_csr_64bit_counters) {
  TestRunner runner("csr_64bit", false);

  // Test will read both lower and upper 32-bit words of counters
  // and verify they form a coherent 64-bit value

  BOOST_TEST_MESSAGE("CSR 64-bit counter test - requires test program");
  // TODO: Implement when test program infrastructure is ready
}

/**
 * Test: CSR immediate variants (CSRRWI, CSRRSI, CSRRCI)
 * Verifies that immediate forms of CSR instructions work correctly
 */
BOOST_AUTO_TEST_CASE(test_csr_immediate_variants) {
  TestRunner runner("csr_immediate", false);

  // Test will use immediate variants to access CSRs
  // and verify correct operation

  BOOST_TEST_MESSAGE("CSR immediate variants test - requires test program");
  // TODO: Implement when test program infrastructure is ready
}

/**
 * Test: ECALL instruction and trap handling
 * Verifies that ECALL triggers a trap with mcause=11 and MRET returns correctly
 */
BOOST_AUTO_TEST_CASE(test_ecall_basic) {
  TestRunner runner("ecall_basic", true); // Enable VCD tracing for debugging

  std::string ini_file = get_test_program_path("ecall_basic");
  BOOST_REQUIRE_MESSAGE(runner.load_program(ini_file),
                        "Failed to load ecall_basic.ini");

  TestResult result = runner.run(10000);

  BOOST_CHECK_EQUAL(result, TestResult::PASS);
  BOOST_CHECK_LT(runner.get_cycle_count(), 5000);

  std::cout << "ECALL_BASIC test completed in " << runner.get_cycle_count()
            << " cycles\n";
  std::cout << "Memory accesses: " << runner.get_memory().get_read_count()
            << " reads, " << runner.get_memory().get_write_count()
            << " writes\n";
}

/**
 * Test: EBREAK instruction and trap handling
 * Verifies that EBREAK triggers a trap with mcause=3 and MRET returns correctly
 */
BOOST_AUTO_TEST_CASE(test_ebreak_basic) {
  TestRunner runner("ebreak_basic", false);

  std::string ini_file = get_test_program_path("ebreak_basic");
  BOOST_REQUIRE_MESSAGE(runner.load_program(ini_file),
                        "Failed to load ebreak_basic.ini");

  TestResult result = runner.run(10000);

  BOOST_CHECK_EQUAL(result, TestResult::PASS);
  BOOST_CHECK_LT(runner.get_cycle_count(), 5000);

  std::cout << "EBREAK_BASIC test completed in " << runner.get_cycle_count()
            << " cycles\n";
  std::cout << "Memory accesses: " << runner.get_memory().get_read_count()
            << " reads, " << runner.get_memory().get_write_count()
            << " writes\n";
}

BOOST_AUTO_TEST_SUITE_END()
