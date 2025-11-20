ENTRY(__start)

MEMORY
{
  rom (rx ): ORIGIN = 0x00001000, LENGTH = 16M
  ram (rw ): ORIGIN = 0x10000000, LENGTH = 32M
}

SECTIONS
{
  .text : {
    KEEP(*(.text.boot))
    *(.text*)
  } > rom
  .rodata : { *(.rodata*) } > rom
  .data : { *(.data*) } > ram
  .bss : { *(.bss) } > ram
}
