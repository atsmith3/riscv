void main(void) {
  int a = 32;
  int b = 64;
  int c = b - a;
}

void __attribute__((section (".text.boot"))) __start(void) {
  main();
  /* Infinite Loop */
  while (1) {}
}
