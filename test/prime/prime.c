/*
 * Prime Number Test
 *
 * Checks if numbers are prime using trial division.
 * Tests: Software division/modulo, complex arithmetic, nested loops
 */

#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001
#define MAGIC_FAIL_VALUE 0xFFFFFFFF

unsigned int square(unsigned int x) {
  unsigned int result = 0;
  for (unsigned int i = 0; i < x; i++) {
    result += x;
  }
  return result;
}

// Software modulo operation
unsigned int modulo(unsigned int dividend, unsigned int divisor) {
  while (dividend >= divisor) {
    dividend = dividend - divisor;
  }
  return dividend;
}

// Check if a number is prime
int is_prime(unsigned int n) {
  if (n <= 1) {
    return 0;
  }
  if (n <= 3) {
    return 1;
  }
  if (modulo(n, 2) == 0 || modulo(n, 3) == 0) {
    return 0;
  }

  // Check divisors up to sqrt(n)
  // We'll check up to n/2 for simplicity (no sqrt in bare metal)
  for (unsigned int i = 5; square(i) <= n; i = i + 6) {
    if (modulo(n, i) == 0 || modulo(n, i + 2) == 0) {
      return 0;
    }
  }

  return 1;
}

int main() {
  int all_pass = 1;

  // Test known primes
  if (!is_prime(2))
    all_pass = 0; // 2 is prime
  if (!is_prime(3))
    all_pass = 0; // 3 is prime
  if (!is_prime(5))
    all_pass = 0; // 5 is prime
  if (!is_prime(7))
    all_pass = 0; // 7 is prime
  if (!is_prime(11))
    all_pass = 0; // 11 is prime
  if (!is_prime(13))
    all_pass = 0; // 13 is prime
  if (!is_prime(17))
    all_pass = 0; // 17 is prime
  if (!is_prime(19))
    all_pass = 0; // 19 is prime
  if (!is_prime(23))
    all_pass = 0; // 23 is prime
  if (!is_prime(29))
    all_pass = 0; // 29 is prime
  if (!is_prime(31))
    all_pass = 0; // 31 is prime
  if (!is_prime(97))
    all_pass = 0; // 97 is prime

  // Test known non-primes
  if (is_prime(0))
    all_pass = 0; // 0 is not prime
  if (is_prime(1))
    all_pass = 0; // 1 is not prime
  if (is_prime(4))
    all_pass = 0; // 4 is not prime
  if (is_prime(6))
    all_pass = 0; // 6 is not prime
  if (is_prime(8))
    all_pass = 0; // 8 is not prime
  if (is_prime(9))
    all_pass = 0; // 9 is not prime
  if (is_prime(10))
    all_pass = 0; // 10 is not prime
  if (is_prime(100))
    all_pass = 0; // 100 is not prime

  if (all_pass) {
    *MAGIC_RESULT_ADDR = MAGIC_PASS_VALUE;
  } else {
    *MAGIC_RESULT_ADDR = MAGIC_FAIL_VALUE;
  }

  while (1)
    ;

  return 0;
}
