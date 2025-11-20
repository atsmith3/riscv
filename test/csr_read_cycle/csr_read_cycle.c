/*
 * CSR Read Cycle Counter Test
 *
 * Tests reading the cycle counter CSR using CSRRS instruction.
 * Verifies that:
 * 1. CSR reads work correctly
 * 2. Cycle counter increments
 * 3. Multiple reads return increasing values
 */

// Magic address for test result communication
#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001
#define MAGIC_FAIL_VALUE 0xFFFFFFFF

// CSR addresses
#define CSR_CYCLE 0xC00
#define CSR_TIME 0xC01
#define CSR_INSTRET 0xC02

// CSR read macro - uses CSRRS with rs1=x0 (read-only, no write)
#define read_csr(csr)                                                          \
  ({                                                                           \
    unsigned long __tmp;                                                       \
    asm volatile("csrr %0, %1" : "=r"(__tmp) : "i"(csr));                      \
    __tmp;                                                                     \
  })

int main(void) {
  unsigned int cycle1, cycle2, cycle3;
  unsigned int time1;
  unsigned int instret1;

  // Read cycle counter three times
  cycle1 = read_csr(CSR_CYCLE);
  cycle2 = read_csr(CSR_CYCLE);
  cycle3 = read_csr(CSR_CYCLE);

  // Verify cycle counter is increasing
  if (cycle2 <= cycle1) {
    *MAGIC_RESULT_ADDR = MAGIC_FAIL_VALUE;
    while (1)
      ;
  }

  if (cycle3 <= cycle2) {
    *MAGIC_RESULT_ADDR = MAGIC_FAIL_VALUE;
    while (1)
      ;
  }

  // Read time counter (should mirror cycle)
  time1 = read_csr(CSR_TIME);

  // Time should be greater than cycle1 (since more cycles have passed)
  if (time1 <= cycle1) {
    *MAGIC_RESULT_ADDR = MAGIC_FAIL_VALUE;
    while (1)
      ;
  }

  // Read instret counter
  instret1 = read_csr(CSR_INSTRET);

  // Instret should be non-zero (we've executed some instructions)
  if (instret1 == 0) {
    *MAGIC_RESULT_ADDR = MAGIC_FAIL_VALUE;
    while (1)
      ;
  }

  // Instret should be less than cycle count
  // (instructions take multiple cycles)
  if (instret1 > cycle3) {
    *MAGIC_RESULT_ADDR = MAGIC_FAIL_VALUE;
    while (1)
      ;
  }

  // All tests passed!
  *MAGIC_RESULT_ADDR = MAGIC_PASS_VALUE;
  while (1)
    ;

  return 0;
}
