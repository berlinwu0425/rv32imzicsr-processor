.section .text.init
.globl _start
_start:
    li sp, 0x3ff0
    li a0, 0x03000000

    li t2, 0x01
    sw t2, 0(a0)

    la a1, msg_hello
    jal ra, send_string

    li a2, 396
    jal ra, send_decimal

    la a1, msg_newline
    jal ra, send_string

    li a2, 42
    jal ra, send_decimal

    la a1, msg_newline
    jal ra, send_string

    li a2, 0
    jal ra, send_decimal

    la a1, msg_newline
    jal ra, send_string

    li a2, 4294967295
    jal ra, send_decimal

    li t2, 0xFF
    sw t2, 0(a0)

halt_loop:
    j halt_loop

send_string:
    lb t0, 0(a1)          # 讀取目前這個位元組(有號load，但ASCII都是正值不影響)
    beqz t0, send_string_done   # 讀到0，代表字串結束

send_string_wait_tx:
    li t1, 0x08000008
    lw t1, 0(t1)
    bnez t1, send_string_wait_tx   # 忙碌就繼續等

    li t1, 0x08000004
    sw t0, 0(t1)          # 送出這個位元組

    addi a1, a1, 1        # 移到下一個位元組
    j send_string

send_string_done:
    ret

# =========================================================
# 通用副程式：把32-bit無號數字轉成十進位文字送出UART
# 輸入：a2 = 要顯示的數字
# 作法：反覆除以10取餘數，餘數就是每一位數(但順序反過來)，
#       先把每一位數的ASCII字元暫存進堆疊，最後再反過來依序送出
# 會破壞：t0, t1, a1(呼叫send_string用)
# =========================================================
send_decimal:
    mv t0, a2             # 目前還沒轉換完的數值
    li t1, 10
    addi sp, sp, -16      # 預留堆疊空間(最多存到10位數字，32-bit數字最多10位)
    li s3, 0              # 記錄總共有幾位數字

send_decimal_divide_loop:
    remu t2, t0, t1       # t2 = t0 除以10的餘數(這一位數字)
    addi t2, t2, 48       # 加上'0'的ASCII值(48)，變成正確的數字字元
    add t5, sp, s3
    sb t2, 0(t5)          # 把這個字元暫存進堆疊(尚未反轉順序)
    addi s3, s3, 1
    divu t0, t0, t1       # t0 = t0 除以10(去掉已經處理過的那一位)
    bnez t0, send_decimal_divide_loop

send_decimal_output_loop:
    addi s3, s3, -1
    add t5, sp, s3
    lb t0, 0(t5)          # 從堆疊裡，由後往前依序取出字元(這樣順序就對了)

send_decimal_wait_tx:
    li t1, 0x08000008
    lw t1, 0(t1)
    bnez t1, send_decimal_wait_tx

    li t1, 0x08000004
    sw t0, 0(t1)

    bnez s3, send_decimal_output_loop

    addi sp, sp, 16       # 歸還堆疊空間
    ret


.section .text.init
msg_hello: .string "Hello, this is 396: "
msg_newline: .string "\r\n"
