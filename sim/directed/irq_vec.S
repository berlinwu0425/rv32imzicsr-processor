# Bug C/E：中斷落在向量指令啟動當拍或執行期間，向量指令只能生效一次、中斷不能遺失
#include "common.inc"
.section .text.init
.globl _start
_start:
    la   s4, handler
    csrw mtvec, s4
    VSETVL8
    li   x6, 0x340
    li   s5, 1
    sw   s5, 0(x6)
    li   x5, 0x300
    sw   x0, 0(x5)
    VLD  1, 6                 # v1[0] = 1
    VLD  2, 5                 # v2[0] = 0
    li   a0, 0
    li   a1, 0
    TIMER_IRQ_AFTER OFFS
    li   s7, 20
loop:
    VADD 2, 2, 1              # v2[0] += 1 (不是冪等運算，多做一次就會錯)
#ifdef WITH_VLD
    VLD  3, 5                 # 17拍的向量load，讓中斷有機會落在執行期間
#endif
    addi a1, a1, 1
    blt  a1, s7, loop
    li   x28, 0x380
    VST  2, 28
    lw   a2, 0x380(x0)
    EXPECT a0, 1, 2           # handler恰好執行一次
    EXPECT a1, 20, 3
    EXPECT a2, 20, 4          # 向量加法恰好生效20次
    FINISH
handler:
    TIMER_IRQ_HANDLER_BODY
    mret
    nop
