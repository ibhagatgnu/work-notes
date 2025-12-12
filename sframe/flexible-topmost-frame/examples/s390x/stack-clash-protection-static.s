	.file	"s390x-stack-clash-protection-static.c"
	.machinemode zarch
	.machine "z900"
.text
	.align	8
.globl foo
	.type	foo, @function
foo:
.LFB0:
	.cfi_startproc
	stmg	%r14,%r15,112(%r15)
	.cfi_offset 14, -48
	.cfi_offset 15, -40
	lgr	%r14,%r15
	.cfi_def_cfa_register 14
	aghi	%r14,-12288
	.cfi_def_cfa_offset 12448
.L2:
	aghi	%r15,-4096
	cg	%r0,4088(%r15)
	clgr	%r15,%r14
	jh	.L2
	lgr	%r15,%r14
	.cfi_def_cfa_register 15
	aghi	%r15,-160
	.cfi_def_cfa_offset 12608
	cg	%r0,152(%r15)
	la	%r2,160(%r15)
	brasl	%r14,bar@PLT
	aghi	%r15,12448
	.cfi_def_cfa_offset 160
	lg	%r4,112(%r15)
	lmg	%r14,%r15,112(%r15)
	.cfi_restore 15
	.cfi_restore 14
	br	%r4
	.cfi_endproc
.LFE0:
	.size	foo, .-foo
	.ident	"GCC: (crosstool-NG 1.28.0.3_a3fef85) 15.2.0"
	.section	.note.GNU-stack,"",@progbits
