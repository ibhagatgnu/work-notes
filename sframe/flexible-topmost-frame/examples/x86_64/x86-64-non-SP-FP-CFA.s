# Code from /usr/bin/qemu-hppa-static
#
# 00049214 0000000000000030 00000050 FDE cie=000491c8 pc=0000000000616870..0000000000616c5f
#    LOC           CFA      rbx   ra
# 0000000000616870 rsp+24   u     c-8
# 0000000000616878 rsp+56   u     c-8
# 000000000061687c rsp+56   c-56  c-8
# 0000000000616884 rbx+56   c-56  c-8
# 0000000000616b86 rsp+56   u     c-8
# 0000000000616b8a rsp+8    u     c-8
# 0000000000616b8d rbx+56   c-56  c-8
# 0000000000616c5a rsp+56   u     c-8
# 0000000000616c5e rsp+8    u     c-8

  616870:	f3 0f 1e fa          	endbr64
  616874:	48 83 ec 20          	sub    $0x20,%rsp
  616878:	48 89 1c 24          	mov    %rbx,(%rsp)
  61687c:	48 89 44 24 08       	mov    %rax,0x8(%rsp)
  616881:	48 89 e3             	mov    %rsp,%rbx
  616884:	48 83 e4 e0          	and    $0xffffffffffffffe0,%rsp
  616888:	48 81 ec 80 03 00 00 	sub    $0x380,%rsp
  61688f:	48 89 63 18          	mov    %rsp,0x18(%rbx)
  616893:	48 89 14 24          	mov    %rdx,(%rsp)
  616897:	4c 89 44 24 08       	mov    %r8,0x8(%rsp)
  61689c:	4c 89 4c 24 10       	mov    %r9,0x10(%rsp)
  6168a1:	48 89 4c 24 18       	mov    %rcx,0x18(%rsp)
  6168a6:	48 89 74 24 20       	mov    %rsi,0x20(%rsp)
  6168ab:	48 89 7c 24 28       	mov    %rdi,0x28(%rsp)
  6168b0:	48 89 6c 24 30       	mov    %rbp,0x30(%rsp)
  6168b5:	48 8d 43 30          	lea    0x30(%rbx),%rax
  6168b9:	48 89 44 24 38       	mov    %rax,0x38(%rsp)
  6168be:	c5 f9 7f 44 24 40    	vmovdqa %xmm0,0x40(%rsp)
  6168c4:	c5 f9 7f 4c 24 50    	vmovdqa %xmm1,0x50(%rsp)
  6168ca:	c5 f9 7f 54 24 60    	vmovdqa %xmm2,0x60(%rsp)
  6168d0:	c5 f9 7f 5c 24 70    	vmovdqa %xmm3,0x70(%rsp)
  6168d6:	c5 f9 7f a4 24 80 00 	vmovdqa %xmm4,0x80(%rsp)
  6168dd:	00 00 
  6168df:	c5 f9 7f ac 24 90 00 	vmovdqa %xmm5,0x90(%rsp)
  6168e6:	00 00 
  6168e8:	c5 f9 7f b4 24 a0 00 	vmovdqa %xmm6,0xa0(%rsp)
  6168ef:	00 00 
  6168f1:	c5 f9 7f bc 24 b0 00 	vmovdqa %xmm7,0xb0(%rsp)
  6168f8:	00 00 
  6168fa:	c5 fd 7f 84 24 c0 00 	vmovdqa %ymm0,0xc0(%rsp)
  616901:	00 00 
  616903:	c5 fd 7f 8c 24 00 01 	vmovdqa %ymm1,0x100(%rsp)
  61690a:	00 00 
  61690c:	c5 fd 7f 94 24 40 01 	vmovdqa %ymm2,0x140(%rsp)
  616913:	00 00 
  616915:	c5 fd 7f 9c 24 80 01 	vmovdqa %ymm3,0x180(%rsp)
  61691c:	00 00 
  61691e:	c5 fd 7f a4 24 c0 01 	vmovdqa %ymm4,0x1c0(%rsp)
  616925:	00 00 
  616927:	c5 fd 7f ac 24 00 02 	vmovdqa %ymm5,0x200(%rsp)
  61692e:	00 00 
  616930:	c5 fd 7f b4 24 40 02 	vmovdqa %ymm6,0x240(%rsp)
  616937:	00 00 
  616939:	c5 fd 7f bc 24 80 02 	vmovdqa %ymm7,0x280(%rsp)
  616940:	00 00 
  616942:	c5 f9 7f 84 24 00 03 	vmovdqa %xmm0,0x300(%rsp)
  616949:	00 00 
  61694b:	c5 f9 7f 8c 24 10 03 	vmovdqa %xmm1,0x310(%rsp)
  616952:	00 00 
  616954:	c5 f9 7f 94 24 20 03 	vmovdqa %xmm2,0x320(%rsp)
  61695b:	00 00 
  61695d:	c5 f9 7f 9c 24 30 03 	vmovdqa %xmm3,0x330(%rsp)
  616964:	00 00 
  616966:	c5 f9 7f a4 24 40 03 	vmovdqa %xmm4,0x340(%rsp)
  61696d:	00 00 
  61696f:	c5 f9 7f ac 24 50 03 	vmovdqa %xmm5,0x350(%rsp)
  616976:	00 00 
  616978:	c5 f9 7f b4 24 60 03 	vmovdqa %xmm6,0x360(%rsp)
  61697f:	00 00 
  616981:	c5 f9 7f bc 24 70 03 	vmovdqa %xmm7,0x370(%rsp)
  616988:	00 00 
  61698a:	48 89 e1             	mov    %rsp,%rcx
  61698d:	48 8b 53 30          	mov    0x30(%rbx),%rdx
  616991:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  616995:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  616999:	4c 8d 43 10          	lea    0x10(%rbx),%r8
  61699d:	e8 ce c6 00 00       	call   0x623070
  6169a2:	49 89 c3             	mov    %rax,%r11
  6169a5:	48 8b 43 08          	mov    0x8(%rbx),%rax
  6169a9:	48 8b 14 24          	mov    (%rsp),%rdx
  6169ad:	4c 8b 44 24 08       	mov    0x8(%rsp),%r8
  6169b2:	4c 8b 4c 24 10       	mov    0x10(%rsp),%r9
  6169b7:	c5 f9 6f 44 24 40    	vmovdqa 0x40(%rsp),%xmm0
  6169bd:	c5 f9 6f 4c 24 50    	vmovdqa 0x50(%rsp),%xmm1
  6169c3:	c5 f9 6f 54 24 60    	vmovdqa 0x60(%rsp),%xmm2
  6169c9:	c5 f9 6f 5c 24 70    	vmovdqa 0x70(%rsp),%xmm3
  6169cf:	c5 f9 6f a4 24 80 00 	vmovdqa 0x80(%rsp),%xmm4
  6169d6:	00 00 
  6169d8:	c5 f9 6f ac 24 90 00 	vmovdqa 0x90(%rsp),%xmm5
  6169df:	00 00 
  6169e1:	c5 f9 6f b4 24 a0 00 	vmovdqa 0xa0(%rsp),%xmm6
  6169e8:	00 00 
  6169ea:	c5 f9 6f bc 24 b0 00 	vmovdqa 0xb0(%rsp),%xmm7
  6169f1:	00 00 
  6169f3:	c5 79 74 84 24 00 03 	vpcmpeqb 0x300(%rsp),%xmm0,%xmm8
  6169fa:	00 00 
  6169fc:	c4 c1 79 d7 f0       	vpmovmskb %xmm8,%esi
  616a01:	66 ff c6             	inc    %si
  616a04:	74 0b                	je     0x616a11
  616a06:	c5 f9 7f 84 24 c0 00 	vmovdqa %xmm0,0xc0(%rsp)
  616a0d:	00 00 
  616a0f:	eb 0f                	jmp    0x616a20
  616a11:	c5 fd 6f 84 24 c0 00 	vmovdqa 0xc0(%rsp),%ymm0
  616a18:	00 00 
  616a1a:	c5 f9 7f 44 24 40    	vmovdqa %xmm0,0x40(%rsp)
  616a20:	c5 71 74 84 24 10 03 	vpcmpeqb 0x310(%rsp),%xmm1,%xmm8
  616a27:	00 00 
  616a29:	c4 c1 79 d7 f0       	vpmovmskb %xmm8,%esi
  616a2e:	66 ff c6             	inc    %si
  616a31:	74 0b                	je     0x616a3e
  616a33:	c5 f9 7f 8c 24 00 01 	vmovdqa %xmm1,0x100(%rsp)
  616a3a:	00 00 
  616a3c:	eb 0f                	jmp    0x616a4d
  616a3e:	c5 fd 6f 8c 24 00 01 	vmovdqa 0x100(%rsp),%ymm1
  616a45:	00 00 
  616a47:	c5 f9 7f 4c 24 50    	vmovdqa %xmm1,0x50(%rsp)
  616a4d:	c5 69 74 84 24 20 03 	vpcmpeqb 0x320(%rsp),%xmm2,%xmm8
  616a54:	00 00 
  616a56:	c4 c1 79 d7 f0       	vpmovmskb %xmm8,%esi
  616a5b:	66 ff c6             	inc    %si
  616a5e:	74 0b                	je     0x616a6b
  616a60:	c5 f9 7f 94 24 40 01 	vmovdqa %xmm2,0x140(%rsp)
  616a67:	00 00 
  616a69:	eb 0f                	jmp    0x616a7a
  616a6b:	c5 fd 6f 94 24 40 01 	vmovdqa 0x140(%rsp),%ymm2
  616a72:	00 00 
  616a74:	c5 f9 7f 54 24 60    	vmovdqa %xmm2,0x60(%rsp)
  616a7a:	c5 61 74 84 24 30 03 	vpcmpeqb 0x330(%rsp),%xmm3,%xmm8
  616a81:	00 00 
  616a83:	c4 c1 79 d7 f0       	vpmovmskb %xmm8,%esi
  616a88:	66 ff c6             	inc    %si
  616a8b:	74 0b                	je     0x616a98
  616a8d:	c5 f9 7f 9c 24 80 01 	vmovdqa %xmm3,0x180(%rsp)
  616a94:	00 00 
  616a96:	eb 0f                	jmp    0x616aa7
  616a98:	c5 fd 6f 9c 24 80 01 	vmovdqa 0x180(%rsp),%ymm3
  616a9f:	00 00 
  616aa1:	c5 f9 7f 5c 24 70    	vmovdqa %xmm3,0x70(%rsp)
  616aa7:	c5 59 74 84 24 40 03 	vpcmpeqb 0x340(%rsp),%xmm4,%xmm8
  616aae:	00 00 
  616ab0:	c4 c1 79 d7 f0       	vpmovmskb %xmm8,%esi
  616ab5:	66 ff c6             	inc    %si
  616ab8:	74 0b                	je     0x616ac5
  616aba:	c5 f9 7f a4 24 c0 01 	vmovdqa %xmm4,0x1c0(%rsp)
  616ac1:	00 00 
  616ac3:	eb 12                	jmp    0x616ad7
  616ac5:	c5 fd 6f a4 24 c0 01 	vmovdqa 0x1c0(%rsp),%ymm4
  616acc:	00 00 
  616ace:	c5 f9 7f a4 24 80 00 	vmovdqa %xmm4,0x80(%rsp)
  616ad5:	00 00 
  616ad7:	c5 51 74 84 24 50 03 	vpcmpeqb 0x350(%rsp),%xmm5,%xmm8
  616ade:	00 00 
  616ae0:	c4 c1 79 d7 f0       	vpmovmskb %xmm8,%esi
  616ae5:	66 ff c6             	inc    %si
  616ae8:	74 0b                	je     0x616af5
  616aea:	c5 f9 7f ac 24 00 02 	vmovdqa %xmm5,0x200(%rsp)
  616af1:	00 00 
  616af3:	eb 12                	jmp    0x616b07
  616af5:	c5 fd 6f ac 24 00 02 	vmovdqa 0x200(%rsp),%ymm5
  616afc:	00 00 
  616afe:	c5 f9 7f ac 24 90 00 	vmovdqa %xmm5,0x90(%rsp)
  616b05:	00 00 
  616b07:	c5 49 74 84 24 60 03 	vpcmpeqb 0x360(%rsp),%xmm6,%xmm8
  616b0e:	00 00 
  616b10:	c4 c1 79 d7 f0       	vpmovmskb %xmm8,%esi
  616b15:	66 ff c6             	inc    %si
  616b18:	74 0b                	je     0x616b25
  616b1a:	c5 f9 7f b4 24 40 02 	vmovdqa %xmm6,0x240(%rsp)
  616b21:	00 00 
  616b23:	eb 12                	jmp    0x616b37
  616b25:	c5 fd 6f b4 24 40 02 	vmovdqa 0x240(%rsp),%ymm6
  616b2c:	00 00 
  616b2e:	c5 f9 7f b4 24 a0 00 	vmovdqa %xmm6,0xa0(%rsp)
  616b35:	00 00 
  616b37:	c5 41 74 84 24 70 03 	vpcmpeqb 0x370(%rsp),%xmm7,%xmm8
  616b3e:	00 00 
  616b40:	c4 c1 79 d7 f0       	vpmovmskb %xmm8,%esi
  616b45:	66 ff c6             	inc    %si
  616b48:	74 0b                	je     0x616b55
  616b4a:	c5 f9 7f bc 24 80 02 	vmovdqa %xmm7,0x280(%rsp)
  616b51:	00 00 
  616b53:	eb 12                	jmp    0x616b67
  616b55:	c5 fd 6f bc 24 80 02 	vmovdqa 0x280(%rsp),%ymm7
  616b5c:	00 00 
  616b5e:	c5 f9 7f bc 24 b0 00 	vmovdqa %xmm7,0xb0(%rsp)
  616b65:	00 00 
  616b67:	48 8b 4b 10          	mov    0x10(%rbx),%rcx
  616b6b:	48 85 c9             	test   %rcx,%rcx
  616b6e:	79 1d                	jns    0x616b8d
  616b70:	48 8b 4c 24 18       	mov    0x18(%rsp),%rcx
  616b75:	48 8b 74 24 20       	mov    0x20(%rsp),%rsi
  616b7a:	48 8b 7c 24 28       	mov    0x28(%rsp),%rdi
  616b7f:	48 89 dc             	mov    %rbx,%rsp
  616b82:	48 8b 1c 24          	mov    (%rsp),%rbx
  616b86:	48 83 c4 30          	add    $0x30,%rsp
  616b8a:	41 ff e3             	jmp    *%r11
  616b8d:	48 8d 73 38          	lea    0x38(%rbx),%rsi
  616b91:	48 83 c1 08          	add    $0x8,%rcx
  616b95:	48 83 e1 f0          	and    $0xfffffffffffffff0,%rcx
  616b99:	48 29 cc             	sub    %rcx,%rsp
  616b9c:	48 89 e7             	mov    %rsp,%rdi
  616b9f:	f3 a4                	rep movsb (%rsi),(%rdi)
  616ba1:	48 8b 4f 18          	mov    0x18(%rdi),%rcx
  616ba5:	48 8b 77 20          	mov    0x20(%rdi),%rsi
  616ba9:	48 8b 7f 28          	mov    0x28(%rdi),%rdi
  616bad:	41 ff d3             	call   *%r11
  616bb0:	48 8b 63 18          	mov    0x18(%rbx),%rsp
  616bb4:	48 81 ec 10 01 00 00 	sub    $0x110,%rsp
  616bbb:	48 89 e1             	mov    %rsp,%rcx
  616bbe:	48 89 01             	mov    %rax,(%rcx)
  616bc1:	48 89 51 08          	mov    %rdx,0x8(%rcx)
  616bc5:	c5 f9 7f 41 10       	vmovdqa %xmm0,0x10(%rcx)
  616bca:	c5 f9 7f 49 20       	vmovdqa %xmm1,0x20(%rcx)
  616bcf:	c5 fd 7f 41 50       	vmovdqa %ymm0,0x50(%rcx)
  616bd4:	c5 fd 7f 89 90 00 00 	vmovdqa %ymm1,0x90(%rcx)
  616bdb:	00 
  616bdc:	c5 f9 7f 81 f0 00 00 	vmovdqa %xmm0,0xf0(%rcx)
  616be3:	00 
  616be4:	c5 f9 7f 89 00 01 00 	vmovdqa %xmm1,0x100(%rcx)
  616beb:	00 
  616bec:	db 79 30             	fstpt  0x30(%rcx)
  616bef:	db 79 40             	fstpt  0x40(%rcx)
  616bf2:	48 8b 53 18          	mov    0x18(%rbx),%rdx
  616bf6:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  616bfa:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  616bfe:	e8 ed 58 fd ff       	call   0x5ec4f0
  616c03:	48 8b 04 24          	mov    (%rsp),%rax
  616c07:	48 8b 54 24 08       	mov    0x8(%rsp),%rdx
  616c0c:	c5 f9 6f 44 24 10    	vmovdqa 0x10(%rsp),%xmm0
  616c12:	c5 f9 6f 4c 24 20    	vmovdqa 0x20(%rsp),%xmm1
  616c18:	c5 f9 74 94 24 f0 00 	vpcmpeqb 0xf0(%rsp),%xmm0,%xmm2
  616c1f:	00 00 
  616c21:	c5 f9 d7 f2          	vpmovmskb %xmm2,%esi
  616c25:	66 ff c6             	inc    %si
  616c28:	75 06                	jne    0x616c30
  616c2a:	c5 fd 6f 44 24 50    	vmovdqa 0x50(%rsp),%ymm0
  616c30:	c5 f1 74 94 24 00 01 	vpcmpeqb 0x100(%rsp),%xmm1,%xmm2
  616c37:	00 00 
  616c39:	c5 f9 d7 f2          	vpmovmskb %xmm2,%esi
  616c3d:	66 ff c6             	inc    %si
  616c40:	75 09                	jne    0x616c4b
  616c42:	c5 fd 6f 8c 24 90 00 	vmovdqa 0x90(%rsp),%ymm1
  616c49:	00 00 
  616c4b:	db 6c 24 40          	fldt   0x40(%rsp)
  616c4f:	db 6c 24 30          	fldt   0x30(%rsp)
  616c53:	48 89 dc             	mov    %rbx,%rsp
  616c56:	48 8b 1c 24          	mov    (%rsp),%rbx
  616c5a:	48 83 c4 30          	add    $0x30,%rsp
  616c5e:	c3                   	ret

