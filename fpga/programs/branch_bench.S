.section .text.init
.globl _start
_start:
    li sp, 0x3ff0
    li t0, 0          # 迴圈計數器
    li t1, 1000        # 迴圈次數
    li t2, 0           # 累加結果(隨便算點東西，避免迴圈被最佳化成空轉，雖然我們沒有最佳化編譯器，這裡純粹保險)

loop_start:
    addi t2, t2, 1
    addi t0, t0, 1
    blt  t0, t1, loop_start    # 這是這支程式的唯一分支，會被猜1000次

    # 完成標記
    li t3, 0xFF
    li t4, 0x03000000
    sw t3, 0(t4)

halt_loop:
    j halt_loop
