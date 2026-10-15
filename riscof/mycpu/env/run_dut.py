#!/usr/bin/env python3
import sys
import subprocess

def main():
    elf = sys.argv[1]
    sig_file = sys.argv[2]
    dut_exe = sys.argv[3]

    bin_file = elf + ".text.bin"
    hex_file = elf + ".hex"

    # 1. 只抽取 .text.init 這個 section 成純二進位
    subprocess.run(
        ["riscv64-unknown-elf-objcopy", "-O", "binary",
         "--only-section=.text.init", elf, bin_file],
        check=True
    )

    # 2. 轉成 32-bit word hex 檔（小端序），給 $readmemh 用
    data = open(bin_file, "rb").read()
    pad = (-len(data)) % 4
    data += b"\x00" * pad
    words = []
    for i in range(0, len(data), 4):
        b = data[i:i+4]
        val = b[0] | (b[1] << 8) | (b[2] << 16) | (b[3] << 24)
        words.append(f"{val:08x}")
    with open(hex_file, "w") as f:
        f.write("\n".join(words) + "\n")

    # 2b. 額外抽取 .data section（測試框架預先寫死的初始資料，
    #     load 類指令(lb/lh/lw等)測試會直接讀取這段資料，
    #     一定要載入 dmem，不然讀出來永遠是 0）
    #     用帶 @address 前綴的 byte hex 格式，$readmemh 讀到 @xxx 會自動
    #     把後面資料放到指定位址開始的地方，不用整個陣列從頭填
    data_bin_file = elf + ".data.bin"
    data_hex_file = elf + ".data.hex"
    base_addr = 0x80000000

    objdump_out = subprocess.run(
        ["riscv64-unknown-elf-objdump", "-h", elf],
        capture_output=True, text=True, check=True
    ).stdout

    data_vma = None
    for line in objdump_out.splitlines():
        parts = line.split()
        if len(parts) >= 4 and parts[1] == ".data":
            data_vma = int(parts[3], 16)
            break

    if data_vma is not None:
        dcopy = subprocess.run(
            ["riscv64-unknown-elf-objcopy", "-O", "binary",
             "--only-section=.data", elf, data_bin_file],
            capture_output=True
        )
        if dcopy.returncode == 0:
            try:
                ddata = open(data_bin_file, "rb").read()
            except FileNotFoundError:
                ddata = b""
            if len(ddata) > 0:
                # dmem.v 現在改成以 word(32-bit) 為單位的陣列，
                # @位址前綴要用 word index，且每行資料要是完整32-bit(小端序打包)，
                # 跟前面 .text.hex 的打包方式保持一致
                data_offset = data_vma - base_addr
                word_offset = data_offset // 4
                pad = (-len(ddata)) % 4
                ddata_padded = ddata + b"\x00" * pad
                lines = [f"@{word_offset:x}"]
                for i in range(0, len(ddata_padded), 4):
                    b = ddata_padded[i:i+4]
                    val = b[0] | (b[1] << 8) | (b[2] << 16) | (b[3] << 24)
                    lines.append(f"{val:08x}")
                with open(data_hex_file, "w") as f:
                    f.write("\n".join(lines) + "\n")
            else:
                data_hex_file = None
        else:
            data_hex_file = None
    else:
        data_hex_file = None

    # 3. 從 elf 的 symbol table 抓 begin_signature / end_signature 位址
    out = subprocess.run(
        ["riscv64-unknown-elf-objdump", "-t", elf],
        capture_output=True, text=True, check=True
    ).stdout

    begin_addr = None
    end_addr = None
    tohost_addr = None
    for line in out.splitlines():
        parts = line.split()
        if len(parts) >= 2 and parts[-1] == "begin_signature":
            begin_addr = int(parts[0], 16)
        if len(parts) >= 2 and parts[-1] == "end_signature":
            end_addr = int(parts[0], 16)
        if len(parts) >= 2 and parts[-1] == "tohost":
            tohost_addr = int(parts[0], 16)

    if begin_addr is None or end_addr is None:
        print("ERROR: begin_signature/end_signature not found in " + elf,
              file=sys.stderr)
        sys.exit(1)

    if tohost_addr is None:
        # 找不到就用預設值 (大部分測試的.text.init不大時剛好是這個位址)
        tohost_addr = 0x80038000

    # 4. 呼叫模擬器，傳入 hex 檔路徑、signature 輸出檔、signature 範圍
    # dmem 位址是相對於 link.ld 的基底位址 0x80000000 計算的
    # (imem/dmem 內部都是用相對位移量當陣列 index，不是完整的絕對位址)
    base_addr = 0x80000000
    sig_start_offset = begin_addr - base_addr
    sig_end_offset = end_addr - base_addr

    cmd = [
        dut_exe,
        f"+hex={hex_file}",
        f"+sig={sig_file}",
        f"+sigstart={sig_start_offset}",
        f"+sigend={sig_end_offset}",
        f"+tohost={tohost_addr}",
    ]
    if data_hex_file:
        cmd.append(f"+data={data_hex_file}")
    result = subprocess.run(cmd)
    sys.exit(result.returncode)

if __name__ == "__main__":
    main()
