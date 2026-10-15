.section .text.init
.globl _start
_start:
    li sp, 0x3ff0
    li a0, 0x03000000     # D2 LED，當開機標記用
    li t4, 0x05000000     # 7段顯示器

    li t2, 1
    sw t2, 0(a0)

    # ---- 寫入16組 pattern (A,B)，位址從0x100開始，每組間隔8 bytes ----
    li t0, 0x12345678
    li t1, 1
    li t2, 0x100
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, 0x1000
    li t1, 1
    li t2, 0x108
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, 0xFF00FF00
    li t1, 0x0F0F0F0F
    li t2, 0x110
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, 0x12340000
    li t1, 0x5678
    li t2, 0x118
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, 0xFFFFFFFF
    li t1, 0x0000FFFF
    li t2, 0x120
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, 1
    li t1, 8
    li t2, 0x128
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, 0x80000000
    li t1, 4
    li t2, 0x130
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, 0x80000000
    li t1, 4
    li t2, 0x138
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, -1
    li t1, 1
    li t2, 0x140
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, 0xFFFFFFFF
    li t1, 1
    li t2, 0x148
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, 1234
    li t1, 5678
    li t2, 0x150
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, -1
    li t1, -1
    li t2, 0x158
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, 100000
    li t1, 7
    li t2, 0x160
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, 100000
    li t1, 7
    li t2, 0x168
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, 1
    li t1, 0
    li t2, 0x170
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t0, 0
    li t1, 100
    li t2, 0x178
    sw t0, 0(t2)
    sw t1, 4(t2)

    li t2, 3
    sw t2, 0(a0)

    # ---- 0: ADD ----
    li t3, 0x100
    lw t0, 0(t3)
    lw t1, 4(t3)
    add t2, t0, t1
    sw t2, 0x200(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 1: SUB ----
    li t3, 0x108
    lw t0, 0(t3)
    lw t1, 4(t3)
    sub t2, t0, t1
    sw t2, 0x204(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 2: AND ----
    li t3, 0x110
    lw t0, 0(t3)
    lw t1, 4(t3)
    and t2, t0, t1
    sw t2, 0x208(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 3: OR ----
    li t3, 0x118
    lw t0, 0(t3)
    lw t1, 4(t3)
    or t2, t0, t1
    sw t2, 0x20C(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 4: XOR ----
    li t3, 0x120
    lw t0, 0(t3)
    lw t1, 4(t3)
    xor t2, t0, t1
    sw t2, 0x210(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 5: SLL ----
    li t3, 0x128
    lw t0, 0(t3)
    lw t1, 4(t3)
    sll t2, t0, t1
    sw t2, 0x214(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 6: SRL ----
    li t3, 0x130
    lw t0, 0(t3)
    lw t1, 4(t3)
    srl t2, t0, t1
    sw t2, 0x218(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 7: SRA ----
    li t3, 0x138
    lw t0, 0(t3)
    lw t1, 4(t3)
    sra t2, t0, t1
    sw t2, 0x21C(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 8: SLT ----
    li t3, 0x140
    lw t0, 0(t3)
    lw t1, 4(t3)
    slt t2, t0, t1
    sw t2, 0x220(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 9: SLTU ----
    li t3, 0x148
    lw t0, 0(t3)
    lw t1, 4(t3)
    sltu t2, t0, t1
    sw t2, 0x224(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 10: MUL ----
    li t3, 0x150
    lw t0, 0(t3)
    lw t1, 4(t3)
    mul t2, t0, t1
    sw t2, 0x228(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 11: MULH ----
    li t3, 0x158
    lw t0, 0(t3)
    lw t1, 4(t3)
    mulh t2, t0, t1
    sw t2, 0x22C(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 12: DIV ----
    li t3, 0x160
    lw t0, 0(t3)
    lw t1, 4(t3)
    div t2, t0, t1
    sw t2, 0x230(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 13: REM ----
    li t3, 0x168
    lw t0, 0(t3)
    lw t1, 4(t3)
    rem t2, t0, t1
    sw t2, 0x234(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 14: SLLI (立即值移位, B欄位忽略) ----
    li t3, 0x170
    lw t0, 0(t3)
    slli t2, t0, 16
    sw t2, 0x238(x0)
    sw t2, 0(t4)
    jal ra, delay

    # ---- 15: 分支/迴圈：從BRAM讀目標次數(B)，累加迴圈計數到該值 ----
    li t3, 0x178
    lw t1, 4(t3)         # 目標次數(100)
    li t5, 0
loop_test:
    addi t5, t5, 1
    blt t5, t1, loop_test
    sw t5, 0x23C(x0)
    mv t2, t5
    sw t2, 0(t4)
    jal ra, delay

    li t2, 0x7F
    sw t2, 0(a0)

    # ---- 觸發自動檢查器 ----
    li t5, 1
    li t6, 0x07000000
    sw t5, 0(t6)

    li t2, 0xFF
    sw t2, 0(a0)

halt_loop:
    j halt_loop

delay:
    li t6, 0x00080000
delay_loop:
    addi t6, t6, -1
    bnez t6, delay_loop
    ret
