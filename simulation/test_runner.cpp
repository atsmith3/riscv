/*
 * TestRunner Implementation
 */

#include "include/test_runner.h"
#include "Vcore_top.h"
#include "include/test_utils.h"
#include <iomanip>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>

TestRunner::TestRunner(const std::string &name, bool enable_trace)
    : dut(nullptr), memory(nullptr), trace(nullptr), cycle_count(0),
      sim_time(0), trace_enabled(enable_trace), test_name(name), previous_pc(0),
      stuck_count(0) {
  // Initialize Verilator context
  const char *argv[] = {""};
  Verilated::commandArgs(1, argv);

  // Create DUT instance
  dut = new Vcore_top();

  // Create memory model (1MB, 4 cycle delay, debug enabled)
  memory = new MemoryModel(1024 * 1024, 4, true);

  // Setup tracing if requested
  if (trace_enabled) {
    setup_trace();
  }

  // Initialize DUT inputs
  dut->clk = 0;
  dut->rst_n = 0;
  dut->mem_rdata = 0;
  dut->mem_resp = 0;
  dut->eval(); // Evaluate initial state

  // Reset the design
  reset();

  std::cout << "[TEST] TestRunner initialized for test: " << test_name << "\n";
}

TestRunner::~TestRunner() {
  // Finalize trace before cleanup
  if (trace) {
    cleanup_trace();
  }

  // Clean up Verilator objects
  if (dut) {
    dut->final();
    delete dut;
  }

  if (memory) {
    delete memory;
  }

  std::cout << "[TEST] TestRunner cleanup complete\n";
}

void TestRunner::setup_trace() {
  // Enable tracing globally (safe to call multiple times)
  Verilated::traceEverOn(true);

  trace = new VerilatedVcdC();
  dut->trace(trace, 99); // Trace 99 levels of hierarchy

  std::string trace_file = "trace/" + test_name + ".vcd";
  trace->open(trace_file.c_str());

  std::cout << "[TEST] Tracing enabled: " << trace_file << "\n";
}

void TestRunner::cleanup_trace() {
  if (trace) {
    trace->close();
    delete trace;
    trace = nullptr;
  }
}

bool TestRunner::load_program(const std::string &hex_file) {
  if (!memory) {
    std::cerr << "[ERROR] Memory not initialized\n";
    return false;
  }

  bool success = memory->load_hex_file(hex_file);
  if (success) {
    std::cout << "[TEST] Program loaded: " << hex_file << "\n";
  } else {
    std::cerr << "[ERROR] Failed to load program: " << hex_file << "\n";
  }

  return success;
}

void TestRunner::reset() {
  // Apply reset for several cycles
  dut->rst_n = 0;
  dut->clk = 0;
  dut->eval();

  for (int i = 0; i < 10; i++) {
    clock_cycle();
  }

  // Release reset - eval with clk=0 to let combinational logic settle
  dut->rst_n = 1;
  dut->clk = 0;
  dut->eval(); // Let FSM enter FETCH_0 state with outputs settled

  // Do NOT call memory->eval() here - see comment in debug_test.cpp
  // Do NOT clock here either - the program may not be loaded yet!
  // Clocking will happen when run() is called.

  cycle_count = 0;
  previous_pc = 0;
  stuck_count = 0;

  std::cout << "[TEST] Reset complete\n";
}

void TestRunner::clock_cycle() {
  // Rising edge
  dut->clk = 1;

  // CRITICAL: Evaluate memory BEFORE DUT on rising edge!
  // The memory model needs to sample the DUT's outputs from BEFORE the clock
  // edge to detect 0->1 transitions. If we eval() the DUT first, the FSM
  // advances and mem_read goes back to 0 before the memory sees it.
  bool mem_resp_out;
  uint32_t mem_data_out;
  memory->eval(dut->clk, dut->rst_n, dut->mem_read, dut->mem_write,
               dut->mem_addr, dut->mem_wdata, mem_data_out, mem_resp_out);

  dut->mem_rdata = mem_data_out;
  dut->mem_resp = mem_resp_out;

  dut->eval(); // Now evaluate DUT with rising clock and memory responses

  if (trace) {
    trace->dump(static_cast<vluint64_t>(sim_time));
  }
  sim_time++;

  // Falling edge
  dut->clk = 0;

  // Evaluate memory before DUT on falling edge too
  memory->eval(dut->clk, dut->rst_n, dut->mem_read, dut->mem_write,
               dut->mem_addr, dut->mem_wdata, mem_data_out, mem_resp_out);

  dut->mem_rdata = mem_data_out;
  dut->mem_resp = mem_resp_out;

  dut->eval(); // Evaluate DUT with falling clock and memory responses

  if (trace) {
    trace->dump(static_cast<vluint64_t>(sim_time));
  }
  sim_time++;

  cycle_count++;
}

TestResult TestRunner::run(uint32_t max_cycles) {
  std::cout << "[TEST] Starting simulation (max " << max_cycles << " cycles)\n";

  cycle_count = 0;
  previous_pc = 0;
  stuck_count = 0;

  while (cycle_count < max_cycles) {
    clock_cycle();

    // Check for test completion
    if (is_test_complete()) {
      TestResult result = get_test_result();
      std::cout << "[TEST] Test completed in " << cycle_count << " cycles\n";

      if (result == TestResult::PASS) {
        std::cout << "[TEST] Result: PASS\n";
      } else {
        std::cout << "[TEST] Result: FAIL\n";
      }

      return result;
    }

    // Check for stuck PC (infinite loop without test completion)
    uint32_t current_pc = get_pc();
    if (current_pc == previous_pc) {
      stuck_count++;
      if (stuck_count > 100) {
        std::cout << "[TEST] PC stuck at " << to_hex_string(current_pc, 8)
                  << " for " << stuck_count
                  << " cycles without test completion\n";
        std::cout << "[TEST] Result: TIMEOUT (stuck PC)\n";
        return TestResult::TIMEOUT;
      }
    } else {
      stuck_count = 0;
    }
    previous_pc = current_pc;

    // Periodic progress updates (every 1000 cycles)
    if (cycle_count % 1000 == 0 && cycle_count > 0) {
      // std::cout << "[TEST] Cycle " << cycle_count
      //           << " - PC: " << to_hex_string(get_pc(), 8) << "\n";
    }
  }

  std::cout << "[TEST] Timeout after " << max_cycles << " cycles\n";
  std::cout << "[TEST] Final PC: " << to_hex_string(get_pc(), 8) << "\n";
  std::cout << "[TEST] Result: TIMEOUT\n";
  return TestResult::TIMEOUT;
}

bool TestRunner::is_test_complete() const {
  // Check if magic address has been written
  uint32_t magic_value = memory->backdoor_read_word(MAGIC_RESULT_ADDR);
  return (magic_value == MAGIC_PASS_VALUE || magic_value == MAGIC_FAIL_VALUE);
}

TestResult TestRunner::get_test_result() const {
  uint32_t magic_value = memory->backdoor_read_word(MAGIC_RESULT_ADDR);

  if (magic_value == MAGIC_PASS_VALUE) {
    return TestResult::PASS;
  } else if (magic_value == MAGIC_FAIL_VALUE) {
    return TestResult::FAIL;
  } else {
    return TestResult::ERROR;
  }
}

uint32_t TestRunner::get_result() const {
  return memory->backdoor_read_word(MAGIC_RESULT_ADDR);
}

uint32_t TestRunner::get_pc() const { return dut->pc; }
