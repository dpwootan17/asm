
.intel_syntax noprefix

    .include "../includes/unistd.h"

.data

	msg: 		.ascii  "Hello World!\n"
	mlen = .-msg
	bitches: 	.ascii  "bitches.....\n"
	blen =.-bitches
	msg_seed:	.ascii  "seed generation was successful\n"
	slen = .-msg_seed
	errfail:	.ascii	"*** Failure ***\n"
	elen =.-errfail

	arrbf:		.space  0x400,'#'	# array buffer
	msgptr:		.int	0			# ptr to msg buffer
	msglen:		.int	0 			# length of the msg buffer data
	seed:		.int	0			# seed for the random number generator
	cntr:		.int	0			# loop counter
	dlen:		.int	0x400		# len for printing arrbf

    .global _start                  # ELF linker requires starting point to be _start

_start:
	call  	fillbuffer				# populate the buffer with data

	mov		msgptr, offset dword ptr msg
	mov		msglen, dword ptr mlen
	call	print

	mov		msgptr, offset dword ptr bitches
	mov		msglen, dword ptr blen
	call	print

	jmp		exit

fillbuffer:
	mov		ecx, 0x100				# initialize loop counters
	mov		edx, 0
	_loopstart:
		push	ecx					# push ecx
		push	edx					# push edx
		call 	setseed
		pop		edx					# pop  edx

		mov		eax, 8				# multiplier
		mov		ecx, cntr			# multiplicand
		mul		ecx					# result will be in EDX:EAX
		mov		esi, eax								# put result in esi
		mov 	edi, offset dword ptr arrbf[esi]		# point at arrbf

		mov		esi, seed			# set to point at seed
		pop		ecx					# pop ecx loop counter`
		xchg	eax,ecx				# and save it again
		mov		ecx, 2				# set ecx to move two dwords during the movsb
		cld							# new string op, clear the direction flag
#		rep		movsd				# move the data
		xchg	eax,ecx				# restore ecx one more time

		inc		dword ptr cntr		# increment cntr for next arrbf[offset] calculation
	loopnz _loopstart

	mov		msgptr, offset dword ptr bitches
	mov		msglen, dword ptr blen
	call	print

	sub		esi, esi
	mov		msgptr, offset dword ptr arrbf
	mov		msglen, offset dword ptr dlen
	call	print

	ret

setseed:
	/* 
		Linear-Congruential Algorithm.
		Once a seed value is generated, it is used as the seed for the following random number
		x = (a * s + b) MOD m  

		seed = (a * seed) MOD 2^32 

		m, a and b are picked for the algorithm - for the purposes of this test, m will be 2^32

		from Wikipedia
		Source				m		(multiplier) a   	(increment) c	output bits of seed in rand() / Random(L)  b
		Numerical Recipes	2^32	1664525				1013904223												   (not-used)
	*/

	mov		eax,SYS_TIME				# get the time in seconds
	mov		ebx,offset dword ptr seed	# the address of seed
	int		0x80						# interrupt the kernel

	mov		eax,1664525					# set multipler (a)
	mov		ecx,seed					# set multiplicand : seed
	mul		ecx							# (a * seed) : result will reside in EDX:EAX

	mov		ecx,0xffffffff				# use 'div ecx' to divide the 64-bit operand in EDX:EAX by ecx
	div		ecx
	mov		seed,edx					# the remainder is saved in edx						

	mov		msgptr, offset dword ptr msg_seed
	mov		msglen, dword ptr slen
	call	print

	ret

print:
    mov   	eax,SYS_WRITE           # system call number (sys_write)
    mov   	ebx,1                   # first argument: file handle (stdout)
    mov   	ecx,msgptr	            # second argument: pointer to message to write */
    mov   	edx,msglen              # third argument: message length
    int		0x80                    # call kernel
	ret								# return to the caller

fail:
	mov		msgptr, offset dword ptr errfail
	mov		msglen, dword ptr elen
	call	print

exit:
    mov   	ebx,SYS_EXIT              # first argument: exit code
    mov   	eax,1                     # system call number (sys_exit)
    int   	0x80                      # call kernel

