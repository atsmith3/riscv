	.file	"subtract.c"
	.option nopic
	.attribute arch, "rv32i2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
	li	a5,32
	sw	a5,-20(s0)
	li	a5,64
	sw	a5,-24(s0)
	lw	a4,-24(s0)
	lw	a5,-20(s0)
	sub	a5,a4,a5
	sw	a5,-28(s0)
	nop
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
	.size	main, .-main
	.section	.text.boot,"ax",@progbits
	.align	2
	.globl	__start
	.type	__start, @function
__start:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	addi	s0,sp,16
	call	main
.L3:
	j	.L3
	.size	__start, .-__start
	.ident	"GCC: () 9.3.0"
