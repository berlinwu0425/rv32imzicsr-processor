.section .text.init
.globl _start
_start:
    li sp, 0x3ff0
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
    li x7, 8
    .word 0x0003838b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li x5, 0x300
    .word 0x0002900b
    li x6, 0x340
    .word 0x0003108b
    .word 0x0010310b
    .word 0x0010418b
    .word 0x0000d20b
    .word 0x0210528b
    .word 0x0410530b
    .word 0x0610538b
    li t3, 1
    li t4, 0x03000004
    sw t3, 0(t4)
halt_loop:
    j halt_loop
