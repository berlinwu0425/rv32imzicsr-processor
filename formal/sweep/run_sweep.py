#!/usr/bin/env python3
"""參數掃描：報告 4.6–4.8 節三條邊界關係的逐點形式化驗證。

每一組參數產生一個 SymbiYosys 工作，結果與邊界公式比對：

  family   模型                              邊界關係              參數範圍                  組數
  boundary speculative_boundary_model.v      F <= D + 1            D 0–8、F 0–10              99
  kill     speculative_kill_model.v          F <= D + 1 + L_LAT    再加 L_LAT ∈ {0, 2, 4}    297
  equiv    speculative_equivalence_model.v   同上 (safety+liveness) 同上                     297
  bstall   bounded_stall_model.v             F <= D + 1 + S        再加 S ∈ {0, 1, 2, 3}     396

邊界關係已由 ../symbolic_boundary.sby 以符號化參數一次證明；
這裡保留逐點掃描作為對照，結果記錄在 results.csv。

用法：  cd formal/sweep && python3 run_sweep.py [-j 平行數] [family ...]
需要：  Yosys、SymbiYosys、Z3
"""
import argparse
import concurrent.futures as cf
import os
import shutil
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.abspath(os.path.join(HERE, '..', '..', 'rtl'))
WORK = os.path.join(HERE, '_work')
DEPTH = 40

FAMILIES = {
    # family: (模型, sby 模式, 第三個參數名稱, 第三個參數的值)
    'boundary': ('speculative_boundary_model', 'prove', None, [0]),
    'kill':     ('speculative_kill_model', 'prove', 'L_LAT', [0, 2, 4]),
    'equiv':    ('speculative_equivalence_model', 'bmc', 'L_LAT', [0, 2, 4]),
    'bstall':   ('bounded_stall_model', 'bmc', 'S', [0, 1, 2, 3]),
}

SBY = """[options]
mode {mode}
depth {depth}

[engines]
smtbmc z3

[script]
read -formal -DFORMAL {model}.v
chparam {params} {model}
prep -top {model}

[files]
{rtl}/{model}.v
"""


def jobs(families):
    for fam in families:
        model, mode, pname, pvals = FAMILIES[fam]
        for d in range(9):
            for f in range(11):
                for pv in pvals:
                    yield fam, model, mode, d, f, pname, pv


def run(job):
    fam, model, mode, d, f, pname, pv = job
    name = '%s_D%d_F%d' % (fam, d, f) + ('_%s%d' % (pname, pv) if pname else '')
    params = '-set D %d -set F %d' % (d, f) + (' -set %s %d' % (pname, pv) if pname else '')
    sby = os.path.join(WORK, name + '.sby')
    with open(sby, 'w') as fh:
        fh.write(SBY.format(mode=mode, depth=DEPTH, model=model, params=params, rtl=RTL))
    try:
        subprocess.run(['sby', '-f', name + '.sby'], cwd=WORK, timeout=600,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.TimeoutExpired:
        pass
    jobdir = os.path.join(WORK, name)
    result = 'PASS' if os.path.exists(os.path.join(jobdir, 'PASS')) else \
             'FAIL' if os.path.exists(os.path.join(jobdir, 'FAIL')) else 'UNKNOWN'
    shutil.rmtree(jobdir, ignore_errors=True)
    os.remove(sby)
    expected = 'PASS' if f <= d + 1 + (pv if pname else 0) else 'FAIL'
    return [fam, d, f, pname or '-', pv if pname else '-', mode, DEPTH, result, expected]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-j', type=int, default=os.cpu_count() or 1, help='同時執行的工作數')
    ap.add_argument('families', nargs='*', default=list(FAMILIES), help='要掃描的 family (預設全部)')
    args = ap.parse_args()
    os.makedirs(WORK, exist_ok=True)

    todo = list(jobs(args.families))
    rows, mismatch = [], 0
    with cf.ThreadPoolExecutor(args.j) as ex:
        for i, row in enumerate(ex.map(run, todo), 1):
            rows.append(row)
            if row[7] != row[8]:
                mismatch += 1
                print('不一致:', row)
            if i % 50 == 0 or i == len(todo):
                print('%d / %d' % (i, len(todo)), flush=True)

    with open(os.path.join(HERE, 'results.csv'), 'w') as fh:
        fh.write('family,D,F,param,value,mode,depth,result,expected\n')
        for r in rows:
            fh.write(','.join(str(x) for x in r) + '\n')
    shutil.rmtree(WORK, ignore_errors=True)
    print('完成：%d 組，%s' % (len(rows), '全部與邊界公式一致' if mismatch == 0 else '%d 組不一致' % mismatch))
    return 0 if mismatch == 0 else 1


if __name__ == '__main__':
    raise SystemExit(main())
