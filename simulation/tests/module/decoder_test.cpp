/*
 * Instruction Decoder Module-Level Tests
 *
 * Unit tests for the RISC-V instruction decoder (ir_decoder) module.
 * Tests instruction format detection, field extraction, and immediate
 * generation for all RISC-V 32I instruction types.
 */

#include "Vir_decoder.h"
#include <boost/test/unit_test.hpp>
#include <cstdint>
#include <verilated.h>

// Instruction format types (matching datatypes.sv)
constexpr uint8_t INSTR_R = 0;
constexpr uint8_t INSTR_I = 1;
constexpr uint8_t INSTR_S = 2;
constexpr uint8_t INSTR_B = 3;
constexpr uint8_t INSTR_U = 4;
constexpr uint8_t INSTR_J = 5;
constexpr uint8_t INSTR_ERR = 6;

// Opcodes (matching datatypes.sv)
constexpr uint8_t OP_LUI = 0b0110111;
constexpr uint8_t OP_AUIPC = 0b0010111;
constexpr uint8_t OP_JAL = 0b1101111;
constexpr uint8_t OP_JALR = 0b1100111;
constexpr uint8_t OP_BRANCH = 0b1100011;
constexpr uint8_t OP_LD = 0b0000011;
constexpr uint8_t OP_ST = 0b0100011;
constexpr uint8_t OP_ALUI = 0b0010011;
constexpr uint8_t OP_ALU = 0b0110011;
constexpr uint8_t OP_FENCE = 0b0001111;
constexpr uint8_t OP_ECSR = 0b1110011;

/**
 * Helper function to construct RISC-V instructions
 */
struct Instruction {
  uint32_t opcode : 7;
  uint32_t rd : 5;
  uint32_t funct3 : 3;
  uint32_t rs1 : 5;
  uint32_t rs2 : 5;
  uint32_t funct7 : 7;

  uint32_t encode() const {
    return opcode | (rd << 7) | (funct3 << 12) | (rs1 << 15) | (rs2 << 20) |
           (funct7 << 25);
  }
};

// Construct R-type instruction
uint32_t make_r_type(uint8_t opcode, uint8_t rd, uint8_t funct3, uint8_t rs1,
                     uint8_t rs2, uint8_t funct7) {
  return opcode | (rd << 7) | (funct3 << 12) | (rs1 << 15) | (rs2 << 20) |
         (funct7 << 25);
}

// Construct I-type instruction
uint32_t make_i_type(uint8_t opcode, uint8_t rd, uint8_t funct3, uint8_t rs1,
                     uint16_t imm) {
  return opcode | (rd << 7) | (funct3 << 12) | (rs1 << 15) |
         ((imm & 0xFFF) << 20);
}

// Construct S-type instruction
uint32_t make_s_type(uint8_t opcode, uint8_t funct3, uint8_t rs1, uint8_t rs2,
                     uint16_t imm) {
  uint32_t imm_11_5 = (imm >> 5) & 0x7F;
  uint32_t imm_4_0 = imm & 0x1F;
  return opcode | (imm_4_0 << 7) | (funct3 << 12) | (rs1 << 15) | (rs2 << 20) |
         (imm_11_5 << 25);
}

// Construct B-type instruction
uint32_t make_b_type(uint8_t opcode, uint8_t funct3, uint8_t rs1, uint8_t rs2,
                     uint16_t imm) {
  bool bit_12 = (imm >> 12) & 1;
  bool bit_11 = (imm >> 11) & 1;
  uint32_t bits_10_5 = (imm >> 5) & 0x3F;
  uint32_t bits_4_1 = (imm >> 1) & 0xF;
  return opcode | (bit_11 ? (1 << 7) : 0) | (bits_4_1 << 8) | (funct3 << 12) |
         (rs1 << 15) | (rs2 << 20) | (bits_10_5 << 25) |
         (bit_12 ? (1U << 31) : 0);
}

// Construct U-type instruction
uint32_t make_u_type(uint8_t opcode, uint8_t rd, uint32_t imm) {
  return opcode | (rd << 7) | (imm & 0xFFFFF000);
}

// Construct J-type instruction
uint32_t make_j_type(uint8_t opcode, uint8_t rd, uint32_t imm) {
  bool bit_20 = (imm >> 20) & 1;
  uint32_t bits_19_12 = (imm >> 12) & 0xFF;
  bool bit_11 = (imm >> 11) & 1;
  uint32_t bits_10_1 = (imm >> 1) & 0x3FF;
  return opcode | (rd << 7) | (bits_19_12 << 12) | (bit_11 ? (1 << 20) : 0) |
         (bits_10_1 << 21) | (bit_20 ? (1U << 31) : 0);
}

BOOST_AUTO_TEST_SUITE(Decoder_ModuleTests)

// Test R-type instruction decoding (e.g., ADD, SUB, SLL, etc.)
BOOST_AUTO_TEST_CASE(decoder_r_type) {
  Vir_decoder *dut = new Vir_decoder();

  // ADD x5, x6, x7 (R-type: opcode=0110011, funct3=000, funct7=0000000)
  uint32_t add_instr = make_r_type(OP_ALU, 5, 0b000, 6, 7, 0b0000000);
  dut->ir = add_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_R);
  BOOST_CHECK_EQUAL(dut->opcode, OP_ALU);
  BOOST_CHECK_EQUAL(dut->rd, 5);
  BOOST_CHECK_EQUAL(dut->funct3, 0b000);
  BOOST_CHECK_EQUAL(dut->rs1, 6);
  BOOST_CHECK_EQUAL(dut->rs2, 7);
  BOOST_CHECK_EQUAL(dut->funct7, 0b0000000);
  BOOST_CHECK_EQUAL(dut->arithmetic, 0); // ADD (bit 30 = 0)
  BOOST_CHECK_EQUAL(dut->immediate,
                    7); // R-type immediate = bits[24:20] = rs2 field

  // SUB x1, x2, x3 (funct7=0100000 distinguishes from ADD)
  uint32_t sub_instr = make_r_type(OP_ALU, 1, 0b000, 2, 3, 0b0100000);
  dut->ir = sub_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_R);
  BOOST_CHECK_EQUAL(dut->rd, 1);
  BOOST_CHECK_EQUAL(dut->rs1, 2);
  BOOST_CHECK_EQUAL(dut->rs2, 3);
  BOOST_CHECK_EQUAL(dut->funct7, 0b0100000);
  BOOST_CHECK_EQUAL(dut->arithmetic, 1); // SUB (bit 30 = 1)

  // SRA x10, x11, x12 (shift right arithmetic, funct7=0100000)
  uint32_t sra_instr = make_r_type(OP_ALU, 10, 0b101, 11, 12, 0b0100000);
  dut->ir = sra_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_R);
  BOOST_CHECK_EQUAL(dut->funct3, 0b101);
  BOOST_CHECK_EQUAL(dut->arithmetic, 1); // SRA (bit 30 = 1)

  delete dut;
}

// Test I-type instruction decoding (ADDI, LW, JALR, etc.)
BOOST_AUTO_TEST_CASE(decoder_i_type) {
  Vir_decoder *dut = new Vir_decoder();

  // ADDI x5, x6, 100 (I-type: opcode=0010011, funct3=000)
  uint32_t addi_instr = make_i_type(OP_ALUI, 5, 0b000, 6, 100);
  dut->ir = addi_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_I);
  BOOST_CHECK_EQUAL(dut->opcode, OP_ALUI);
  BOOST_CHECK_EQUAL(dut->rd, 5);
  BOOST_CHECK_EQUAL(dut->funct3, 0b000);
  BOOST_CHECK_EQUAL(dut->rs1, 6);
  BOOST_CHECK_EQUAL(dut->immediate, 100);

  // LW x1, 50(x2) (Load word: opcode=0000011, funct3=010)
  uint32_t lw_instr = make_i_type(OP_LD, 1, 0b010, 2, 50);
  dut->ir = lw_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_I);
  BOOST_CHECK_EQUAL(dut->opcode, OP_LD);
  BOOST_CHECK_EQUAL(dut->rd, 1);
  BOOST_CHECK_EQUAL(dut->funct3, 0b010);
  BOOST_CHECK_EQUAL(dut->rs1, 2);
  BOOST_CHECK_EQUAL(dut->immediate, 50);

  // JALR x1, x2, 8 (Jump and link register: opcode=1100111)
  uint32_t jalr_instr = make_i_type(OP_JALR, 1, 0b000, 2, 8);
  dut->ir = jalr_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_I);
  BOOST_CHECK_EQUAL(dut->opcode, OP_JALR);
  BOOST_CHECK_EQUAL(dut->rd, 1);
  BOOST_CHECK_EQUAL(dut->rs1, 2);
  BOOST_CHECK_EQUAL(dut->immediate, 8);

  // Test negative immediate (sign extension)
  uint32_t addi_neg = make_i_type(OP_ALUI, 10, 0b000, 11, 0xFFF); // -1
  dut->ir = addi_neg;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_I);
  BOOST_CHECK_EQUAL(dut->immediate, 0xFFFFFFFF); // Sign-extended -1

  delete dut;
}

// Test S-type instruction decoding (SW, SH, SB)
BOOST_AUTO_TEST_CASE(decoder_s_type) {
  Vir_decoder *dut = new Vir_decoder();

  // SW x5, 100(x6) (Store word: opcode=0100011, funct3=010)
  uint32_t sw_instr = make_s_type(OP_ST, 0b010, 6, 5, 100);
  dut->ir = sw_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_S);
  BOOST_CHECK_EQUAL(dut->opcode, OP_ST);
  BOOST_CHECK_EQUAL(dut->funct3, 0b010);
  BOOST_CHECK_EQUAL(dut->rs1, 6); // Base register
  BOOST_CHECK_EQUAL(dut->rs2, 5); // Source register
  BOOST_CHECK_EQUAL(dut->immediate, 100);

  // SH x1, 50(x2) (Store halfword: funct3=001)
  uint32_t sh_instr = make_s_type(OP_ST, 0b001, 2, 1, 50);
  dut->ir = sh_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_S);
  BOOST_CHECK_EQUAL(dut->funct3, 0b001);
  BOOST_CHECK_EQUAL(dut->rs1, 2);
  BOOST_CHECK_EQUAL(dut->rs2, 1);
  BOOST_CHECK_EQUAL(dut->immediate, 50);

  // SB x3, -4(x4) (Store byte: funct3=000, negative offset)
  uint32_t sb_instr = make_s_type(OP_ST, 0b000, 4, 3, 0xFFC); // -4 as 12-bit
  dut->ir = sb_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_S);
  BOOST_CHECK_EQUAL(dut->funct3, 0b000);
  BOOST_CHECK_EQUAL(dut->rs1, 4);
  BOOST_CHECK_EQUAL(dut->rs2, 3);
  BOOST_CHECK_EQUAL(dut->immediate, static_cast<uint32_t>(-4)); // Sign-extended

  delete dut;
}

// Test B-type instruction decoding (BEQ, BNE, BLT, etc.)
BOOST_AUTO_TEST_CASE(decoder_b_type) {
  Vir_decoder *dut = new Vir_decoder();

  // BEQ x1, x2, 8 (Branch if equal: opcode=1100011, funct3=000)
  uint32_t beq_instr = make_b_type(OP_BRANCH, 0b000, 1, 2, 8);
  dut->ir = beq_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_B);
  BOOST_CHECK_EQUAL(dut->opcode, OP_BRANCH);
  BOOST_CHECK_EQUAL(dut->funct3, 0b000);
  BOOST_CHECK_EQUAL(dut->rs1, 1);
  BOOST_CHECK_EQUAL(dut->rs2, 2);
  BOOST_CHECK_EQUAL(dut->immediate, 8);
  BOOST_CHECK_EQUAL(dut->immediate & 1, 0); // LSB always 0

  // BLT x5, x6, -16 (Branch if less than: funct3=100)
  uint32_t blt_instr =
      make_b_type(OP_BRANCH, 0b100, 5, 6, static_cast<uint16_t>(-16));
  dut->ir = blt_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_B);
  BOOST_CHECK_EQUAL(dut->funct3, 0b100);
  BOOST_CHECK_EQUAL(dut->rs1, 5);
  BOOST_CHECK_EQUAL(dut->rs2, 6);
  BOOST_CHECK_EQUAL(dut->immediate, static_cast<uint32_t>(-16));
  BOOST_CHECK_EQUAL(dut->immediate & 1, 0); // LSB always 0

  delete dut;
}

// Test U-type instruction decoding (LUI, AUIPC)
BOOST_AUTO_TEST_CASE(decoder_u_type) {
  Vir_decoder *dut = new Vir_decoder();

  // LUI x5, 0x12345 (Load upper immediate: opcode=0110111)
  uint32_t lui_instr = make_u_type(OP_LUI, 5, 0x12345000);
  dut->ir = lui_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_U);
  BOOST_CHECK_EQUAL(dut->opcode, OP_LUI);
  BOOST_CHECK_EQUAL(dut->rd, 5);
  BOOST_CHECK_EQUAL(dut->immediate, 0x12345000);

  // AUIPC x10, 0xABCDE (Add upper immediate to PC: opcode=0010111)
  uint32_t auipc_instr = make_u_type(OP_AUIPC, 10, 0xABCDE000);
  dut->ir = auipc_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_U);
  BOOST_CHECK_EQUAL(dut->opcode, OP_AUIPC);
  BOOST_CHECK_EQUAL(dut->rd, 10);
  BOOST_CHECK_EQUAL(dut->immediate, 0xABCDE000);

  delete dut;
}

// Test J-type instruction decoding (JAL)
BOOST_AUTO_TEST_CASE(decoder_j_type) {
  Vir_decoder *dut = new Vir_decoder();

  // JAL x1, 2048 (Jump and link: opcode=1101111)
  uint32_t jal_instr = make_j_type(OP_JAL, 1, 2048);
  dut->ir = jal_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_J);
  BOOST_CHECK_EQUAL(dut->opcode, OP_JAL);
  BOOST_CHECK_EQUAL(dut->rd, 1);
  BOOST_CHECK_EQUAL(dut->immediate, 2048);
  BOOST_CHECK_EQUAL(dut->immediate & 1, 0); // LSB always 0

  // JAL x0, -100 (Unconditional jump, no link when rd=x0)
  uint32_t jal_neg = make_j_type(OP_JAL, 0, static_cast<uint32_t>(-100));
  dut->ir = jal_neg;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_J);
  BOOST_CHECK_EQUAL(dut->rd, 0);
  BOOST_CHECK_EQUAL(dut->immediate, static_cast<uint32_t>(-100));
  BOOST_CHECK_EQUAL(dut->immediate & 1, 0); // LSB always 0

  delete dut;
}

// Test FENCE instruction field extraction
BOOST_AUTO_TEST_CASE(decoder_fence) {
  Vir_decoder *dut = new Vir_decoder();

  // FENCE instruction (opcode=0001111, funct3=000)
  // Format: fm[3:0] | pred[3:0] | succ[3:0] | rs1 | funct3 | rd | opcode
  uint32_t fence_instr = OP_FENCE;
  fence_instr |= (0b0000 << 7);   // rd = 0
  fence_instr |= (0b000 << 12);   // funct3 = 000
  fence_instr |= (0b00000 << 15); // rs1 = 0
  fence_instr |= (0b0011 << 20);  // succ = 0011 (w+r)
  fence_instr |= (0b0011 << 24);  // pred = 0011 (w+r)
  fence_instr |= (0b0000 << 28);  // fm = 0000

  dut->ir = fence_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_I); // FENCE uses I-type format
  BOOST_CHECK_EQUAL(dut->opcode, OP_FENCE);
  BOOST_CHECK_EQUAL(dut->succ, 0b0011);
  BOOST_CHECK_EQUAL(dut->pred, 0b0011);
  BOOST_CHECK_EQUAL(dut->fm, 0b0000);

  delete dut;
}

// Test EBREAK detection
BOOST_AUTO_TEST_CASE(decoder_ebreak) {
  Vir_decoder *dut = new Vir_decoder();

  // EBREAK instruction (opcode=1110011, funct3=000, imm=000000000001)
  uint32_t ebreak_instr = OP_ECSR | (0b000 << 12) | (0b000000000001 << 20);
  dut->ir = ebreak_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_I);
  BOOST_CHECK_EQUAL(dut->opcode, OP_ECSR);
  BOOST_CHECK_EQUAL(dut->ebreak, 1);

  // ECALL instruction (imm=000000000000, not EBREAK)
  uint32_t ecall_instr = OP_ECSR | (0b000 << 12) | (0b000000000000 << 20);
  dut->ir = ecall_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_I);
  BOOST_CHECK_EQUAL(dut->opcode, OP_ECSR);
  BOOST_CHECK_EQUAL(dut->ebreak, 0);

  delete dut;
}

// Test all valid opcodes
BOOST_AUTO_TEST_CASE(decoder_all_opcodes) {
  Vir_decoder *dut = new Vir_decoder();

  struct OpcodeTest {
    uint8_t opcode;
    uint8_t expected_type;
  };

  OpcodeTest tests[] = {
      {OP_LUI, INSTR_U},   {OP_AUIPC, INSTR_U},  {OP_JAL, INSTR_J},
      {OP_JALR, INSTR_I},  {OP_BRANCH, INSTR_B}, {OP_LD, INSTR_I},
      {OP_ST, INSTR_S},    {OP_ALUI, INSTR_I},   {OP_ALU, INSTR_R},
      {OP_FENCE, INSTR_I}, {OP_ECSR, INSTR_I},
  };

  for (const auto &test : tests) {
    // Create minimal valid instruction with this opcode
    uint32_t instr = test.opcode;
    dut->ir = instr;
    dut->eval();

    BOOST_CHECK_MESSAGE(
        dut->opcode == test.opcode,
        "Opcode: 0x" << std::hex << (int)test.opcode << " Expected opcode: 0x"
                     << (int)test.opcode << " Got: 0x" << (int)dut->opcode);

    BOOST_CHECK_MESSAGE(dut->instr_type == test.expected_type,
                        "Opcode: 0x" << std::hex << (int)test.opcode
                                     << " Expected type: " << std::dec
                                     << (int)test.expected_type
                                     << " Got: " << (int)dut->instr_type);
  }

  delete dut;
}

// Test invalid/reserved opcodes
BOOST_AUTO_TEST_CASE(decoder_invalid_opcodes) {
  Vir_decoder *dut = new Vir_decoder();

  // Test some invalid opcodes
  uint8_t invalid_opcodes[] = {
      0b0000000,
      0b0000001,
      0b0001000,
      0b1111111,
  };

  for (uint8_t opcode : invalid_opcodes) {
    dut->ir = opcode;
    dut->eval();

    BOOST_CHECK_MESSAGE(dut->instr_type == INSTR_ERR,
                        "Invalid opcode 0x"
                            << std::hex << (int)opcode
                            << " should produce INSTR_ERR, got type "
                            << std::dec << (int)dut->instr_type);
  }

  delete dut;
}

// Test field extraction with various bit patterns
BOOST_AUTO_TEST_CASE(decoder_field_extraction) {
  Vir_decoder *dut = new Vir_decoder();

  // Test rd, rs1, rs2 extraction with all registers
  for (int rd = 0; rd < 32; rd++) {
    for (int rs1 = 0; rs1 < 32; rs1++) {
      for (int rs2 = 0; rs2 < 32; rs2 += 7) { // Sample rs2 to reduce test count
        uint32_t instr = make_r_type(OP_ALU, rd, 0b000, rs1, rs2, 0b0000000);
        dut->ir = instr;
        dut->eval();

        BOOST_CHECK_EQUAL(dut->rd, rd);
        BOOST_CHECK_EQUAL(dut->rs1, rs1);
        BOOST_CHECK_EQUAL(dut->rs2, rs2);
      }
    }
  }

  // Test funct3 extraction (0-7)
  for (int funct3 = 0; funct3 < 8; funct3++) {
    uint32_t instr = make_r_type(OP_ALU, 1, funct3, 2, 3, 0);
    dut->ir = instr;
    dut->eval();
    BOOST_CHECK_EQUAL(dut->funct3, funct3);
  }

  // Test funct7 extraction
  for (int funct7 = 0; funct7 < 128; funct7 += 16) { // Sample values
    uint32_t instr = make_r_type(OP_ALU, 1, 0, 2, 3, funct7);
    dut->ir = instr;
    dut->eval();
    BOOST_CHECK_EQUAL(dut->funct7, funct7);
  }

  delete dut;
}

// Test arithmetic bit (bit 30) for distinguishing ADD/SUB, SRL/SRA
BOOST_AUTO_TEST_CASE(decoder_arithmetic_bit) {
  Vir_decoder *dut = new Vir_decoder();

  // ADD: arithmetic = 0 (bit 30 = 0)
  uint32_t add_instr = make_r_type(OP_ALU, 1, 0b000, 2, 3, 0b0000000);
  dut->ir = add_instr;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->arithmetic, 0);

  // SUB: arithmetic = 1 (bit 30 = 1)
  uint32_t sub_instr = make_r_type(OP_ALU, 1, 0b000, 2, 3, 0b0100000);
  dut->ir = sub_instr;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->arithmetic, 1);

  // SRL: arithmetic = 0 (bit 30 = 0)
  uint32_t srl_instr = make_r_type(OP_ALU, 1, 0b101, 2, 3, 0b0000000);
  dut->ir = srl_instr;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->arithmetic, 0);

  // SRA: arithmetic = 1 (bit 30 = 1)
  uint32_t sra_instr = make_r_type(OP_ALU, 1, 0b101, 2, 3, 0b0100000);
  dut->ir = sra_instr;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->arithmetic, 1);

  delete dut;
}

// Test with real RISC-V assembly examples
BOOST_AUTO_TEST_CASE(decoder_real_instructions) {
  Vir_decoder *dut = new Vir_decoder();

  // addi x5, x0, 42  (li pseudo-instruction)
  dut->ir = make_i_type(OP_ALUI, 5, 0b000, 0, 42);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_I);
  BOOST_CHECK_EQUAL(dut->rd, 5);
  BOOST_CHECK_EQUAL(dut->rs1, 0);
  BOOST_CHECK_EQUAL(dut->immediate, 42);

  // add x1, x2, x3
  dut->ir = make_r_type(OP_ALU, 1, 0b000, 2, 3, 0b0000000);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_R);
  BOOST_CHECK_EQUAL(dut->rd, 1);
  BOOST_CHECK_EQUAL(dut->rs1, 2);
  BOOST_CHECK_EQUAL(dut->rs2, 3);

  // lw x4, 100(x5)
  dut->ir = make_i_type(OP_LD, 4, 0b010, 5, 100);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_I);
  BOOST_CHECK_EQUAL(dut->rd, 4);
  BOOST_CHECK_EQUAL(dut->rs1, 5);
  BOOST_CHECK_EQUAL(dut->immediate, 100);

  // sw x6, 200(x7)
  dut->ir = make_s_type(OP_ST, 0b010, 7, 6, 200);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_S);
  BOOST_CHECK_EQUAL(dut->rs1, 7);
  BOOST_CHECK_EQUAL(dut->rs2, 6);
  BOOST_CHECK_EQUAL(dut->immediate, 200);

  // beq x8, x9, 16
  dut->ir = make_b_type(OP_BRANCH, 0b000, 8, 9, 16);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_B);
  BOOST_CHECK_EQUAL(dut->rs1, 8);
  BOOST_CHECK_EQUAL(dut->rs2, 9);
  BOOST_CHECK_EQUAL(dut->immediate, 16);

  // lui x10, 0x12345
  dut->ir = make_u_type(OP_LUI, 10, 0x12345000);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_U);
  BOOST_CHECK_EQUAL(dut->rd, 10);
  BOOST_CHECK_EQUAL(dut->immediate, 0x12345000);

  // jal x1, 1024
  dut->ir = make_j_type(OP_JAL, 1, 1024);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_J);
  BOOST_CHECK_EQUAL(dut->rd, 1);
  BOOST_CHECK_EQUAL(dut->immediate, 1024);

  delete dut;
}

/**
 * Test FENCE instruction decoding
 */
BOOST_AUTO_TEST_CASE(test_fence_decode) {
  Vir_decoder *dut = new Vir_decoder();

  // FENCE instruction with pred=IORW (1111), succ=IORW (1111), fm=0000
  // Encoding: fm[31:28]=0000, pred[27:24]=1111, succ[23:20]=1111,
  // rs1[19:15]=00000
  //           funct3[14:12]=000, rd[11:7]=00000, opcode[6:0]=0001111
  uint32_t fence_instr = 0x0FF0000F; // fence iorw, iorw
  dut->ir = fence_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->opcode, OP_FENCE);
  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_I);
  BOOST_CHECK_EQUAL(dut->funct3, 0b000); // FENCE has funct3=000
  BOOST_CHECK_EQUAL(dut->fm, 0b0000);    // fm field
  BOOST_CHECK_EQUAL(dut->pred, 0b1111);  // pred=IORW
  BOOST_CHECK_EQUAL(dut->succ, 0b1111);  // succ=IORW
  BOOST_CHECK_EQUAL(dut->rs1, 0);        // Reserved, should be 0
  BOOST_CHECK_EQUAL(dut->rd, 0);         // Reserved, should be 0

  // FENCE with pred=RW (0011), succ=RW (0011)
  fence_instr = 0x0330000F; // fence rw, rw
  dut->ir = fence_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->opcode, OP_FENCE);
  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_I);
  BOOST_CHECK_EQUAL(dut->funct3, 0b000);
  BOOST_CHECK_EQUAL(dut->pred, 0b0011); // pred=RW
  BOOST_CHECK_EQUAL(dut->succ, 0b0011); // succ=RW

  // FENCE with pred=W (0010), succ=R (0001)
  fence_instr = 0x0210000F; // fence w, r
  dut->ir = fence_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->opcode, OP_FENCE);
  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_I);
  BOOST_CHECK_EQUAL(dut->pred, 0b0010); // pred=W
  BOOST_CHECK_EQUAL(dut->succ, 0b0001); // succ=R

  delete dut;
}

/**
 * Test FENCE.I instruction decoding
 */
BOOST_AUTO_TEST_CASE(test_fence_i_decode) {
  Vir_decoder *dut = new Vir_decoder();

  // FENCE.I instruction encoding
  // Encoding: imm[31:20]=000000000000, rs1[19:15]=00000
  //           funct3[14:12]=001, rd[11:7]=00000, opcode[6:0]=0001111
  uint32_t fence_i_instr = 0x0000100F; // fence.i
  dut->ir = fence_i_instr;
  dut->eval();

  BOOST_CHECK_EQUAL(dut->opcode, OP_FENCE);
  BOOST_CHECK_EQUAL(dut->instr_type, INSTR_I);
  BOOST_CHECK_EQUAL(dut->funct3, 0b001); // FENCE.I has funct3=001
  BOOST_CHECK_EQUAL(dut->rs1, 0);        // Reserved, should be 0
  BOOST_CHECK_EQUAL(dut->rd, 0);         // Reserved, should be 0
  BOOST_CHECK_EQUAL(dut->immediate, 0);  // Reserved, should be 0

  delete dut;
}

BOOST_AUTO_TEST_SUITE_END()
