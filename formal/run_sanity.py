#!/usr/bin/env python3
"""健全性檢查 (mutation testing)：確認形式化性質真的抓得到錯誤。

對 RTL 植入一個已知的錯誤 (每次只改一處)，重跑對應的證明，預期結果必須是 FAIL。
如果某個植入的錯誤還是 PASS，代表性質沒有涵蓋到那個行為 (vacuous)。

用法：  cd formal && python3 run_sanity.py
需要：  Yosys、SymbiYosys、Z3
"""
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.join(HERE, '..', 'rtl')
WORK = os.path.join(HERE, '_sanity')

# (名稱, 使用的 .sby, 要改的檔案, 原文, 替換成, 第幾次出現, 說明)
MUTATIONS = [
    ('A1_no_clear', 'theorem_A1.sby', 'id_ex_register.v',
     "is_vec_op_o     <= 1'b0;", "is_vec_op_o     <= is_vec_op_in;", 2,
     'flush 時不清除 is_vec_op_o'),
    ('A1_stall_first', 'theorem_A1.sby', 'id_ex_register.v',
     "else if (flush) begin", "else if (flush && !stall) begin", 1,
     'stall 的優先權高於 flush'),
    ('S1_mret_no_flush', 'cpu_top_safety.sby', 'cpu_top.v',
     "id_ex_hazard_flush || trap_taken_ex || is_mret_ex_r", "id_ex_hazard_flush || trap_taken_ex", 1,
     'mret 時不 flush ID/EX (mret 後的指令會被執行)'),
    ('S2_launch_when_squashed', 'cpu_top_safety.sby', 'cpu_top.v',
     "&& valid_ex && !vec_stall && !interrupt_pending;", "&& valid_ex && !vec_stall;", 1,
     '被中斷取消的向量指令仍然啟動 (生效兩次)'),
    ('S3_irq_while_busy', 'cpu_top_safety.sby', 'cpu_top.v',
     "wire irq_allowed = valid_ex && (!vec_stall || vec_killable);", "wire irq_allowed = valid_ex;", 1,
     '已經開始寫記憶體的 vst 仍被中斷取消'),
    ('K1_kill_ignored', 'vector_unit_kill.sby', 'vector_unit.v',
     "if (kill && (state != S_IDLE)) begin", "if (1'b0) begin", 1,
     '向量單元忽略 kill (被取消的指令仍然寫入結果)'),
    ('K2_no_buffer', 'vector_unit_kill.sby', 'vector_unit.v',
     "ld_buf[elem_idx] <= vec_mem_rdata;", "vregs[op_vd][elem_idx] <= vec_mem_rdata;", 1,
     'vld 不經暫存區直接寫向量暫存器 (kill 後留下部分結果)'),
    ('S4_no_hold', 'cpu_top_safety.sby', 'cpu_top.v',
     ".stall (vec_hold),", ".stall (vec_stall),", 1,
     '啟動當拍不凍結 ID/EX (向量指令先離開 EX，下一條被卡在 EX)'),
    ('S5_pc_frozen', 'cpu_top_safety.sby', 'cpu_top.v',
     "wire pc_write_en = ~stall_all || trap_taken_ex || is_mret_ex_r || redirect_ex;",
     "wire pc_write_en = ~stall_all;", 1,
     'stall 期間的 trap/redirect 不更新 PC (控制流程遺失)'),
    ('dmem_sw_no_write', 'dmem.sby', 'dmem.v',
     "word_wr = wdata;", "word_wr = word_rd;", 1,
     'SW 沒有寫入記憶體'),
    ('mtime_strict', 'mtime_unit.sby', 'mtime_unit.v',
     "assign mtip_pending = (mtime >= mtimecmp);", "assign mtip_pending = (mtime > mtimecmp);", 1,
     'mtime 等於 mtimecmp 時沒有觸發計時器中斷'),
    ('if_id_reset', 'if_id_register.sby', 'if_id_register.v',
     "inst_o             <= NOP;", "inst_o             <= inst_in;", 1,
     'reset 時 IF/ID 沒有清成 NOP'),
    ('irq_priority', 'interrupt_priority.sby', 'interrupt_priority_formal.v',
     "if (msi_pending)            trap_cause_ex", "if (msi_pending && !mti_pending) trap_cause_ex", 1,
     '計時器中斷優先於軟體中斷'),
    ('bp_target_leak', 'branch_predictor_security.sby', 'branch_predictor.v',
     "assign predict_target = tag_hit ? btb_table[query_idx] : 32'b0;", "assign predict_target = btb_table[query_idx];", 1,
     'tag miss 時仍輸出 BTB 內容'),
    ('bp_taken_no_tag', 'branch_predictor_security.sby', 'branch_predictor.v',
     "assign predict_taken  = tag_hit && counter_table[query_idx][1];", "assign predict_taken  = counter_table[query_idx][1];", 1,
     'tag miss 時仍依計數器預測 taken'),
    ('ghost_no_latch', 'ghost_timing.sby', 'ghost_timing_model.v',
     "ghost_is_vec_o <= is_vec_op_in;", "ghost_is_vec_o <= ghost_is_vec_o;", 1,
     'ghost 訊號沒有跟著管線前進'),
]


def replace_nth(text, old, new, n):
    pos = -1
    for _ in range(n):
        pos = text.find(old, pos + 1)
        if pos < 0:
            return None
    return text[:pos] + new + text[pos + len(old):]


def run_sby(workdir, sby_name):
    """回傳 'PASS' / 'FAIL' / 'UNKNOWN'"""
    job = sby_name[:-4]
    with open(os.path.join(workdir, job + '.log'), 'w') as log:
        subprocess.run(['sby', '-f', sby_name], cwd=workdir, stdout=log, stderr=subprocess.STDOUT)
    for r in ('PASS', 'FAIL'):
        if os.path.exists(os.path.join(workdir, job, r)):
            return r
    return 'UNKNOWN'


def prepare(name, sby_name):
    d = os.path.join(WORK, name)
    if os.path.isdir(d):
        shutil.rmtree(d)
    os.makedirs(os.path.join(d, 'rtl'))
    for f in os.listdir(RTL):
        if f.endswith('.v'):
            shutil.copy(os.path.join(RTL, f), os.path.join(d, 'rtl', f))
    sby = open(os.path.join(HERE, sby_name), encoding='utf8').read().replace('../rtl/', 'rtl/')
    open(os.path.join(d, sby_name), 'w', encoding='utf8').write(sby)
    return d


def main():
    ok = True
    print('%-26s %-8s %-8s %s' % ('測試', '預期', '結果', '植入的錯誤'))
    for sby_name in sorted(set(m[1] for m in MUTATIONS)):
        d = prepare('baseline_' + sby_name[:-4], sby_name)
        r = run_sby(d, sby_name)
        ok &= (r == 'PASS')
        print('%-26s %-8s %-8s %s' % (sby_name[:-4], 'PASS', r, '(未修改的 RTL)'))
    for name, sby_name, fname, old, new, nth, desc in MUTATIONS:
        d = prepare(name, sby_name)
        path = os.path.join(d, 'rtl', fname)
        text = replace_nth(open(path, encoding='utf8').read(), old, new, nth)
        if text is None:
            print('%-26s %-8s %-8s %s' % (name, 'FAIL', 'ERROR', '找不到要替換的原文，RTL 可能已經改動'))
            ok = False
            continue
        open(path, 'w', encoding='utf8').write(text)
        r = run_sby(d, sby_name)
        ok &= (r == 'FAIL')
        print('%-26s %-8s %-8s %s' % (name, 'FAIL', r, desc), flush=True)
    print('sanity check:', 'OK，所有植入的錯誤都被偵測到' if ok else '有項目不符預期')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
