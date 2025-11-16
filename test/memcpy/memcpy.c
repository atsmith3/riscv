/*
 * Memory Copy Test
 *
 * Copies an array from source to destination and verifies correctness.
 * Tests: LW, SW, ADDI, BLT, memory access patterns
 */

#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001
#define MAGIC_FAIL_VALUE 0xFFFFFFFF

void *memcpy(void *dst, const void *src, unsigned int n) {
  unsigned char *d = dst;
  const unsigned char *s = src;
  for (unsigned int i = 0; i < n; i++) {
    d[i] = s[i];
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
  // Source array in .rodata
  const unsigned int source[16] = {
      0x11111111, 0x22222222, 0x33333333, 0x44444444, 0x55555555, 0x66666666,
      0x77777777, 0x88888888, 0x99999999, 0xAAAAAAAA, 0xBBBBBBBB, 0xCCCCCCCC,
      0xDDDDDDDD, 0xEEEEEEEE, 0xFFFFFFFF, 0x12345678};

  // Destination array in .bss (uninitialized)
  unsigned int dest[16];

  // Copy array
  memcpy(dest, source, 16);

  // Verify copy
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
