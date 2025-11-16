/*
 * Software Multiplication Test
 *
 * Implements 32-bit multiplication using shift-and-add algorithm.
 * Tests: SLL, ADD, ANDI, BEQ, complex arithmetic
 * No hardware multiplication (M extension not available)
 */

#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001
#define MAGIC_FAIL_VALUE 0xFFFFFFFF

// Software multiply using shift-and-add
unsigned int multiply(unsigned int a, unsigned int b) {
  unsigned int result = 0;

  while (b != 0) {
    // If LSB of b is 1, add a to result
    if (b & 1) {
      result = result + a;
    }

    // Shift a left and b right
    a = a << 1; // SLL
    b = b >> 1; // SRL
  }

  return result;
}

int main() {
  int all_pass = 1;

  // Test 1: 12 * 13 = 156
  unsigned int result1 = multiply(12, 13);
  if (result1 != 156) {
    all_pass = 0;
  }

  // Test 2: 255 * 255 = 65025
  unsigned int result2 = multiply(255, 255);
  if (result2 != 65025) {
    all_pass = 0;
  }

  // Test 3: 1000 * 1000 = 1000000
  unsigned int result3 = multiply(1000, 1000);
  if (result3 != 1000000) {
    all_pass = 0;
  }

  // Test 4: 0 * anything = 0
  unsigned int result4 = multiply(0, 12345);
  if (result4 != 0) {
    all_pass = 0;
  }

  // Test 5: anything * 1 = anything
  unsigned int result5 = multiply(98765, 1);
  if (result5 != 98765) {
    all_pass = 0;
  }

  if (all_pass) {
    *MAGIC_RESULT_ADDR = MAGIC_PASS_VALUE;
  } else {
    *MAGIC_RESULT_ADDR = MAGIC_FAIL_VALUE;
  }

  while (1)
    ;

  return 0;
}
