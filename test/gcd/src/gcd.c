#ifdef LOCAL_COMPILE
#include <stdio.h>
#include <stdlib.h>
#endif

// Magic address for test result communication
#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001

int gcd(int a, int b) {
#ifdef LOCAL_COMPILE
  int i = 0;
#endif
  while (a != b) {
#ifdef LOCAL_COMPILE
    printf("i: %d, a: %d, b: %d\n", i, a, b);
#endif
    if (a > b) {
      a = a - b;
    } else {
      b = b - a;
    }
#ifdef LOCAL_COMPILE
    i += 1;
#endif
  }
  return a;
}

int main() {
  // int result = gcd(272,1479); // 17
  int result = gcd(1479, 272); // 17
  // int result = gcd(22,26); // 2
  // int result = gcd(45,40); // 5
  // int result = gcd(6,4); // 2
  if (result == 17) {
    // Write result to magic address
    *MAGIC_RESULT_ADDR = result;

    // Indicate test pass
    *MAGIC_RESULT_ADDR = MAGIC_PASS_VALUE;

    while (1)
      ;
  }
  return 0;
}
