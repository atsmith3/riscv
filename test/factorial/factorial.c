/*
 * Factorial Test
 *
 * Calculates factorial(7) = 5040 using recursive function.
 * Tests: JAL, JALR, stack operations (SW/LW with sp), function calls, recursion
 */

#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001
#define MAGIC_FAIL_VALUE 0xFFFFFFFF

// Software multiply (needed because -nostdlib doesn't provide __mulsi3)
int multiply(int a, int b) {
  int result = 0;
  int negative = 0;

  // Handle negative numbers
  if (a < 0) {
    negative = !negative;
    a = -a;
  }
  if (b < 0) {
    negative = !negative;
    b = -b;
  }

  while (b != 0) {
    if (b & 1) {
      result = result + a;
    }
    a = a << 1;
    b = b >> 1;
  }

  return negative ? -result : result;
}

// Recursive factorial implementation
int factorial(int n) {
  if (n <= 1) {
    return 1;
  }
  return multiply(n, factorial(n - 1));
}

// Iterative factorial for verification
int factorial_iterative(int n) {
  int result = 1;
  for (int i = 2; i <= n; i++) {
    result = multiply(result, i);
  }
  return result;
}

int main() {
  int all_pass = 1;

  // Test 1: factorial(7) = 5040
  int result1 = factorial(7);
  if (result1 != 5040) {
    all_pass = 0;
  }

  // Test 2: factorial(5) = 120
  int result2 = factorial(5);
  if (result2 != 120) {
    all_pass = 0;
  }

  // Test 3: factorial(0) = 1
  int result3 = factorial(0);
  if (result3 != 1) {
    all_pass = 0;
  }

  // Test 4: factorial(10) = 3628800
  int result4 = factorial(10);
  if (result4 != 3628800) {
    all_pass = 0;
  }

  // Verify recursive and iterative produce same result
  int recursive = factorial(6);
  int iterative = factorial_iterative(6);
  if (recursive != iterative || iterative != 720) {
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
