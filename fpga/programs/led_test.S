.section .text.init
.globl _start
_start:
    li sp, 0x3ff0

    li t3, 0x00000001
    li t4, 0x03000000
    sw t3, 0(t4)

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

    li t3, 0xFF
    li t4, 0x03000000
    sw t3, 0(t4)

    la t5, done
    csrw mepc, t5

    mret

done:
    li t3, 0xAA
    li t4, 0x03000000
    sw t3, 0(t4)

halt_loop:
    j halt_loop
