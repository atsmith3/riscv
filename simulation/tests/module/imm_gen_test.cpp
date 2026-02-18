/*
 * Immediate Generator Module-Level Tests
 *
 * Unit tests for the RISC-V 32-bit immediate generator using reference model
 * verification. Tests all instruction format types (I, S, B, U, J) and
 * immediate sign extension.
 */

#include "Vimm_gen_32.h"
#include <boost/test/unit_test.hpp>
#include <cstdint>
#include <verilated.h>

// Instruction format types (matching datatypes.sv instr_format_t)
constexpr uint8_t INSTR_R = 0;
constexpr uint8_t INSTR_I = 1;
constexpr uint8_t INSTR_S = 2;
constexpr uint8_t INSTR_B = 3;
constexpr uint8_t INSTR_U = 4;
constexpr uint8_t INSTR_J = 5;
constexpr uint8_t INSTR_ERR = 6;

// Strip bits [6:0] (opcode) to match the [31:7] Verilator port mapping
static inline uint32_t to_ir(uint32_t instruction) {
    return instruction >> 7;
}

/**
 * Reference model for immediate generation
 * Matches the logic in imm_gen.sv
 */
uint32_t ref_imm_gen(uint32_t ir, uint8_t instr_type) {
  uint32_t imm = 0;

  switch (instr_type) {
  case INSTR_I: {
    // I-type: bits [31:20], sign-extended
    uint32_t imm_bits = (ir >> 20) & 0xFFF;
    bool sign = (ir >> 31) & 1;
    imm = sign ? (imm_bits | 0xFFFFF000) : imm_bits;
    break;
  }
  case INSTR_S: {
    // S-type: bits [31:25] and [11:7], sign-extended
    uint32_t upper = (ir >> 25) & 0x7F;
    uint32_t lower = (ir >> 7) & 0x1F;
    uint32_t imm_bits = (upper << 5) | lower;
    bool sign = (ir >> 31) & 1;
    imm = sign ? (imm_bits | 0xFFFFF000) : imm_bits;
    break;
  }
  case INSTR_B: {
    // B-type: bits [31], [7], [30:25], [11:8], LSB=0, sign-extended
    bool bit_12 = (ir >> 31) & 1;
    bool bit_11 = (ir >> 7) & 1;
    uint32_t bits_10_5 = (ir >> 25) & 0x3F;
    uint32_t bits_4_1 = (ir >> 8) & 0xF;
    uint32_t imm_bits =
        (bit_12 << 12) | (bit_11 << 11) | (bits_10_5 << 5) | (bits_4_1 << 1);
    bool sign = bit_12;
    imm = sign ? (imm_bits | 0xFFFFE000) : imm_bits;
    break;
  }
  case INSTR_U: {
    // U-type: bits [31:12] in upper 20 bits, lower 12 bits = 0
    imm = ir & 0xFFFFF000;
    break;
  }
  case INSTR_J: {
    // J-type: bits [31], [19:12], [20], [30:21], LSB=0, sign-extended
    bool bit_20 = (ir >> 31) & 1;
    uint32_t bits_19_12 = (ir >> 12) & 0xFF;
    bool bit_11 = (ir >> 20) & 1;
    uint32_t bits_10_1 = (ir >> 21) & 0x3FF;
    uint32_t imm_bits =
        (bit_20 << 20) | (bits_19_12 << 12) | (bit_11 << 11) | (bits_10_1 << 1);
    bool sign = bit_20;
    imm = sign ? (imm_bits | 0xFFE00000) : imm_bits;
    break;
  }
  case INSTR_R: {
    // R-type: For shift immediate instructions (SLLI, SRLI, SRAI)
    // Extract shift amount from bits [24:20] (shamt field)
    imm = (ir >> 20) & 0x1F;
    break;
  }
  default:
    imm = 0;
    break;
  }

  return imm;
}

/**
 * Helper to construct instruction with immediate fields
 */
uint32_t construct_i_type(uint32_t imm_11_0) {
  return (imm_11_0 & 0xFFF) << 20;
}

uint32_t construct_s_type(uint32_t imm_11_0) {
  uint32_t upper = (imm_11_0 >> 5) & 0x7F;
  uint32_t lower = imm_11_0 & 0x1F;
  return (upper << 25) | (lower << 7);
}

uint32_t construct_b_type(uint32_t imm_12_1) {
  bool bit_12 = (imm_12_1 >> 12) & 1;
  bool bit_11 = (imm_12_1 >> 11) & 1;
  uint32_t bits_10_5 = (imm_12_1 >> 5) & 0x3F;
  uint32_t bits_4_1 = (imm_12_1 >> 1) & 0xF;
  return (bit_12 ? (1U << 31) : 0) | (bits_10_5 << 25) | (bits_4_1 << 8) |
         (bit_11 ? (1U << 7) : 0);
}

uint32_t construct_u_type(uint32_t imm_31_12) {
  return (imm_31_12 & 0xFFFFF) << 12;
}

uint32_t construct_j_type(uint32_t imm_20_1) {
  bool bit_20 = (imm_20_1 >> 20) & 1;
  uint32_t bits_19_12 = (imm_20_1 >> 12) & 0xFF;
  bool bit_11 = (imm_20_1 >> 11) & 1;
  uint32_t bits_10_1 = (imm_20_1 >> 1) & 0x3FF;
  return (bit_20 ? (1U << 31) : 0) | (bits_10_1 << 21) |
         (bit_11 ? (1U << 20) : 0) | (bits_19_12 << 12);
}

BOOST_AUTO_TEST_SUITE(ImmGen_ModuleTests)

// Test I-type immediate generation
BOOST_AUTO_TEST_CASE(imm_gen_i_type) {
  Vimm_gen_32 *dut = new Vimm_gen_32();

  dut->instr_type = INSTR_I;

  // Positive immediate: 100 (0x064)
  dut->ir = to_ir(construct_i_type(100));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 100);

  // Negative immediate: -100 (0xF9C as 12-bit)
  dut->ir = to_ir(construct_i_type(0xF9C));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, static_cast<uint32_t>(-100));

  // Zero immediate
  dut->ir = to_ir(construct_i_type(0));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0);

  // Max positive 12-bit: 2047 (0x7FF)
  dut->ir = to_ir(construct_i_type(0x7FF));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 2047);

  // Max negative 12-bit: -2048 (0x800)
  dut->ir = to_ir(construct_i_type(0x800));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, static_cast<uint32_t>(-2048));

  // All ones: -1
  dut->ir = to_ir(construct_i_type(0xFFF));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, static_cast<uint32_t>(-1));

  delete dut;
}

// Test S-type immediate generation
BOOST_AUTO_TEST_CASE(imm_gen_s_type) {
  Vimm_gen_32 *dut = new Vimm_gen_32();

  dut->instr_type = INSTR_S;

  // Positive immediate: 100
  dut->ir = to_ir(construct_s_type(100));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 100);

  // Negative immediate: -100
  dut->ir = to_ir(construct_s_type(0xF9C));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, static_cast<uint32_t>(-100));

  // Zero immediate
  dut->ir = to_ir(construct_s_type(0));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0);

  // Max positive: 2047
  dut->ir = to_ir(construct_s_type(0x7FF));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 2047);

  // Max negative: -2048
  dut->ir = to_ir(construct_s_type(0x800));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, static_cast<uint32_t>(-2048));

  // Different bit patterns to test field extraction
  uint32_t s_instr = construct_s_type(0x555);
  dut->ir = to_ir(s_instr);
  dut->eval();
  uint32_t expected_555 = ref_imm_gen(s_instr, INSTR_S);
  BOOST_CHECK_EQUAL(dut->imm, expected_555);

  delete dut;
}

// Test B-type immediate generation
BOOST_AUTO_TEST_CASE(imm_gen_b_type) {
  Vimm_gen_32 *dut = new Vimm_gen_32();

  dut->instr_type = INSTR_B;

  // Positive branch offset: +8
  dut->ir = to_ir(construct_b_type(8));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 8);
  BOOST_CHECK_EQUAL(dut->imm & 1, 0); // LSB must be 0

  // Negative branch offset: -8
  dut->ir = to_ir(construct_b_type(static_cast<uint32_t>(-8)));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, static_cast<uint32_t>(-8));
  BOOST_CHECK_EQUAL(dut->imm & 1, 0); // LSB must be 0

  // Zero offset
  dut->ir = to_ir(construct_b_type(0));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0);

  // Max positive: 4094 (0xFFE)
  dut->ir = to_ir(construct_b_type(0xFFE));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 4094);

  // Max negative: -4096 (0x1000)
  dut->ir = to_ir(construct_b_type(0x1000));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, static_cast<uint32_t>(-4096));

  // Verify LSB is always 0 for various values
  for (int i = 0; i < 10; i++) {
    uint32_t offset_bits = (i * 100) & 0x1FFE; // Ensure bit 0 is 0
    dut->ir = to_ir(construct_b_type(offset_bits));
    dut->eval();
    BOOST_CHECK_EQUAL(dut->imm & 1, 0);
  }

  delete dut;
}

// Test U-type immediate generation
BOOST_AUTO_TEST_CASE(imm_gen_u_type) {
  Vimm_gen_32 *dut = new Vimm_gen_32();

  dut->instr_type = INSTR_U;

  // Upper immediate: 0x12345 -> 0x12345000
  dut->ir = to_ir(construct_u_type(0x12345));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0x12345000);

  // Zero upper immediate
  dut->ir = to_ir(construct_u_type(0));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0);

  // All ones upper: 0xFFFFF -> 0xFFFFF000
  dut->ir = to_ir(construct_u_type(0xFFFFF));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0xFFFFF000);

  // Verify lower 12 bits are always 0
  dut->ir = to_ir(construct_u_type(0xABCDE));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm & 0xFFF, 0);
  BOOST_CHECK_EQUAL(dut->imm, 0xABCDE000);

  // Test that only upper 20 bits are used (extra bits ignored)
  dut->ir = to_ir(0xFFFFF123);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0xFFFFF000);

  delete dut;
}

// Test J-type immediate generation
BOOST_AUTO_TEST_CASE(imm_gen_j_type) {
  Vimm_gen_32 *dut = new Vimm_gen_32();

  dut->instr_type = INSTR_J;

  // Positive jump offset: +8
  dut->ir = to_ir(construct_j_type(8));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 8);
  BOOST_CHECK_EQUAL(dut->imm & 1, 0); // LSB must be 0

  // Negative jump offset: -100
  dut->ir = to_ir(construct_j_type(static_cast<uint32_t>(-100)));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, static_cast<uint32_t>(-100));
  BOOST_CHECK_EQUAL(dut->imm & 1, 0); // LSB must be 0

  // Zero offset
  dut->ir = to_ir(construct_j_type(0));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0);

  // Large positive offset: 0x7FFFE (max positive 21-bit, mult of 2)
  dut->ir = to_ir(construct_j_type(0xFFFFE));
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0x000FFFFE);

  // Large negative offset
  dut->ir = to_ir(construct_j_type(0x100000)); // Bit 20 set (sign bit)
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, static_cast<uint32_t>(-1048576));

  // Verify LSB is always 0
  for (int i = 0; i < 10; i++) {
    uint32_t offset_bits = (i * 1000) & 0x1FFFFE;
    dut->ir = to_ir(construct_j_type(offset_bits));
    dut->eval();
    BOOST_CHECK_EQUAL(dut->imm & 1, 0);
  }

  delete dut;
}

// Test R-type (should return shift amount from bits [24:20])
BOOST_AUTO_TEST_CASE(imm_gen_r_type) {
  Vimm_gen_32 *dut = new Vimm_gen_32();

  dut->instr_type = INSTR_R;
  dut->ir = to_ir(0xFFFFFFFF); // All bits set, shamt = 0x1F (31)
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0x1F);

  dut->ir = to_ir(0x12345678); // bits[24:20] = 0x03
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0x03);

  delete dut;
}

// Test error type (should return 0)
BOOST_AUTO_TEST_CASE(imm_gen_error_type) {
  Vimm_gen_32 *dut = new Vimm_gen_32();

  dut->instr_type = INSTR_ERR;
  dut->ir = to_ir(0xFFFFFFFF);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0);

  delete dut;
}

// Test with real RISC-V instruction encodings
BOOST_AUTO_TEST_CASE(imm_gen_real_instructions) {
  Vimm_gen_32 *dut = new Vimm_gen_32();

  // ADDI x5, x0, 10  (I-type: imm=10)
  // Format: imm[11:0] | rs1[4:0] | 000 | rd[4:0] | 0010011
  dut->instr_type = INSTR_I;
  uint32_t addi_instr = (10 << 20) | (0 << 15) | (0 << 12) | (5 << 7) | 0b0010011;
  dut->ir = to_ir(addi_instr);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 10);

  // LUI x10, 0x12345  (U-type: imm=0x12345000)
  dut->instr_type = INSTR_U;
  uint32_t lui_instr = (0x12345 << 12) | (10 << 7) | 0b0110111;
  dut->ir = to_ir(lui_instr);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0x12345000);

  // SW x5, 100(x2)  (S-type: imm=100)
  // Format: imm[11:5] | rs2[4:0] | rs1[4:0] | 010 | imm[4:0] | 0100011
  uint32_t sw_imm = 100;
  uint32_t sw_upper = (sw_imm >> 5) & 0x7F;
  uint32_t sw_lower = sw_imm & 0x1F;
  dut->instr_type = INSTR_S;
  uint32_t sw_instr = (sw_upper << 25) | (5 << 20) | (2 << 15) | (0b010 << 12) |
            (sw_lower << 7) | 0b0100011;
  dut->ir = to_ir(sw_instr);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 100);

  // BEQ x1, x2, -8  (B-type: imm=-8)
  dut->instr_type = INSTR_B;
  uint32_t beq_instr = construct_b_type(static_cast<uint32_t>(-8));
  beq_instr |= (2 << 20) | (1 << 15) | (0b000 << 12) | 0b1100011;
  dut->ir = to_ir(beq_instr);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, static_cast<uint32_t>(-8));

  // JAL x1, 2048  (J-type: imm=2048)
  dut->instr_type = INSTR_J;
  uint32_t jal_instr = construct_j_type(2048);
  jal_instr |= (1 << 7) | 0b1101111;
  dut->ir = to_ir(jal_instr);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 2048);

  delete dut;
}

// Test sign extension correctness
BOOST_AUTO_TEST_CASE(imm_gen_sign_extension) {
  Vimm_gen_32 *dut = new Vimm_gen_32();

  // I-type: negative value should have upper bits set
  dut->instr_type = INSTR_I;
  dut->ir = to_ir(construct_i_type(0xFFF)); // -1
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0xFFFFFFFF);

  // S-type: negative value
  dut->instr_type = INSTR_S;
  dut->ir = to_ir(construct_s_type(0xFFF)); // -1
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0xFFFFFFFF);

  // B-type: negative value
  dut->instr_type = INSTR_B;
  dut->ir = to_ir(construct_b_type(0x1FFE)); // All bits set except LSB
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0xFFFFFFFE); // -2 (sign extended, LSB=0)

  // J-type: negative value
  dut->instr_type = INSTR_J;
  dut->ir = to_ir(construct_j_type(0x1FFFFE)); // All bits set except LSB
  dut->eval();
  BOOST_CHECK_EQUAL(dut->imm, 0xFFFFFFFE); // -2 (sign extended, LSB=0)

  delete dut;
}

// Test against reference model with various patterns
BOOST_AUTO_TEST_CASE(imm_gen_reference_model) {
  Vimm_gen_32 *dut = new Vimm_gen_32();

  // Test various instruction patterns
  uint32_t test_patterns[] = {
      0x00000000, 0xFFFFFFFF, 0x12345678, 0xABCDEF01,
      0x55555555, 0xAAAAAAAA, 0x7FFFFFFF, 0x80000000,
  };

  uint8_t instr_types[] = {INSTR_R, INSTR_I, INSTR_S,  INSTR_B,
                           INSTR_U, INSTR_J, INSTR_ERR};

  for (uint32_t pattern : test_patterns) {
    for (uint8_t type : instr_types) {
      dut->ir = to_ir(pattern);
      dut->instr_type = type;
      dut->eval();

      uint32_t expected = ref_imm_gen(pattern, type);
      BOOST_CHECK_MESSAGE(dut->imm == expected,
                          "Pattern: 0x" << std::hex << pattern << " Type: "
                                        << (int)type << " Expected: 0x"
                                        << expected << " Got: 0x" << dut->imm);
    }
  }

  delete dut;
}

BOOST_AUTO_TEST_SUITE_END()
