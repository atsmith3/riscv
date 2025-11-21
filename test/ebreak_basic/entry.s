.text
.global __start
__start:
  li sp, 0x5000      # Initialize stack pointer
  call main          # Call main function
LOOP:
  j LOOP             # Infinite loop after main returns
