# Bug B：向量指令的下一條是 jal / 猜錯的分支 / ecall 時，控制流程不能遺失
#include "common.inc"
.section .text.init
.globl _start
_start:
    la   s4, handler
    csrw mtvec, s4
    VSETVL8
    li   x5, 0x300
    li   a0, 0                # 走到不該走的路徑就加1
    li   a1, 0                # handler執行次數
    li   a2, 0
    VADD 2, 0, 1
    jal  x0, 1f
    addi a0, a0, 1
    addi a0, a0, 1
1:  VLD  0, 5
    beq  x0, x0, 2f           # 第一次遇到，預測不跳、實際會跳
    addi a0, a0, 1
    addi a0, a0, 1
2:  VADD 2, 0, 1
    ecall                     # 緊接在向量指令後的例外
    addi a2, a2, 100          # 從handler返回後才執行
    EXPECT a0, 0, 2
    EXPECT a1, 1, 3
    EXPECT a2, 100, 4
    FINISH
handler:
    addi a1, a1, 1
    csrr s2, mepc
    addi s2, s2, 4
    csrw mepc, s2
    mret
    addi a0, a0, 1
