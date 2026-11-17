# 未對齊的load緊接著用到它結果的指令(load-use stall與例外同拍)：例外不能遺失
#include "common.inc"
.section .text.init
.globl _start
_start:
    la   s4, handler
    csrw mtvec, s4
    li   a0, 0
    li   s9, 0x300
    lw   s4, 1(s9)            # 未對齊 -> load address misaligned (mcause = 4)
    addi s5, s4, 1            # 用到t0：load-use
    EXPECT a0, 1, 2
    EXPECT a1, 4, 3
    FINISH
handler:
    addi a0, a0, 1
    csrr a1, mcause
    csrr s2, mepc
    addi s2, s2, 4
    csrw mepc, s2
    mret
    nop
