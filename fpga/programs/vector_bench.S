.section .text.init
.globl _start
_start:
    li sp, 0x3ff0

    # 向量A (1~8) 寫進 0x300
    li t0, 0x300
    li t1, 1
    sw t1, 0(t0)
    li t1, 2
    sw t1, 4(t0)
    li t1, 3
    sw t1, 8(t0)
    li t1, 4
    sw t1, 12(t0)
    li t1, 5
    sw t1, 16(t0)
    li t1, 6
    sw t1, 20(t0)
    li t1, 7
    sw t1, 24(t0)
    li t1, 8
    sw t1, 28(t0)

    # 向量B (10,20,...,80) 寫進 0x340
    li t0, 0x340
    li t1, 10
    sw t1, 0(t0)
    li t1, 20
    sw t1, 4(t0)
    li t1, 30
    sw t1, 8(t0)
    li t1, 40
    sw t1, 12(t0)
    li t1, 50
    sw t1, 16(t0)
    li t1, 60
    sw t1, 20(t0)
    li t1, 70
    sw t1, 24(t0)
    li t1, 80
    sw t1, 28(t0)

    # vsetvl x7, x7 (只需要設定一次)
    li x7, 8
    .word 0x0003838b

    # 迴圈計數器：跑50輪
    li s0, 0
    li s1, 50

vec_loop:
    # vld v0, (x5)  x5指向A
    li x5, 0x300
    .word 0x0002900b

    # vld v1, (x6)  x6指向B
    li x6, 0x340
    .word 0x0003108b

    # vadd.vv v2, v0, v1
    .word 0x0010310b

    # vmul.vv v3, v0, v1
    .word 0x0010418b

    # vsub.vv v4, v1, v0
    .word 0x0000d20b

    # vand.vv v5, v0, v1
    .word 0x0210528b

    # vor.vv v6, v0, v1
    .word 0x0410530b

    # vxor.vv v7, v0, v1
    .word 0x0610538b

    addi s0, s0, 1
    blt s0, s1, vec_loop

    # 完成標記
    li t3, 1
    li t4, 0x03000004
    sw t3, 0(t4)

halt_loop:
    j halt_loop
