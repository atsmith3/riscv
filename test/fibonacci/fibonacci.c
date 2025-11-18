/*
 * Fibonacci Sequence Test
 *
 * Calculates the 10th Fibonacci number (F(10) = 55) using iterative approach.
 * Tests loops, conditional branches, and basic arithmetic.
 */

// Magic address for test result communication
#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001
#define MAGIC_FAIL_VALUE 0xFFFFFFFF

int fibonacci(int n) {
  if (n <= 1) {
    return n;
  }

  int fib_prev = 0;
  int fib_curr = 1;
  int fib_next;

  for (int i = 2; i <= n; i++) {
    fib_next = fib_prev + fib_curr;
    fib_prev = fib_curr;
    fib_curr = fib_next;
  }

  return fib_curr;
}

int main() {
  int result = fibonacci(10);

  // Write result for debugging
  *MAGIC_RESULT_ADDR = result;

  // Check if result is correct (F(10) = 55)
  if (result == 55) {
    *MAGIC_RESULT_ADDR = MAGIC_PASS_VALUE;
  } else {
    *MAGIC_RESULT_ADDR = MAGIC_FAIL_VALUE;
  }

  // Infinite loop
  while (1)
    ;

  return 0;
}
