.section .text
.global  _start

_start:
	add	r0, pc,  #12	@addr of string
	mov	r1, #0		@argv
	mov	r2, #0		@envp
	mov	r7, #11		@__NR_execve
	svc	#0
.ascii "/bin/sh\0"
