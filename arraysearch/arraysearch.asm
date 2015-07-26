
    .intel_syntax noprefix
    .include "../includes/unistd.h"

.data
    adjup:    .asciz  "\nadjup\n"
    uplen =.-adjup
    adjdown:    .asciz  "\nadjdown\n"
    downlen =.-adjdown
    debugmsg:   .asciz  "*** debug ***\n"
    debuglen =.-debugmsg

    bitches:    .ascii  "\nbitches.....\n"
    blen =.-bitches
    msg_seed:   .ascii  "seed generation was successful\n"
    slen = .-msg_seed

    arrbf:      .asciz  ""          # array buffer
        .org arrbf + 0x400
    regdata:    .asciz  "1234"
#        .org regdata + 4

    blank:      .int    0x20
    msgptr:     .int    0           # ptr to msg buffer
    msglen:     .int    0           # length of the msg buffer data
    seed:       .int    0           # seed for the random number generator
    cntr:       .int    0           # loop counter
    dlen:       .int    0x400       # len for printing arrbf

    .global _start                  # ELF linker requires starting point to be _start

_start:
    call    _fillbuffer             # populate the buffer with data
    jmp     _exit

    mov  cntr, dword ptr 48           # set to loop for a total of 4 times

_fillbuffer:
    call  debug
    call  setseed       # get new seed
    call debug

    cld
    mov esi, offset dword ptr seed
    call debug
    mov ecx, cntr
    mov edi, offset dword ptr regdata[ecx]
    call debug
    rep movsb
    call debug

    mov  msgptr, offset dword ptr regdata
    mov  msglen, dword ptr 4
    call print

    sub edi, edi            # clear registers
    sub ecx, ecx
    mov ecx, dword ptr cntr
    mov esi, regdata[ecx]   # point si at the next char
    call debug
    mov edi, 0x20
    cmp si, di              # do the compare
    jbe _adjustup           # if si <= di, add value to regdata

    call debug

    mov di, 0x7e            # set edi to tilde char
    cmp si, di              # compare again
    jg  _adjustdown         # if si > di, subtract value from regdata

    # !!!!!!!!!!!!!! save the character that was in the ascii table, right here!!!!!!!!!!!!!!!

_adjustdown:
    mov     msgptr, offset dword ptr adjdown
    mov     msglen, dword ptr downlen
    call    print

    call debug
    mov esi, offset regdata[ecx]    # point si at the next char
    call debug
    mov ebx, esi                    # put esi into ebx - its lazy, but that's what those register are for
    sub ebx, 0x7e                   # subtract to move into the ascii table
    mov regdata[ecx], bl            # move into the buffer
    call debug

    pop  ecx
    dec  ecx
    cmp  ecx,0
    jnz  _fillbuffer
    jmp _printregdat

_adjustup:
    mov     msgptr, offset dword ptr adjup
    mov     msglen, dword ptr uplen
    call    print

    call debug
    mov esi, offset dword ptr regdata[ecx]   # point si at the next char
    call debug
    mov bx, si              # put si into bx
    add bx, 0x21            # add 0x21 to move into the printable character range
    mov regdata[ecx], bl    # move that back into the buffer
    call debug

    pop  ecx
    dec  ecx
    cmp  ecx,0
    jnz  _fillbuffer
    jmp _printregdat

setseed:
    /*
        Linear-Congruential Algorithm.
        Once a seed value is generated, it is used as the seed for the following random number
        x = (a * s + b) MOD m

        seed = (a * seed) MOD 2^32

        m, a and b are picked for the algorithm - for the purposes of this test, m will be 2^32

        from Wikipedia
        Source              m       (multiplier) a      (increment) c   output bits of seed in rand() / Random(L)  b
        Numerical Recipes   2^32    1664525             1013904223                                                 (not-used)
    */
    push    eax     # push registers
    push    ebx
    push    ecx
    push    edx

    mov     eax,SYS_TIME                # get the time in seconds
    mov     ebx,offset dword ptr seed   # the address of seed
    int     0x80                        # interrupt the kernel
    call debug

    mov     eax,1664525                 # set multipler (a)
    mov     ecx,seed                    # set multiplicand : seed
    mul     ecx                         # (a * seed) : result will reside in EDX:EAX
    call debug

    mov     ecx,0xffffffff              # use 'div ecx' to divide the 64-bit operand in EDX:EAX by ecx
    div     ecx                         # the quotient is saved in to eax
    mov     seed,edx                    # the remainder is saved in edx
    call debug

    mov     msgptr, offset dword ptr msg_seed
    mov     msglen, dword ptr slen
    call    print
    call debug

    pop     edx     # pop registers
    pop     ecx
    pop     ebx
    pop     eax

    ret

debug:
    push    eax     # push registers
    push    ebx
    push    ecx
    push    edx

    mov     eax, SYS_WRITE              # just like it sounds
    mov     ebx, 1                      # stdout
    mov     ecx, offset debugmsg        # pointer to message to write
    mov     edx, dword ptr debuglen     # message length
    int     0x80                        # call kernel

    pop     edx     # pop registers
    pop     ecx
    pop     ebx
    pop     eax
    ret             # return to the caller

_printregdat:
    push    eax     #push registers
    push    ebx
    push    ecx
    push    edx

    mov     eax,SYS_WRITE           # just like it sounds
    mov     ebx,1                   #   stdout
    mov     ecx, offset regdata     # pointer to message to write
    mov     edx, dword ptr 2        # message length
    int     0x80                    # call kernel

    pop     edx     # pop registers
    pop     ecx
    pop     ebx
    pop     eax
    jmp     _exit   # get out

print:
    push    eax                     # push registers
    push    ebx
    push    ecx
    push    edx

    mov     eax,SYS_WRITE           # just like it sounds
    mov     ebx,1                   # stdout
    mov     ecx,msgptr              # pointer to message to write
    mov     edx,msglen              # message length
    int     0x80                    # call kernel

    pop     edx                     # pop registers
    pop     ecx
    pop     ebx
    pop     eax
    ret                             # return to the caller

_exit:
    mov     ebx,SYS_EXIT            # first argument: exit code
    mov     eax,1                   # system call number (sys_exit)
    int     0x80                    # call kernel

    ret
