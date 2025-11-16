/*
 * Memory Model Implementation
 */

#include "memory_model.h"
#include <cctype>
#include <iomanip>
#include <sstream>

// Helper function to convert to hex string
static std::string to_hex(uint32_t value) {
  std::ostringstream oss;
  oss << std::setw(8) << std::setfill('0') << std::hex << value;
  return oss.str();
}

MemoryModel::MemoryModel(uint32_t size_bytes, uint32_t delay, bool debug)
    : memory_size(size_bytes), delay_cycles(delay), debug_enabled(debug),
      state(IDLE), next_state(IDLE), cycle_count(0), output_buffer(0),
      old_read(false), old_write(false), old_clk(false), read_count(0),
      write_count(0) {
  memory.resize(memory_size, 0);
  log("Memory model initialized: " + std::to_string(size_bytes) + " bytes, " +
      std::to_string(delay) + " cycle delay");
}

MemoryModel::~MemoryModel() {
  if (debug_enabled) {
    log("Memory statistics - Reads: " + std::to_string(read_count) +
        ", Writes: " + std::to_string(write_count));
  }
}

void MemoryModel::eval(bool clk, bool rst_n, bool read, bool write,
                       uint32_t addr, uint32_t data_in, uint32_t &data_out,
                       bool &resp) {
  // Detect rising edge
  bool rising_edge = clk && !old_clk;
  old_clk = clk;

  if (!rst_n) {
    // Reset
    state = IDLE;
    next_state = IDLE;
    old_read = false;
    old_write = false;
    cycle_count = 0;
    resp = false;
    data_out = output_buffer;
    return;
  }

  if (rising_edge) {
    // Compute next state BEFORE updating old_read/old_write
    // This matches SystemVerilog behavior where combinational logic
    // sees old flip-flop values before non-blocking assignments take effect
    update_next_state(read, write);

    // Update state on rising edge
    bool state_changed = (state != next_state);
    state = next_state;
    old_read = read;
    old_write = write;

    // State-specific actions
    if (state == WAIT_READ || state == WAIT_WRITE) {
      if (state_changed) {
        cycle_count = 0; // Reset count when entering wait state
      } else {
        cycle_count++; // Increment count while in wait state
      }
    }

    if (state == DONE_READ) {
      // Perform read - little-endian byte ordering
      if (is_valid_address(addr) && is_valid_address(addr + 3)) {
        output_buffer = static_cast<uint32_t>(memory[addr]) |
                        (static_cast<uint32_t>(memory[addr + 1]) << 8) |
                        (static_cast<uint32_t>(memory[addr + 2]) << 16) |
                        (static_cast<uint32_t>(memory[addr + 3]) << 24);
        read_count++;
        log("READ  addr=0x" + to_hex(addr) + " data=0x" +
            to_hex(output_buffer));
      } else {
        log("ERROR: Invalid read address 0x" + to_hex(addr));
        output_buffer = 0xDEADBEEF; // Error pattern
      }
    }

    if (state == DONE_WRITE) {
      // Perform write - little-endian byte ordering
      // Special case: Allow writes to magic address region
      // (0xDEAD0000-0xDEADFFFF) even though it's outside physical memory for
      // test result communication
      if ((addr & 0xFFFF0000) == 0xDEAD0000) {
        // Write to magic address region - store in special location
        // Map 0xDEAD0000+ to the last 64KB of physical memory
        uint32_t magic_offset = (memory_size - 65536) + (addr & 0xFFFF);
        if (magic_offset + 3 < memory_size) {
          memory[magic_offset] = data_in & 0xFF;
          memory[magic_offset + 1] = (data_in >> 8) & 0xFF;
          memory[magic_offset + 2] = (data_in >> 16) & 0xFF;
          memory[magic_offset + 3] = (data_in >> 24) & 0xFF;
          write_count++;
          log("WRITE addr=0x" + to_hex(addr) + " data=0x" + to_hex(data_in) +
              " (magic address)");
        }
      } else if (is_valid_address(addr) && is_valid_address(addr + 3)) {
        memory[addr] = data_in & 0xFF;
        memory[addr + 1] = (data_in >> 8) & 0xFF;
        memory[addr + 2] = (data_in >> 16) & 0xFF;
        memory[addr + 3] = (data_in >> 24) & 0xFF;
        write_count++;
        log("WRITE addr=0x" + to_hex(addr) + " data=0x" + to_hex(data_in));
      } else {
        log("ERROR: Invalid write address 0x" + to_hex(addr));
      }
    }
  } else {
    // Update next state on non-edge evals too (combinational)
    update_next_state(read, write);
  }

  // Generate outputs (combinational)
  resp = (state == DONE_READ || state == DONE_WRITE);
  data_out = output_buffer;
}

void MemoryModel::update_next_state(bool read, bool write) {
  next_state = IDLE;

  switch (state) {
  case IDLE:
    if (!old_read && read) {
      next_state = WAIT_READ;
    } else if (!old_write && write) {
      next_state = WAIT_WRITE;
    } else {
      next_state = IDLE;
    }
    break;

  case WAIT_READ:
    if (cycle_count >= delay_cycles - 1) {
      next_state = DONE_READ;
    } else {
      next_state = WAIT_READ;
    }
    break;

  case WAIT_WRITE:
    if (cycle_count >= delay_cycles - 1) {
      next_state = DONE_WRITE;
    } else {
      next_state = WAIT_WRITE;
    }
    break;

  case DONE_READ:
    next_state = IDLE;
    break;

  case DONE_WRITE:
    next_state = IDLE;
    break;

  default:
    next_state = IDLE;
    break;
  }
}

bool MemoryModel::load_hex_file(const std::string &filename) {
  std::ifstream file(filename);
  if (!file.is_open()) {
    log("ERROR: Cannot open file: " + filename);
    return false;
  }

  uint32_t addr = 0;
  std::string line;

  while (std::getline(file, line)) {
    std::istringstream iss(line);
    std::string byte_str;

    while (iss >> byte_str) {
      // Parse hex byte (handles both "AB" and "0xAB" formats)
      if (byte_str.size() >= 2) {
        try {
          uint8_t byte_val =
              static_cast<uint8_t>(std::stoi(byte_str, nullptr, 16));
          if (addr < memory_size) {
            memory[addr++] = byte_val;
          } else {
            log("WARNING: File exceeds memory size at byte " +
                std::to_string(addr));
            file.close();
            return false;
          }
        } catch (const std::exception &e) {
          log("WARNING: Invalid hex value: " + byte_str);
        }
      }
    }
  }

  file.close();
  log("Loaded " + std::to_string(addr) + " bytes from " + filename);
  return true;
}

uint32_t MemoryModel::backdoor_read_word(uint32_t addr) const {
  // Handle magic address region specially
  if ((addr & 0xFFFF0000) == 0xDEAD0000) {
    uint32_t magic_offset = (memory_size - 65536) + (addr & 0xFFFF);
    if (magic_offset + 3 < memory_size) {
      return static_cast<uint32_t>(memory[magic_offset]) |
             (static_cast<uint32_t>(memory[magic_offset + 1]) << 8) |
             (static_cast<uint32_t>(memory[magic_offset + 2]) << 16) |
             (static_cast<uint32_t>(memory[magic_offset + 3]) << 24);
    }
    return 0xDEADBEEF;
  }

  if (!is_valid_address(addr) || !is_valid_address(addr + 3)) {
    return 0xDEADBEEF;
  }

  return static_cast<uint32_t>(memory[addr]) |
         (static_cast<uint32_t>(memory[addr + 1]) << 8) |
         (static_cast<uint32_t>(memory[addr + 2]) << 16) |
         (static_cast<uint32_t>(memory[addr + 3]) << 24);
}

uint8_t MemoryModel::backdoor_read_byte(uint32_t addr) const {
  if (!is_valid_address(addr)) {
    return 0xFF;
  }
  return memory[addr];
}

void MemoryModel::backdoor_write_word(uint32_t addr, uint32_t data) {
  if (!is_valid_address(addr) || !is_valid_address(addr + 3)) {
    return;
  }

  memory[addr] = data & 0xFF;
  memory[addr + 1] = (data >> 8) & 0xFF;
  memory[addr + 2] = (data >> 16) & 0xFF;
  memory[addr + 3] = (data >> 24) & 0xFF;
}

void MemoryModel::backdoor_write_byte(uint32_t addr, uint8_t data) {
  if (!is_valid_address(addr)) {
    return;
  }
  memory[addr] = data;
}

void MemoryModel::dump_memory(uint32_t start_addr, uint32_t end_addr) const {
  std::cout << "Memory dump [0x" << std::hex << start_addr << " - 0x"
            << end_addr << "]:\n";

  for (uint32_t addr = start_addr; addr < end_addr && addr < memory_size;
       addr += 16) {
    std::cout << "0x" << std::setw(8) << std::setfill('0') << std::hex << addr
              << ": ";

    // Print hex bytes
    for (uint32_t i = 0;
         i < 16 && (addr + i) < end_addr && (addr + i) < memory_size; i++) {
      std::cout << std::setw(2) << std::setfill('0') << std::hex
                << static_cast<int>(memory[addr + i]) << " ";
    }

    // Print ASCII representation
    std::cout << " |";
    for (uint32_t i = 0;
         i < 16 && (addr + i) < end_addr && (addr + i) < memory_size; i++) {
      char c = memory[addr + i];
      std::cout << (isprint(c) ? c : '.');
    }
    std::cout << "|\n";
  }
  std::cout << std::dec;
}

void MemoryModel::clear() {
  std::fill(memory.begin(), memory.end(), 0);
  reset_statistics();
  log("Memory cleared");
}

void MemoryModel::reset_statistics() {
  read_count = 0;
  write_count = 0;
}

void MemoryModel::log(const std::string &message) const {
  if (debug_enabled) {
    std::cout << "[MEM] " << message << std::endl;
  }
}
