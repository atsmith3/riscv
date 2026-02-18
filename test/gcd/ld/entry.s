.text
.global __start
__start:
  li sp, 0x20000
  call main
LOOP:
  j LOOP
