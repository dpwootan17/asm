
    .intel_syntax noprefix
    .include "../includes/unistd.h"

.data
    adjup:    .ascii  "\nadjup\n"
    uplen =.-adjup
    adjdown:    .ascii  "\nadjdown\n"
    downlen =.-adjdown

    bitches:    .ascii  "\nbitches.....\n"
    blen =.-bitches
    msg_seed:   .ascii  "seed generation was successful\n"
    slen = .-msg_seed
    errfail:    .ascii  "\n*** Failure ***\n"
    elen =.-errfail

    arrbf:      .asciz  ""          # array buffer
        .org arrbf + 0x400
    regdata:    .asciz  ""
        .org regdata + 4

    msgptr:     .int    0           # ptr to msg buffer
    msglen:     .int    0           # length of the msg buffer data
    seed:       .int    0           # seed for the random number generator
    cntr:       .int    0           # loop counter
    dlen:       .int    0x400       # len for printing arrbf

    .global _start                  # ELF linker requires starting point to be _start

_start:
    call    fillbuffer              # populate the buffer with data
    jmp     exit

fillbuffer:

     call    setseed             # get new seed

/* */

    mov ecx, 4
    cld
    mov esi, offset dword ptr seed
    mov edi, offset dword ptr regdata
    rep movsb

    mov     msgptr, offset dword ptr regdata
    mov     msglen, dword ptr 4
    call    print

    sub edi, edi            # clear registers
    sub ecx, ecx
    mov esi, regdata[ecx]   # point si at the next char
    mov edi, 0x20           # set edi to space char
    cld
    cmp esi, edi            # do the compare
    jbe _adjustdown         # if esi <= edi, add value to regdata
    mov edi, 0x7e           # set edi to tilde char
    cld
    cmp esi, edi            # compare again
    jg  _adjustup           # if esi > edi, subtract value in regdata
    jmp _donehere

_adjustdown:
    mov     msgptr, offset dword ptr adjdown
    mov     msglen, dword ptr downlen
    call    print
#    mov [esi], dword ptr 0x7e         # set tilde char

_adjustup:
    mov     msgptr, offset dword ptr adjup
    mov     msglen, dword ptr uplen
    call    print
#    mov     [esi], dword ptr 0x32         # add value of space char to the buffer

_donehere:

    mov     msgptr, offset dword ptr bitches
    mov     msglen, dword ptr blen
    call    print

    mov     msgptr, esi
    mov     msglen, dword ptr 4
    call    print


    mov     msgptr, offset dword ptr bitches
    mov     msglen, dword ptr blen
    call    print

    mov     eax,SYS_WRITE                  # system call number (sys_write)
    mov     ebx,1                          # first argument: file handle (stdout)
    mov     ecx,offset dword ptr regdata   # second argument: pointer to message to write */
    mov     edx,4                          # third argument: message length
    int     0x80                           # call kernel

/* */

#        mov     eax, 8                              # multiplier
#        mov     ecx, cntr                           # multiplicand
#        mul     ecx                                 # result will be in EDX:EAX
#        mov     esi, eax                            # put result in esi
#        mov     edi, offset dword ptr arrbf[esi]    # point at arrbf
#
#        inc     dword ptr cntr                      # increment cntr for next arrbf[offset] calculation

_end:
    mov     msgptr, offset dword ptr bitches
    mov     msglen, dword ptr blen
    call    print

    ret

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

    mov     eax,SYS_TIME                # get the time in seconds
    mov     ebx,offset dword ptr seed   # the address of seed
    int     0x80                        # interrupt the kernel

    mov     eax,1664525                 # set multipler (a)
    mov     ecx,seed                    # set multiplicand : seed
    mul     ecx                         # (a * seed) : result will reside in EDX:EAX

    mov     ecx,0xffffffff              # use 'div ecx' to divide the 64-bit operand in EDX:EAX by ecx
    div     ecx
    mov     seed,edx                    # the remainder is saved in edx

    mov     msgptr, offset dword ptr msg_seed
    mov     msglen, dword ptr slen
    call    print

    ret

print:
    mov     eax,SYS_WRITE           # system call number (sys_write)
    mov     ebx,1                   # first argument: file handle (stdout)
    mov     ecx,msgptr              # second argument: pointer to message to write */
    mov     edx,msglen              # third argument: message length
    int     0x80                    # call kernel
    ret                             # return to the caller

fail:
    mov     msgptr, offset dword ptr errfail
    mov     msglen, dword ptr elen
    call    print

exit:
    mov     ebx,SYS_EXIT              # first argument: exit code
    mov     eax,1                     # system call number (sys_exit)
    int     0x80                      # call kernel

