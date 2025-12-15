
.. contents:: **Contents**

=======================================================
Case for Representing Flexible Topmost Frames in SFrame
=======================================================
The existing default FDE type in SFrame is quite aptly tuned towards
representing the most common cases of "ABI-conformant CFA/FP/RA tracking".
However, there are cases where the default FDE type is not sufficient:

  - DRAP on x86_64
  - Stack realignment (seen on x86_64, but may be present on other future
    ABI/arch)
  - Static stack allocation and -fstack-clash-protection (see with GCC on
    s390x. Neglegible occurence.)
  - ...

In the following sections we will give more details on each of these patterns.

Unrepresented Patterns in SFrame V2
------------------------------------

DRAP and non-SP/FP based CFA on x86_64
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Dynamically Realigned Argument Pointer (DRAP) is a compiler-internal term used
to handle the case of stack misalignment.

System V AMD64 ABI excerpts
^^^^^^^^^^^^^^^^^^^^^^^^^^^^
As per System V AMD64 ABI, "The end of the input argument area shall be aligned
on a 16 (32 or 64, if __m256 or __m512 is passed on stack) byte boundary. In
other words, the stack needs to be 16 (32 or 64) byte aligned immediately
before the call instruction is executed. Once control has been transferred to
the function entry point, i.e. immediately after the return address has been
pushed, %rsp points to the return address, and the value of (%rsp + 8) is a
multiple of 16 (32 or 64)."

Also, another case of stack alignment requirements come from SSE instructions.
From the "Intel® 64 and IA-32 Architectures Software Developer’s Manual",
Source Vol. 3A 6-41: "Executing an SSE/SSE2/SSE3 instruction that attempts to
access a 128-bit memory location that is not aligned on a 16-byte boundary when
the instruction requires 16-byte alignment. This condition also applies to the
stack segment."

Why is DRAP on x86_64 necessary
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Using x86_64 jargon, lets see why DRAP is necessary.

A typical function call sequence on x86-64 immediately creates an alignment
challenge. The System V ABI requires the stack pointer ($\%rsp$) to be 16-byte
aligned immediately before a function call (call foo).  However, the call
instruction itself pushes an 8-byte return address onto the stack.
Consequently, upon entry to the called function, the stack pointer is
misaligned by 8 bytes relative to the 16-byte boundary ($\%rsp \pmod{16} = 8$).
While some standard function prologues often do not suffer with this as they
may push 8-byte frame pointer ($\%rbp$) (or they may adjust the amount of
static stack allocated) , bringing the stack back into 16-byte alignment before
a callee is invoked, these static fixes are only effective if the required
stack adjustments are known at compile time.

Second, for x86_64, another instance where DRAP pattern is used to support
execution of SSE/SSE2/SSE3 instructions that attempt to access a 128-bit memory
location.

These two cases motivate the need in the compiler to dynamically align the
stack where necessary.  Dynamic stack alignment exposes the problem for stack
tracing/stack unwinding formats: How do you reover the CFA ?  As per
DWARF5 standard - "Typically, the CFA is defined to be the value of the stack
pointer at the call site in the previous frame (which may be different from its
value on entry to the current frame)".  This effectively means that there is a
case where CFA recovery cannot be done using a fixed offset anymore when DRAP
pattern is used, as the amount of stack shift as done by "andq    $-32, %rsp"
instructions is unknown.

In the following sections, we will see that DWARF is expressive enough to
represent such cases of dynamic stack realignement.

When is DRAP pattern generated 
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
GCC has a command line option ``-mstackrealign`` which can be used to *support
mixing legacy codes that keep 4-byte stack alignment with modern codes that
keep 16-byte stack alignment for SSE compatibility.*  There is also an
attribute.

There is also an internal-only option ``-mforce-drap``.  This is an
undocumented option, basically added for debugging GCC code and like. So as to
"when will a user want to use the ``-mforce-drap`` option": the answer is never.

Internally in gcc/cfgexpand.cc expand_stack_alignment ()::

  if (cfun->calls_alloca
      || cfun->has_nonlocal_label
      || crtl->has_nonlocal_goto)
    crtl->need_drap = true;

At the moment in GCC, only two backends use the DRAP pattern, x86_64 and nvptx.
BTW, the above stub does not necessarily mean that GCC generates the DRAP
pattern for all alloca.

Lastly, the GCC command line option ``-mpreferred-stack-boundary=num`` _may_ have
implications as well.

DRAP Mechanism: Function and Definition
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
The Dynamically Realigned Argument Pointer (DRAP) is a conceptual pointer,
typically implemented as a dedicated register or an internal compiler variable,
used when a function's stack requires dynamic realignment. The DRAP, therefore,
IIUC, serves as a fixed, static anchor that ensures stack-passed arguments and
certain local variables can be addressed consistently, regardless of how far
the current stack pointer has moved.

See code samples to see how DRAP is used on AMD64.  Roughly, the DRAP pattern
looks like::

        .cfi_startproc
	endbr64
	leaq	8(%rsp), %r10
	.cfi_def_cfa 10, 0
	andq	$-32, %rsp
	movq	%rdi, %rdx
	pushq	-8(%r10)
	pushq	%rbp
	movq	%rsp, %rbp
        # DW_CFA_expression: r6 (rbp) (DW_OP_breg6 (rbp): 0)
	.cfi_escape 0x10,0x6,0x2,0x76,0
        # RBP = *(%rbp)
	pushq	%r10
        # DW_CFA_def_cfa_expression (DW_OP_breg6 (rbp): -8; DW_OP_deref)
        # CFA = *(%rbp-8)
	.cfi_escape 0xf,0x3,0x76,0x78,0x6
	subq	$48, %rsp
        ...
	movq	-8(%rbp), %r10
	.cfi_def_cfa 10, 0
	vmovaps	-48(%rbp), %ymm0
	popq	%rax
	popq	%rdx
	leave
	leaq	-8(%r10), %rsp
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc

The EH Frame info for the above looks like::

    00000018 000000000000002c 0000001c FDE cie=00000000 pc=0000000000000000..000000000000005f
    LOC           CFA      rbp   ra    
    0000000000000000 rsp+8    u     c-8   
    0000000000000009 r10+0    u     c-8   
    0000000000000018 r10+0    exp   c-8   
    000000000000001a exp      exp   c-8   
    0000000000000052 r10+0    exp   c-8   
    000000000000005e rsp+8    exp   c-8   


Other patterns (AMD64 - non-SP/FP CFA)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Not just in the DRAP pattern above, non-SP/FP based CFA on x86_64 can be seen
in other isolated cases.  E.g., Seen in /usr/bin/qemu-hppa-static::

    00049214 0000000000000030 00000050 FDE cie=000491c8 pc=0000000000616870..0000000000616c5f
    LOC           CFA      rbx   ra    
    0000000000616870 rsp+24   u     c-8   
    0000000000616878 rsp+56   u     c-8   
    000000000061687c rsp+56   c-56  c-8   
    0000000000616884 rbx+56   c-56  c-8   
    0000000000616b86 rsp+56   u     c-8   
    0000000000616b8a rsp+8    u     c-8   
    0000000000616b8d rbx+56   c-56  c-8   
    0000000000616c5a rsp+56   u     c-8   
    0000000000616c5e rsp+8    u     c-8   

Data on occurrence
^^^^^^^^^^^^^^^^^^^
A quick scan of binaries in /usr/bin and /usr/lib64 shows occasional occurence.

+------------------+------------------------+-------------------------+
|                  |/usr/bin                | /usr/lib64              |
|                  |(num files/total files) | (num files/total files) |
+==================+========================+=========================+
| non-SP/FP CFA    |  67/1878 (=3.5%)       | 62/3022 (=2.11%)        |
+------------------+------------------------+-------------------------+
| DRAP             |  39/1878 (=2.1%)       | 48/3022 (=1.59%)        |
+------------------+------------------------+-------------------------+

where ``DRAP`` row measures the presence of "exp" in the CFA-rule (barring .plt
entries), and the ``non-SP/FP CFA`` row measures the occurence of non-"exp",
non-SP, and non-FP based CFA rules.

.. _amd64-ra-in-reg:

Other patterns (AMD64 - RA in reg)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
As seen in unwind-dw2.S::

    movq    0(%rbp), %rbp
    .cfi_restore 6
    .cfi_def_cfa 2, 8
    movq    %rcx, %rsp
    .cfi_def_cfa_register 7
    popq    %rcx
    .cfi_register 16, 2
    .cfi_def_cfa_offset 0
    jmp     \*%rcx

objdump of this excerpt being as follows::

    00000560 0000000000000040 00000564 FDE cie=00000000 pc=00000000000038c0..0000000000003acf
    LOC           CFA      rax   rdx   rbx   rbp   r12   r13   r14   r15   ra
    00000000000038c0 rsp+8    u     u     u     u     u     u     u     u     c-8
    00000000000038c5 rsp+16   u     u     u     c-16  u     u     u     u     c-8
    00000000000038c8 rbp+16   u     u     u     c-16  u     u     u     u     c-8
    00000000000038cc rbp+16   u     u     u     c-16  u     u     c-32  c-24  c-8
    00000000000038d5 rbp+16   u     u     u     c-16  u     c-40  c-32  c-24  c-8
    00000000000038db rbp+16   u     u     c-56  c-16  c-48  c-40  c-32  c-24  c-8
    00000000000038ee rbp+16   c-72  c-64  c-56  c-16  c-48  c-40  c-32  c-24  c-8
    0000000000003a04 rsp+8    c-72  c-64  c-56  c-16  c-48  c-40  c-32  c-24  c-8
    0000000000003a05 rbp+16   c-72  c-64  c-56  c-16  c-48  c-40  c-32  c-24  c-8
    ...
    0000000000003ac9 rcx+8    c-72  c-64  c-56  u     c-48  c-40  c-32  c-24  c-8
    0000000000003acc rsp+8    c-72  c-64  c-56  u     c-48  c-40  c-32  c-24  c-8
    0000000000003acd rsp+0    c-72  c-64  c-56  u     c-48  c-40  c-32  c-24  r2 (rcx)

Other patterns (AMD64 - signal trampoline)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Following is seen for signal trampoline on AMD64::

    000000000003b0c0 <__restore_rt>:
       3b0c0:       48 c7 c0 0f 00 00 00    mov    $0xf,%rax
       3b0c7:       0f 05                   syscall
       3b0c9:       0f 1f 80 00 00 00 00    nopl   0x0(%rax)

objdump of this trampoline being as follows::

    00002770 0000000000000078 00000018 FDE cie=0000275c pc=000000000003b0bf..000000000003b0c9
      DW_CFA_def_cfa_expression (DW_OP_breg7 (rsp): 160; DW_OP_deref)
      DW_CFA_expression: r8 (r8) (DW_OP_breg7 (rsp): 40)
      DW_CFA_expression: r9 (r9) (DW_OP_breg7 (rsp): 48)
      DW_CFA_expression: r10 (r10) (DW_OP_breg7 (rsp): 56)
      DW_CFA_expression: r11 (r11) (DW_OP_breg7 (rsp): 64)
      DW_CFA_expression: r12 (r12) (DW_OP_breg7 (rsp): 72)
      DW_CFA_expression: r13 (r13) (DW_OP_breg7 (rsp): 80)
      DW_CFA_expression: r14 (r14) (DW_OP_breg7 (rsp): 88)
      DW_CFA_expression: r15 (r15) (DW_OP_breg7 (rsp): 96)
      DW_CFA_expression: r5 (rdi) (DW_OP_breg7 (rsp): 104)
      DW_CFA_expression: r4 (rsi) (DW_OP_breg7 (rsp): 112)
      DW_CFA_expression: r6 (rbp) (DW_OP_breg7 (rsp): 120)
      DW_CFA_expression: r3 (rbx) (DW_OP_breg7 (rsp): 128)
      DW_CFA_expression: r1 (rdx) (DW_OP_breg7 (rsp): 136)
      DW_CFA_expression: r0 (rax) (DW_OP_breg7 (rsp): 144)
      DW_CFA_expression: r2 (rcx) (DW_OP_breg7 (rsp): 152)
      DW_CFA_expression: r7 (rsp) (DW_OP_breg7 (rsp): 160)
      DW_CFA_expression: r16 (rip) (DW_OP_breg7 (rsp): 168)
      DW_CFA_nop
      DW_CFA_nop

IOW, the stack trace information has patterns like:

  - CFA = \*(rsp+160)
  - rbp = \*(rsp+120)
  - rsp = \*(rsp+160)
  - RA = \*(rsp+168)

Note that in SFrame, we cannot explicitly encode information to restore rsp.
Restoration of rsp is based on implicit rules.  But IIUC, in the above rules,
the implicit rule of CFA = sp at __restore_rt boundary is not violated.  TBD -
Confirm.

As a side note, for AArch64, following can be noted in
arch/arm64/kernel/vdso/sigreturn.S::

    /*
     * Tell the unwinder where to locate the frame record linking back to the
     * interrupted context. We don't provide unwind info for registers other than
     * the frame pointer and the link register here; in practice, this is likely to
     * be insufficient for unwinding in C/C++ based runtimes, especially without a
     * means to restore the stack pointer. Thankfully, unwinders and debuggers
     * already have baked-in strategies for attempting to unwind out of signals.
     */
    //      .cfi_def_cfa    x29, 0
    //      .cfi_offset     x29, 0 * 8
    //      .cfi_offset     x30, 1 * 8

While the above can be represented in SFrame, restoration of SP to a
non-implicit rule is not.

.. _s390x-ra-in-reg-offset:

Other patterns (s390x - non-SP/FP CFA)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
See example in examples/s390x/stack-clash-protection-static.s.  The
corresponding objdump (-WF) output for the same is as follows::

    00000018 000000000000002c 0000001c FDE cie=00000000 pc=0000000000000000..000000000000004a
    LOC           CFA      ra    r15   
    0000000000000000 r15+160  u     u     
    0000000000000006 r15+160  c-48  c-40  
    000000000000000a r14+160  c-48  c-40  
    000000000000000e r14+12448 c-48  c-40  
    0000000000000024 r15+12448 c-48  c-40  
    0000000000000028 r15+12608 c-48  c-40  
    000000000000003c r15+160  c-48  c-40  
    0000000000000048 r15+160  u     u     

GCC can be seen generating this when using -fstack-clash-protection for static
stack allocation templates.

As you see, r14 is used to recover CFA.  A note about register roles on s390x:
r15 is SP, r11 is FP, and r14 is RA.  This means there is non-SP/FP based CFA
in the above case, which currently SFrame (V2) cannot represent.

Other patterns (AArch64 - non-default RA)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ATM, for AArch64, for compiler-generated code we expect that the return address
is either in the link register or on the stack.

In some hand-written assembly trampolines, however, there are cases where the
return address is transiently stored in another GPR, and in future it's not
inconceivable that compiler generated code might transiently place the return
address in a different GPR (e.g. for special trampoline sequences).

IOW, its clear that we do not need this right away, but for making SFrame
future-proof for needs of AArch64, we might need a way for SFrame to explicitly
describe whether the return address is in a specific GPR.  The recommendation,
hence is: If this is simple and doesn't bloat the format, it might be worth
adding regardless.

Note however, if it comes to this, we should be able to use the default FDE
with REG encoded into the offset as done currently for s390x.

Implications for SFrame
------------------------
In SFrame V2, only the most common case of CFA being based on SP/FP register is
represented.  DRAP pattern, on x86_64, is a case where non-SP/FP register is
used for CFA tracking.  Note that DRAP on x86_64 is one usecase; On other ABIs,
e.g., s390x, non-SP/FP based CFA has been observed to be used occasionally.
See examples/s390x/stack-clash-protection-static.s.  So there can be cases
where:

  - the CFA is based on non-SP/FP register.
  - Recovering FP for caller needs dereferencing a pointer.

Next, SFrame V2 represents the common case when the RA is present in stack or
the designated RA register.  In some cases, however, RA can be seen to be
temporarily buffered into a register.  See section `amd64-ra-in-reg`_.

In general, the DRAP pattern, or other patterns used by the compiler may evolve
over time.  In theory, such patterns may be used anywhere in a function.  In
which case, for completely supporting these patterns, one would need to track
these additional registers through all the frames.  In practice though, these
patterns are very limited, and when they do occur (on the ABIs on interest),
they mostly occur on top-most frames.  It makes sense to target supporting a
"flexible FDE" in SFrame such that:

  - non-SP/FP CFA base register in topmost frame
  - recovering FP / RA from register in topmost frame

Note that the designation of whether or not a frame is top-most cannot be
safely made by the assembler at this point (the assembler does not understand
the instructions or the control-flow).  It is, however, a distinction that a
stack tracer should be able to make unambiguously.

The central question, then, is how flexible should this representation of the
new FDE type be.  To answer that, lets look at each aspect of the desirable
flexibility in isolation:

**Q1: Is the offset of DRAP pattern always zero ?**
For DRAP pattern on x86_64, typically yes.  But there are other patterns in
AM64 (see examples/x86_64/unwind-dw2.S), where non-SP/FP based CFA is used for
topmost frame with non-zero offset. It makes sense to must support non-zero CFA
offset for maximum flexibility across ABIs.

On a related note, the corresponding DW_CFA_def_cfa_expression in drap.s::

    # DW_CFA_def_cfa_expression (DW_OP_breg6 (rbp): -8; DW_OP_deref)
        .cfi_escape 0xf,0x3,0x76,0x78,0x6

IOW, CFA = \*(rbp-8)

**Q2: What about FP recovery ?**
Apart from a unique CFA-rule, the DRAP usecase needs to represent a unique
FP-rule: ``location`` of FP = rbp.  See drap.s for DW_CFA_expression::

    # DW_CFA_expression: r6 (rbp) (DW_OP_breg6 (rbp): 0)
            .cfi_escape 0x10,0x6,0x2,0x76,0
            pushq   %r10

IOW, FP = \*(rbp+0)

PS: See "dwarf2cfi: Defer queued register saves some more `PR99334
<https://gcc.gnu.org/bugzilla/show_bug.cgi?id=99334>`_ in gcc commits to
understand the above expressions and usages in DRAP.

Side note: when talking about DWARF CFA expression, the DWARF CFA expr for PLT
may come to mind::

   # DW_CFA_def_cfa_expression (DW_OP_breg7 (rsp): 8; DW_OP_breg16 (rip): 0; DW_OP_lit15; DW_OP_and; DW_OP_lit11; DW_OP_ge; DW_OP_lit3; DW_OP_shl; DW_OP_plus)

This is the DWARF way of saying::

  rsp + 8 + ((((rip & 15)>= 11)? 1 : 0) << 3)

The above is handled by using SFRAME PC type SFRAME_FDE_TYPE_PCMASK.  The
default FDE type suffices to encode the above information thereafter.  Do a
objdump --sframe on your favorite ET_EXEC/ET_DYN and you will see an FDE tagged
with "[m]" (for mask) near STARTPC::

    func idx [1]: pc = 0x401030, size = 64 bytes
    STARTPC[m]      CFA       FP        RA           
    0000000000000000  sp+8      u         f            
    000000000000000b  sp+16     u         f            

**Q3: What about RA recovery ?**
On s390x, the RA can be saved in a register.  This can be seen in certain leaf
functions, where RA is saved in floating point register too.  The current FDE
representations in SFrame (V2) handle this for s390x, by encoding register::

    #define SFRAME_V2_S390X_OFFSET_ENCODE_REGNUM(regnum) \
        (((regnum) << 3) | 1)

On s390x, same may be used for FP recovery.  IOW, on s390x, the following most
common patterns are already supported by the default FDE (SFrame V2).

  - ``FP = CFA+offset`` or ``FP = REG``
  - ``RA = CFA+offset`` or ``RA = REG``

ATM, there are no known cases where a more general ``RA = REG+offset`` pattern
(i.e., REG != CFA, and with non-zero offset) may be helpful for any ABI/arch.
Not that it matters for the design overall, the former statement is simply a
remark.

Next, on x86_64, as seen in unwind-dw2.S::

    movq    0(%rbp), %rbp
    .cfi_restore 6
    .cfi_def_cfa 2, 8
    movq    %rcx, %rsp
    .cfi_def_cfa_register 7
    popq    %rcx
    .cfi_register 16, 2
    .cfi_def_cfa_offset 0
    jmp     \*%rcx

a simpler pattern of ``RA = REG`` suffices (not represented in the current
default FDE in SFrame V2).

On AArch64, LR be temporarily saved in a reg in some trampolines.

Possible Solution
-----------------
To summarise, here is a list of what is currently supported in the default FDE,
vs the corner cases needing flexible FDE representation.

+---------------+-------------------------------------+-------------------------------------+
| **Arch**      | **Default FDE**                     | **Currently seen patterns of more** |
|               |                                     | **rules (needing Flexible FDE)**    |
+===============+=====================================+=====================================+
| **AMD64**     | CFA=FP+offset or CFA=SP+offset      | CFA=*(REG+offset) or CFA=REG+offset |
+               +-------------------------------------+-------------------------------------+
|               | FP=*(CFA+offset)                    | FP=REG or FP=*(REG+offset)          |
+               +-------------------------------------+-------------------------------------+
|               | RA (unstated; always RA=*(CFA-8)    | RA=REG                              |
+---------------+-------------------------------------+-------------------------------------+
| **s390x**     | CFA=FP+offset or CFA=SP+offset      | CFA=*(REG+offset)                   |
+ (RA-tracking  +-------------------------------------+-------------------------------------+
| enabled)      | FP=*(CFA+offset) or FP=REG          |                                     |
+               +-------------------------------------+-------------------------------------+
|               | RA=*(CFA+offset) or RA=REG          |                                     |
+---------------+-------------------------------------+-------------------------------------+
| **AArch64**   | CFA=FP+offset or CFA=SP+offset      |                                     |
+ (RA-tracking  +-------------------------------------+-------------------------------------+
| enabled)      | FP=*(CFA+offset)                    |                                     |
+               +-------------------------------------+-------------------------------------+
|               | RA=*(CFA+offset)                    | RA=REG                              |
+---------------+-------------------------------------+-------------------------------------+

**NB** Although the currently seen patterns needing Flexible FDE (shown above)
are explicitly mentioned, the representation below is capable of representing
the variants not explicitly mentioned above (e.g., FP=REG+offset, or FP=*REG, or
RA=*REG, or RA=REG+offset etc.).

Introduce a new FDE type SFRAME_FDE_TYPE_FLEX_TOPMOST_FRAME, which can encode a
more flexible set of CFA, FP and RA recovery rules.  In the above table, note:

  - The use of "deref" after the operation of "REG+offset".
  - The use of REG instead of CFA for FP/RA recovery.
  - The use of REG instead of SP/FP for CFA recovery.

The new FDE type allows representation of the these patterns by **always**
using two offsets for each of CFA, FP, or RA (if tracking the respective
entity). The offsets are in the usual order:  CFA, FP if present, RA if
present.  The interpretation of the two offsets is as follows:

  - (minimum 8-bit) offset1 to encode register: (regnum << 3) | unused << 2 | deref_p << 1 | reg_p (=1)
  - offset2 to encode offset: offset

reg_p = 1 indicates a register, reg_p = 0 indicates CFA.

**Q1: Can register 0 be used for CFA/FP/RA tracking in FDE type SFRAME_FDE_TYPE_FLEX_TOPMOST_FRAME?**
Yes. Use reg = 0 with reg_p = 1.

**NB** We use 5 bits for encoding register number regnum on AMD64 in the above
suggested encoding.  An ABI may define the number of bits to encode the DWARF
register numbers.  If anything more than 5 bits, this will mean the minimum
size of offset1 then is 16bits.  This then means all SFrame FRE offsets of that
function will need to be a minimum of 16 bits..

The offsets are in the usual order:  CFA, RA, FP if present.

For example, for FP/RA tracking,

a) If the reg is REG1 for FP/RA tracking,
   - Encoding:

     + offset1 to encode register: (REG1 << 3) | unused << 2 | deref << 1 | reg_p (=1)
     + offset2 to encode offset: offset

   - Action:

     + if deref, FP/RA = \*(REG1 + offset) (e.g., seen for FP recovery
       with certain DRAP patterns on x86_64)
     + if no deref, FP/RA = REG1 + offset (pattern not expected to be seen)

b) If the reg is CFA for FP/RA tracking,
   - Encoding:

     + [=Effectively Padding] offset1 to encode register:
        (( 0 << 3 ) | unused << 2 | deref << 1 | reg_p (=0))
     + offset2 to encode offset: offset

   - Action:

     + if deref, FP/RA = \*(CFA + offset)
     + if no deref, FP/RA = CFA + offset (pattern not expected to be seen)

Next for CFA tracking,
   - Action:

     + if deref, CFA = \*(reg + offset) (e.g., seen for CFA recovery in
       some stack realignment patterns on AMD64)
     + if no deref, CFA = reg + offset (e.g., for .cfi_def_cfa 2, 8, or
       .cfi_def_cfa 10, 0)

Expected usage of this FDE type is quite low (DRAP on x86_64).

Taking all the currently supported ABIs into perspective here: The expected
usage of this FDE type is expected to be minimal.

Implications of new FDE type for stack tracers
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 - Additional conditionals due to a new FDE type (rare) on fast path to
   access the offsets accordingly.
 - Flexible topmost frame must be determined to be the topmost frame by stack
   tracer.  If not topmost frame, skip using SFrame data for stack tracing
   starting from the topmost frame.
 - Error checking/validation of offsets depending on the FDE type
 - TBD Work out a suggested pseudocode for spec

WIP::

    fre = sframe_find_fre (pc, &fde_type);
    if (fre && fde_type == default_fde_type)
        // Whether the base register for CFA tracking is REG_FP.
        base_reg_val = sframe_fre_base_reg_fp_p (fre) ? fp : sp;
        // Get the CFA stack offset from the FRE.
        cfa_offset = sframe_fre_get_cfa_offset (fre);
        // Get the fixed RA offset or FRE stack offset as applicable.
        ra_offset = sframe_fre_get_ra_offset (fre);
        // Get the fixed FP offset or FRE stack offset as applicable.
        fp_offset = sframe_fre_get_fp_offset (fre);

        cfa = base_reg_val + cfa_offset;
        next_frame->sp = cfa [+ SFRAME_S390X_SP_VAL_OFFSET on s390x];

        ra_stack_loc = cfa + ra_offset;
        // Get the address stored in the stack location.
        next_frame->pc = read_value (ra_stack_loc);

        if (fp_offset is VALID)
            fp_stack_loc = cfa + fp_offset;
            // Get the value stored in the stack location.
            next_frame->fp = read_value (fp_stack_loc);
        else
            // Continue to use the value of fp as it has not
            // been clobbered by the current frame yet.
            next_frame->fp = fp;
    else if (fre && fde_type == flex_topmost_fde_type)
        // Get the base register, offset, and deref_p for CFA tracking.
        cfa_reg_data = sframe_fre_get_offset (fre, 0);
        cfa_reg_offset = sframe_fre_get_cfa_offset (fre);
        // Get the RA reg, offset, and deref_p.
        ra_reg_data = sframe_fre_get_offset (fre, 2);
        ra_reg_offset = sframe_fre_get_ra_offset (fre);
        // Get the FP reg, offset, and deref_p.
        fp_tracking_p = fre.num_offsets > 4;
        if (fp_tracking_p)
                fp_reg_offset = sframe_fre_get_fp_offset (4);
                fp_offset = sframe_fre_get_fp_offset (fre);

        // Safety check for topmost frames.  REG_SP/REG_FP are arch-specific
        if (!topmost_frame_p && (ra_base_reg != REG_FP && ra_base_reg != REG_SP)
                skip SFrame stacktracing
        if (!topmost_frame_p && fre.num_offsets > 4
            && (fp_base_reg != REG_FP && fp_base_reg != REG_SP)
                skip SFrame stacktracing

        cfa = sframe_apply_rule (cfa_reg_data, cfa_offset, cfa, 1);
        ra = sframe_apply_rule (ra_reg_data, ra_offset, cfa, 0);
        if (fp_tracking_p)
                fp = sframe_apply_rule (fp_reg_data, fp_offset, cfa, 0);
 
        next_frame->sp = cfa;
        next_frame->pc = ra;

        if (fp_tracking_p)
            next_frame->fp = fp;
        else
            // Continue to use the value of fp as it has not
            // been clobbered by the current frame yet.
            next_frame->fp = fp;
    else
        ret = ERR_NO_SFRAME_FRE;

As for sframe_apply_rule::

    sframe_apply_rule (reg_data, reg_offset, cfa, cfa_p):
        reg_p = SFRAME_V3_FLEX_FDE_OFFSET_REG_P(cfa_reg_data);
        base_loc = (reg_p ? get_reg_value(SFRAME_V3_FLEX_FDE_OFFSET_REG_NUM(ra_reg_data))
                          : cfa);
        // Expected reg_p for cfa_p
        assert(!cfa_p || reg_p);

        deref_p = SFRAME_V3_FLEX_FDE_OFFSET_REG_DEREF_P(reg_data);

        loc = base_loc + offset
        value = deref_p ? *loc : loc;
        return value;

References
-------------------
#. Eli Bendersky, Stack frame layout on x86-64 https://eli.thegreenplace.net/2011/09/06/stack-frame-layout-on-x86-64
#. System V AMD64 ABI https://gitlab.com/x86-psABIs/x86-64-ABI/-/tree/master?ref_type=heads
