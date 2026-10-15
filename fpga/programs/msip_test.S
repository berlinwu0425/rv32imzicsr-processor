.section .text.init
.globl _start
_start:
    li sp, 0x80003000

    la t0, trap_handler
    csrw mtvec, t0

    li t0, 0x8
    csrw mie, t0

    li t0, 0x8
    csrw mstatus, t0

    li t1, 1
    li t2, 0x2000000
    sw t1, 0(t2)

busy_loop:
    j busy_loop

trap_handler:
    li t1, 0
    li t2, 0x2000000
    sw t1, 0(t2)

    li t3, 0xCAFEBABE
    li t4, 0x80003100
    sw t3, 0(t4)

    la t5, done
    csrw mepc, t5

    mret

done:
    li t3, 0x01
    li t4, 0x03000000
    sw t3, 0(t4)

busy_loop2:
    j busy_loop2
