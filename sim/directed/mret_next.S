# Bug D：mret 後面那條指令(錯誤路徑)不能執行，是向量store時也不能改到記憶體
#include "common.inc"
.section .text.init
.globl _start
_start:
    la   s4, handler
    csrw mtvec, s4
    VSETVL8
    li   x5, 0x300
    li   s5, 77
    sw   s5, 0(x5)            # mem[0x300] = 77
    li   a0, 0
    ecall
    lw   a1, 0(x5)
    EXPECT a0, 0, 2
    EXPECT a1, 77, 3
    la   s4, handler2
    csrw mtvec, s4
    ecall
    lw   a1, 0(x5)
    EXPECT a1, 77, 4
    FINISH
handler:
    csrr s2, mepc
    addi s2, s2, 4
    csrw mepc, s2
    mret
    addi a0, a0, 1            # 不能執行
    addi a0, a0, 1
handler2:
    csrr s2, mepc
    addi s2, s2, 4
    csrw mepc, s2
    mret
    VST  0, 5                 # 不能執行：v0全為0，執行了會把mem[0x300]蓋成0
    nop
