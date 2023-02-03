.text
__start:
  lw a4, VAL_1
  lw a5, VAL_2
  add a6, a4, a5
LOOP:
  j LOOP

.data
VAL_1:
  .long 0xdeadbeef
VAL_2:
  .long 0xbadcaffe
