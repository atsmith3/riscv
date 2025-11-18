/*
 * Test Utilities for RISC-V Core Verification
 *
 * Helper functions for test setup, execution, and verification
 */

#ifndef TEST_UTILS_H
#define TEST_UTILS_H

#include <cstdint>
#include <iostream>
#include <string>

// Magic addresses for test result communication
constexpr uint32_t MAGIC_RESULT_ADDR = 0xDEAD0000; // Write test result here
constexpr uint32_t MAGIC_PASS_VALUE = 0x00000001;  // Write to indicate pass
constexpr uint32_t MAGIC_FAIL_VALUE =
    0xFFFFFFFF; // Write to indicate fail (NOT 0, as memory initializes to 0)

// Test result enumeration
enum class TestResult { PASS, FAIL, TIMEOUT, ERROR };

// Stream output operator for TestResult (needed by Boost.Test)
inline std::ostream &operator<<(std::ostream &os, const TestResult &result) {
  switch (result) {
  case TestResult::PASS:
    return os << "PASS";
  case TestResult::FAIL:
    return os << "FAIL";
  case TestResult::TIMEOUT:
    return os << "TIMEOUT";
  case TestResult::ERROR:
    return os << "ERROR";
  default:
    return os << "UNKNOWN";
  }
}

// Test program paths
std::string get_test_program_path(const std::string &test_name);

// Hex string conversions
std::string to_hex_string(uint32_t value, int width = 8);
uint32_t from_hex_string(const std::string &hex_str);

// PC stuck detection (infinite loop)
bool is_pc_stuck(uint32_t current_pc, uint32_t previous_pc,
                 int stuck_count_threshold = 100);

// Result verification helpers
bool check_register_value(uint32_t actual, uint32_t expected,
                          const std::string &reg_name);
bool check_memory_word(uint32_t actual, uint32_t expected, uint32_t address);

// Test program information
struct TestProgram {
  std::string name;
  std::string ini_file;
  uint32_t expected_cycles_min;
  uint32_t expected_cycles_max;
  uint32_t timeout_cycles;
};

// Predefined test programs
extern const TestProgram TEST_ADD;
extern const TestProgram TEST_SUBTRACT;
extern const TestProgram TEST_GCD;

#endif // TEST_UTILS_H
