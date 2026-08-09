	.file	"hello.cpp"
	.section	.rodata.str1.8,"aMS",@progbits,1
	.align 8
.LC0:
	.string	"basic_string::_M_construct null not valid"
	.text
	.align 2
	.p2align 4,,15
	.type	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPcEEvT_S7_St20forward_iterator_tag.isra.74, @function
_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPcEEvT_S7_St20forward_iterator_tag.isra.74:
.LFB4511:
	.cfi_startproc
	pushq	%r12
	.cfi_def_cfa_offset 16
	.cfi_offset 12, -16
	pushq	%rbp
	.cfi_def_cfa_offset 24
	.cfi_offset 6, -24
	movq	%rsi, %r12
	pushq	%rbx
	.cfi_def_cfa_offset 32
	.cfi_offset 3, -32
	movq	%rdi, %rbp
	subq	$16, %rsp
	.cfi_def_cfa_offset 48
	movq	%fs:40, %rax
	movq	%rax, 8(%rsp)
	xorl	%eax, %eax
	testq	%rsi, %rsi
	jne	.L4
	testq	%rdx, %rdx
	je	.L4
	leaq	.LC0(%rip), %rdi
	call	_ZSt19__throw_logic_errorPKc@PLT
	.p2align 4,,10
	.p2align 3
.L4:
	movq	%rdx, %rbx
	subq	%r12, %rbx
	cmpq	$15, %rbx
	movq	%rbx, (%rsp)
	ja	.L23
	movq	0(%rbp), %rdx
	cmpq	$1, %rbx
	movq	%rdx, %rdi
	je	.L24
	testq	%rbx, %rbx
	jne	.L5
.L7:
	movq	(%rsp), %rax
	movq	%rax, 8(%rbp)
	movb	$0, (%rdx,%rax)
	movq	8(%rsp), %rax
	xorq	%fs:40, %rax
	jne	.L25
	addq	$16, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 32
	popq	%rbx
	.cfi_def_cfa_offset 24
	popq	%rbp
	.cfi_def_cfa_offset 16
	popq	%r12
	.cfi_def_cfa_offset 8
	ret
	.p2align 4,,10
	.p2align 3
.L23:
	.cfi_restore_state
	movq	%rbp, %rdi
	movq	%rsp, %rsi
	xorl	%edx, %edx
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERmm@PLT
	movq	%rax, %rdi
	movq	%rax, 0(%rbp)
	movq	(%rsp), %rax
	movq	%rax, 16(%rbp)
.L5:
	movq	%rbx, %rdx
	movq	%r12, %rsi
	call	memcpy@PLT
	movq	0(%rbp), %rdx
	jmp	.L7
	.p2align 4,,10
	.p2align 3
.L24:
	movzbl	(%r12), %eax
	movb	%al, (%rdx)
	movq	0(%rbp), %rdx
	jmp	.L7
.L25:
	call	__stack_chk_fail@PLT
	.cfi_endproc
.LFE4511:
	.size	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPcEEvT_S7_St20forward_iterator_tag.isra.74, .-_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPcEEvT_S7_St20forward_iterator_tag.isra.74
	.set	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPKcEEvT_S8_St20forward_iterator_tag.isra.54,_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPcEEvT_S7_St20forward_iterator_tag.isra.74
	.section	.text._ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE8_M_eraseEPSt13_Rb_tree_nodeIS8_E,"axG",@progbits,_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE8_M_eraseEPSt13_Rb_tree_nodeIS8_E,comdat
	.align 2
	.p2align 4,,15
	.weak	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE8_M_eraseEPSt13_Rb_tree_nodeIS8_E
	.type	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE8_M_eraseEPSt13_Rb_tree_nodeIS8_E, @function
_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE8_M_eraseEPSt13_Rb_tree_nodeIS8_E:
.LFB3977:
	.cfi_startproc
	testq	%rsi, %rsi
	je	.L39
	pushq	%r12
	.cfi_def_cfa_offset 16
	.cfi_offset 12, -16
	movq	%rdi, %r12
	pushq	%rbp
	.cfi_def_cfa_offset 24
	.cfi_offset 6, -24
	pushq	%rbx
	.cfi_def_cfa_offset 32
	.cfi_offset 3, -32
	movq	%rsi, %rbx
	.p2align 4,,10
	.p2align 3
.L33:
	movq	24(%rbx), %rsi
	movq	%r12, %rdi
	call	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE8_M_eraseEPSt13_Rb_tree_nodeIS8_E
	movq	32(%rbx), %rdi
	leaq	48(%rbx), %rax
	movq	16(%rbx), %rbp
	cmpq	%rax, %rdi
	je	.L28
	call	_ZdlPv@PLT
.L28:
	movq	%rbx, %rdi
	movq	%rbp, %rbx
	call	_ZdlPv@PLT
	testq	%rbp, %rbp
	jne	.L33
	popq	%rbx
	.cfi_restore 3
	.cfi_def_cfa_offset 24
	popq	%rbp
	.cfi_restore 6
	.cfi_def_cfa_offset 16
	popq	%r12
	.cfi_restore 12
	.cfi_def_cfa_offset 8
.L39:
	rep ret
	.cfi_endproc
.LFE3977:
	.size	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE8_M_eraseEPSt13_Rb_tree_nodeIS8_E, .-_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE8_M_eraseEPSt13_Rb_tree_nodeIS8_E
	.section	.text._ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEENS0_5__ops15_Iter_less_iterEEvT_S9_T0_,"axG",@progbits,_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEENS0_5__ops15_Iter_less_iterEEvT_S9_T0_,comdat
	.p2align 4,,15
	.weak	_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEENS0_5__ops15_Iter_less_iterEEvT_S9_T0_
	.type	_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEENS0_5__ops15_Iter_less_iterEEvT_S9_T0_, @function
_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEENS0_5__ops15_Iter_less_iterEEvT_S9_T0_:
.LFB4221:
	.cfi_startproc
	cmpq	%rdi, %rsi
	je	.L59
	leaq	4(%rdi), %rax
	cmpq	%rax, %rsi
	je	.L59
	pushq	%r15
	.cfi_def_cfa_offset 16
	.cfi_offset 15, -16
	pushq	%r14
	.cfi_def_cfa_offset 24
	.cfi_offset 14, -24
	movq	%rdi, %r15
	pushq	%r13
	.cfi_def_cfa_offset 32
	.cfi_offset 13, -32
	pushq	%r12
	.cfi_def_cfa_offset 40
	.cfi_offset 12, -40
	leaq	8(%rdi), %r12
	pushq	%rbp
	.cfi_def_cfa_offset 48
	.cfi_offset 6, -48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	.cfi_offset 3, -56
	movq	%rsi, %rbp
	movl	$4, %r13d
	subq	$8, %rsp
	.cfi_def_cfa_offset 64
	.p2align 4,,10
	.p2align 3
.L48:
	movl	-4(%r12), %ebx
	cmpl	(%r15), %ebx
	leaq	-4(%r12), %rcx
	movq	%r12, %r14
	jl	.L61
	movl	-8(%r12), %edx
	leaq	-8(%r12), %rax
	cmpl	%edx, %ebx
	jl	.L47
	jmp	.L62
	.p2align 4,,10
	.p2align 3
.L50:
	movq	%rcx, %rax
.L47:
	movl	%edx, 4(%rax)
	movl	-4(%rax), %edx
	leaq	-4(%rax), %rcx
	cmpl	%edx, %ebx
	jl	.L50
.L46:
	movl	%ebx, (%rax)
.L45:
	addq	$4, %r12
	addq	$4, %r13
	cmpq	%r14, %rbp
	jne	.L48
	addq	$8, %rsp
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_restore 3
	.cfi_def_cfa_offset 48
	popq	%rbp
	.cfi_restore 6
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_restore 12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_restore 13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_restore 14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_restore 15
	.cfi_def_cfa_offset 8
.L59:
	rep ret
	.p2align 4,,10
	.p2align 3
.L61:
	.cfi_def_cfa_offset 64
	.cfi_offset 3, -56
	.cfi_offset 6, -48
	.cfi_offset 12, -40
	.cfi_offset 13, -32
	.cfi_offset 14, -24
	.cfi_offset 15, -16
	movq	%r13, %rax
	sarq	$2, %rax
	testq	%rax, %rax
	je	.L44
	movl	$4, %edi
	movq	%r13, %rdx
	movq	%r15, %rsi
	subq	%r13, %rdi
	addq	%rcx, %rdi
	call	memmove@PLT
.L44:
	movl	%ebx, (%r15)
	jmp	.L45
.L62:
	movq	%rcx, %rax
	jmp	.L46
	.cfi_endproc
.LFE4221:
	.size	_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEENS0_5__ops15_Iter_less_iterEEvT_S9_T0_, .-_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEENS0_5__ops15_Iter_less_iterEEvT_S9_T0_
	.section	.text._ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE24_M_get_insert_unique_posERS7_,"axG",@progbits,_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE24_M_get_insert_unique_posERS7_,comdat
	.align 2
	.p2align 4,,15
	.weak	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE24_M_get_insert_unique_posERS7_
	.type	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE24_M_get_insert_unique_posERS7_, @function
_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE24_M_get_insert_unique_posERS7_:
.LFB4255:
	.cfi_startproc
	pushq	%r15
	.cfi_def_cfa_offset 16
	.cfi_offset 15, -16
	pushq	%r14
	.cfi_def_cfa_offset 24
	.cfi_offset 14, -24
	pushq	%r13
	.cfi_def_cfa_offset 32
	.cfi_offset 13, -32
	pushq	%r12
	.cfi_def_cfa_offset 40
	.cfi_offset 12, -40
	pushq	%rbp
	.cfi_def_cfa_offset 48
	.cfi_offset 6, -48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	.cfi_offset 3, -56
	subq	$24, %rsp
	.cfi_def_cfa_offset 80
	movq	16(%rdi), %rbx
	movq	%rdi, 8(%rsp)
	movq	%rsi, (%rsp)
	testq	%rbx, %rbx
	je	.L88
	movq	(%rsp), %rax
	movq	8(%rax), %r15
	movq	(%rax), %r12
	jmp	.L66
	.p2align 4,,10
	.p2align 3
.L89:
	movq	%r14, %rdx
	movq	%r13, %rsi
	movq	%r12, %rdi
	call	memcmp@PLT
	testl	%eax, %eax
	je	.L68
.L69:
	testl	%eax, %eax
	js	.L71
.L70:
	movq	24(%rbx), %rax
	xorl	%edx, %edx
	testq	%rax, %rax
	je	.L67
.L90:
	movq	%rax, %rbx
.L66:
	movq	40(%rbx), %rbp
	movq	32(%rbx), %r13
	cmpq	%rbp, %r15
	movq	%rbp, %r14
	cmovbe	%r15, %r14
	testq	%r14, %r14
	jne	.L89
.L68:
	movq	%r15, %rax
	subq	%rbp, %rax
	cmpq	$2147483647, %rax
	jg	.L70
	cmpq	$-2147483648, %rax
	jge	.L69
	.p2align 4,,10
	.p2align 3
.L71:
	movq	16(%rbx), %rax
	movl	$1, %edx
	testq	%rax, %rax
	jne	.L90
.L67:
	testb	%dl, %dl
	jne	.L65
	movq	%r14, %rdx
	movq	%rbx, %r14
.L73:
	testq	%rdx, %rdx
	je	.L76
	movq	%r12, %rsi
	movq	%r13, %rdi
	call	memcmp@PLT
	testl	%eax, %eax
	je	.L76
	testl	%eax, %eax
	js	.L79
.L78:
	addq	$24, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 56
	movq	%r14, %rax
	xorl	%edx, %edx
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%rbp
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	ret
	.p2align 4,,10
	.p2align 3
.L76:
	.cfi_restore_state
	subq	%r15, %rbp
	cmpq	$2147483647, %rbp
	jg	.L78
	cmpq	$-2147483648, %rbp
	jl	.L79
	movl	%ebp, %eax
	testl	%eax, %eax
	jns	.L78
.L79:
	addq	$24, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 56
	movq	%rbx, %rdx
	xorl	%eax, %eax
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%rbp
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	ret
.L88:
	.cfi_restore_state
	leaq	8(%rdi), %rbx
	.p2align 4,,10
	.p2align 3
.L65:
	movq	8(%rsp), %rax
	cmpq	%rbx, 24(%rax)
	je	.L79
	movq	%rbx, %rdi
	call	_ZSt18_Rb_tree_decrementPSt18_Rb_tree_node_base@PLT
	movq	%rax, %r14
	movq	(%rsp), %rax
	movq	40(%r14), %rbp
	movq	32(%r14), %r13
	movq	8(%rax), %r15
	movq	(%rax), %r12
	cmpq	%r15, %rbp
	movq	%r15, %rdx
	cmovbe	%rbp, %rdx
	jmp	.L73
	.cfi_endproc
.LFE4255:
	.size	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE24_M_get_insert_unique_posERS7_, .-_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE24_M_get_insert_unique_posERS7_
	.section	.text._ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE29_M_get_insert_hint_unique_posESt23_Rb_tree_const_iteratorIS8_ERS7_,"axG",@progbits,_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE29_M_get_insert_hint_unique_posESt23_Rb_tree_const_iteratorIS8_ERS7_,comdat
	.align 2
	.p2align 4,,15
	.weak	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE29_M_get_insert_hint_unique_posESt23_Rb_tree_const_iteratorIS8_ERS7_
	.type	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE29_M_get_insert_hint_unique_posESt23_Rb_tree_const_iteratorIS8_ERS7_, @function
_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE29_M_get_insert_hint_unique_posESt23_Rb_tree_const_iteratorIS8_ERS7_:
.LFB4136:
	.cfi_startproc
	pushq	%r15
	.cfi_def_cfa_offset 16
	.cfi_offset 15, -16
	leaq	8(%rdi), %rax
	pushq	%r14
	.cfi_def_cfa_offset 24
	.cfi_offset 14, -24
	pushq	%r13
	.cfi_def_cfa_offset 32
	.cfi_offset 13, -32
	pushq	%r12
	.cfi_def_cfa_offset 40
	.cfi_offset 12, -40
	movq	%rdi, %r15
	pushq	%rbp
	.cfi_def_cfa_offset 48
	.cfi_offset 6, -48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	.cfi_offset 3, -56
	movq	%rdx, %r13
	subq	$24, %rsp
	.cfi_def_cfa_offset 80
	cmpq	%rax, %rsi
	je	.L136
	movq	8(%rdx), %r12
	movq	40(%rsi), %rbp
	movq	%rsi, %rbx
	movq	32(%rsi), %r8
	movq	(%rdx), %r14
	cmpq	%rbp, %r12
	movq	%rbp, %rcx
	cmovbe	%r12, %rcx
	testq	%rcx, %rcx
	jne	.L137
	movq	%r12, %rax
	subq	%rbp, %rax
	cmpq	$2147483647, %rax
	jle	.L118
.L108:
	subq	%r12, %rbp
	cmpq	$2147483647, %rbp
	jle	.L138
.L110:
	movq	%rbx, %rax
	xorl	%edx, %edx
.L127:
	addq	$24, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%rbp
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	ret
	.p2align 4,,10
	.p2align 3
.L137:
	.cfi_restore_state
	movq	%rcx, %rdx
	movq	%r8, %rsi
	movq	%r14, %rdi
	movq	%rcx, 8(%rsp)
	movq	%r8, (%rsp)
	call	memcmp@PLT
	testl	%eax, %eax
	movq	(%rsp), %r8
	movq	8(%rsp), %rcx
	je	.L139
	js	.L101
.L117:
	movq	%rcx, %rdx
	movq	%r14, %rsi
	movq	%r8, %rdi
	call	memcmp@PLT
	testl	%eax, %eax
	je	.L108
.L109:
	testl	%eax, %eax
	jns	.L110
.L111:
	cmpq	%rbx, 32(%r15)
	je	.L134
	movq	%rbx, %rdi
	call	_ZSt18_Rb_tree_incrementPSt18_Rb_tree_node_base@PLT
	movq	40(%rax), %rcx
	movq	%rax, %rbp
	cmpq	%rcx, %r12
	movq	%rcx, %rdx
	cmovbe	%r12, %rdx
	testq	%rdx, %rdx
	je	.L113
	movq	32(%rax), %rsi
	movq	%r14, %rdi
	movq	%rcx, (%rsp)
	call	memcmp@PLT
	testl	%eax, %eax
	movq	(%rsp), %rcx
	je	.L113
.L114:
	testl	%eax, %eax
	jns	.L93
.L115:
	cmpq	$0, 24(%rbx)
	movq	%rbp, %rax
	movq	%rbp, %rdx
	jne	.L127
.L134:
	addq	$24, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 56
	movq	%rbx, %rdx
	xorl	%eax, %eax
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%rbp
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	ret
	.p2align 4,,10
	.p2align 3
.L101:
	.cfi_restore_state
	cmpq	%rbx, 24(%r15)
	movq	%rbx, %rax
	movq	%rbx, %rdx
	je	.L127
	movq	%rbx, %rdi
	call	_ZSt18_Rb_tree_decrementPSt18_Rb_tree_node_base@PLT
	movq	40(%rax), %rbp
	movq	%rax, %rcx
	cmpq	%rbp, %r12
	movq	%rbp, %rdx
	cmovbe	%r12, %rdx
	testq	%rdx, %rdx
	je	.L104
	movq	32(%rax), %rdi
	movq	%r14, %rsi
	movq	%rax, (%rsp)
	call	memcmp@PLT
	testl	%eax, %eax
	movq	(%rsp), %rcx
	je	.L104
.L105:
	testl	%eax, %eax
	jns	.L93
.L106:
	cmpq	$0, 24(%rcx)
	movq	%rbx, %rax
	movq	%rbx, %rdx
	jne	.L127
	xorl	%eax, %eax
	movq	%rcx, %rdx
	jmp	.L127
	.p2align 4,,10
	.p2align 3
.L104:
	subq	%r12, %rbp
	cmpq	$2147483647, %rbp
	jle	.L140
.L93:
	movq	%r13, %rsi
	movq	%r15, %rdi
	call	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE24_M_get_insert_unique_posERS7_
	addq	$24, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%rbp
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	ret
	.p2align 4,,10
	.p2align 3
.L139:
	.cfi_restore_state
	movq	%r12, %rax
	subq	%rbp, %rax
	cmpq	$2147483647, %rax
	jg	.L117
.L118:
	cmpq	$-2147483648, %rax
	jl	.L101
	testl	%eax, %eax
	js	.L101
	testq	%rcx, %rcx
	jne	.L117
	jmp	.L108
	.p2align 4,,10
	.p2align 3
.L136:
	cmpq	$0, 40(%rdi)
	je	.L93
	movq	32(%rdi), %rbx
	movq	8(%rdx), %r12
	movq	40(%rbx), %rbp
	movq	%r12, %rdx
	cmpq	%r12, %rbp
	cmovbe	%rbp, %rdx
	testq	%rdx, %rdx
	jne	.L141
.L94:
	subq	%r12, %rbp
	cmpq	$2147483647, %rbp
	jg	.L93
	cmpq	$-2147483648, %rbp
	jl	.L134
	movl	%ebp, %eax
.L95:
	testl	%eax, %eax
	jns	.L93
	jmp	.L134
	.p2align 4,,10
	.p2align 3
.L138:
	cmpq	$-2147483648, %rbp
	jl	.L111
	movl	%ebp, %eax
	jmp	.L109
	.p2align 4,,10
	.p2align 3
.L113:
	subq	%rcx, %r12
	cmpq	$2147483647, %r12
	jg	.L93
	cmpq	$-2147483648, %r12
	jl	.L115
	movl	%r12d, %eax
	jmp	.L114
	.p2align 4,,10
	.p2align 3
.L141:
	movq	32(%rbx), %rdi
	movq	0(%r13), %rsi
	call	memcmp@PLT
	testl	%eax, %eax
	jne	.L95
	jmp	.L94
	.p2align 4,,10
	.p2align 3
.L140:
	cmpq	$-2147483648, %rbp
	jl	.L106
	movl	%ebp, %eax
	jmp	.L105
	.cfi_endproc
.LFE4136:
	.size	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE29_M_get_insert_hint_unique_posESt23_Rb_tree_const_iteratorIS8_ERS7_, .-_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE29_M_get_insert_hint_unique_posESt23_Rb_tree_const_iteratorIS8_ERS7_
	.section	.text._ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC2ESt16initializer_listISA_ERKS7_RKSB_,"axG",@progbits,_ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC5ESt16initializer_listISA_ERKS7_RKSB_,comdat
	.align 2
	.p2align 4,,15
	.weak	_ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC2ESt16initializer_listISA_ERKS7_RKSB_
	.type	_ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC2ESt16initializer_listISA_ERKS7_RKSB_, @function
_ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC2ESt16initializer_listISA_ERKS7_RKSB_:
.LFB3752:
	.cfi_startproc
	.cfi_personality 0x9b,DW.ref.__gxx_personality_v0
	.cfi_lsda 0x1b,.LLSDA3752
	leaq	(%rdx,%rdx,4), %rax
	pushq	%r15
	.cfi_def_cfa_offset 16
	.cfi_offset 15, -16
	pushq	%r14
	.cfi_def_cfa_offset 24
	.cfi_offset 14, -24
	pushq	%r13
	.cfi_def_cfa_offset 32
	.cfi_offset 13, -32
	pushq	%r12
	.cfi_def_cfa_offset 40
	.cfi_offset 12, -40
	leaq	8(%rdi), %r14
	pushq	%rbp
	.cfi_def_cfa_offset 48
	.cfi_offset 6, -48
	leaq	(%rsi,%rax,8), %r15
	pushq	%rbx
	.cfi_def_cfa_offset 56
	.cfi_offset 3, -56
	subq	$40, %rsp
	.cfi_def_cfa_offset 96
	cmpq	%rsi, %r15
	movl	$0, 8(%rdi)
	movq	$0, 16(%rdi)
	movq	$0, 40(%rdi)
	movq	%r14, 24(%rdi)
	movq	%r14, 32(%rdi)
	je	.L142
	movq	%rdi, %r13
	movq	%rsi, %rbx
	.p2align 4,,10
	.p2align 3
.L163:
	movq	%rbx, %rdx
	movq	%r14, %rsi
	movq	%r13, %rdi
	call	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE29_M_get_insert_hint_unique_posESt23_Rb_tree_const_iteratorIS8_ERS7_
	testq	%rdx, %rdx
	movq	%rdx, %r12
	je	.L144
	testq	%rax, %rax
	setne	%al
	cmpq	%rdx, %r14
	sete	%dil
	orb	%dil, %al
	movb	%al, (%rsp)
	jne	.L145
	movq	8(%rbx), %rbp
	movq	40(%rdx), %rcx
	cmpq	%rcx, %rbp
	movq	%rcx, %rdx
	cmovbe	%rbp, %rdx
	testq	%rdx, %rdx
	je	.L146
	movq	32(%r12), %rsi
	movq	(%rbx), %rdi
	movq	%rcx, 24(%rsp)
	call	memcmp@PLT
	testl	%eax, %eax
	movq	24(%rsp), %rcx
	je	.L146
.L147:
	shrl	$31, %eax
	movl	%eax, (%rsp)
.L145:
	movl	$72, %edi
.LEHB0:
	call	_Znwm@PLT
.LEHE0:
	movq	(%rbx), %rsi
	movq	%rax, %rbp
	leaq	32(%rax), %rdi
	leaq	48(%rax), %rax
	movq	%rsi, %rdx
	addq	8(%rbx), %rdx
	movq	%rax, 32(%rbp)
.LEHB1:
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPcEEvT_S7_St20forward_iterator_tag.isra.74
.LEHE1:
	movl	32(%rbx), %eax
	movzbl	(%rsp), %edi
	movq	%r14, %rcx
	movq	%r12, %rdx
	movq	%rbp, %rsi
	movl	%eax, 64(%rbp)
	call	_ZSt29_Rb_tree_insert_and_rebalancebPSt18_Rb_tree_node_baseS0_RS_@PLT
	addq	$1, 40(%r13)
.L144:
	addq	$40, %rbx
	cmpq	%r15, %rbx
	jne	.L163
.L142:
	addq	$40, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%rbp
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	ret
	.p2align 4,,10
	.p2align 3
.L146:
	.cfi_restore_state
	subq	%rcx, %rbp
	cmpq	$2147483647, %rbp
	jg	.L145
	cmpq	$-2147483648, %rbp
	jl	.L153
	movl	%ebp, %eax
	jmp	.L147
.L153:
	movb	$1, (%rsp)
	jmp	.L145
.L155:
	movq	%rax, %rdi
	call	__cxa_begin_catch@PLT
	movq	%rbp, %rdi
	call	_ZdlPv@PLT
.LEHB2:
	call	__cxa_rethrow@PLT
.LEHE2:
.L154:
	movq	%rax, %rbx
.L150:
	movq	16(%r13), %rsi
	movq	%r13, %rdi
	call	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE8_M_eraseEPSt13_Rb_tree_nodeIS8_E
	movq	%rbx, %rdi
.LEHB3:
	call	_Unwind_Resume@PLT
.LEHE3:
.L156:
	movq	%rax, %rbx
	call	__cxa_end_catch@PLT
	jmp	.L150
	.cfi_endproc
.LFE3752:
	.globl	__gxx_personality_v0
	.section	.gcc_except_table._ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC2ESt16initializer_listISA_ERKS7_RKSB_,"aG",@progbits,_ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC5ESt16initializer_listISA_ERKS7_RKSB_,comdat
	.align 4
.LLSDA3752:
	.byte	0xff
	.byte	0x9b
	.uleb128 .LLSDATT3752-.LLSDATTD3752
.LLSDATTD3752:
	.byte	0x1
	.uleb128 .LLSDACSE3752-.LLSDACSB3752
.LLSDACSB3752:
	.uleb128 .LEHB0-.LFB3752
	.uleb128 .LEHE0-.LEHB0
	.uleb128 .L154-.LFB3752
	.uleb128 0
	.uleb128 .LEHB1-.LFB3752
	.uleb128 .LEHE1-.LEHB1
	.uleb128 .L155-.LFB3752
	.uleb128 0x1
	.uleb128 .LEHB2-.LFB3752
	.uleb128 .LEHE2-.LEHB2
	.uleb128 .L156-.LFB3752
	.uleb128 0
	.uleb128 .LEHB3-.LFB3752
	.uleb128 .LEHE3-.LEHB3
	.uleb128 0
	.uleb128 0
.LLSDACSE3752:
	.byte	0x1
	.byte	0
	.align 4
	.long	0

.LLSDATT3752:
	.section	.text._ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC2ESt16initializer_listISA_ERKS7_RKSB_,"axG",@progbits,_ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC5ESt16initializer_listISA_ERKS7_RKSB_,comdat
	.size	_ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC2ESt16initializer_listISA_ERKS7_RKSB_, .-_ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC2ESt16initializer_listISA_ERKS7_RKSB_
	.weak	_ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC1ESt16initializer_listISA_ERKS7_RKSB_
	.set	_ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC1ESt16initializer_listISA_ERKS7_RKSB_,_ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC2ESt16initializer_listISA_ERKS7_RKSB_
	.section	.text._ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_less_iterEEvT_T0_SA_T1_T2_,"axG",@progbits,_ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_less_iterEEvT_T0_SA_T1_T2_,comdat
	.p2align 4,,15
	.weak	_ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_less_iterEEvT_T0_SA_T1_T2_
	.type	_ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_less_iterEEvT_T0_SA_T1_T2_, @function
_ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_less_iterEEvT_T0_SA_T1_T2_:
.LFB4390:
	.cfi_startproc
	leaq	-1(%rdx), %rax
	pushq	%r12
	.cfi_def_cfa_offset 16
	.cfi_offset 12, -16
	pushq	%rbp
	.cfi_def_cfa_offset 24
	.cfi_offset 6, -24
	pushq	%rbx
	.cfi_def_cfa_offset 32
	.cfi_offset 3, -32
	movq	%rax, %r12
	shrq	$63, %r12
	addq	%rax, %r12
	sarq	%r12
	cmpq	%r12, %rsi
	jge	.L166
	movq	%rsi, %r10
	.p2align 4,,10
	.p2align 3
.L168:
	leaq	1(%r10), %r8
	leaq	(%r8,%r8), %rax
	leaq	(%rdi,%r8,8), %r8
	leaq	-1(%rax), %r11
	movl	(%r8), %r9d
	leaq	(%rdi,%r11,4), %rbp
	movl	0(%rbp), %ebx
	cmpl	%r9d, %ebx
	jle	.L167
	movq	%rbp, %r8
	movl	%ebx, %r9d
	movq	%r11, %rax
.L167:
	cmpq	%r12, %rax
	movl	%r9d, (%rdi,%r10,4)
	movq	%rax, %r10
	jl	.L168
	testb	$1, %dl
	jne	.L169
.L175:
	leaq	-2(%rdx), %r9
	movq	%r9, %rdx
	shrq	$63, %rdx
	addq	%r9, %rdx
	sarq	%rdx
	cmpq	%rax, %rdx
	je	.L180
.L169:
	cmpq	%rsi, %rax
	jle	.L170
	leaq	-1(%rax), %r9
	movq	%r9, %rdx
	shrq	$63, %rdx
	addq	%r9, %rdx
	sarq	%rdx
	movl	(%rdi,%rdx,4), %r10d
	cmpl	%r10d, %ecx
	jle	.L170
	cmpq	%rdx, %rsi
	leaq	(%rdi,%rdx,4), %r8
	movl	%r10d, (%rdi,%rax,4)
	jge	.L170
.L173:
	leaq	-1(%rdx), %rax
	movq	%rax, %r9
	shrq	$63, %r9
	addq	%rax, %r9
	sarq	%r9
	movl	(%rdi,%r9,4), %r10d
	cmpl	%r10d, %ecx
	jle	.L170
	movq	%rdx, %rax
	movq	%r9, %rdx
	cmpq	%rdx, %rsi
	leaq	(%rdi,%rdx,4), %r8
	movl	%r10d, (%rdi,%rax,4)
	jl	.L173
.L170:
	movl	%ecx, (%r8)
	popq	%rbx
	.cfi_remember_state
	.cfi_def_cfa_offset 24
	popq	%rbp
	.cfi_def_cfa_offset 16
	popq	%r12
	.cfi_def_cfa_offset 8
	ret
	.p2align 4,,10
	.p2align 3
.L180:
	.cfi_restore_state
	leaq	1(%rax,%rax), %rax
	leaq	(%rdi,%rax,4), %rdx
	movl	(%rdx), %r9d
	movl	%r9d, (%r8)
	movq	%rdx, %r8
	jmp	.L169
.L166:
	testb	$1, %dl
	leaq	(%rdi,%rsi,4), %r8
	movq	%rsi, %rax
	je	.L175
	jmp	.L170
	.cfi_endproc
.LFE4390:
	.size	_ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_less_iterEEvT_T0_SA_T1_T2_, .-_ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_less_iterEEvT_T0_SA_T1_T2_
	.text
	.p2align 4,,15
	.type	_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEElNS0_5__ops15_Iter_less_iterEEvT_S9_T0_T1_.isra.97, @function
_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEElNS0_5__ops15_Iter_less_iterEEvT_S9_T0_T1_.isra.97:
.LFB4534:
	.cfi_startproc
	movq	%rsi, %rax
	subq	%rdi, %rax
	cmpq	$67, %rax
	jle	.L212
	testq	%rdx, %rdx
	pushq	%r14
	.cfi_def_cfa_offset 16
	.cfi_offset 14, -16
	movq	%rdx, %r14
	pushq	%r13
	.cfi_def_cfa_offset 24
	.cfi_offset 13, -24
	movq	%rsi, %r13
	pushq	%r12
	.cfi_def_cfa_offset 32
	.cfi_offset 12, -32
	movq	%rdi, %r12
	pushq	%rbp
	.cfi_def_cfa_offset 40
	.cfi_offset 6, -40
	pushq	%rbx
	.cfi_def_cfa_offset 48
	.cfi_offset 3, -48
	je	.L183
	leaq	8(%rdi), %rbx
	movq	%rsi, %rbp
.L184:
	subq	%r12, %rbp
	movl	4(%r12), %esi
	subq	$1, %r14
	sarq	$2, %rbp
	movl	-4(%r13), %ecx
	movq	%rbp, %rax
	shrq	$63, %rax
	addq	%rax, %rbp
	sarq	%rbp
	leaq	(%r12,%rbp,4), %rdx
	movl	(%rdx), %eax
	cmpl	%eax, %esi
	jge	.L189
	cmpl	%ecx, %eax
	jl	.L195
	cmpl	%ecx, %esi
	jge	.L213
.L214:
	movl	(%r12), %edx
	movl	%ecx, (%r12)
	movl	%edx, -4(%r13)
	movl	4(%r12), %r8d
	movl	(%r12), %esi
.L191:
	movq	%rbx, %rdi
	movq	%r13, %rcx
	.p2align 4,,10
	.p2align 3
.L193:
	cmpl	%esi, %r8d
	leaq	-4(%rdi), %rbp
	jl	.L196
	cmpl	%esi, %edx
	leaq	-4(%rcx), %rax
	jle	.L201
	leaq	-8(%rcx), %rax
	.p2align 4,,10
	.p2align 3
.L198:
	movq	%rax, %rcx
	subq	$4, %rax
	movl	4(%rax), %edx
	cmpl	%esi, %edx
	jg	.L198
	cmpq	%rcx, %rbp
	jnb	.L215
.L199:
	movl	%edx, -4(%rdi)
	movl	%r8d, (%rcx)
	movl	-4(%rcx), %edx
	movl	(%r12), %esi
.L196:
	movl	(%rdi), %r8d
	addq	$4, %rdi
	jmp	.L193
.L201:
	movq	%rax, %rcx
	cmpq	%rcx, %rbp
	jb	.L199
.L215:
	movq	%r14, %rdx
	movq	%r13, %rsi
	movq	%rbp, %rdi
	call	_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEElNS0_5__ops15_Iter_less_iterEEvT_S9_T0_T1_.isra.97
	movq	%rbp, %rax
	subq	%r12, %rax
	cmpq	$67, %rax
	jle	.L181
	testq	%r14, %r14
	movq	%rbp, %r13
	jne	.L184
.L183:
	sarq	$2, %rax
	leaq	-2(%rax), %rbp
	movq	%rax, %rbx
	sarq	%rbp
	jmp	.L186
.L216:
	subq	$1, %rbp
.L186:
	subq	$8, %rsp
	.cfi_def_cfa_offset 56
	movl	(%r12,%rbp,4), %ecx
	movq	%rbp, %rsi
	pushq	$0
	.cfi_def_cfa_offset 64
	movq	%rbx, %rdx
	movq	%r12, %rdi
	call	_ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_less_iterEEvT_T0_SA_T1_T2_
	testq	%rbp, %rbp
	popq	%rcx
	.cfi_def_cfa_offset 56
	popq	%rsi
	.cfi_def_cfa_offset 48
	jne	.L216
	subq	$4, %r13
.L187:
	movl	(%r12), %eax
	movq	%r13, %rbx
	movl	0(%r13), %ecx
	subq	$8, %rsp
	.cfi_def_cfa_offset 56
	subq	%r12, %rbx
	xorl	%esi, %esi
	movq	%rbx, %rdx
	movq	%r12, %rdi
	subq	$4, %r13
	movl	%eax, 4(%r13)
	pushq	$0
	.cfi_def_cfa_offset 64
	sarq	$2, %rdx
	call	_ZSt13__adjust_heapIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEEliNS0_5__ops15_Iter_less_iterEEvT_T0_SA_T1_T2_
	cmpq	$7, %rbx
	popq	%rax
	.cfi_def_cfa_offset 56
	popq	%rdx
	.cfi_def_cfa_offset 48
	jg	.L187
.L181:
	popq	%rbx
	.cfi_restore 3
	.cfi_def_cfa_offset 40
	popq	%rbp
	.cfi_restore 6
	.cfi_def_cfa_offset 32
	popq	%r12
	.cfi_restore 12
	.cfi_def_cfa_offset 24
	popq	%r13
	.cfi_restore 13
	.cfi_def_cfa_offset 16
	popq	%r14
	.cfi_restore 14
	.cfi_def_cfa_offset 8
.L212:
	ret
.L189:
	.cfi_def_cfa_offset 48
	.cfi_offset 3, -48
	.cfi_offset 6, -40
	.cfi_offset 12, -32
	.cfi_offset 13, -24
	.cfi_offset 14, -16
	cmpl	%ecx, %esi
	jl	.L213
	cmpl	%ecx, %eax
	jl	.L214
.L195:
	movl	(%r12), %ecx
	movl	%eax, (%r12)
	movl	%ecx, (%rdx)
	movl	4(%r12), %r8d
	movl	(%r12), %esi
	movl	-4(%r13), %edx
	jmp	.L191
.L213:
	movl	(%r12), %r8d
	movl	%esi, (%r12)
	movl	%r8d, 4(%r12)
	movl	-4(%r13), %edx
	jmp	.L191
	.cfi_endproc
.LFE4534:
	.size	_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEElNS0_5__ops15_Iter_less_iterEEvT_S9_T0_T1_.isra.97, .-_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEElNS0_5__ops15_Iter_less_iterEEvT_S9_T0_T1_.isra.97
	.section	.rodata.str1.1,"aMS",@progbits,1
.LC1:
	.string	"a"
.LC2:
	.string	"C++ "
.LC3:
	.string	" "
	.section	.text.startup,"ax",@progbits
	.p2align 4,,15
	.globl	main
	.type	main, @function
main:
.LFB3490:
	.cfi_startproc
	.cfi_personality 0x9b,DW.ref.__gxx_personality_v0
	.cfi_lsda 0x1b,.LLSDA3490
	pushq	%r15
	.cfi_def_cfa_offset 16
	.cfi_offset 15, -16
	pushq	%r14
	.cfi_def_cfa_offset 24
	.cfi_offset 14, -24
	movl	$12, %edi
	pushq	%r13
	.cfi_def_cfa_offset 32
	.cfi_offset 13, -32
	pushq	%r12
	.cfi_def_cfa_offset 40
	.cfi_offset 12, -40
	pushq	%rbp
	.cfi_def_cfa_offset 48
	.cfi_offset 6, -48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	.cfi_offset 3, -56
	subq	$632, %rsp
	.cfi_def_cfa_offset 688
	movq	%fs:40, %rax
	movq	%rax, 616(%rsp)
	xorl	%eax, %eax
.LEHB4:
	call	_Znwm@PLT
.LEHE4:
	movq	%rax, %rbp
	leaq	12(%rax), %rbx
	movq	._69(%rip), %rax
	movl	$2, %edx
	movq	%rbp, %rdi
	movq	%rbx, %rsi
	movq	%rax, 0(%rbp)
	movl	8+._69(%rip), %eax
	movl	%eax, 8(%rbp)
	call	_ZSt16__introsort_loopIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEElNS0_5__ops15_Iter_less_iterEEvT_S9_T0_T1_.isra.97
	subq	$8, %rsp
	.cfi_def_cfa_offset 696
	movq	%rbx, %rsi
	movq	%rbp, %rdi
	pushq	$0
	.cfi_def_cfa_offset 704
	leaq	208(%rsp), %rbx
	call	_ZSt16__insertion_sortIN9__gnu_cxx17__normal_iteratorIPiSt6vectorIiSaIiEEEENS0_5__ops15_Iter_less_iterEEvT_S9_T0_
	leaq	16(%rbx), %rax
	leaq	.LC1(%rip), %rsi
	movq	%rbx, %rdi
	movq	%rax, 208(%rsp)
	popq	%rax
	.cfi_def_cfa_offset 696
	popq	%rdx
	.cfi_def_cfa_offset 688
	leaq	1+.LC1(%rip), %rdx
.LEHB5:
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPKcEEvT_S8_St20forward_iterator_tag.isra.54
.LEHE5:
	leaq	80(%rsp), %rax
	leaq	78(%rsp), %rcx
	leaq	79(%rsp), %r8
	movq	%rbx, %rsi
	movl	$1, %edx
	movl	$1, 224(%rsp)
	movq	%rax, %rdi
	movq	%rax, (%rsp)
.LEHB6:
	call	_ZNSt3mapINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEiSt4lessIS5_ESaISt4pairIKS5_iEEEC1ESt16initializer_listISA_ERKS7_RKSB_
.LEHE6:
	movq	192(%rsp), %rdi
	addq	$16, %rbx
	cmpq	%rbx, %rdi
	je	.L222
	call	_ZdlPv@PLT
.L222:
	movl	$4, %edi
.LEHB7:
	call	_Znwm@PLT
.LEHE7:
	movq	%rax, %rbx
	movq	%rax, 24(%rsp)
	movl	$7, (%rax)
	leaq	240(%rsp), %rax
	movl	$16, %esi
	movq	%rax, %rdi
	movq	%rax, 8(%rsp)
.LEHB8:
	call	_ZNSt7__cxx1119basic_ostringstreamIcSt11char_traitsIcESaIcEEC1ESt13_Ios_Openmode@PLT
.LEHE8:
	movl	(%rbx), %eax
	leaq	1+.LC1(%rip), %rdx
	leaq	.LC1(%rip), %rsi
	movl	%eax, 36(%rsp)
	leaq	128(%rsp), %rax
	movq	%rax, %rdi
	movq	%rax, 16(%rsp)
	leaq	144(%rsp), %rax
	movq	%rax, 128(%rsp)
.LEHB9:
	call	_ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE12_M_constructIPKcEEvT_S8_St20forward_iterator_tag.isra.54
.LEHE9:
	movq	96(%rsp), %rcx
	testq	%rcx, %rcx
	je	.L252
	movq	(%rsp), %rax
	movq	128(%rsp), %r13
	movq	%rcx, %r15
	movq	136(%rsp), %r12
	leaq	8(%rax), %rbx
	jmp	.L224
	.p2align 4,,10
	.p2align 3
.L278:
	movq	32(%r15), %rdi
	movq	%r13, %rsi
	call	memcmp@PLT
	testl	%eax, %eax
	je	.L226
	testl	%eax, %eax
	js	.L229
.L228:
	movq	%r15, %rbx
	movq	16(%r15), %r15
	testq	%r15, %r15
	je	.L225
.L224:
	movq	40(%r15), %r14
	cmpq	%r14, %r12
	movq	%r14, %rdx
	cmovbe	%r12, %rdx
	testq	%rdx, %rdx
	jne	.L278
.L226:
	movq	%r14, %r8
	subq	%r12, %r8
	cmpq	$2147483647, %r8
	jg	.L228
	cmpq	$-2147483648, %r8
	jl	.L229
	movl	%r8d, %eax
	testl	%eax, %eax
	jns	.L228
.L229:
	movq	24(%r15), %r15
	testq	%r15, %r15
	jne	.L224
.L225:
	movq	(%rsp), %rax
	addq	$8, %rax
	cmpq	%rax, %rbx
	je	.L223
	movq	40(%rbx), %rcx
	cmpq	%rcx, %r12
	movq	%rcx, %rdx
	cmovbe	%r12, %rdx
	testq	%rdx, %rdx
	je	.L231
	movq	32(%rbx), %rsi
	movq	%r13, %rdi
	movq	%rcx, 40(%rsp)
	call	memcmp@PLT
	testl	%eax, %eax
	movq	40(%rsp), %rcx
	je	.L231
.L232:
	testl	%eax, %eax
	movq	%rbx, %rdx
	jns	.L233
.L223:
	movl	$72, %edi
.LEHB10:
	call	_Znwm@PLT
	leaq	48(%rax), %rcx
	movq	16(%rsp), %rsi
	movq	%rax, %r13
	leaq	32(%rax), %rdx
	movq	%rcx, 32(%rax)
	movq	128(%rsp), %rax
	addq	$16, %rsi
	cmpq	%rsi, %rax
	je	.L279
	movq	%rax, 32(%r13)
	movq	144(%rsp), %rax
	movq	%rax, 48(%r13)
.L235:
	movq	136(%rsp), %rax
	movq	(%rsp), %r14
	movq	%rbx, %rsi
	movl	$0, 64(%r13)
	movq	%rcx, 40(%rsp)
	movq	$0, 136(%rsp)
	movb	$0, 144(%rsp)
	movq	%rax, 40(%r13)
	movq	16(%rsp), %rax
	movq	%r14, %rdi
	addq	$16, %rax
	movq	%rax, 128(%rsp)
	call	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE29_M_get_insert_hint_unique_posESt23_Rb_tree_const_iteratorIS8_ERS7_
	testq	%rdx, %rdx
	movq	%rdx, %r8
	movq	%rax, %rbx
	movq	40(%rsp), %rcx
	je	.L236
	leaq	8(%r14), %rdx
	cmpq	%rdx, %r8
	sete	%dil
	testq	%rax, %rax
	setne	%al
	movl	%edi, %ebx
	orb	%al, %bl
	jne	.L237
	movq	40(%r13), %r9
	movq	40(%r8), %rcx
	cmpq	%rcx, %r9
	movq	%rcx, %rdx
	cmovbe	%r9, %rdx
	testq	%rdx, %rdx
	je	.L238
	movq	32(%r8), %rsi
	movq	32(%r13), %rdi
	movq	%rcx, 56(%rsp)
	movq	%r9, 48(%rsp)
	movq	%r8, 40(%rsp)
	call	memcmp@PLT
	testl	%eax, %eax
	movq	40(%rsp), %r8
	movq	48(%rsp), %r9
	movq	56(%rsp), %rcx
	je	.L238
.L239:
	shrl	$31, %eax
	movl	%eax, %ebx
.L237:
	movq	(%rsp), %rax
	movzbl	%bl, %edi
	movq	%r8, %rdx
	movq	%r13, %rsi
	movq	%r13, %rbx
	leaq	8(%rax), %rcx
	call	_ZSt29_Rb_tree_insert_and_rebalancebPSt18_Rb_tree_node_baseS0_RS_@PLT
	addq	$1, 120(%rsp)
.L240:
	movq	%rbx, %rdx
.L233:
	movq	8(%rsp), %rbx
	leaq	.LC2(%rip), %rsi
	movl	64(%rdx), %r13d
	movl	$4, %edx
	movq	%rbx, %rdi
	call	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movl	$3, %esi
	movq	%rbx, %rdi
	call	_ZNSo9_M_insertImEERSoT_@PLT
	leaq	.LC3(%rip), %rsi
	movl	$1, %edx
	movq	%rax, %rdi
	movq	%rax, %rbx
	call	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movl	%r13d, %esi
	movq	%rbx, %rdi
	call	_ZNSolsEi@PLT
	leaq	.LC3(%rip), %rsi
	movl	$1, %edx
	movq	%rax, %rdi
	movq	%rax, %rbx
	call	_ZSt16__ostream_insertIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_PKS3_l@PLT
	movl	36(%rsp), %esi
	movq	%rbx, %rdi
	call	_ZNSolsEi@PLT
.LEHE10:
	movq	16(%rsp), %r12
	movq	128(%rsp), %rdi
	addq	$16, %r12
	cmpq	%r12, %rdi
	je	.L242
	call	_ZdlPv@PLT
.L242:
	movq	8(%rsp), %rax
	leaq	160(%rsp), %rbx
	movq	%rbx, %rdi
	leaq	8(%rax), %rsi
.LEHB11:
	call	_ZNKSt7__cxx1115basic_stringbufIcSt11char_traitsIcESaIcEE3strEv@PLT
.LEHE11:
	movq	160(%rsp), %rdi
.LEHB12:
	call	puts@PLT
.LEHE12:
	movq	160(%rsp), %rdi
	addq	$16, %rbx
	cmpq	%rbx, %rdi
	je	.L243
	call	_ZdlPv@PLT
.L243:
	movq	8(%rsp), %rdi
	call	_ZNSt7__cxx1119basic_ostringstreamIcSt11char_traitsIcESaIcEED1Ev@PLT
	movq	24(%rsp), %rdi
	movl	$4, %esi
	call	_ZdlPvm@PLT
	movq	96(%rsp), %rsi
	movq	(%rsp), %rdi
	call	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE8_M_eraseEPSt13_Rb_tree_nodeIS8_E
	movq	%rbp, %rdi
	call	_ZdlPv@PLT
	xorl	%eax, %eax
	movq	616(%rsp), %rcx
	xorq	%fs:40, %rcx
	jne	.L280
	addq	$632, %rsp
	.cfi_remember_state
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%rbp
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	ret
.L231:
	.cfi_restore_state
	movq	%r12, %r9
	movq	%rbx, %rdx
	subq	%rcx, %r9
	cmpq	$2147483647, %r9
	jg	.L233
	cmpq	$-2147483648, %r9
	jl	.L223
	movl	%r9d, %eax
	jmp	.L232
.L236:
	movq	32(%r13), %rdi
	cmpq	%rcx, %rdi
	je	.L241
	call	_ZdlPv@PLT
.L241:
	movq	%r13, %rdi
	call	_ZdlPv@PLT
	jmp	.L240
.L252:
	movq	(%rsp), %rax
	leaq	8(%rax), %rbx
	jmp	.L223
.L279:
	movq	144(%rsp), %rsi
	movq	152(%rsp), %rdi
	movq	%rsi, 48(%r13)
	movq	%rdi, 56(%r13)
	jmp	.L235
.L238:
	movq	%r9, %rax
	subq	%rcx, %rax
	cmpq	$2147483647, %rax
	jg	.L237
	cmpq	$-2147483648, %rax
	jge	.L239
	movl	$1, %ebx
	jmp	.L237
.L263:
	movq	160(%rsp), %rdi
	addq	$16, %rbx
	movq	%rax, %r12
	cmpq	%rbx, %rdi
	je	.L248
	call	_ZdlPv@PLT
.L248:
	movq	%r12, %rbx
.L246:
	movq	8(%rsp), %rdi
	call	_ZNSt7__cxx1119basic_ostringstreamIcSt11char_traitsIcESaIcEED1Ev@PLT
.L249:
	movq	24(%rsp), %rdi
	movl	$4, %esi
	call	_ZdlPvm@PLT
.L250:
	movq	96(%rsp), %rsi
	movq	(%rsp), %rdi
	call	_ZNSt8_Rb_treeINSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEESt4pairIKS5_iESt10_Select1stIS8_ESt4lessIS5_ESaIS8_EE8_M_eraseEPSt13_Rb_tree_nodeIS8_E
.L221:
	movq	%rbp, %rdi
	call	_ZdlPv@PLT
	movq	%rbx, %rdi
.LEHB13:
	call	_Unwind_Resume@PLT
.LEHE13:
.L260:
	movq	%rax, %rbx
	jmp	.L249
.L259:
	movq	%rax, %rbx
	jmp	.L250
.L258:
	movq	192(%rsp), %rdi
	addq	$16, %rbx
	movq	%rax, %r12
	cmpq	%rbx, %rdi
	je	.L220
	call	_ZdlPv@PLT
.L220:
	movq	%r12, %rbx
	jmp	.L221
.L262:
	movq	%rax, %rbx
	jmp	.L246
.L280:
	call	__stack_chk_fail@PLT
.L257:
	movq	%rax, %rbx
	jmp	.L221
.L261:
	movq	16(%rsp), %r12
	movq	128(%rsp), %rdi
	movq	%rax, %rbx
	addq	$16, %r12
	cmpq	%r12, %rdi
	je	.L246
	call	_ZdlPv@PLT
	jmp	.L246
	.cfi_endproc
.LFE3490:
	.section	.gcc_except_table,"a",@progbits
.LLSDA3490:
	.byte	0xff
	.byte	0xff
	.byte	0x1
	.uleb128 .LLSDACSE3490-.LLSDACSB3490
.LLSDACSB3490:
	.uleb128 .LEHB4-.LFB3490
	.uleb128 .LEHE4-.LEHB4
	.uleb128 0
	.uleb128 0
	.uleb128 .LEHB5-.LFB3490
	.uleb128 .LEHE5-.LEHB5
	.uleb128 .L257-.LFB3490
	.uleb128 0
	.uleb128 .LEHB6-.LFB3490
	.uleb128 .LEHE6-.LEHB6
	.uleb128 .L258-.LFB3490
	.uleb128 0
	.uleb128 .LEHB7-.LFB3490
	.uleb128 .LEHE7-.LEHB7
	.uleb128 .L259-.LFB3490
	.uleb128 0
	.uleb128 .LEHB8-.LFB3490
	.uleb128 .LEHE8-.LEHB8
	.uleb128 .L260-.LFB3490
	.uleb128 0
	.uleb128 .LEHB9-.LFB3490
	.uleb128 .LEHE9-.LEHB9
	.uleb128 .L262-.LFB3490
	.uleb128 0
	.uleb128 .LEHB10-.LFB3490
	.uleb128 .LEHE10-.LEHB10
	.uleb128 .L261-.LFB3490
	.uleb128 0
	.uleb128 .LEHB11-.LFB3490
	.uleb128 .LEHE11-.LEHB11
	.uleb128 .L262-.LFB3490
	.uleb128 0
	.uleb128 .LEHB12-.LFB3490
	.uleb128 .LEHE12-.LEHB12
	.uleb128 .L263-.LFB3490
	.uleb128 0
	.uleb128 .LEHB13-.LFB3490
	.uleb128 .LEHE13-.LEHB13
	.uleb128 0
	.uleb128 0
.LLSDACSE3490:
	.section	.text.startup
	.size	main, .-main
	.section	.rodata
	.align 8
	.type	._69, @object
	.size	._69, 12
._69:
	.long	3
	.long	1
	.long	2
	.hidden	DW.ref.__gxx_personality_v0
	.weak	DW.ref.__gxx_personality_v0
	.section	.data.DW.ref.__gxx_personality_v0,"awG",@progbits,DW.ref.__gxx_personality_v0,comdat
	.align 8
	.type	DW.ref.__gxx_personality_v0, @object
	.size	DW.ref.__gxx_personality_v0, 8
DW.ref.__gxx_personality_v0:
	.quad	__gxx_personality_v0
	.ident	"GCC: (Alpine 6.4.0) 6.4.0"
	.section	.note.GNU-stack,"",@progbits
