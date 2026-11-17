# Bug A：向量指令的下一條指令只能執行一次
# EXPECT_UART=1
#include "common.inc"
.section .text.init
.globl _start
_start:
    VSETVL8
    li   x5, 0x300
    li   a0, 0
    VADD 2, 0, 1
    addi a0, a0, 1            # 緊接在單拍向量運算後
    VLD  0, 5
    addi a0, a0, 1            # 緊接在17拍的vld後
    li   s4, 0x08000004
    li   s5, 0x41
    VLD  0, 5
    sb   s5, 0(s4)            # UART只能送出1個byte (由testbench計數)
    nop
    EXPECT a0, 2, 2
    FINISH
