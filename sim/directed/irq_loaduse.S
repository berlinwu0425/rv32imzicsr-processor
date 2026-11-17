# Bug C：中斷剛好落在load-use stall那一拍時不能遺失 (OFFS 由組譯參數掃描)
#include "common.inc"
.section .text.init
.globl _start
_start:
    la   s4, handler
    csrw mtvec, s4
    li   a0, 0
    li   a1, 0
    li   s9, 0x300
    li   s8, 5
    sw   s8, 0(s9)
    TIMER_IRQ_AFTER OFFS
    li   s7, 60
loop:
    lw   s4, 0(s9)
    add  a1, a1, s4           # load-use：這裡會stall一拍
    addi s7, s7, -1
    bnez s7, loop
    EXPECT a0, 1, 2           # handler恰好執行一次
    EXPECT a1, 300, 3         # 迴圈的工作一次都不能少
    csrr s4, mstatus
    andi s4, s4, 8
    EXPECT s4, 8, 4           # 返回後MIE必須是開的
    FINISH
handler:
    TIMER_IRQ_HANDLER_BODY
    mret
    nop
