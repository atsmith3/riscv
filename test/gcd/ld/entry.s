.text
.global __start
__start:
  li sp, 0x5000
  call main
LOOP:
  j LOOP
