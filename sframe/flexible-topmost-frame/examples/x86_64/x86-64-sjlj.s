# as --gsframe sjlj.s
# sjlj.s: Assembler messages:
# sjlj.s: Warning: no SFrame FDE emitted; non-SP/FP register 4 in .cfi_def_cfa with offset 0
 .align 4
 .globl GTM_longjmp

GTM_longjmp:
 .cfi_startproc
 endbr64

 movq (%rsi), %rcx
 movq 8(%rsi), %rbx
 movq 16(%rsi), %rbp
 movq 24(%rsi), %r12
 movq 32(%rsi), %r13
 movq 40(%rsi), %r14
 movq 48(%rsi), %r15
 movl %edi, %eax
 .cfi_def_cfa %rsi, 0
 .cfi_offset %rip, 64
 .cfi_register %rsp, %rcx
 movq %rcx, %rsp

 xorq %rcx, %rcx
 rdsspq %rcx
 testq %rcx, %rcx
 je .L1

 subq 56(%rsi), %rcx
 negq %rcx
 shrq $3, %rcx
 incq %rcx

 cmpq $255, %rcx
 jbe .L3
 movl $255, %edi
 .p2align 4,,10
 .p2align 3
.L4:
 incsspq %rdi
 subq $255, %rcx
 cmpq $255, %rcx
 ja .L4
.L3:
 incsspq %rcx
.L1:

 jmp *64(%rsi)
 .cfi_endproc

 .type GTM_longjmp, @function
 .hidden GTM_longjmp
 .size GTM_longjmp, . - GTM_longjmp


.section .note.GNU-stack, "", @progbits
