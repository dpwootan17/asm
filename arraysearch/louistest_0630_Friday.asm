
.intel_syntax noprefix

    .include "../includes/unistd.h"

    .data                           # section declaration

msg:
    .ascii      "Hello, world!\n"   # our dear string
    .global _start                  # ELF linker requires starting point to be _startr 

_start:
	  mov   eax,SYS_WRITE       # system call number (sys_write)
	  mov   ebx,1               # first argument: file handle (stdout)
	  mov   ecx,offset msg      # second argument: pointer to message to write
	  mov   edx,14              # third argument: message length
	  int   0x80                # call kernel

	  mov   ebx,SYS_EXIT        # first argument: exit code
	  mov   eax,1               # system call number (sys_exit)
	  int   0x80                # call kernel
