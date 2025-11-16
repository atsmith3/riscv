/*
 * Bitwise Operations Test
 *
 * Tests all logical and shift operations available in RV32I:
 * - Count bits set (popcount)
 * - Reverse bits
 * - Check if power of 2
 * Tests: AND, OR, XOR, SLL, SRL, SRA
 */

#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001
#define MAGIC_FAIL_VALUE 0xFFFFFFFF

// Count number of set bits (popcount)
int count_bits(unsigned int n) {
  int count = 0;
  while (n) {
    count += n & 1;
    n >>= 1; // SRL
  }
  return count;
}

// Reverse bits in a 32-bit word
unsigned int reverse_bits(unsigned int n) {
  unsigned int result = 0;
  for (int i = 0; i < 32; i++) {
    result <<= 1;      // SLL
    result |= (n & 1); // OR
    n >>= 1;           // SRL
  }
  return result;
}

// Check if number is a power of 2
int is_power_of_2(unsigned int n) {
  if (n == 0) {
    return 0;
  }
  return (n & (n - 1)) == 0; // AND
}

// Test arithmetic right shift with negative number
int test_arithmetic_shift(int n) {
  // For negative numbers, SRA should sign-extend
  return n >> 2; // SRA for signed integers
}

int main() {
  int all_pass = 1;

  // Test 1: Count bits in 0xAAAAAAAA (alternating bits) = 16
  int bits = count_bits(0xAAAAAAAA);
  if (bits != 16) {
    all_pass = 0;
  }

  // Test 2: Reverse bits of 0x00000001 should be 0x80000000
  unsigned int reversed = reverse_bits(0x00000001);
  if (reversed != 0x80000000) {
    all_pass = 0;
  }

  // Test 3: 16 is a power of 2
  if (!is_power_of_2(16)) {
    all_pass = 0;
  }

  // Test 4: 15 is not a power of 2
  if (is_power_of_2(15)) {
    all_pass = 0;
  }

  // Test 5: Arithmetic shift of -16 >> 2 should be -4 (sign extended)
  int shifted = test_arithmetic_shift(-16);
  if (shifted != -4) {
    all_pass = 0;
  }

  // Test 6: XOR test - a XOR a should be 0
  unsigned int xor_test = 0x12345678 ^ 0x12345678;
  if (xor_test != 0) {
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
