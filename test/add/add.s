.text
.global __start
__start:
  lw a4, VAL_1
  lw a5, VAL_2
  add a6, a4, a5

  # Write result to magic address for verification
  lui a7, 0xDEAD0      # Magic result address 0xDEAD0000
  sw a6, 0(a7)         # Store result

  # Indicate test pass
  li a0, 1             # MAGIC_PASS_VALUE
  sw a0, 0(a7)         # Write pass indicator

LOOP:
  j LOOP

.data
VAL_1:
  .long 0xdeadbeef
VAL_2:
  .long 0xbadcaffe
