/*
 * TestRunner Class for RISC-V Core Testing
 *
 * Encapsulates DUT instantiation, memory setup, and simulation execution.
 * Provides a clean interface for writing automated tests with Boost.Test.
 *
 * Features:
 *   - DUT (core_top) instantiation and lifecycle management
 *   - Memory model integration
 *   - Program loading from hex files
 *   - Simulation execution with timeout and completion detection
 *   - Result extraction from magic addresses
 *   - Optional VCD waveform tracing
 *   - Cycle counting and statistics
 *
 * Usage Example:
 *   TestRunner runner("my_test", true);  // Enable tracing
 *   runner.load_program(get_test_program_path("add"));
 *   TestResult result = runner.run(10000);
 *   if (result == TestResult::PASS) {
 *     uint32_t cycles = runner.get_cycle_count();
 *   }
 */

#ifndef TEST_RUNNER_H
#define TEST_RUNNER_H

#include "../memory_model.h"
#include "test_utils.h"
#include <cstdint>
#include <string>

// Forward declarations for Verilator components
class Vcore_top;
class VerilatedVcdC;

class TestRunner {
public:
  // Constructor
  // test_name: Name of the test (used for trace file naming)
  // enable_trace: If true, generate VCD waveform file
  TestRunner(const std::string &test_name, bool enable_trace = false);

  // Destructor - cleanup DUT and trace
  ~TestRunner();

  // Load a program from a hex file into memory
  // Returns true on success, false on failure
  bool load_program(const std::string &hex_file);

  // Run the simulation until completion, timeout, or error
  // max_cycles: Maximum number of cycles to run before timeout
  // Returns: TestResult indicating pass/fail/timeout/error
  TestResult run(uint32_t max_cycles);

  // Accessors
  uint32_t get_cycle_count() const { return cycle_count; }
  uint32_t get_result() const; // Read from magic address
  uint32_t get_pc() const;

  // Direct access to components for advanced testing
  MemoryModel &get_memory() { return *memory; }
  Vcore_top &get_dut() { return *dut; }

  // Control
  void reset();
  void clock_cycle();

private:
  // Verilator components
  Vcore_top *dut;
  MemoryModel *memory;
  VerilatedVcdC *trace;

  // Simulation state
  uint64_t cycle_count;
  uint64_t sim_time;
  bool trace_enabled;
  std::string test_name;

  // Previous PC for stuck detection
  uint32_t previous_pc;
  int stuck_count;

  // Helper functions
  void setup_trace();
  void cleanup_trace();
  bool is_test_complete() const;
  TestResult get_test_result() const;
};

#endif // TEST_RUNNER_H
