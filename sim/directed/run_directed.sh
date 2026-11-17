#!/bin/bash
# 定向回歸測試：針對管線凍結(向量單元、load-use)與trap/mret交互作用的自我檢查測試
# 用法：./run_directed.sh            (需要 Verilator 5.x 與 RISC-V toolchain)
#       CROSS=riscv32-unknown-elf- ./run_directed.sh   (手動指定toolchain前綴)
#       RTL_DIR=/path/to/rtl ./run_directed.sh   (指定要測的RTL目錄)
set -u
cd "$(dirname "$0")"
if [ -z "${CROSS:-}" ]; then   # 自動偵測toolchain前綴
    for c in riscv64-unknown-elf- riscv32-unknown-elf-; do
        command -v ${c}gcc > /dev/null 2>&1 && CROSS=$c && break
    done
fi
if [ -z "${CROSS:-}" ]; then echo "找不到 RISC-V gcc (riscv64-unknown-elf-gcc 或 riscv32-unknown-elf-gcc)"; exit 2; fi
RTL_DIR=${RTL_DIR:-../../rtl}
BUILD=${BUILD:-build}
mkdir -p "$BUILD"

RTL=$(ls "$RTL_DIR"/*.v | grep -v -E '_formal\.v$|_model\.v$')
if ! verilator -Wno-fatal --binary -j 2 $RTL tb_directed.v --top-module tb_directed \
        -o Vtb_directed --Mdir "$BUILD/obj" > "$BUILD/verilator.log" 2>&1; then
    echo "Verilator build failed, see $BUILD/verilator.log"; exit 2
fi

pass=0; fail=0
run_one() {   # 名稱  原始檔  [額外的組譯定義...]
    local name=$1 src=$2; shift 2
    local defs=""; for d in "$@"; do defs="$defs -D$d"; done
    if ! ${CROSS}gcc -march=rv32im_zicsr -mabi=ilp32 -nostdlib -nostartfiles -x assembler-with-cpp \
            $defs -T link.ld -o "$BUILD/$name.elf" "$src" 2> "$BUILD/$name.asm.log"; then
        echo "FAIL  $name (assemble error, see $BUILD/$name.asm.log)"; fail=$((fail+1)); return
    fi
    ${CROSS}objcopy -O binary "$BUILD/$name.elf" "$BUILD/$name.bin"
    od -An -tx4 -v -w4 "$BUILD/$name.bin" | tr -d ' ' > "$BUILD/$name.hex"
    local out; out=$("$BUILD/obj/Vtb_directed" +hex="$BUILD/$name.hex" 2>/dev/null | grep RESULT)
    local code; code=$(echo "$out" | sed -E 's/.*code=([0-9]+).*/\1/')
    local uart; uart=$(echo "$out" | sed -E 's/.*uart=([0-9]+).*/\1/')
    local want_uart; want_uart=$(grep -m1 -o 'EXPECT_UART=[0-9]*' "$src" | cut -d= -f2)
    local ok=1
    [ "$code" = "1" ] || ok=0
    [ -z "$want_uart" ] || [ "$uart" = "$want_uart" ] || ok=0
    if [ $ok = 1 ]; then pass=$((pass+1)); [ "${VERBOSE:-0}" = 1 ] && echo "PASS  $name"
    else fail=$((fail+1)); echo "FAIL  $name  ($out${want_uart:+, expected uart=$want_uart})"; fi
}

run_one vec_next_once    vec_next_once.S
run_one vec_next_operand vec_next_operand.S
run_one vec_next_jump    vec_next_jump.S
run_one mret_next        mret_next.S
run_one trap_loaduse     trap_loaduse.S
# 中斷到達時間掃描：每個offset讓中斷落在不同的pipeline狀態上
for o in $(seq 20 59);  do run_one irq_loaduse_$o irq_loaduse.S OFFS=$o; done
for o in $(seq 40 89);  do run_one irq_vec_$o     irq_vec.S     OFFS=$o; done
for o in $(seq 40 139); do run_one irq_vecld_$o   irq_vec.S     OFFS=$o WITH_VLD; done

echo "directed tests: $pass passed, $fail failed"
[ $fail = 0 ]
