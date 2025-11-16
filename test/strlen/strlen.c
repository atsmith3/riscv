/*
 * String Length Test
 *
 * Calculates the length of a null-terminated string.
 * Tests: LBU (load byte unsigned), BEQ, ADDI, character array traversal
 */

#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001
#define MAGIC_FAIL_VALUE 0xFFFFFFFF

// Calculate string length
int string_length(const char *str) {
  int len = 0;
  while (str[len] != '\0') {
    len++;
  }
  return len;
}

int main() {
  int all_pass = 1;

  // Test strings
  const char str1[] = "Hello";   // Length 5
  const char str2[] = "RISC-V";  // Length 6
  const char str3[] = "";        // Length 0
  const char str4[] = "Test123"; // Length 7

  int len1 = string_length(str1);
  if (len1 != 5) {
    all_pass = 0;
  }

  int len2 = string_length(str2);
  if (len2 != 6) {
    all_pass = 0;
  }

  int len3 = string_length(str3);
  if (len3 != 0) {
    all_pass = 0;
  }

  int len4 = string_length(str4);
  if (len4 != 7) {
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
