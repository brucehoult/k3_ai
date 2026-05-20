	.globl _start
_start:	ld	s0, (sp)	# argc
	addi	s1, sp, 8	# argv
	addi	s2, sp, 24
	sh3add	s2, s0, s2	# envp

	# s3 = ourPID
	li	a7, 172
	ecall
	mv	s3, a0

	# s11 = openat(aiFile)
	li	a0, -100
	la	a1, aiFile
	li	a2, 0x241
	li	a3, 0600
	li	a7, 56
	ecall
	mv	s11, a0

	# print PID to file
	mv	a0, s3
	call	wuint

	# close file
	mv	a0, s11
	li	a7, 57
	ecall
	
	# Exec the program in argv[1] with remaining args
	ld	a0, 8(s1)	# filename = argv[1]
	addi	a1, s1, 8	# new_argv = &argv[1]
	mv	a2, s2		# envp
	li	a7, 221		# sys_execve
	ecall

	# If execve fails, exit
	li	a0, 1
	li	a7, 93
	ecall

wuint:	la	a1, bufend
	mv	a2, a1
	li	a3, 10
1:	remu	a4, a0, a3
	divu	a0, a0, a3
	addi	a4, a4, '0'
	addi	a1, a1, -1
	sb	a4, (a1)
	bnez	a0, 1b
	mv	a0, s11		# fd
	sub	a2, a2, a1	# count, a1 is already ptr to buf
	li	a7,64
	ecall
	ret

aiFile:	.asciz "/proc/set_ai_thread"

	.section .data
buf:	.space 24
bufend:	
