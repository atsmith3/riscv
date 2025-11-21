#include "include/test_runner.h"
#include "include/test_utils.h"
#include <iostream>

int main() {
  TestRunner runner("ecall_debug", true); // Enable VCD tracing

  std::string ini_file = get_test_program_path("ecall_basic");
  if (!runner.load_program(ini_file)) {
    std::cerr << "Failed to load program\n";
    return 1;
  }

  TestResult result = runner.run(500); // Run for 500 cycles max

  std::cout << "Result: "
            << (result == TestResult::PASS   ? "PASS"
                : result == TestResult::FAIL ? "FAIL"
                                             : "TIMEOUT")
            << "\n";
  std::cout << "Cycles: " << runner.get_cycle_count() << "\n";
  std::cout << "Final PC: 0x" << std::hex << runner.get_pc() << std::dec
            << "\n";
  std::cout << "VCD file: ecall_debug.vcd\n";

  return 0;
}
