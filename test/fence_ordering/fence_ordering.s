# FENCE Memory Ordering Test
# Tests FENCE instruction with memory operations
# Verifies that memory operations complete correctly across FENCE boundaries
# In a single-core, non-pipelined, no-cache architecture with strictly ordered
# FSM execution, FENCE is effectively a NOP but should not break ordering

.text
.global __start
__start:
  # Initialize test data address
  lui a0, 0x1000       # Data region at 0x10000000

  # Write first value
  li a1, 0x12345678
  sw a1, 0(a0)

  # FENCE to ensure write completes (trivial in this arch)
  fence w, r

  # Read back the value
  lw a2, 0(a0)

  # Verify value matches
  bne a1, a2, FAIL

  # Write second value
  li a1, 0xABCDEF00
  sw a1, 4(a0)

  # FENCE with different ordering
  fence rw, rw

  # Read back second value
  lw a3, 4(a0)

  # Verify second value matches
  bne a1, a3, FAIL

  # Test passes - both values read correctly across FENCE boundaries
  lui a7, 0xDEAD0      # Magic result address 0xDEAD0000
  li a6, 1             # MAGIC_PASS_VALUE
  sw a6, 0(a7)         # Write pass indicator
  j LOOP

FAIL:
  # Test failed - write result and fail
  lui a7, 0xDEAD0      # Magic result address 0xDEAD0000
  li a6, 0xFFFFFFFF    # MAGIC_FAIL_VALUE
  sw a6, 0(a7)         # Write fail indicator

LOOP:
  j LOOP
