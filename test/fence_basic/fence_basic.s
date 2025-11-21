# FENCE Basic Test
# Tests that FENCE instruction executes without trapping
# In a single-core, no-cache architecture, FENCE is an architectural NOP

.text
.global __start
__start:
  # Execute a FENCE instruction
  # FENCE with all bits set (fm=1111, pred=IORW, succ=IORW)
  fence iorw, iorw

  # Execute another FENCE with different pred/succ
  # FENCE with pred=RW, succ=RW
  fence rw, rw

  # Execute FENCE with minimal ordering
  # FENCE with pred=W, succ=R
  fence w, r

  # If we reached here, FENCE didn't trap - test passes
  lui a7, 0xDEAD0      # Magic result address 0xDEAD0000
  li a0, 1             # MAGIC_PASS_VALUE
  sw a0, 0(a7)         # Write pass indicator

LOOP:
  j LOOP
