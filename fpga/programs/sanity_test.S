.section .text.init
.globl _start
_start:
    li t3, 0xAA
    li t4, 0x03000000
    sw t3, 0(t4)
loop:
    j loop
