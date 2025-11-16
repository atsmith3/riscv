/*
 * Branch Evaluator Module-Level Tests
 *
 * Unit tests for the RISC-V branch evaluation unit using reference model
 * verification. Tests all branch comparison operations (BEQ, BNE, BLT, BGE,
 * BLTU, BGEU) and exception handling for reserved opcodes.
 */

#include "Vbranch_eval.h"
#include <boost/test/unit_test.hpp>
#include <cstdint>
#include <random>
#include <verilated.h>

// Branch operation codes (matching datatypes.sv branch_t)
constexpr uint8_t BEQ = 0;        // Branch if Equal
constexpr uint8_t BNE = 1;        // Branch if Not Equal
constexpr uint8_t RESERVED_2 = 2; // Reserved
constexpr uint8_t RESERVED_3 = 3; // Reserved
constexpr uint8_t BLT = 4;        // Branch if Less Than (signed)
constexpr uint8_t BGE = 5;        // Branch if Greater or Equal (signed)
constexpr uint8_t BLTU = 6;       // Branch if Less Than Unsigned
constexpr uint8_t BGEU = 7;       // Branch if Greater or Equal Unsigned

/**
 * Reference model for branch evaluation
 * Returns {branch_taken, exception}
 */
std::pair<bool, bool> ref_branch_eval(uint32_t rs1, uint32_t rs2,
                                      uint8_t func) {
  bool branch = false;
  bool exception = false;

  switch (func) {
  case BEQ:
    branch = (rs1 == rs2);
    break;
  case BNE:
    branch = (rs1 != rs2);
    break;
  case BLT:
    branch = (static_cast<int32_t>(rs1) < static_cast<int32_t>(rs2));
    break;
  case BGE:
    branch = (static_cast<int32_t>(rs1) >= static_cast<int32_t>(rs2));
    break;
  case BLTU:
    branch = (rs1 < rs2);
    break;
  case BGEU:
    branch = (rs1 >= rs2);
    break;
  case RESERVED_2:
  case RESERVED_3:
    exception = true;
    branch = false;
    break;
  default:
    exception = true;
    branch = false;
    break;
  }

  return {branch, exception};
}

BOOST_AUTO_TEST_SUITE(BranchEval_ModuleTests)

// Test BEQ (Branch if Equal) operation
BOOST_AUTO_TEST_CASE(branch_eval_beq) {
  Vbranch_eval *dut = new Vbranch_eval();

  dut->func = BEQ;

  // Equal values - should branch
  dut->rs1 = 42;
  dut->rs2 = 42;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Different values - should not branch
  dut->rs1 = 42;
  dut->rs2 = 100;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 0);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Zero values - should branch
  dut->rs1 = 0;
  dut->rs2 = 0;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Max value - should branch
  dut->rs1 = 0xFFFFFFFF;
  dut->rs2 = 0xFFFFFFFF;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  delete dut;
}

// Test BNE (Branch if Not Equal) operation
BOOST_AUTO_TEST_CASE(branch_eval_bne) {
  Vbranch_eval *dut = new Vbranch_eval();

  dut->func = BNE;

  // Different values - should branch
  dut->rs1 = 42;
  dut->rs2 = 100;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Equal values - should not branch
  dut->rs1 = 42;
  dut->rs2 = 42;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 0);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Zero vs non-zero - should branch
  dut->rs1 = 0;
  dut->rs2 = 1;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  delete dut;
}

// Test BLT (Branch if Less Than - signed) operation
BOOST_AUTO_TEST_CASE(branch_eval_blt_signed) {
  Vbranch_eval *dut = new Vbranch_eval();

  dut->func = BLT;

  // Positive: 10 < 20 - should branch
  dut->rs1 = 10;
  dut->rs2 = 20;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Positive: 20 < 10 - should not branch
  dut->rs1 = 20;
  dut->rs2 = 10;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 0);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Equal - should not branch
  dut->rs1 = 15;
  dut->rs2 = 15;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 0);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Signed comparison: -1 < 0 (0xFFFFFFFF < 0x00000000 as signed)
  dut->rs1 = 0xFFFFFFFF; // -1 as signed
  dut->rs2 = 0x00000000; // 0
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Signed comparison: 0 < -1 should not branch
  dut->rs1 = 0x00000000; // 0
  dut->rs2 = 0xFFFFFFFF; // -1 as signed
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 0);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Signed comparison: -100 < -50
  dut->rs1 = static_cast<uint32_t>(-100);
  dut->rs2 = static_cast<uint32_t>(-50);
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Min signed value < max signed value
  dut->rs1 = 0x80000000; // -2147483648 (min signed)
  dut->rs2 = 0x7FFFFFFF; // 2147483647 (max signed)
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  delete dut;
}

// Test BGE (Branch if Greater or Equal - signed) operation
BOOST_AUTO_TEST_CASE(branch_eval_bge_signed) {
  Vbranch_eval *dut = new Vbranch_eval();

  dut->func = BGE;

  // 20 >= 10 - should branch
  dut->rs1 = 20;
  dut->rs2 = 10;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // 15 >= 15 - should branch
  dut->rs1 = 15;
  dut->rs2 = 15;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // 10 >= 20 - should not branch
  dut->rs1 = 10;
  dut->rs2 = 20;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 0);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Signed: 0 >= -1
  dut->rs1 = 0x00000000;
  dut->rs2 = 0xFFFFFFFF; // -1 as signed
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Signed: -1 >= 0 - should not branch
  dut->rs1 = 0xFFFFFFFF; // -1 as signed
  dut->rs2 = 0x00000000;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 0);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  delete dut;
}

// Test BLTU (Branch if Less Than Unsigned) operation
BOOST_AUTO_TEST_CASE(branch_eval_bltu_unsigned) {
  Vbranch_eval *dut = new Vbranch_eval();

  dut->func = BLTU;

  // 10 < 20 - should branch
  dut->rs1 = 10;
  dut->rs2 = 20;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // 20 < 10 - should not branch
  dut->rs1 = 20;
  dut->rs2 = 10;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 0);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Equal - should not branch
  dut->rs1 = 15;
  dut->rs2 = 15;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 0);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Unsigned: 0 < 0xFFFFFFFF (different from signed!)
  dut->rs1 = 0x00000000;
  dut->rs2 = 0xFFFFFFFF;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Unsigned: 0xFFFFFFFF < 0 - should not branch (different from signed!)
  dut->rs1 = 0xFFFFFFFF;
  dut->rs2 = 0x00000000;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 0);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  delete dut;
}

// Test BGEU (Branch if Greater or Equal Unsigned) operation
BOOST_AUTO_TEST_CASE(branch_eval_bgeu_unsigned) {
  Vbranch_eval *dut = new Vbranch_eval();

  dut->func = BGEU;

  // 20 >= 10 - should branch
  dut->rs1 = 20;
  dut->rs2 = 10;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // 15 >= 15 - should branch
  dut->rs1 = 15;
  dut->rs2 = 15;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // 10 >= 20 - should not branch
  dut->rs1 = 10;
  dut->rs2 = 20;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 0);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Unsigned: 0xFFFFFFFF >= 0 (different from signed!)
  dut->rs1 = 0xFFFFFFFF;
  dut->rs2 = 0x00000000;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  // Unsigned: 0 >= 0xFFFFFFFF - should not branch
  dut->rs1 = 0x00000000;
  dut->rs2 = 0xFFFFFFFF;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 0);
  BOOST_CHECK_EQUAL(dut->exception, 0);

  delete dut;
}

// Test reserved opcodes generate exceptions
BOOST_AUTO_TEST_CASE(branch_eval_reserved_opcodes) {
  Vbranch_eval *dut = new Vbranch_eval();

  dut->rs1 = 100;
  dut->rs2 = 200;

  // Reserved opcode 2
  dut->func = RESERVED_2;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->exception, 1);
  BOOST_CHECK_EQUAL(dut->branch, 0);

  // Reserved opcode 3
  dut->func = RESERVED_3;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->exception, 1);
  BOOST_CHECK_EQUAL(dut->branch, 0);

  delete dut;
}

// Test edge cases with boundary values
BOOST_AUTO_TEST_CASE(branch_eval_edge_cases) {
  Vbranch_eval *dut = new Vbranch_eval();

  // Test all zeros
  dut->rs1 = 0x00000000;
  dut->rs2 = 0x00000000;

  dut->func = BEQ;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);

  dut->func = BNE;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 0);

  // Test all ones
  dut->rs1 = 0xFFFFFFFF;
  dut->rs2 = 0xFFFFFFFF;

  dut->func = BEQ;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);

  dut->func = BGE;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);

  dut->func = BGEU;
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);

  // Test max signed positive vs min signed negative
  dut->rs1 = 0x7FFFFFFF; // Max positive signed
  dut->rs2 = 0x80000000; // Min negative signed

  dut->func = BLT; // Signed: max_pos < min_neg? No
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 0);

  dut->func = BLTU; // Unsigned: 0x7FFFFFFF < 0x80000000? Yes
  dut->eval();
  BOOST_CHECK_EQUAL(dut->branch, 1);

  delete dut;
}

// Random testing against reference model
BOOST_AUTO_TEST_CASE(branch_eval_random_operations) {
  Vbranch_eval *dut = new Vbranch_eval();

  std::mt19937 rng(42); // Fixed seed for reproducibility
  std::uniform_int_distribution<uint32_t> dist(0, 0xFFFFFFFF);
  std::uniform_int_distribution<uint8_t> func_dist(0, 7);

  const int NUM_TESTS = 1000;
  int pass_count = 0;

  for (int i = 0; i < NUM_TESTS; i++) {
    uint32_t rs1 = dist(rng);
    uint32_t rs2 = dist(rng);
    uint8_t func = func_dist(rng);

    // Get expected result from reference model
    auto [expected_branch, expected_exception] =
        ref_branch_eval(rs1, rs2, func);

    // Test DUT
    dut->rs1 = rs1;
    dut->rs2 = rs2;
    dut->func = func;
    dut->eval();

    bool pass = (dut->branch == expected_branch) &&
                (dut->exception == expected_exception);
    if (pass) {
      pass_count++;
    } else {
      BOOST_TEST_MESSAGE("FAIL: rs1=" << std::hex << rs1 << " rs2=" << rs2
                                      << " func=" << (int)func << " expected={"
                                      << expected_branch << ","
                                      << expected_exception << "}"
                                      << " got={" << (int)dut->branch << ","
                                      << (int)dut->exception << "}");
    }

    BOOST_CHECK(pass);
  }

  delete dut;
}

BOOST_AUTO_TEST_SUITE_END()
