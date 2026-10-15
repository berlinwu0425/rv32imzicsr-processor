.section .text.init
.globl _start
_start:
    li sp, 0x3ff0

    # ---- 把向量A (1~8) 寫進記憶體 0x300 開始 ----
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

    # ---- 把向量B (10,20,...,80) 寫進記憶體 0x340 開始 ----
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

    # ---- vsetvl x7, x7  (先把x7設成8，再設定vl) ----
    li x7, 8
    .word 0x0003838b

    # ---- vld v0, (x5)  x5指向向量A ----
    li x5, 0x300
    .word 0x0002900b

    # ---- vld v1, (x6)  x6指向向量B ----
    li x6, 0x340
    .word 0x0003108b

    # ---- vadd.vv v2, v0, v1 ----
    .word 0x0010310b

    # ---- vmul.vv v3, v0, v1 ----
    .word 0x0010418b

    # ---- vst v2, (x28)  結果存到0x380 ----
    li x28, 0x380
    .word 0x002e200b

    # ---- vst v3, (x29)  結果存到0x3C0 ----
    li x29, 0x3C0
    .word 0x003ea00b

    # 標記完成
    li t3, 0xAA
    li t4, 0x03000000
    sw t3, 0(t4)

halt_loop:
    j halt_loop
