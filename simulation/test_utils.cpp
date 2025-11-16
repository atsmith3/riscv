/*
 * Test Utilities Implementation
 */

#include "include/test_utils.h"
#include <cstdlib>
#include <iomanip>
#include <iostream>
#include <sstream>

// Get path to test program .ini file
std::string get_test_program_path(const std::string &test_name) {
  const char *workspace = std::getenv("WORKSPACE");
  std::string base_path =
      workspace ? workspace : "/home/andrew/prj/chip/potato/riscv";
  return base_path + "/test/" + test_name + "/" + test_name + ".ini";
}

// Convert value to hex string
std::string to_hex_string(uint32_t value, int width) {
  std::ostringstream oss;
  oss << "0x" << std::setw(width) << std::setfill('0') << std::hex << value;
  return oss.str();
}

// Convert hex string to value
uint32_t from_hex_string(const std::string &hex_str) {
  return static_cast<uint32_t>(std::stoul(hex_str, nullptr, 16));
}

// Check if PC is stuck (infinite loop detection)
bool is_pc_stuck(uint32_t current_pc, uint32_t previous_pc,
                 int stuck_count_threshold) {
  static uint32_t last_pc = 0;
  static int stuck_count = 0;

  if (current_pc == previous_pc) {
    stuck_count++;
    if (stuck_count >= stuck_count_threshold) {
      std::cout << "[TEST] PC stuck at " << to_hex_string(current_pc) << " for "
                << stuck_count << " cycles\n";
      return true;
    }
  } else {
    stuck_count = 0;
  }

  last_pc = current_pc;
  return false;
}

// Check register value with reporting
bool check_register_value(uint32_t actual, uint32_t expected,
                          const std::string &reg_name) {
  if (actual == expected) {
    std::cout << "[PASS] " << reg_name << " = " << to_hex_string(actual)
              << "\n";
    return true;
  } else {
    std::cout << "[FAIL] " << reg_name << " = " << to_hex_string(actual)
              << ", expected " << to_hex_string(expected) << "\n";
    return false;
  }
}

// Check memory word with reporting
bool check_memory_word(uint32_t actual, uint32_t expected, uint32_t address) {
  if (actual == expected) {
    std::cout << "[PASS] MEM[" << to_hex_string(address)
              << "] = " << to_hex_string(actual) << "\n";
    return true;
  } else {
    std::cout << "[FAIL] MEM[" << to_hex_string(address)
              << "] = " << to_hex_string(actual) << ", expected "
              << to_hex_string(expected) << "\n";
    return false;
  }
}

// Predefined test programs
const TestProgram TEST_ADD = {"add",
                              "", // Will be filled by get_test_program_path()
                              10, 1000, 10000};

const TestProgram TEST_SUBTRACT = {"subtract", "", 10, 1000, 10000};

const TestProgram TEST_GCD = {"gcd", "", 100, 50000, 100000};
