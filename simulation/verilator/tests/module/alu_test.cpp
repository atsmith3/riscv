/*
 * ALU Module-Level Tests
 *
 * Unit tests for the RISC-V ALU using a reference model for verification.
 * Tests all ALU operations with directed and random test vectors.
 */

#include "Valu.h"
#include <boost/test/unit_test.hpp>
#include <cstdlib>
#include <ctime>
#include <verilated.h>

// Reference ALU model for golden results
// Note: ALU operation codes match datatypes.sv enum
uint32_t ref_alu(uint32_t a, uint32_t b, uint8_t op) {
  switch (op) {
  case 0:
    return a + b; // ALU_ADD
  case 1:
    return a << (b & 0x1F); // ALU_SLL
  case 2:
    return ((int32_t)a < (int32_t)b) ? 1 : 0; // ALU_SLT
  case 3:
    return (a < b) ? 1 : 0; // ALU_SLTU
  case 4:
    return a ^ b; // ALU_XOR
  case 5:
    return a >> (b & 0x1F); // ALU_SRL
  case 6:
    return a | b; // ALU_OR
  case 7:
    return a & b; // ALU_AND
  case 8:
    return a - b; // ALU_SUB
  case 9:
    return a; // ALU_PASS_RS1
  case 10:
    return b; // ALU_PASS_RS2
  case 13:
    return (uint32_t)((int32_t)a >> (b & 0x1F)); // ALU_SRA
  default:
    return 0;
  }
}

BOOST_AUTO_TEST_SUITE(ALU_ModuleTests)

// Test ADD operation with directed test cases
BOOST_AUTO_TEST_CASE(alu_add_operation) {
  Valu *alu = new Valu();

  struct TestCase {
    uint32_t a, b, expected;
    const char *description;
  };

  TestCase cases[] = {
      {0, 0, 0, "zero + zero"},
      {10, 20, 30, "simple addition"},
      {0xFFFFFFFF, 1, 0, "overflow wrap"},
      {0x80000000, 0x80000000, 0, "negative overflow"},
      {0xDEADBEEF, 0xBADCAFFE, 0x998A6EED, "test data"}
      // 0xDEADBEEF + 0xBADCAFFE = 0x998A6EED (32-bit)
  };

  for (const auto &tc : cases) {
    alu->a = tc.a;
    alu->b = tc.b;
    alu->op = 0; // ADD
    alu->eval();

    BOOST_CHECK_MESSAGE(alu->y == tc.expected,
                        "ADD failed: " << tc.description << " - Expected 0x"
                                       << std::hex << tc.expected << ", got 0x"
                                       << alu->y);
  }

  delete alu;
}

// Test SUB operation
BOOST_AUTO_TEST_CASE(alu_sub_operation) {
  Valu *alu = new Valu();

  struct TestCase {
    uint32_t a, b, expected;
    const char *description;
  };

  TestCase cases[] = {{10, 5, 5, "simple subtraction"},
                      {5, 10, 0xFFFFFFFB, "negative result (wrap)"},
                      {0, 0, 0, "zero - zero"},
                      {0x80000000, 1, 0x7FFFFFFF, "boundary case"}};

  for (const auto &tc : cases) {
    alu->a = tc.a;
    alu->b = tc.b;
    alu->op = 8; // SUB
    alu->eval();

    BOOST_CHECK_MESSAGE(alu->y == tc.expected,
                        "SUB failed: " << tc.description);
  }

  delete alu;
}

// Test logical operations (AND, OR, XOR)
BOOST_AUTO_TEST_CASE(alu_logical_operations) {
  Valu *alu = new Valu();

  uint32_t a = 0xAAAAAAAA;
  uint32_t b = 0x55555555;

  // AND
  alu->a = a;
  alu->b = b;
  alu->op = 7;
  alu->eval();
  BOOST_CHECK_EQUAL(alu->y, 0x00000000);

  // OR
  alu->op = 6;
  alu->eval();
  BOOST_CHECK_EQUAL(alu->y, 0xFFFFFFFF);

  // XOR
  alu->op = 4;
  alu->eval();
  BOOST_CHECK_EQUAL(alu->y, 0xFFFFFFFF);

  delete alu;
}

// Test shift operations
BOOST_AUTO_TEST_CASE(alu_shift_operations) {
  Valu *alu = new Valu();

  uint32_t a = 0x80000001;

  // SLL (Shift Left Logical)
  alu->a = a;
  alu->b = 4;
  alu->op = 1;
  alu->eval();
  BOOST_CHECK_EQUAL(alu->y, 0x00000010);

  // SRL (Shift Right Logical)
  alu->a = a;
  alu->b = 1;
  alu->op = 5;
  alu->eval();
  BOOST_CHECK_EQUAL(alu->y, 0x40000000);

  // SRA (Shift Right Arithmetic) - op code is 13
  alu->a = a;
  alu->b = 1;
  alu->op = 13;
  alu->eval();
  BOOST_CHECK_EQUAL(alu->y, 0xC0000000); // Sign extended

  delete alu;
}

// Test comparison operations
BOOST_AUTO_TEST_CASE(alu_comparison_operations) {
  Valu *alu = new Valu();

  // SLT (Set Less Than - signed)
  alu->a = 0xFFFFFFFF; // -1 in signed
  alu->b = 0;
  alu->op = 2;
  alu->eval();
  BOOST_CHECK_EQUAL(alu->y, 1); // -1 < 0

  alu->a = 1;
  alu->b = 2;
  alu->eval();
  BOOST_CHECK_EQUAL(alu->y, 1); // 1 < 2

  alu->a = 2;
  alu->b = 1;
  alu->eval();
  BOOST_CHECK_EQUAL(alu->y, 0); // 2 not < 1

  // SLTU (Set Less Than Unsigned)
  alu->a = 0xFFFFFFFF;
  alu->b = 0;
  alu->op = 3;
  alu->eval();
  BOOST_CHECK_EQUAL(alu->y, 0); // 0xFFFFFFFF not < 0 (unsigned)

  alu->a = 1;
  alu->b = 2;
  alu->eval();
  BOOST_CHECK_EQUAL(alu->y, 1); // 1 < 2 (unsigned)

  delete alu;
}

// Random testing with reference model
BOOST_AUTO_TEST_CASE(alu_random_operations) {
  Valu *alu = new Valu();

  srand(time(NULL));

  const int NUM_TESTS = 1000;
  int failures = 0;

  // Valid op codes based on datatypes.sv: 0-10, 13
  const uint8_t valid_ops[] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 13};
  const int num_valid_ops = sizeof(valid_ops) / sizeof(valid_ops[0]);

  for (int i = 0; i < NUM_TESTS; i++) {
    uint32_t a = rand();
    uint32_t b = rand();
    uint8_t op = valid_ops[rand() % num_valid_ops];

    alu->a = a;
    alu->b = b;
    alu->op = op;
    alu->eval();

    uint32_t expected = ref_alu(a, b, op);

    if (alu->y != expected) {
      failures++;
      BOOST_ERROR("Random test failed: " << "a=0x" << std::hex << a << ", b=0x"
                                         << b << ", op=" << std::dec << (int)op
                                         << " - Expected 0x" << std::hex
                                         << expected << ", got 0x" << alu->y);
    }
  }

  BOOST_CHECK_EQUAL(failures, 0);
  std::cout << "ALU random tests: " << NUM_TESTS << " tests passed\n";

  delete alu;
}

BOOST_AUTO_TEST_SUITE_END()
