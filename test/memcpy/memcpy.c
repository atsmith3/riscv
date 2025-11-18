/*
 * Memory Copy Test
 *
 * Copies an array from source to destination and verifies correctness.
 * Tests: LW, SW, ADDI, BLT, memory access patterns
 */

#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001
#define MAGIC_FAIL_VALUE 0xFFFFFFFF

// Simple word-aligned memcpy for testing
void *memcpy(void *dst, const void *src, unsigned int n) {
  // For word-aligned copies, copy word by word
  if (n % 4 == 0 && ((unsigned int)dst % 4 == 0) &&
      ((unsigned int)src % 4 == 0)) {
    unsigned int *d = (unsigned int *)dst;
    const unsigned int *s = (const unsigned int *)src;
    for (unsigned int i = 0; i < n / 4; i++) {
      d[i] = s[i];
    }
  } else {
    // Fallback to byte-by-byte
    unsigned char *d = dst;
    const unsigned char *s = src;
    for (unsigned int i = 0; i < n; i++) {
      d[i] = s[i];
    }
  }
  return dst;
}

// Verify two arrays are equal
int arrays_equal(const unsigned int *arr1, const unsigned int *arr2, int n) {
  for (int i = 0; i < n; i++) {
    if (arr1[i] != arr2[i]) {
      return 0;
    }
  }
  return 1;
}

int main() {
  // Full test with 16 elements
  unsigned int source[16];
  unsigned int dest[16];

  // Initialize source
  source[0] = 0x11111111;
  source[1] = 0x22222222;
  source[2] = 0x33333333;
  source[3] = 0x44444444;
  source[4] = 0x55555555;
  source[5] = 0x66666666;
  source[6] = 0x77777777;
  source[7] = 0x88888888;
  source[8] = 0x99999999;
  source[9] = 0xAAAAAAAA;
  source[10] = 0xBBBBBBBB;
  source[11] = 0xCCCCCCCC;
  source[12] = 0xDDDDDDDD;
  source[13] = 0xEEEEEEEE;
  source[14] = 0xFFFFFFFF;
  source[15] = 0x12345678;

  // Copy using memcpy (word-level copy will be used)
  memcpy(dest, source, 16 * sizeof(unsigned int));

  // Verify using arrays_equal
  int all_pass = arrays_equal(source, dest, 16);

  if (all_pass) {
    *MAGIC_RESULT_ADDR = MAGIC_PASS_VALUE;
  } else {
    *MAGIC_RESULT_ADDR = MAGIC_FAIL_VALUE;
  }

  while (1)
    ;

  return 0;
}
