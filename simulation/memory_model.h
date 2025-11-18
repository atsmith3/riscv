/*
 * Memory Model for RISC-V Core Verification
 *
 * C++ memory model matching the behavior of the SystemVerilog ram.sv module.
 * Provides configurable delay, little-endian byte ordering, and supports
 * loading programs from hex files (.ini format).
 *
 * Features:
 *   - Parameterizable size and delay
 *   - Word-aligned 32-bit access
 *   - Little-endian byte ordering
 *   - Load from hex files
 *   - Backdoor read/write for test setup/verification
 *   - FSM-based delay modeling matching hardware
 *   - Debug logging capabilities
 */

#ifndef MEMORY_MODEL_H
#define MEMORY_MODEL_H

#include <cstdint>
#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <vector>

class MemoryModel {
public:
  // Memory states matching the SystemVerilog FSM
  enum State { IDLE = 0, WAIT_READ, WAIT_WRITE, DONE_READ, DONE_WRITE };

  // Constructor
  MemoryModel(uint32_t size_bytes = 1024 * 1024, // 1MB default
              uint32_t delay_cycles = 4,         // Match ram.sv default
              bool debug = false);

  // Destructor
  ~MemoryModel();

  // Main interface - call on every clock cycle
  void eval(bool clk, bool rst_n, bool read, bool write, uint32_t addr,
            uint32_t data_in, uint32_t &data_out, bool &resp,
            uint8_t byte_enables = 0xF);

  // Program loading
  bool load_hex_file(const std::string &filename);

  // Backdoor access for test setup and verification
  uint32_t backdoor_read_word(uint32_t addr) const;
  uint8_t backdoor_read_byte(uint32_t addr) const;
  void backdoor_write_word(uint32_t addr, uint32_t data);
  void backdoor_write_byte(uint32_t addr, uint8_t data);

  // Memory introspection
  void dump_memory(uint32_t start_addr, uint32_t end_addr) const;
  void clear();
  uint32_t get_size() const { return memory_size; }

  // Statistics
  uint64_t get_read_count() const { return read_count; }
  uint64_t get_write_count() const { return write_count; }
  void reset_statistics();

  // Debug control
  void set_debug(bool enable) { debug_enabled = enable; }

private:
  // Memory storage
  std::vector<uint8_t> memory;
  uint32_t memory_size;

  // Configuration
  uint32_t delay_cycles;
  bool debug_enabled;

  // FSM state
  State state;
  State next_state;
  uint32_t cycle_count;
  uint32_t output_buffer;

  // Edge detection for read/write signals
  bool old_read;
  bool old_write;
  bool old_clk;

  // Statistics
  uint64_t read_count;
  uint64_t write_count;

  // Helper functions
  bool is_aligned(uint32_t addr) const { return (addr & 0x3) == 0; }
  bool is_valid_address(uint32_t addr) const { return addr < memory_size; }
  void log(const std::string &message) const;

  // FSM logic
  void update_next_state(bool read, bool write);
  void update_state_outputs(bool clk, bool rst_n);
};

#endif // MEMORY_MODEL_H
