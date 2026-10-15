.section .text.init
.globl _start
_start:
    li sp, 0x3ff0
    li a0, 0x03000000

    li t2, 0x01
    sw t2, 0(a0)

    la t0, trap_handler
    csrw mtvec, t0

    # ---- 啟用 mie.MTIE (bit7) ----
    li t0, 0x80
    csrw mie, t0

    # ---- 啟用 mstatus.MIE ----
    li t0, 0x8
    csrw mstatus, t0

    # ---- 設定 mtimecmp 低位址為一個不算太大的值，讓計時器很快就觸發 ----
    li t1, 5000
    li t3, 0x09000008
    sw t1, 0(t3)
    li t1, 0
    li t3, 0x0900000C
    sw t1, 0(t3)

    li t2, 0x03
    sw t2, 0(a0)

busy_loop:
    j busy_loop

trap_handler:
    # 標記：計時器中斷觸發，讀出mcause確認原因
    csrr t4, mcause
    li t2, 0xAA
    sw t2, 0(a0)

    # 把mtimecmp設成很大的值，避免同一個中斷立刻又觸發一次
    li t1, 0xFFFFFFFF
    li t3, 0x09000008
    sw t1, 0(t3)
    li t1, 0xFFFFFFFF
    li t3, 0x0900000C
    sw t1, 0(t3)

    la t6, done
    csrw mepc, t6

    mret

done:
    li t2, 0xFF
    sw t2, 0(a0)

halt_loop:
    j halt_loop
