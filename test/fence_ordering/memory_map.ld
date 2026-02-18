ENTRY(__start)

MEMORY
{
  mem (rwx): ORIGIN = 0x00001000, LENGTH = 124K
}

SECTIONS
{
  .text   : { KEEP(*(.text.boot)) *(.text*) } > mem
  .rodata : { *(.rodata*) } > mem
  .data   : { *(.data*) } > mem
  .bss    : { *(.bss) } > mem
}
