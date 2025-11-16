/*
 * System-Level Test Cases for RISC-V Core
 *
 * These tests run complete programs on the core and verify correct execution.
 * Each test loads a program from a hex file, runs it to completion, and checks
 * the result using magic address communication.
 *
 * Test programs are expected to write to MAGIC_RESULT_ADDR:
 *   - MAGIC_PASS_VALUE (0x00000001) for success
 *   - MAGIC_FAIL_VALUE (0x00000000) for failure
 */

#include "../include/test_runner.h"
#include "../include/test_utils.h"
#include <boost/test/unit_test.hpp>
#include <iostream>

BOOST_AUTO_TEST_SUITE(SystemLevelTests)

BOOST_AUTO_TEST_CASE(test_add_program) {
  TestRunner runner("add", false); // No trace for faster execution

  std::string ini_file = get_test_program_path("add");
  BOOST_REQUIRE_MESSAGE(
      runner.load_program(ini_file),
      "Failed to load add.ini - check WORKSPACE environment variable");

  TestResult result = runner.run(10000);

  BOOST_CHECK_EQUAL(result, TestResult::PASS);
  BOOST_CHECK_LT(runner.get_cycle_count(), 1000);

  // Expected: VAL_1 (0xDEADBEEF) + VAL_2 (0xBADCAFFE) = 0x199A89ED
  uint32_t mem_result =
      runner.get_memory().backdoor_read_word(MAGIC_RESULT_ADDR);
  BOOST_CHECK_EQUAL(mem_result, MAGIC_PASS_VALUE);

  std::cout << "ADD test completed in " << runner.get_cycle_count()
            << " cycles\n";
  std::cout << "Memory accesses: " << runner.get_memory().get_read_count()
            << " reads, " << runner.get_memory().get_write_count()
            << " writes\n";
}

BOOST_AUTO_TEST_CASE(test_subtract_program) {
  TestRunner runner("subtract", false);

  std::string ini_file = get_test_program_path("subtract");
  BOOST_REQUIRE_MESSAGE(runner.load_program(ini_file),
                        "Failed to load subtract.ini");

  TestResult result = runner.run(10000);

  BOOST_CHECK_EQUAL(result, TestResult::PASS);
  BOOST_CHECK_LT(runner.get_cycle_count(), 1000);

  std::cout << "SUBTRACT test completed in " << runner.get_cycle_count()
            << " cycles\n";
  std::cout << "Memory accesses: " << runner.get_memory().get_read_count()
            << " reads, " << runner.get_memory().get_write_count()
            << " writes\n";
}

BOOST_AUTO_TEST_CASE(test_gcd_program) {
  TestRunner runner("gcd", false);

  std::string ini_file = get_test_program_path("gcd");
  BOOST_REQUIRE_MESSAGE(runner.load_program(ini_file),
                        "Failed to load gcd.ini");

  TestResult result = runner.run(100000); // GCD takes longer

  BOOST_CHECK_EQUAL(result, TestResult::PASS);
  BOOST_CHECK_LT(runner.get_cycle_count(), 50000);

  std::cout << "GCD test completed in " << runner.get_cycle_count()
            << " cycles\n";
  std::cout << "Memory accesses: " << runner.get_memory().get_read_count()
            << " reads, " << runner.get_memory().get_write_count()
            << " writes\n";
}

BOOST_AUTO_TEST_CASE(test_fibonacci_program) {
  TestRunner runner("fibonacci", false);

  std::string ini_file = get_test_program_path("fibonacci");
  BOOST_REQUIRE_MESSAGE(runner.load_program(ini_file),
                        "Failed to load fibonacci.ini");

  TestResult result = runner.run(10000);

  BOOST_CHECK_EQUAL(result, TestResult::PASS);
  BOOST_CHECK_LT(runner.get_cycle_count(), 5000);

  std::cout << "FIBONACCI test completed in " << runner.get_cycle_count()
            << " cycles\n";
  std::cout << "Memory accesses: " << runner.get_memory().get_read_count()
            << " reads, " << runner.get_memory().get_write_count()
            << " writes\n";
}

BOOST_AUTO_TEST_CASE(test_bitops_program) {
  TestRunner runner("bitops", false);

  std::string ini_file = get_test_program_path("bitops");
  BOOST_REQUIRE_MESSAGE(runner.load_program(ini_file),
                        "Failed to load bitops.ini");

  TestResult result = runner.run(100000);

  BOOST_CHECK_EQUAL(result, TestResult::PASS);
  BOOST_CHECK_LT(runner.get_cycle_count(), 10000);

  std::cout << "BITOPS test completed in " << runner.get_cycle_count()
            << " cycles\n";
  std::cout << "Memory accesses: " << runner.get_memory().get_read_count()
            << " reads, " << runner.get_memory().get_write_count()
            << " writes\n";
}

BOOST_AUTO_TEST_CASE(test_multiply_program) {
  TestRunner runner("multiply", false);

  std::string ini_file = get_test_program_path("multiply");
  BOOST_REQUIRE_MESSAGE(runner.load_program(ini_file),
                        "Failed to load multiply.ini");

  TestResult result = runner.run(100000);

  BOOST_CHECK_EQUAL(result, TestResult::PASS);
  BOOST_CHECK_LT(runner.get_cycle_count(), 20000);

  std::cout << "MULTIPLY test completed in " << runner.get_cycle_count()
            << " cycles\n";
  std::cout << "Memory accesses: " << runner.get_memory().get_read_count()
            << " reads, " << runner.get_memory().get_write_count()
            << " writes\n";
}

BOOST_AUTO_TEST_CASE(test_strlen_program) {
  TestRunner runner("strlen", false);

  std::string ini_file = get_test_program_path("strlen");
  BOOST_REQUIRE_MESSAGE(runner.load_program(ini_file),
                        "Failed to load strlen.ini");

  TestResult result = runner.run(100000);

  BOOST_CHECK_EQUAL(result, TestResult::PASS);
  BOOST_CHECK_LT(runner.get_cycle_count(), 20000);

  std::cout << "STRLEN test completed in " << runner.get_cycle_count()
            << " cycles\n";
  std::cout << "Memory accesses: " << runner.get_memory().get_read_count()
            << " reads, " << runner.get_memory().get_write_count()
            << " writes\n";
}

BOOST_AUTO_TEST_CASE(test_memcpy_program) {
  TestRunner runner("memcpy", false);

  std::string ini_file = get_test_program_path("memcpy");
  BOOST_REQUIRE_MESSAGE(runner.load_program(ini_file),
                        "Failed to load memcpy.ini");

  TestResult result = runner.run(100000);

  BOOST_CHECK_EQUAL(result, TestResult::PASS);
  BOOST_CHECK_LT(runner.get_cycle_count(), 25000);

  std::cout << "MEMCPY test completed in " << runner.get_cycle_count()
            << " cycles\n";
  std::cout << "Memory accesses: " << runner.get_memory().get_read_count()
            << " reads, " << runner.get_memory().get_write_count()
            << " writes\n";
}

BOOST_AUTO_TEST_CASE(test_bubble_sort_program) {
  TestRunner runner("bubble_sort", false);

  std::string ini_file = get_test_program_path("bubble_sort");
  BOOST_REQUIRE_MESSAGE(runner.load_program(ini_file),
                        "Failed to load bubble_sort.ini");

  TestResult result = runner.run(100000);

  BOOST_CHECK_EQUAL(result, TestResult::PASS);
  BOOST_CHECK_LT(runner.get_cycle_count(), 20000);

  std::cout << "BUBBLE_SORT test completed in " << runner.get_cycle_count()
            << " cycles\n";
  std::cout << "Memory accesses: " << runner.get_memory().get_read_count()
            << " reads, " << runner.get_memory().get_write_count()
            << " writes\n";
}

BOOST_AUTO_TEST_CASE(test_factorial_program) {
  TestRunner runner("factorial", false);

  std::string ini_file = get_test_program_path("factorial");
  BOOST_REQUIRE_MESSAGE(runner.load_program(ini_file),
                        "Failed to load factorial.ini");

  TestResult result = runner.run(100000);

  BOOST_CHECK_EQUAL(result, TestResult::PASS);
  BOOST_CHECK_LT(runner.get_cycle_count(), 20000);

  std::cout << "FACTORIAL test completed in " << runner.get_cycle_count()
            << " cycles\n";
  std::cout << "Memory accesses: " << runner.get_memory().get_read_count()
            << " reads, " << runner.get_memory().get_write_count()
            << " writes\n";
}

BOOST_AUTO_TEST_CASE(test_prime_program) {
  TestRunner runner("prime", false);

  std::string ini_file = get_test_program_path("prime");
  BOOST_REQUIRE_MESSAGE(runner.load_program(ini_file),
                        "Failed to load prime.ini");

  TestResult result = runner.run(200000);

  BOOST_CHECK_EQUAL(result, TestResult::PASS);
  BOOST_CHECK_LT(runner.get_cycle_count(), 70000);

  std::cout << "PRIME test completed in " << runner.get_cycle_count()
            << " cycles\n";
  std::cout << "Memory accesses: " << runner.get_memory().get_read_count()
            << " reads, " << runner.get_memory().get_write_count()
            << " writes\n";
}

BOOST_AUTO_TEST_CASE(test_timeout_detection) {
  TestRunner runner("add", false);

  std::string ini_file = get_test_program_path("add");
  BOOST_REQUIRE_MESSAGE(runner.load_program(ini_file),
                        "Failed to load add.ini");

  // Run with very short timeout to test timeout mechanism
  TestResult result = runner.run(10); // Too short, should timeout

  BOOST_CHECK_EQUAL(result, TestResult::TIMEOUT);
  std::cout << "Timeout detection working correctly\n";
}

BOOST_AUTO_TEST_SUITE_END()
