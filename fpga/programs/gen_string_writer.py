import sys

def gen_string_writer(label, text, dmem_addr):
    # 修正關鍵錯誤：註解裡用repr()把換行字元等特殊字元轉成看得懂的\r\n這種文字表示，
    # 而不是讓真正的換行字元跑進註解，把整行結構弄斷
    safe_text_for_comment = repr(text)
    lines = [f"    # write string {safe_text_for_comment} to dmem 0x{dmem_addr:x}"]
    lines.append(f"    li t0, 0x{dmem_addr:x}")
    text_bytes = text.encode('ascii')
    for i, byte in enumerate(text_bytes):
        lines.append(f"    li t1, {byte}")
        lines.append(f"    sb t1, {i}(t0)")
    lines.append(f"    li t1, 0")
    lines.append(f"    sb t1, {len(text_bytes)}(t0)")
    return "\n".join(lines)

if __name__ == "__main__":
    strings = [
        ("msg_title",   "\r\n== RV32IMZicsr Custom CPU FPGA Demo ==\r\n", 0x500),
        ("msg_check1",  "\r\n[1] Auto self-check (ALU/MUL/DIV/SHIFT/CMP)...\r\n", 0x580),
        ("msg_check2",  "    16/16 PASSED\r\n", 0x620),
        ("msg_vec1",    "\r\n[2] Vector unit: A=[1..8] + B=[10..80]\r\n    Checksum = ", 0x660),
        ("msg_vec2",    " (expect 396)\r\n", 0x700),
        ("msg_in1",     "\r\n[3] Set switches for value 1, press S0\r\n", 0x720),
        ("msg_in1val",  "    You entered: ", 0x780),
        ("msg_in2",     "\r\n[4] Set switches for value 2, press S0\r\n", 0x7A0),
        ("msg_in2val",  "    You entered: ", 0x800),
        ("msg_result",  "\r\n[5] CPU computes: ", 0x820),
        ("msg_plus",    " + ", 0x860),
        ("msg_equal",   " = ", 0x870),
        ("msg_timer",   "\r\n[6] Timer interrupt test...\r\n    Fired and handled\r\n", 0x880),
        ("msg_uart",    "\r\n[7] Press any key to test UART echo...\r\n", 0x900),
    ]

    with open("/home/berlinwu/fpga_bringup/string_init_block.txt", "w") as f:
        f.write("    # =========================================================\n")
        f.write("    # 一次性初始化：把所有UART說明文字寫進dmem\n")
        f.write("    # =========================================================\n")
        for label, text, addr in strings:
            f.write(gen_string_writer(label, text, addr) + "\n")

    print("string_init_block.txt 重新產生完成(修正版)")
