# ---- 共用巨集：自我檢查型定向測試 ----
# 測試結束時把結果碼寫到 0x03000004：1 = PASS，其他值 = 第幾個檢查點失敗
# 向量指令以 .word 編碼 (custom-0 opcode)，編碼方式見各巨集
.macro VSETVL8                      # x7 = 8; vsetvl x7, x7
    li   x7, 8
    .word 0x0003838b
.endm
.macro VLD vd, rs1                  # vld v<vd>, (x<rs1>)
    .word (\rs1 << 15) | (1 << 12) | (\vd << 7) | 0x0b
.endm
.macro VST vs2, rs1                 # vst v<vs2>, (x<rs1>)
    .word (\vs2 << 20) | (\rs1 << 15) | (2 << 12) | 0x0b
.endm
.macro VADD vd, vs1, vs2            # vadd.vv v<vd>, v<vs1>, v<vs2>
    .word (\vs2 << 20) | (\vs1 << 15) | (3 << 12) | (\vd << 7) | 0x0b
.endm
.macro EXPECT reg, val, code        # reg != val -> 以結果碼 code 結束
    li   t6, \val
    li   t5, \code
    bne  \reg, t6, test_end
.endm
.macro FINISH                       # 全部檢查通過
    li   t5, 1
test_end:
    li   t6, 0x03000004
    sw   t5, 0(t6)
1:  j    1b
.endm
.macro TIMER_IRQ_AFTER n            # 設定計時器中斷在 n 個cycle後觸發，並開啟MTIE/MIE
    li   s2, 0x09000000
    lw   s3, 0(s2)
    addi s3, s3, \n
    sw   s3, 8(s2)
    sw   x0, 12(s2)
    li   s3, 0x80
    csrw mie, s3
    csrsi mstatus, 8
.endm
.macro TIMER_IRQ_HANDLER_BODY       # handler內：a0計數+1，並把mtimecmp設回最大值(清除中斷來源)
    addi a0, a0, 1
    li   s2, 0x09000000
    li   s3, -1
    sw   s3, 8(s2)
    sw   s3, 12(s2)
.endm
