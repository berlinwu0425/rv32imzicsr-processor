# 向量指令的下一條指令，必須拿到「向量指令前一條」剛寫入的暫存器新值
#include "common.inc"
.section .text.init
.globl _start
_start:
    VSETVL8
    li   x5, 0x300
    li   s4, 0
    nop
    nop
    nop
    li   s4, 5
    VADD 2, 0, 1
    addi a0, s4, 1            # 預期 6
    li   s4, 0
    nop
    nop
    nop
    li   s4, 7
    VLD  0, 5
    addi a1, s4, 1            # 預期 8
    EXPECT a0, 6, 2
    EXPECT a1, 8, 3
    FINISH
