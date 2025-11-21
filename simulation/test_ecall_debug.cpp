/*
 * Debug test for ECALL - with VCD tracing enabled
 */

#include "include/test_runner.h"
#include "include/test_utils.h"
#include <iostream>

int main() {
  // Enable VCD tracing
  TestRunner runner("ecall_debug", true);

  std::string ini_file = get_test_program_path("ecall_basic");
  if (!runner.load_program(ini_file)) {
    std::cerr << "Failed to load program\n";
    return 1;
  }

  TestResult result = runner.run(10000);

  std::cout << "Test result: "
            << (result == TestResult::PASS   ? "PASS"
                : result == TestResult::FAIL ? "FAIL"
                                             : "TIMEOUT")
            << "\n";
  std::cout << "Cycles: " << runner.get_cycle_count() << "\n";
  std::cout << "PC: 0x" << std::hex << runner.get_pc() << "\n";

  return (result == TestResult::PASS) ? 0 : 1;
}
