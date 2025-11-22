/*
 * ECALL Basic Test
 *
 * Tests the ECALL instruction and trap handling:
 * 1. Sets up a trap handler at mtvec (0x100)
 * 2. Executes ECALL instruction
 * 3. Trap handler verifies mcause == 11 (ECALL)
 * 4. Trap handler returns using MRET
 * 5. Main function resumes and signals test pass
 */

// Magic address for test result communication
#define MAGIC_RESULT_ADDR ((volatile unsigned int *)0xDEAD0000)
#define MAGIC_PASS_VALUE 0x00000001
#define MAGIC_FAIL_VALUE 0xFFFFFFFF

// Machine-mode CSR addresses
#define CSR_MTVEC 0x305
#define CSR_MEPC 0x341
#define CSR_MCAUSE 0x342
#define CSR_MTVAL 0x343

// CSR read/write macros
#define read_csr(csr)                                                          \
  ({                                                                           \
    unsigned long __tmp;                                                       \
    asm volatile("csrr %0, %1" : "=r"(__tmp) : "i"(csr));                      \
    __tmp;                                                                     \
  })

#define write_csr(csr, val)                                                    \
  ({ asm volatile("csrw %0, %1" : : "i"(csr), "r"(val)); })

// Global flag to track trap handler execution
volatile unsigned int trap_handled = 0;

// Trap handler - will be called when ECALL executes
// Important: This must not use stack/return, only MRET
void __attribute__((naked)) trap_handler(void) {
  // Save context (we'll use a0-a2 for scratch)
  asm volatile("csrr a0, 0x342\n"    // a0 = mcause
               "li   a1, 11\n"       // a1 = 11 (expected ECALL code)
               "bne  a0, a1, fail\n" // if mcause != 11, fail

               // Set trap_handled flag
               "la   a0, trap_handled\n" // a0 = &trap_handled
               "li   a1, 1\n"            // a1 = 1
               "sw   a1, 0(a0)\n"        // trap_handled = 1

               // Increment mepc to skip past ECALL (4 bytes)
               "csrr a0, 0x341\n" // a0 = mepc
               "addi a0, a0, 4\n" // mepc += 4
               "csrw 0x341, a0\n" // write mepc

               // Return from trap
               "mret\n"

               "fail:\n"
               "li   a0, 0xDEAD0000\n" // a0 = MAGIC_RESULT_ADDR
               "li   a1, 0xFFFFFFFF\n" // a1 = MAGIC_FAIL_VALUE
               "sw   a1, 0(a0)\n"      // Signal failure
               "1: j 1b\n"             // Infinite loop
  );
}

int main(void) {
  // Get trap handler address
  unsigned int handler_addr = (unsigned int)&trap_handler;

  // Write mtvec to point to trap handler
  write_csr(CSR_MTVEC, handler_addr);

  // Verify mtvec was written correctly
  unsigned int mtvec_read = read_csr(CSR_MTVEC);
  if (mtvec_read != handler_addr) {
    *MAGIC_RESULT_ADDR = MAGIC_FAIL_VALUE;
    while (1)
      ;
  }

  // Execute ECALL instruction
  asm volatile("ecall");

  // Verify trap handler was executed
  if (trap_handled != 1) {
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
