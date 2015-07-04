
.intel_syntax noprefix

    .include "../includes/unistd.h"

    .data                           # section declaration

	msg: 		.ascii  "Hello World!\n"
	msg2: 		.ascii  "bitches.....\n"
	msglen:		.int	0 
	errfail:	.ascii	"*** Failure ***\n"		
	arr_bf:		.space  0x400				# arrarybuffer
	loopmax:	.int	32
	msgptr:		.int	0
	seed:		.int	0
	vara:		.int	1664525
	varc:		.int	1013904223
	
    .global _start                  # ELF linker requires starting point to be _start

_start:
	call  	fillbuffer				# populate the buffer with data

	mov		ecx, offset msg			
	mov		msgptr, ecx
	mov		ecx,13
	mov		msglen, ecx
	call	print

	mov		ecx, offset msg2		
	mov		msgptr, ecx
	mov		ecx,13
	mov		msglen, ecx
	call	print

	jmp		exit

fillbuffer:
	call getseed
	ret

getseed:
	mov		eax,SYS_TIME			# get the time in seconds
	mov		ebx,offset seed			# the address of seed
	int		0x80					# interrupt the kernel

	mov		eax,1664525				# set multipler (a)
	mov		ecx,seed				# set multiplicand : seed
	mul		ecx						# (a * seed) : result will reside in EDX:EAX


	jnc		fail					# print msg and get out if there was a problem

	/* do MOD function with result here */

	/* create a method to print the value of seed */


	/* SYS_TIME
		Linear-Congruential Algorithm.
		Once a seed value is generated, it is used as the seed for the following random number
		x = (a * s + b) MOD m  

		seed = (a * seed) MOD 2^32 

		m, a and b are picked for the algorithm - for the purposes of this test, m will be 2^32

		from Wikipedia
		Source				m	(multiplier) a   	(increment) c	output bits of seed in rand() / Random(L)  b
		Numerical Recipes	2	1664525				1013904223												   (not-used)
	*/

	ret

print:
    mov   	eax,SYS_WRITE           # system call number (sys_write)
    mov   	ebx,1                   # first argument: file handle (stdout)
    mov   	ecx,msgptr	            # second argument: pointer to message to write */
    mov   	edx,msglen              # third argument: message length
    int		0x80                    # call kernel
	ret								# return to the caller

fail:
	mov		ecx,offset errfail
	mov		msgptr, ecx				# set address of failure message
	mov		ecx,13
	mov		msglen, ecx
	call	print

exit:
    mov   	ebx,SYS_EXIT              # first argument: exit code
    mov   	eax,1                     # system call number (sys_exit)
    int   	0x80                      # call kernel

