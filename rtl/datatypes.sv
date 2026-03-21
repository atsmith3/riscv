/* datatypes.sv
 *
 * Type definitions for the RISC-V 32I processor
 *
 * This file defines all the enumerated types used throughout the RTL codebase
 * for control signals, instruction formats, and operation codes.
 */

`ifndef __DATATYPES_SV__
`define __DATATYPES_SV__

// ============================================================================
// Databus Mux Selection
// ============================================================================
// Selects which source drives the shared databus
typedef enum bit [2 : 0] {
  DATABUS_PC = 0, // Program counter (for JALR, JAL, branch targets)
  DATABUS_ALU,    // ALU output (for register writes, memory addresses)
  DATABUS_MDR,    // Memory Data Register (for load results)
  DATABUS_MAR,    // Memory Address Register (unused in current design)
  DATABUS_CSR     // CSR read data (for CSR operations, trap handling)
} databus_mux_sel_t;

// ============================================================================
// RS1 Mux Selection
// ============================================================================
// Selects source for RS1 input to ALU
typedef enum bit [1 : 0] {
  RS1_OUT = 0, // RS1 from register file
  RS1_PC,      // PC + 4 (for JAL return address, JALR target base)
  RS1_2,       // Constant value 2 (unused)
  RS1_4        // Constant value 4 (for PC + 4 increment)
} rs1_mux_sel_t;

// ============================================================================
// RS2 Mux Selection
// ============================================================================
// Selects source for RS2 input to ALU
typedef enum bit [1 : 0] {
  RS2_OUT = 0, // RS2 from register file
  RS2_SEL,     // RS2 from register file (alternate name)
  RS2_IMM,     // Sign-extended immediate (for I-type instructions)
  RS2_PC       // PC + 4 (for JAL return address)
} rs2_mux_sel_t;

// ============================================================================
// ALU Operations
// ============================================================================
// All standard RV32I integer operations
typedef enum bit [3 : 0] {
  ALU_ADD = 0,  // Addition
  ALU_SLL,      // Logical shift left (shift amount in bits [4:0] of B)
  ALU_SLT,      // Set less than (signed comparison)
  ALU_SLTU,     // Set less than unsigned (unsigned comparison)
  ALU_XOR,      // Exclusive OR
  ALU_SRL,      // Logical shift right (shift amount in bits [4:0] of B)
  ALU_OR,       // Bitwise OR
  ALU_AND,      // Bitwise AND
  ALU_SUB,      // Subtraction
  ALU_PASS_RS1, // Pass RS1 through (used for LUI, AUIPC)
  ALU_PASS_RS2, // Pass RS2 through (used for LUI)
  ALU_SRA = 13  // Arithmetic shift right (shift amount in bits [4:0] of B)
} alu_op_t;

// ============================================================================
// Branch Condition Encodings
// ============================================================================
// Used for branch status register (BSR) output from ALU
typedef enum bit [2 : 0] {
  BEQ = 0,           // Branch if equal (a == b)
  BNE,               // Branch if not equal (a != b)
  BRANCH_RESERVED_1, // Reserved
  BRANCH_RESERVED_2, // Reserved
  BLT,               // Branch if less than (signed)
  BGE,               // Branch if greater than or equal (signed)
  BLTU,              // Branch if less than unsigned
  BGEU               // Branch if greater than or equal unsigned
} branch_t;

// ============================================================================
// Instruction Format Types
// ============================================================================
// RISC-V instruction formats
typedef enum bit [2 : 0] {
  INSTR_R = 0, // R-type: register-register operations (ALU, etc.)
  INSTR_I,     // I-type: immediate operations (loads, stores, ALUI, branches)
  INSTR_S,     // S-type: store operations
  INSTR_B,     // B-type: branch operations
  INSTR_U,     // U-type: upper immediate (LUI, AUIPC)
  INSTR_J,     // J-type: jump operations (JAL)
  INSTR_ERR    // Error/invalid instruction
} instr_format_t;

// ============================================================================
// Instruction Opcodes
// ============================================================================
// 7-bit opcode fields for instruction classification
typedef enum bit [6 : 0] {
  LUI = 7'b0110111,    // Load upper immediate
  AUIPC = 7'b0010111,  // Add upper immediate to PC
  JAL = 7'b1101111,    // Jump and link
  JALR = 7'b1100111,   // Jump and link register
  BRANCH = 7'b1100011, // Branch (BEQ, BNE, BLT, etc.)
  LD = 7'b0000011,     // Load (LB, LH, LW, LBU, LHU)
  ST = 7'b0100011,     // Store (SB, SH, SW)
  ALUI = 7'b0010011,  // ALU immediate (ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI)
  ALU = 7'b0110011,   // ALU register (ADD, SUB, SLL, etc.)
  FENCE = 7'b0001111, // Fence (FENCE, FENCE.I)
  ECSR = 7'b1110011   // CSR access (CSRRW, CSRRS, CSRRC, ECALL, EBREAK, MRET)
} opcode_t;

// ============================================================================
// Memory Access Size
// ============================================================================
// Used for sub-word load/store operations
typedef enum bit [1 : 0] {
  MEM_SIZE_BYTE = 2'b00, // Byte access (8 bits)
  MEM_SIZE_HALF = 2'b01, // Halfword access (16 bits)
  MEM_SIZE_WORD = 2'b10  // Word access (32 bits)
} mem_size_t;

// ============================================================================
// Load Instruction Funct3 Values
// ============================================================================
// Distinguishes between different load operations
typedef enum bit [2 : 0] {
  LD_BYTE = 3'b000,  // LB - Load byte (sign extended)
  LD_HALF = 3'b001,  // LH - Load halfword (sign extended)
  LD_WORD = 3'b010,  // LW - Load word
  LD_BYTEU = 3'b100, // LBU - Load byte unsigned (zero extended)
  LD_HALFU = 3'b101  // LHU - Load halfword unsigned (zero extended)
} load_funct3_t;

// ============================================================================
// Store Instruction Funct3 Values
// ============================================================================
// Distinguishes between different store operations
typedef enum bit [2 : 0] {
  ST_BYTE = 3'b000, // SB - Store byte
  ST_HALF = 3'b001, // SH - Store halfword
  ST_WORD = 3'b010  // SW - Store word
} store_funct3_t;

// ============================================================================
// CSR Operation Funct3 Values
// ============================================================================
// Atomic read-modify-write operations on Control Status Registers
typedef enum bit [2 : 0] {
  CSR_RW = 3'b001, // CSRRW  - Atomic Read/Write (rd = old_csr, csr = rs1)
  CSR_RS = 3'b010, // CSRRS  - Atomic Read and Set Bits (rd = old_csr, csr =
                   // old_csr | rs1)
  CSR_RC = 3'b011, // CSRRC  - Atomic Read and Clear Bits (rd = old_csr, csr =
                   // old_csr & ~rs1)
  CSR_RWI =
      3'b101, // CSRRWI - Atomic Read/Write Immediate (rd = old_csr, csr = imm)
  CSR_RSI = 3'b110, // CSRRSI - Atomic Read and Set Bits Immediate (rd =
                    // old_csr, csr = old_csr | imm)
  CSR_RCI = 3'b111  // CSRRCI - Atomic Read and Clear Bits Immediate (rd =
                    // old_csr, csr = old_csr & ~imm)
} csr_op_t;

`endif
