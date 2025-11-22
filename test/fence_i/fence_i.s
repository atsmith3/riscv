# FENCE.I Basic Test
# Tests that FENCE.I instruction executes without trapping
# FENCE.I synchronizes instruction and data streams (I-cache coherency)
# In a no-cache architecture, FENCE.I is an architectural NOP

.text
.global __start
__start:
  # Execute a FENCE.I instruction
  fence.i

  # Execute another FENCE.I to verify multiple executions
  fence.i

  # If we reached here, FENCE.I didn't trap - test passes
  lui a7, 0xDEAD0      # Magic result address 0xDEAD0000
  li a0, 1             # MAGIC_PASS_VALUE
  sw a0, 0(a7)         # Write pass indicator

LOOP:
  j LOOP
