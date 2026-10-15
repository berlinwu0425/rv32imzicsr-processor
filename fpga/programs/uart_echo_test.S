.section .text.init
.globl _start
_start:
    li sp, 0x3ff0
    li a0, 0x03000000

    li t2, 0x01
    sw t2, 0(a0)

    la t0, trap_handler
    csrw mtvec, t0

    li t0, 0x8
    csrw mie, t0

    li t0, 0x8
    csrw mstatus, t0

    li t2, 0x03
    sw t2, 0(a0)

busy_loop:
    j busy_loop

trap_handler:
    li t3, 0x08000000
    lw t1, 0(t3)

    sw t1, 0(a0)

    li t4, 0
    li t5, 0x2000000
    sw t4, 0(t5)

wait_tx_ready:
    li t3, 0x08000008
    lw t4, 0(t3)
    bnez t4, wait_tx_ready

    li t3, 0x08000004
    sw t1, 0(t3)

    la t6, busy_loop
    csrw mepc, t6

    mret
