.section .text.init
.globl _start
_start:
    li sp, 0x3ff0
    li a0, 0x03000000
    li t4, 0x05000000
    li s10, 0x0A000000
    li s11, 0x0B000000
    # write string '\r\n[STAGE 0x01] System boot, initializing...\r\n' to dmem 0x500
    li t0, 0x500
    li t1, 13
    sb t1, 0(t0)
    li t1, 10
    sb t1, 1(t0)
    li t1, 91
    sb t1, 2(t0)
    li t1, 83
    sb t1, 3(t0)
    li t1, 84
    sb t1, 4(t0)
    li t1, 65
    sb t1, 5(t0)
    li t1, 71
    sb t1, 6(t0)
    li t1, 69
    sb t1, 7(t0)
    li t1, 32
    sb t1, 8(t0)
    li t1, 48
    sb t1, 9(t0)
    li t1, 120
    sb t1, 10(t0)
    li t1, 48
    sb t1, 11(t0)
    li t1, 49
    sb t1, 12(t0)
    li t1, 93
    sb t1, 13(t0)
    li t1, 32
    sb t1, 14(t0)
    li t1, 83
    sb t1, 15(t0)
    li t1, 121
    sb t1, 16(t0)
    li t1, 115
    sb t1, 17(t0)
    li t1, 116
    sb t1, 18(t0)
    li t1, 101
    sb t1, 19(t0)
    li t1, 109
    sb t1, 20(t0)
    li t1, 32
    sb t1, 21(t0)
    li t1, 98
    sb t1, 22(t0)
    li t1, 111
    sb t1, 23(t0)
    li t1, 111
    sb t1, 24(t0)
    li t1, 116
    sb t1, 25(t0)
    li t1, 44
    sb t1, 26(t0)
    li t1, 32
    sb t1, 27(t0)
    li t1, 105
    sb t1, 28(t0)
    li t1, 110
    sb t1, 29(t0)
    li t1, 105
    sb t1, 30(t0)
    li t1, 116
    sb t1, 31(t0)
    li t1, 105
    sb t1, 32(t0)
    li t1, 97
    sb t1, 33(t0)
    li t1, 108
    sb t1, 34(t0)
    li t1, 105
    sb t1, 35(t0)
    li t1, 122
    sb t1, 36(t0)
    li t1, 105
    sb t1, 37(t0)
    li t1, 110
    sb t1, 38(t0)
    li t1, 103
    sb t1, 39(t0)
    li t1, 46
    sb t1, 40(t0)
    li t1, 46
    sb t1, 41(t0)
    li t1, 46
    sb t1, 42(t0)
    li t1, 13
    sb t1, 43(t0)
    li t1, 10
    sb t1, 44(t0)
    li t1, 0
    sb t1, 45(t0)
    # write string '[STAGE 0x02] == RV32IMZicsr Custom CPU FPGA Demo ==\r\n' to dmem 0x560
    li t0, 0x560
    li t1, 91
    sb t1, 0(t0)
    li t1, 83
    sb t1, 1(t0)
    li t1, 84
    sb t1, 2(t0)
    li t1, 65
    sb t1, 3(t0)
    li t1, 71
    sb t1, 4(t0)
    li t1, 69
    sb t1, 5(t0)
    li t1, 32
    sb t1, 6(t0)
    li t1, 48
    sb t1, 7(t0)
    li t1, 120
    sb t1, 8(t0)
    li t1, 48
    sb t1, 9(t0)
    li t1, 50
    sb t1, 10(t0)
    li t1, 93
    sb t1, 11(t0)
    li t1, 32
    sb t1, 12(t0)
    li t1, 61
    sb t1, 13(t0)
    li t1, 61
    sb t1, 14(t0)
    li t1, 32
    sb t1, 15(t0)
    li t1, 82
    sb t1, 16(t0)
    li t1, 86
    sb t1, 17(t0)
    li t1, 51
    sb t1, 18(t0)
    li t1, 50
    sb t1, 19(t0)
    li t1, 73
    sb t1, 20(t0)
    li t1, 77
    sb t1, 21(t0)
    li t1, 90
    sb t1, 22(t0)
    li t1, 105
    sb t1, 23(t0)
    li t1, 99
    sb t1, 24(t0)
    li t1, 115
    sb t1, 25(t0)
    li t1, 114
    sb t1, 26(t0)
    li t1, 32
    sb t1, 27(t0)
    li t1, 67
    sb t1, 28(t0)
    li t1, 117
    sb t1, 29(t0)
    li t1, 115
    sb t1, 30(t0)
    li t1, 116
    sb t1, 31(t0)
    li t1, 111
    sb t1, 32(t0)
    li t1, 109
    sb t1, 33(t0)
    li t1, 32
    sb t1, 34(t0)
    li t1, 67
    sb t1, 35(t0)
    li t1, 80
    sb t1, 36(t0)
    li t1, 85
    sb t1, 37(t0)
    li t1, 32
    sb t1, 38(t0)
    li t1, 70
    sb t1, 39(t0)
    li t1, 80
    sb t1, 40(t0)
    li t1, 71
    sb t1, 41(t0)
    li t1, 65
    sb t1, 42(t0)
    li t1, 32
    sb t1, 43(t0)
    li t1, 68
    sb t1, 44(t0)
    li t1, 101
    sb t1, 45(t0)
    li t1, 109
    sb t1, 46(t0)
    li t1, 111
    sb t1, 47(t0)
    li t1, 32
    sb t1, 48(t0)
    li t1, 61
    sb t1, 49(t0)
    li t1, 61
    sb t1, 50(t0)
    li t1, 13
    sb t1, 51(t0)
    li t1, 10
    sb t1, 52(t0)
    li t1, 0
    sb t1, 53(t0)
    # write string '[STAGE 0x03] Running 16-item self-check (ALU/MUL/DIV/SHIFT/CMP)...\r\n' to dmem 0x5a0
    li t0, 0x5a0
    li t1, 91
    sb t1, 0(t0)
    li t1, 83
    sb t1, 1(t0)
    li t1, 84
    sb t1, 2(t0)
    li t1, 65
    sb t1, 3(t0)
    li t1, 71
    sb t1, 4(t0)
    li t1, 69
    sb t1, 5(t0)
    li t1, 32
    sb t1, 6(t0)
    li t1, 48
    sb t1, 7(t0)
    li t1, 120
    sb t1, 8(t0)
    li t1, 48
    sb t1, 9(t0)
    li t1, 51
    sb t1, 10(t0)
    li t1, 93
    sb t1, 11(t0)
    li t1, 32
    sb t1, 12(t0)
    li t1, 82
    sb t1, 13(t0)
    li t1, 117
    sb t1, 14(t0)
    li t1, 110
    sb t1, 15(t0)
    li t1, 110
    sb t1, 16(t0)
    li t1, 105
    sb t1, 17(t0)
    li t1, 110
    sb t1, 18(t0)
    li t1, 103
    sb t1, 19(t0)
    li t1, 32
    sb t1, 20(t0)
    li t1, 49
    sb t1, 21(t0)
    li t1, 54
    sb t1, 22(t0)
    li t1, 45
    sb t1, 23(t0)
    li t1, 105
    sb t1, 24(t0)
    li t1, 116
    sb t1, 25(t0)
    li t1, 101
    sb t1, 26(t0)
    li t1, 109
    sb t1, 27(t0)
    li t1, 32
    sb t1, 28(t0)
    li t1, 115
    sb t1, 29(t0)
    li t1, 101
    sb t1, 30(t0)
    li t1, 108
    sb t1, 31(t0)
    li t1, 102
    sb t1, 32(t0)
    li t1, 45
    sb t1, 33(t0)
    li t1, 99
    sb t1, 34(t0)
    li t1, 104
    sb t1, 35(t0)
    li t1, 101
    sb t1, 36(t0)
    li t1, 99
    sb t1, 37(t0)
    li t1, 107
    sb t1, 38(t0)
    li t1, 32
    sb t1, 39(t0)
    li t1, 40
    sb t1, 40(t0)
    li t1, 65
    sb t1, 41(t0)
    li t1, 76
    sb t1, 42(t0)
    li t1, 85
    sb t1, 43(t0)
    li t1, 47
    sb t1, 44(t0)
    li t1, 77
    sb t1, 45(t0)
    li t1, 85
    sb t1, 46(t0)
    li t1, 76
    sb t1, 47(t0)
    li t1, 47
    sb t1, 48(t0)
    li t1, 68
    sb t1, 49(t0)
    li t1, 73
    sb t1, 50(t0)
    li t1, 86
    sb t1, 51(t0)
    li t1, 47
    sb t1, 52(t0)
    li t1, 83
    sb t1, 53(t0)
    li t1, 72
    sb t1, 54(t0)
    li t1, 73
    sb t1, 55(t0)
    li t1, 70
    sb t1, 56(t0)
    li t1, 84
    sb t1, 57(t0)
    li t1, 47
    sb t1, 58(t0)
    li t1, 67
    sb t1, 59(t0)
    li t1, 77
    sb t1, 60(t0)
    li t1, 80
    sb t1, 61(t0)
    li t1, 41
    sb t1, 62(t0)
    li t1, 46
    sb t1, 63(t0)
    li t1, 46
    sb t1, 64(t0)
    li t1, 46
    sb t1, 65(t0)
    li t1, 13
    sb t1, 66(t0)
    li t1, 10
    sb t1, 67(t0)
    li t1, 0
    sb t1, 68(t0)
    # write string '[STAGE 0x04] Self-check complete: 16/16 PASSED\r\n' to dmem 0x600
    li t0, 0x600
    li t1, 91
    sb t1, 0(t0)
    li t1, 83
    sb t1, 1(t0)
    li t1, 84
    sb t1, 2(t0)
    li t1, 65
    sb t1, 3(t0)
    li t1, 71
    sb t1, 4(t0)
    li t1, 69
    sb t1, 5(t0)
    li t1, 32
    sb t1, 6(t0)
    li t1, 48
    sb t1, 7(t0)
    li t1, 120
    sb t1, 8(t0)
    li t1, 48
    sb t1, 9(t0)
    li t1, 52
    sb t1, 10(t0)
    li t1, 93
    sb t1, 11(t0)
    li t1, 32
    sb t1, 12(t0)
    li t1, 83
    sb t1, 13(t0)
    li t1, 101
    sb t1, 14(t0)
    li t1, 108
    sb t1, 15(t0)
    li t1, 102
    sb t1, 16(t0)
    li t1, 45
    sb t1, 17(t0)
    li t1, 99
    sb t1, 18(t0)
    li t1, 104
    sb t1, 19(t0)
    li t1, 101
    sb t1, 20(t0)
    li t1, 99
    sb t1, 21(t0)
    li t1, 107
    sb t1, 22(t0)
    li t1, 32
    sb t1, 23(t0)
    li t1, 99
    sb t1, 24(t0)
    li t1, 111
    sb t1, 25(t0)
    li t1, 109
    sb t1, 26(t0)
    li t1, 112
    sb t1, 27(t0)
    li t1, 108
    sb t1, 28(t0)
    li t1, 101
    sb t1, 29(t0)
    li t1, 116
    sb t1, 30(t0)
    li t1, 101
    sb t1, 31(t0)
    li t1, 58
    sb t1, 32(t0)
    li t1, 32
    sb t1, 33(t0)
    li t1, 49
    sb t1, 34(t0)
    li t1, 54
    sb t1, 35(t0)
    li t1, 47
    sb t1, 36(t0)
    li t1, 49
    sb t1, 37(t0)
    li t1, 54
    sb t1, 38(t0)
    li t1, 32
    sb t1, 39(t0)
    li t1, 80
    sb t1, 40(t0)
    li t1, 65
    sb t1, 41(t0)
    li t1, 83
    sb t1, 42(t0)
    li t1, 83
    sb t1, 43(t0)
    li t1, 69
    sb t1, 44(t0)
    li t1, 68
    sb t1, 45(t0)
    li t1, 13
    sb t1, 46(t0)
    li t1, 10
    sb t1, 47(t0)
    li t1, 0
    sb t1, 48(t0)
    # write string '[STAGE 0x05] Vector unit done. A=[1..8]+B=[10..80], checksum=' to dmem 0x640
    li t0, 0x640
    li t1, 91
    sb t1, 0(t0)
    li t1, 83
    sb t1, 1(t0)
    li t1, 84
    sb t1, 2(t0)
    li t1, 65
    sb t1, 3(t0)
    li t1, 71
    sb t1, 4(t0)
    li t1, 69
    sb t1, 5(t0)
    li t1, 32
    sb t1, 6(t0)
    li t1, 48
    sb t1, 7(t0)
    li t1, 120
    sb t1, 8(t0)
    li t1, 48
    sb t1, 9(t0)
    li t1, 53
    sb t1, 10(t0)
    li t1, 93
    sb t1, 11(t0)
    li t1, 32
    sb t1, 12(t0)
    li t1, 86
    sb t1, 13(t0)
    li t1, 101
    sb t1, 14(t0)
    li t1, 99
    sb t1, 15(t0)
    li t1, 116
    sb t1, 16(t0)
    li t1, 111
    sb t1, 17(t0)
    li t1, 114
    sb t1, 18(t0)
    li t1, 32
    sb t1, 19(t0)
    li t1, 117
    sb t1, 20(t0)
    li t1, 110
    sb t1, 21(t0)
    li t1, 105
    sb t1, 22(t0)
    li t1, 116
    sb t1, 23(t0)
    li t1, 32
    sb t1, 24(t0)
    li t1, 100
    sb t1, 25(t0)
    li t1, 111
    sb t1, 26(t0)
    li t1, 110
    sb t1, 27(t0)
    li t1, 101
    sb t1, 28(t0)
    li t1, 46
    sb t1, 29(t0)
    li t1, 32
    sb t1, 30(t0)
    li t1, 65
    sb t1, 31(t0)
    li t1, 61
    sb t1, 32(t0)
    li t1, 91
    sb t1, 33(t0)
    li t1, 49
    sb t1, 34(t0)
    li t1, 46
    sb t1, 35(t0)
    li t1, 46
    sb t1, 36(t0)
    li t1, 56
    sb t1, 37(t0)
    li t1, 93
    sb t1, 38(t0)
    li t1, 43
    sb t1, 39(t0)
    li t1, 66
    sb t1, 40(t0)
    li t1, 61
    sb t1, 41(t0)
    li t1, 91
    sb t1, 42(t0)
    li t1, 49
    sb t1, 43(t0)
    li t1, 48
    sb t1, 44(t0)
    li t1, 46
    sb t1, 45(t0)
    li t1, 46
    sb t1, 46(t0)
    li t1, 56
    sb t1, 47(t0)
    li t1, 48
    sb t1, 48(t0)
    li t1, 93
    sb t1, 49(t0)
    li t1, 44
    sb t1, 50(t0)
    li t1, 32
    sb t1, 51(t0)
    li t1, 99
    sb t1, 52(t0)
    li t1, 104
    sb t1, 53(t0)
    li t1, 101
    sb t1, 54(t0)
    li t1, 99
    sb t1, 55(t0)
    li t1, 107
    sb t1, 56(t0)
    li t1, 115
    sb t1, 57(t0)
    li t1, 117
    sb t1, 58(t0)
    li t1, 109
    sb t1, 59(t0)
    li t1, 61
    sb t1, 60(t0)
    li t1, 0
    sb t1, 61(t0)
    # write string ' (expect 396)\r\n' to dmem 0x6c0
    li t0, 0x6c0
    li t1, 32
    sb t1, 0(t0)
    li t1, 40
    sb t1, 1(t0)
    li t1, 101
    sb t1, 2(t0)
    li t1, 120
    sb t1, 3(t0)
    li t1, 112
    sb t1, 4(t0)
    li t1, 101
    sb t1, 5(t0)
    li t1, 99
    sb t1, 6(t0)
    li t1, 116
    sb t1, 7(t0)
    li t1, 32
    sb t1, 8(t0)
    li t1, 51
    sb t1, 9(t0)
    li t1, 57
    sb t1, 10(t0)
    li t1, 54
    sb t1, 11(t0)
    li t1, 41
    sb t1, 12(t0)
    li t1, 13
    sb t1, 13(t0)
    li t1, 10
    sb t1, 14(t0)
    li t1, 0
    sb t1, 15(t0)
    # write string '[STAGE 0x06] Set switches for value 1, then press S0\r\n' to dmem 0x6e0
    li t0, 0x6e0
    li t1, 91
    sb t1, 0(t0)
    li t1, 83
    sb t1, 1(t0)
    li t1, 84
    sb t1, 2(t0)
    li t1, 65
    sb t1, 3(t0)
    li t1, 71
    sb t1, 4(t0)
    li t1, 69
    sb t1, 5(t0)
    li t1, 32
    sb t1, 6(t0)
    li t1, 48
    sb t1, 7(t0)
    li t1, 120
    sb t1, 8(t0)
    li t1, 48
    sb t1, 9(t0)
    li t1, 54
    sb t1, 10(t0)
    li t1, 93
    sb t1, 11(t0)
    li t1, 32
    sb t1, 12(t0)
    li t1, 83
    sb t1, 13(t0)
    li t1, 101
    sb t1, 14(t0)
    li t1, 116
    sb t1, 15(t0)
    li t1, 32
    sb t1, 16(t0)
    li t1, 115
    sb t1, 17(t0)
    li t1, 119
    sb t1, 18(t0)
    li t1, 105
    sb t1, 19(t0)
    li t1, 116
    sb t1, 20(t0)
    li t1, 99
    sb t1, 21(t0)
    li t1, 104
    sb t1, 22(t0)
    li t1, 101
    sb t1, 23(t0)
    li t1, 115
    sb t1, 24(t0)
    li t1, 32
    sb t1, 25(t0)
    li t1, 102
    sb t1, 26(t0)
    li t1, 111
    sb t1, 27(t0)
    li t1, 114
    sb t1, 28(t0)
    li t1, 32
    sb t1, 29(t0)
    li t1, 118
    sb t1, 30(t0)
    li t1, 97
    sb t1, 31(t0)
    li t1, 108
    sb t1, 32(t0)
    li t1, 117
    sb t1, 33(t0)
    li t1, 101
    sb t1, 34(t0)
    li t1, 32
    sb t1, 35(t0)
    li t1, 49
    sb t1, 36(t0)
    li t1, 44
    sb t1, 37(t0)
    li t1, 32
    sb t1, 38(t0)
    li t1, 116
    sb t1, 39(t0)
    li t1, 104
    sb t1, 40(t0)
    li t1, 101
    sb t1, 41(t0)
    li t1, 110
    sb t1, 42(t0)
    li t1, 32
    sb t1, 43(t0)
    li t1, 112
    sb t1, 44(t0)
    li t1, 114
    sb t1, 45(t0)
    li t1, 101
    sb t1, 46(t0)
    li t1, 115
    sb t1, 47(t0)
    li t1, 115
    sb t1, 48(t0)
    li t1, 32
    sb t1, 49(t0)
    li t1, 83
    sb t1, 50(t0)
    li t1, 48
    sb t1, 51(t0)
    li t1, 13
    sb t1, 52(t0)
    li t1, 10
    sb t1, 53(t0)
    li t1, 0
    sb t1, 54(t0)
    # write string '[STAGE 0x07] Value 1 = ' to dmem 0x740
    li t0, 0x740
    li t1, 91
    sb t1, 0(t0)
    li t1, 83
    sb t1, 1(t0)
    li t1, 84
    sb t1, 2(t0)
    li t1, 65
    sb t1, 3(t0)
    li t1, 71
    sb t1, 4(t0)
    li t1, 69
    sb t1, 5(t0)
    li t1, 32
    sb t1, 6(t0)
    li t1, 48
    sb t1, 7(t0)
    li t1, 120
    sb t1, 8(t0)
    li t1, 48
    sb t1, 9(t0)
    li t1, 55
    sb t1, 10(t0)
    li t1, 93
    sb t1, 11(t0)
    li t1, 32
    sb t1, 12(t0)
    li t1, 86
    sb t1, 13(t0)
    li t1, 97
    sb t1, 14(t0)
    li t1, 108
    sb t1, 15(t0)
    li t1, 117
    sb t1, 16(t0)
    li t1, 101
    sb t1, 17(t0)
    li t1, 32
    sb t1, 18(t0)
    li t1, 49
    sb t1, 19(t0)
    li t1, 32
    sb t1, 20(t0)
    li t1, 61
    sb t1, 21(t0)
    li t1, 32
    sb t1, 22(t0)
    li t1, 0
    sb t1, 23(t0)
    # write string '. Now set value 2, press S0\r\n' to dmem 0x760
    li t0, 0x760
    li t1, 46
    sb t1, 0(t0)
    li t1, 32
    sb t1, 1(t0)
    li t1, 78
    sb t1, 2(t0)
    li t1, 111
    sb t1, 3(t0)
    li t1, 119
    sb t1, 4(t0)
    li t1, 32
    sb t1, 5(t0)
    li t1, 115
    sb t1, 6(t0)
    li t1, 101
    sb t1, 7(t0)
    li t1, 116
    sb t1, 8(t0)
    li t1, 32
    sb t1, 9(t0)
    li t1, 118
    sb t1, 10(t0)
    li t1, 97
    sb t1, 11(t0)
    li t1, 108
    sb t1, 12(t0)
    li t1, 117
    sb t1, 13(t0)
    li t1, 101
    sb t1, 14(t0)
    li t1, 32
    sb t1, 15(t0)
    li t1, 50
    sb t1, 16(t0)
    li t1, 44
    sb t1, 17(t0)
    li t1, 32
    sb t1, 18(t0)
    li t1, 112
    sb t1, 19(t0)
    li t1, 114
    sb t1, 20(t0)
    li t1, 101
    sb t1, 21(t0)
    li t1, 115
    sb t1, 22(t0)
    li t1, 115
    sb t1, 23(t0)
    li t1, 32
    sb t1, 24(t0)
    li t1, 83
    sb t1, 25(t0)
    li t1, 48
    sb t1, 26(t0)
    li t1, 13
    sb t1, 27(t0)
    li t1, 10
    sb t1, 28(t0)
    li t1, 0
    sb t1, 29(t0)
    # write string '[STAGE 0x08] Value 2 = ' to dmem 0x7a0
    li t0, 0x7a0
    li t1, 91
    sb t1, 0(t0)
    li t1, 83
    sb t1, 1(t0)
    li t1, 84
    sb t1, 2(t0)
    li t1, 65
    sb t1, 3(t0)
    li t1, 71
    sb t1, 4(t0)
    li t1, 69
    sb t1, 5(t0)
    li t1, 32
    sb t1, 6(t0)
    li t1, 48
    sb t1, 7(t0)
    li t1, 120
    sb t1, 8(t0)
    li t1, 48
    sb t1, 9(t0)
    li t1, 56
    sb t1, 10(t0)
    li t1, 93
    sb t1, 11(t0)
    li t1, 32
    sb t1, 12(t0)
    li t1, 86
    sb t1, 13(t0)
    li t1, 97
    sb t1, 14(t0)
    li t1, 108
    sb t1, 15(t0)
    li t1, 117
    sb t1, 16(t0)
    li t1, 101
    sb t1, 17(t0)
    li t1, 32
    sb t1, 18(t0)
    li t1, 50
    sb t1, 19(t0)
    li t1, 32
    sb t1, 20(t0)
    li t1, 61
    sb t1, 21(t0)
    li t1, 32
    sb t1, 22(t0)
    li t1, 0
    sb t1, 23(t0)
    # write string '. Computing: ' to dmem 0x7c0
    li t0, 0x7c0
    li t1, 46
    sb t1, 0(t0)
    li t1, 32
    sb t1, 1(t0)
    li t1, 67
    sb t1, 2(t0)
    li t1, 111
    sb t1, 3(t0)
    li t1, 109
    sb t1, 4(t0)
    li t1, 112
    sb t1, 5(t0)
    li t1, 117
    sb t1, 6(t0)
    li t1, 116
    sb t1, 7(t0)
    li t1, 105
    sb t1, 8(t0)
    li t1, 110
    sb t1, 9(t0)
    li t1, 103
    sb t1, 10(t0)
    li t1, 58
    sb t1, 11(t0)
    li t1, 32
    sb t1, 12(t0)
    li t1, 0
    sb t1, 13(t0)
    # write string ' + ' to dmem 0x800
    li t0, 0x800
    li t1, 32
    sb t1, 0(t0)
    li t1, 43
    sb t1, 1(t0)
    li t1, 32
    sb t1, 2(t0)
    li t1, 0
    sb t1, 3(t0)
    # write string ' = ' to dmem 0x810
    li t0, 0x810
    li t1, 32
    sb t1, 0(t0)
    li t1, 61
    sb t1, 1(t0)
    li t1, 32
    sb t1, 2(t0)
    li t1, 0
    sb t1, 3(t0)
    # write string '\r\n' to dmem 0x820
    li t0, 0x820
    li t1, 13
    sb t1, 0(t0)
    li t1, 10
    sb t1, 1(t0)
    li t1, 0
    sb t1, 2(t0)
    # write string '[STAGE 0x09] Arming timer interrupt (fires in ~0.6s)\r\n' to dmem 0x830
    li t0, 0x830
    li t1, 91
    sb t1, 0(t0)
    li t1, 83
    sb t1, 1(t0)
    li t1, 84
    sb t1, 2(t0)
    li t1, 65
    sb t1, 3(t0)
    li t1, 71
    sb t1, 4(t0)
    li t1, 69
    sb t1, 5(t0)
    li t1, 32
    sb t1, 6(t0)
    li t1, 48
    sb t1, 7(t0)
    li t1, 120
    sb t1, 8(t0)
    li t1, 48
    sb t1, 9(t0)
    li t1, 57
    sb t1, 10(t0)
    li t1, 93
    sb t1, 11(t0)
    li t1, 32
    sb t1, 12(t0)
    li t1, 65
    sb t1, 13(t0)
    li t1, 114
    sb t1, 14(t0)
    li t1, 109
    sb t1, 15(t0)
    li t1, 105
    sb t1, 16(t0)
    li t1, 110
    sb t1, 17(t0)
    li t1, 103
    sb t1, 18(t0)
    li t1, 32
    sb t1, 19(t0)
    li t1, 116
    sb t1, 20(t0)
    li t1, 105
    sb t1, 21(t0)
    li t1, 109
    sb t1, 22(t0)
    li t1, 101
    sb t1, 23(t0)
    li t1, 114
    sb t1, 24(t0)
    li t1, 32
    sb t1, 25(t0)
    li t1, 105
    sb t1, 26(t0)
    li t1, 110
    sb t1, 27(t0)
    li t1, 116
    sb t1, 28(t0)
    li t1, 101
    sb t1, 29(t0)
    li t1, 114
    sb t1, 30(t0)
    li t1, 114
    sb t1, 31(t0)
    li t1, 117
    sb t1, 32(t0)
    li t1, 112
    sb t1, 33(t0)
    li t1, 116
    sb t1, 34(t0)
    li t1, 32
    sb t1, 35(t0)
    li t1, 40
    sb t1, 36(t0)
    li t1, 102
    sb t1, 37(t0)
    li t1, 105
    sb t1, 38(t0)
    li t1, 114
    sb t1, 39(t0)
    li t1, 101
    sb t1, 40(t0)
    li t1, 115
    sb t1, 41(t0)
    li t1, 32
    sb t1, 42(t0)
    li t1, 105
    sb t1, 43(t0)
    li t1, 110
    sb t1, 44(t0)
    li t1, 32
    sb t1, 45(t0)
    li t1, 126
    sb t1, 46(t0)
    li t1, 48
    sb t1, 47(t0)
    li t1, 46
    sb t1, 48(t0)
    li t1, 54
    sb t1, 49(t0)
    li t1, 115
    sb t1, 50(t0)
    li t1, 41
    sb t1, 51(t0)
    li t1, 13
    sb t1, 52(t0)
    li t1, 10
    sb t1, 53(t0)
    li t1, 0
    sb t1, 54(t0)
    # write string '[STAGE 0x0A] Waiting for timer to fire...\r\n' to dmem 0x870
    li t0, 0x870
    li t1, 91
    sb t1, 0(t0)
    li t1, 83
    sb t1, 1(t0)
    li t1, 84
    sb t1, 2(t0)
    li t1, 65
    sb t1, 3(t0)
    li t1, 71
    sb t1, 4(t0)
    li t1, 69
    sb t1, 5(t0)
    li t1, 32
    sb t1, 6(t0)
    li t1, 48
    sb t1, 7(t0)
    li t1, 120
    sb t1, 8(t0)
    li t1, 48
    sb t1, 9(t0)
    li t1, 65
    sb t1, 10(t0)
    li t1, 93
    sb t1, 11(t0)
    li t1, 32
    sb t1, 12(t0)
    li t1, 87
    sb t1, 13(t0)
    li t1, 97
    sb t1, 14(t0)
    li t1, 105
    sb t1, 15(t0)
    li t1, 116
    sb t1, 16(t0)
    li t1, 105
    sb t1, 17(t0)
    li t1, 110
    sb t1, 18(t0)
    li t1, 103
    sb t1, 19(t0)
    li t1, 32
    sb t1, 20(t0)
    li t1, 102
    sb t1, 21(t0)
    li t1, 111
    sb t1, 22(t0)
    li t1, 114
    sb t1, 23(t0)
    li t1, 32
    sb t1, 24(t0)
    li t1, 116
    sb t1, 25(t0)
    li t1, 105
    sb t1, 26(t0)
    li t1, 109
    sb t1, 27(t0)
    li t1, 101
    sb t1, 28(t0)
    li t1, 114
    sb t1, 29(t0)
    li t1, 32
    sb t1, 30(t0)
    li t1, 116
    sb t1, 31(t0)
    li t1, 111
    sb t1, 32(t0)
    li t1, 32
    sb t1, 33(t0)
    li t1, 102
    sb t1, 34(t0)
    li t1, 105
    sb t1, 35(t0)
    li t1, 114
    sb t1, 36(t0)
    li t1, 101
    sb t1, 37(t0)
    li t1, 46
    sb t1, 38(t0)
    li t1, 46
    sb t1, 39(t0)
    li t1, 46
    sb t1, 40(t0)
    li t1, 13
    sb t1, 41(t0)
    li t1, 10
    sb t1, 42(t0)
    li t1, 0
    sb t1, 43(t0)
    # write string '[STAGE 0x0B] Timer fired! Interrupt handled successfully\r\n' to dmem 0x8a0
    li t0, 0x8a0
    li t1, 91
    sb t1, 0(t0)
    li t1, 83
    sb t1, 1(t0)
    li t1, 84
    sb t1, 2(t0)
    li t1, 65
    sb t1, 3(t0)
    li t1, 71
    sb t1, 4(t0)
    li t1, 69
    sb t1, 5(t0)
    li t1, 32
    sb t1, 6(t0)
    li t1, 48
    sb t1, 7(t0)
    li t1, 120
    sb t1, 8(t0)
    li t1, 48
    sb t1, 9(t0)
    li t1, 66
    sb t1, 10(t0)
    li t1, 93
    sb t1, 11(t0)
    li t1, 32
    sb t1, 12(t0)
    li t1, 84
    sb t1, 13(t0)
    li t1, 105
    sb t1, 14(t0)
    li t1, 109
    sb t1, 15(t0)
    li t1, 101
    sb t1, 16(t0)
    li t1, 114
    sb t1, 17(t0)
    li t1, 32
    sb t1, 18(t0)
    li t1, 102
    sb t1, 19(t0)
    li t1, 105
    sb t1, 20(t0)
    li t1, 114
    sb t1, 21(t0)
    li t1, 101
    sb t1, 22(t0)
    li t1, 100
    sb t1, 23(t0)
    li t1, 33
    sb t1, 24(t0)
    li t1, 32
    sb t1, 25(t0)
    li t1, 73
    sb t1, 26(t0)
    li t1, 110
    sb t1, 27(t0)
    li t1, 116
    sb t1, 28(t0)
    li t1, 101
    sb t1, 29(t0)
    li t1, 114
    sb t1, 30(t0)
    li t1, 114
    sb t1, 31(t0)
    li t1, 117
    sb t1, 32(t0)
    li t1, 112
    sb t1, 33(t0)
    li t1, 116
    sb t1, 34(t0)
    li t1, 32
    sb t1, 35(t0)
    li t1, 104
    sb t1, 36(t0)
    li t1, 97
    sb t1, 37(t0)
    li t1, 110
    sb t1, 38(t0)
    li t1, 100
    sb t1, 39(t0)
    li t1, 108
    sb t1, 40(t0)
    li t1, 101
    sb t1, 41(t0)
    li t1, 100
    sb t1, 42(t0)
    li t1, 32
    sb t1, 43(t0)
    li t1, 115
    sb t1, 44(t0)
    li t1, 117
    sb t1, 45(t0)
    li t1, 99
    sb t1, 46(t0)
    li t1, 99
    sb t1, 47(t0)
    li t1, 101
    sb t1, 48(t0)
    li t1, 115
    sb t1, 49(t0)
    li t1, 115
    sb t1, 50(t0)
    li t1, 102
    sb t1, 51(t0)
    li t1, 117
    sb t1, 52(t0)
    li t1, 108
    sb t1, 53(t0)
    li t1, 108
    sb t1, 54(t0)
    li t1, 121
    sb t1, 55(t0)
    li t1, 13
    sb t1, 56(t0)
    li t1, 10
    sb t1, 57(t0)
    li t1, 0
    sb t1, 58(t0)
    # write string '[STAGE 0x0C] Ready. Press any key to test UART echo\r\n' to dmem 0x900
    li t0, 0x900
    li t1, 91
    sb t1, 0(t0)
    li t1, 83
    sb t1, 1(t0)
    li t1, 84
    sb t1, 2(t0)
    li t1, 65
    sb t1, 3(t0)
    li t1, 71
    sb t1, 4(t0)
    li t1, 69
    sb t1, 5(t0)
    li t1, 32
    sb t1, 6(t0)
    li t1, 48
    sb t1, 7(t0)
    li t1, 120
    sb t1, 8(t0)
    li t1, 48
    sb t1, 9(t0)
    li t1, 67
    sb t1, 10(t0)
    li t1, 93
    sb t1, 11(t0)
    li t1, 32
    sb t1, 12(t0)
    li t1, 82
    sb t1, 13(t0)
    li t1, 101
    sb t1, 14(t0)
    li t1, 97
    sb t1, 15(t0)
    li t1, 100
    sb t1, 16(t0)
    li t1, 121
    sb t1, 17(t0)
    li t1, 46
    sb t1, 18(t0)
    li t1, 32
    sb t1, 19(t0)
    li t1, 80
    sb t1, 20(t0)
    li t1, 114
    sb t1, 21(t0)
    li t1, 101
    sb t1, 22(t0)
    li t1, 115
    sb t1, 23(t0)
    li t1, 115
    sb t1, 24(t0)
    li t1, 32
    sb t1, 25(t0)
    li t1, 97
    sb t1, 26(t0)
    li t1, 110
    sb t1, 27(t0)
    li t1, 121
    sb t1, 28(t0)
    li t1, 32
    sb t1, 29(t0)
    li t1, 107
    sb t1, 30(t0)
    li t1, 101
    sb t1, 31(t0)
    li t1, 121
    sb t1, 32(t0)
    li t1, 32
    sb t1, 33(t0)
    li t1, 116
    sb t1, 34(t0)
    li t1, 111
    sb t1, 35(t0)
    li t1, 32
    sb t1, 36(t0)
    li t1, 116
    sb t1, 37(t0)
    li t1, 101
    sb t1, 38(t0)
    li t1, 115
    sb t1, 39(t0)
    li t1, 116
    sb t1, 40(t0)
    li t1, 32
    sb t1, 41(t0)
    li t1, 85
    sb t1, 42(t0)
    li t1, 65
    sb t1, 43(t0)
    li t1, 82
    sb t1, 44(t0)
    li t1, 84
    sb t1, 45(t0)
    li t1, 32
    sb t1, 46(t0)
    li t1, 101
    sb t1, 47(t0)
    li t1, 99
    sb t1, 48(t0)
    li t1, 104
    sb t1, 49(t0)
    li t1, 111
    sb t1, 50(t0)
    li t1, 13
    sb t1, 51(t0)
    li t1, 10
    sb t1, 52(t0)
    li t1, 0
    sb t1, 53(t0)

    # write string '0x' to dmem 0xb50
    li t0, 0xb50
    li t1, 48
    sb t1, 0(t0)
    li t1, 120
    sb t1, 1(t0)
    li t1, 0
    sb t1, 2(t0)
    li t2, 0x01
    sw t2, 0(a0)
    li a1, 0x500
    jal ra, send_string
    jal ra, short_pause

    la t0, trap_handler
    csrw mtvec, t0
    li t0, 0x88
    csrw mie, t0
    li t0, 0x8
    csrw mstatus, t0

    li t2, 0x02
    sw t2, 0(a0)
    li a1, 0x560
    jal ra, send_string
    jal ra, short_pause

    # =========================================================
    # 16-pattern 自動檢查器：進入前短暫停留，讓0x02看得清楚
    # =========================================================
    li t2, 0x03
    sw t2, 0(a0)
    li a1, 0x5a0
    jal ra, send_string
    jal ra, short_pause

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

    li t3, 0x100
    lw t0, 0(t3)
    lw t1, 4(t3)
    add t2, t0, t1
    sw t2, 0x200(x0)
    sw t2, 0(t4)

    li t3, 0x108
    lw t0, 0(t3)
    lw t1, 4(t3)
    sub t2, t0, t1
    sw t2, 0x204(x0)
    sw t2, 0(t4)
    jal ra, short_pause_tiny

    li t3, 0x110
    lw t0, 0(t3)
    lw t1, 4(t3)
    and t2, t0, t1
    sw t2, 0x208(x0)
    sw t2, 0(t4)
    jal ra, short_pause_tiny

    li t3, 0x118
    lw t0, 0(t3)
    lw t1, 4(t3)
    or t2, t0, t1
    sw t2, 0x20C(x0)
    sw t2, 0(t4)
    jal ra, short_pause_tiny

    li t3, 0x120
    lw t0, 0(t3)
    lw t1, 4(t3)
    xor t2, t0, t1
    sw t2, 0x210(x0)
    sw t2, 0(t4)
    jal ra, short_pause_tiny

    li t3, 0x128
    lw t0, 0(t3)
    lw t1, 4(t3)
    sll t2, t0, t1
    sw t2, 0x214(x0)
    sw t2, 0(t4)
    jal ra, short_pause_tiny

    li t3, 0x130
    lw t0, 0(t3)
    lw t1, 4(t3)
    srl t2, t0, t1
    sw t2, 0x218(x0)
    sw t2, 0(t4)
    jal ra, short_pause_tiny

    li t3, 0x138
    lw t0, 0(t3)
    lw t1, 4(t3)
    sra t2, t0, t1
    sw t2, 0x21C(x0)
    sw t2, 0(t4)
    jal ra, short_pause_tiny

    li t3, 0x140
    lw t0, 0(t3)
    lw t1, 4(t3)
    slt t2, t0, t1
    sw t2, 0x220(x0)
    sw t2, 0(t4)
    jal ra, short_pause_tiny

    li t3, 0x148
    lw t0, 0(t3)
    lw t1, 4(t3)
    sltu t2, t0, t1
    sw t2, 0x224(x0)
    sw t2, 0(t4)
    jal ra, short_pause_tiny

    li t3, 0x150
    lw t0, 0(t3)
    lw t1, 4(t3)
    mul t2, t0, t1
    sw t2, 0x228(x0)
    sw t2, 0(t4)
    jal ra, short_pause_tiny

    li t3, 0x158
    lw t0, 0(t3)
    lw t1, 4(t3)
    mulh t2, t0, t1
    sw t2, 0x22C(x0)
    sw t2, 0(t4)
    jal ra, short_pause_tiny

    li t3, 0x160
    lw t0, 0(t3)
    lw t1, 4(t3)
    div t2, t0, t1
    sw t2, 0x230(x0)
    sw t2, 0(t4)
    jal ra, short_pause_tiny

    li t3, 0x168
    lw t0, 0(t3)
    lw t1, 4(t3)
    rem t2, t0, t1
    sw t2, 0x234(x0)
    sw t2, 0(t4)
    jal ra, short_pause_tiny

    li t3, 0x170
    lw t0, 0(t3)
    slli t2, t0, 16
    sw t2, 0x238(x0)
    sw t2, 0(t4)
    jal ra, short_pause_tiny

    li t3, 0x178
    lw t1, 4(t3)
    li t5, 0
loop_test:
    addi t5, t5, 1
    blt t5, t1, loop_test
    sw t5, 0x23C(x0)
    mv t2, t5
    sw t2, 0(t4)

    li t2, 0x04
    sw t2, 0(a0)
    li a1, 0x600
    jal ra, send_string
    jal ra, short_pause

    li t5, 1
    li t6, 0x07000000
    sw t5, 0(t6)

    jal ra, wait_for_s0

    # =========================================================
    # 向量單元
    # =========================================================
    li t2, 0x05
    sw t2, 0(a0)
    li a1, 0x640
    jal ra, send_string
    jal ra, short_pause

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

    li x28, 0x380
    .word 0x002e200b
    li x28, 0x3C0
    .word 0x003e200b

    li t3, 0x380
    li t5, 0
    li t6, 0
vec_sum_loop:
    lw t0, 0(t3)
    add t5, t5, t0
    addi t3, t3, 4
    addi t6, t6, 1
    li t1, 8
    blt t6, t1, vec_sum_loop
    sw t5, 0(t4)
    mv a2, t5
    jal ra, send_hex
    li a1, 0x6C0
    jal ra, send_string

    jal ra, wait_for_s0

    # =========================================================
    # 即時運算：兩個數字依序輸入，各自即時同步顯示、各自按S0鎖定
    # =========================================================
    li t2, 0x06
    sw t2, 0(a0)
    li a1, 0x6e0
    jal ra, send_string
input1_loop:
    lw t0, 0(s11)          # 持續讀取開關目前的值
    sw t0, 0(t4)           # 即時同步顯示到7段顯示器
    lw t1, 0(s10)
    beqz t1, input1_loop
    li t1, 0
    sw t1, 0(s10)
    mv s1, t0              # 鎖定第一個數字到s1

    li t2, 0x07
    sw t2, 0(a0)
    li a1, 0x740
    jal ra, send_string
    mv a2, s1
    jal ra, send_hex
    li a1, 0x760
    jal ra, send_string
input2_loop:
    lw t0, 0(s11)
    sw t0, 0(t4)
    lw t1, 0(s10)
    beqz t1, input2_loop
    li t1, 0
    sw t1, 0(s10)
    mv s2, t0              # 鎖定第二個數字到s2

    li t2, 0x08
    sw t2, 0(a0)
    li a1, 0x7A0
    jal ra, send_string
    mv a2, s2
    jal ra, send_hex
    li a1, 0x7C0
    jal ra, send_string
    mv a2, s1
    jal ra, send_hex
    li a1, 0x800
    jal ra, send_string
    mv a2, s2
    jal ra, send_hex
    li a1, 0x810
    jal ra, send_string
    add t2, s1, s2
    mv a2, t2
    jal ra, send_hex
    li a1, 0x820
    jal ra, send_string
    sw t2, 0(t4)
    jal ra, short_pause
    jal ra, wait_for_s0

    # =========================================================
    # 計時器中斷
    # =========================================================
    li t2, 0x09
    sw t2, 0(a0)
    li a1, 0x830
    jal ra, send_string
    jal ra, short_pause

    li t2, 0x0A
    sw t2, 0(a0)
    li a1, 0x870
    jal ra, send_string
    jal ra, short_pause

    # 計時器比較值設定在short_pause"之後"、確定要進入等待迴圈前才設定，
    # 這樣0x09這個畫面才能真正被完整看到，不會被計時器中斷提前打斷
    li t1, 20000
    li t3, 0x09000008
    sw t1, 0(t3)
    li t1, 0
    li t3, 0x0900000C
    sw t1, 0(t3)

timer_wait_loop:
    j timer_wait_loop

wait_for_s0:
    lw t0, 0(s10)
    beqz t0, wait_for_s0
    li t0, 0
    sw t0, 0(s10)
    ret

short_pause:
    li t6, 0x00600000
short_pause_loop:
    addi t6, t6, -1
    bnez t6, short_pause_loop
    ret

short_pause_tiny:
    li t6, 0x00080000
short_pause_tiny_loop:
    addi t6, t6, -1
    bnez t6, short_pause_tiny_loop
    ret

# =========================================================
# 通用副程式：傳送一整個字串到UART
# 輸入：a1 = 字串起始位址(字串以0結尾)
# =========================================================
send_string:
    lb t0, 0(a1)
    beqz t0, send_string_done

send_string_wait_tx:
    li t1, 0x08000008
    lw t1, 0(t1)
    bnez t1, send_string_wait_tx

    li t1, 0x08000004
    sw t0, 0(t1)

    addi a1, a1, 1
    j send_string

send_string_done:
    ret

# =========================================================
# 通用副程式：把32-bit無號數字轉成十進位文字送出UART
# 輸入：a2 = 要顯示的數字
# =========================================================
# =========================================================
# 通用副程式：把32-bit數字轉成十六進位文字送出UART(格式：0xXXXXXXXX)
# 輸入：a2 = 要顯示的數字
# 會破壞：t0, t1, t2, t3
# =========================================================
send_hex:
    addi sp, sp, -4
    sw ra, 0(sp)              # 保護ra，避免內部呼叫send_string時被覆寫掉

    li a1, 0xB50
    jal ra, send_string      # 印出"0x"前綴(先寫進dmem初始化)

    li t3, 28                # 從最高4位元(bit 31~28)開始，每次減4
send_hex_loop:
    srl t0, a2, t3
    andi t0, t0, 0xF
    li t1, 10
    blt t0, t1, send_hex_digit
    addi t0, t0, 55          # 'A'-10
    j send_hex_char_ready
send_hex_digit:
    addi t0, t0, 48          # '0'-0
send_hex_char_ready:

send_hex_wait_tx:
    li t1, 0x08000008
    lw t1, 0(t1)
    bnez t1, send_hex_wait_tx

    li t1, 0x08000004
    sw t0, 0(t1)

    addi t3, t3, -4
    bgez t3, send_hex_loop

    lw ra, 0(sp)
    addi sp, sp, 4
    ret

send_decimal:
    mv t0, a2
    li t1, 10
    addi sp, sp, -16
    li s3, 0

send_decimal_divide_loop:
    remu t2, t0, t1
    addi t2, t2, 48
    add t5, sp, s3
    sb t2, 0(t5)
    addi s3, s3, 1
    divu t0, t0, t1
    bnez t0, send_decimal_divide_loop

send_decimal_output_loop:
    addi s3, s3, -1
    add t5, sp, s3
    lb t0, 0(t5)

send_decimal_wait_tx:
    li t1, 0x08000008
    lw t1, 0(t1)
    bnez t1, send_decimal_wait_tx

    li t1, 0x08000004
    sw t0, 0(t1)

    bnez s3, send_decimal_output_loop

    addi sp, sp, 16
    ret

trap_handler:
    csrr t4, mcause
    li t6, 0x80000007
    beq t4, t6, handle_timer
    j handle_uart

handle_timer:
    li t2, 0x0B
    sw t2, 0(a0)
    li a1, 0x8a0
    jal ra, send_string
    jal ra, short_pause

    li t1, 0xFFFFFFFF
    li t3, 0x09000008
    sw t1, 0(t3)
    li t1, 0xFFFFFFFF
    li t3, 0x0900000C
    sw t1, 0(t3)

    la t6, uart_stage
    csrw mepc, t6
    mret

handle_uart:
    li t3, 0x08000000
    lw t1, 0(t3)
    sw t1, 0(a0)

    la t6, uart_wait_loop
    csrw mepc, t6

    li t4, 0
    li t5, 0x2000000
    sw t4, 0(t5)

wait_tx_ready:
    li t3, 0x08000008
    lw t4, 0(t3)
    bnez t4, wait_tx_ready

    li t3, 0x08000004
    sw t1, 0(t3)
    mret

uart_stage:
    li t2, 0x0C
    sw t2, 0(a0)
    li a1, 0x900
    jal ra, send_string

uart_wait_loop:
    j uart_wait_loop
