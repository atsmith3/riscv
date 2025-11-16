// Magic address for test result communication
#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001

void main(void) {
  int a = 32;
  int b = 64;
  int c = b - a;

  // Verify result
  if (c == 32) {
    // Write result to magic address
    *MAGIC_RESULT_ADDR = c;

    // Indicate test pass
    *MAGIC_RESULT_ADDR = MAGIC_PASS_VALUE;
  }
}
/*
void __attribute__((section (".text.boot"))) __start(void) {
  main();
  while (1) {}
}
*/
