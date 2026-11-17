# A RISC-V RV32IMZicsr Processor with Multi-Layer Verification

**From RISCOF Compliance and FPGA Deployment to Formal Characterization of the Safety Boundary for Speculative Coprocessor Offloading in In-Order Pipelines**

自製 RV32IMZicsr 處理器：從 RISCOF 合規與 FPGA 部署，到循序管線中推測性協同處理器卸載之安全邊界形式化刻畫

國立中興大學電機工程學系 專題研究 ｜ 電機四 伍柏霖 ｜ 指導老師：范志鵬 教授

📄 完整專題報告：[docs/report.pdf](docs/report.pdf)　｜　📝 [更新紀錄](CHANGELOG.md)

---

## 概要

本專題設計並實作一顆自訂的 RV32IM + Zicsr 五級管線處理器，以 RISCOF 官方合規測試與 FPGA 實機部署驗證其正確性，再擴充自訂向量處理器與動態分支預測器兩項微架構。

處理器同時具備分支預測與多週期協同處理器之後，浮現一個具體的時序問題：錯誤路徑上的協同處理器指令，會不會在 flush 生效之前就被啟動，留下「推測性污染」？本專題以三層互補的形式化方法分析這個問題，求出安全邊界，並證明這顆處理器（D = 0、F = 1）剛好位於邊界上，靠同一時脈邊緣 flush 優先於 stall 維持安全。

## 成果摘要

| 項目 | 成果 |
|---|---|
| ISA 合規 | RISCOF 與 Spike 參考模型 signature 逐位元比對：**62 / 62 通過**（RV32I 38、M 8、Zicsr 與特權架構 16） |
| 定向測試 | 195 個自我檢查測試，涵蓋分支、flush、stall、trap、mret 與向量指令交錯的情況 |
| FPGA 實機 | EGO1（Xilinx Artix-7 XC7A35T）；硬體自動檢查器 16/16、UART 雙向互動、計時器中斷、12 階段互動式展示系統 |
| 向量處理器 | custom-0 opcode 自訂 9 條向量指令；平行版本 **約 2.84× speedup**（6,945 → 2,445 cycles），LUT +11.8%、DSP 15 → 36 |
| 動態分支預測器 | 2-bit 飽和計數器 + BTB（含 tag 比對）；基準測試 **cycle 數降低 39.8%**（5,009 → 3,015 cycles） |
| 形式化驗證 | 在處理器 RTL 上以 k-induction 證明 Theorem A1 與系統層級性質 S1–S7；三條安全邊界關係以符號化參數證明雙向成立 |

## 處理器架構

- **管線**：IF / ID / EX / MEM / WB 五級管線，含 forwarding 與 hazard detection；分支、跳躍、trap 與 mret 都在 EX 級處理
- **ISA**：RV32I + M（乘除法）+ Zicsr，含機器模式特權架構
- **中斷／例外**：ecall、ebreak、指令／資料位址未對齊；記憶體映射軟體中斷（可由外部 UART 觸發）；mtime / mtimecmp（64-bit）計時器中斷
- **記憶體**：指令與資料記憶體分開（Harvard 架構），組合讀取，合成為 distributed RAM
- **向量處理器**：`vsetvl`、`vld`、`vst` 與六種向量 ALU 運算；執行期間以多週期 EX stall 凍結主管線。`vld` 的結果先暫存、最後一拍才寫入向量暫存器；`vst` 在第一筆寫入前可被取消
- **分支預測器**：IF 階段預測、EX 階段驗證與更新，猜錯才觸發 flush

## 驗證方法

| 層次 | 方法 | 可偵測的錯誤 |
|---|---|---|
| 指令層 | RISCOF + Spike 參考模型比對 | 單一指令的運算結果、載入／儲存與例外處理 |
| 管線控制層 | 形式化驗證（Yosys + SymbiYosys）、195 個定向測試 | 分支、flush、stall、例外同時發生時的控制錯誤 |
| 實體層 | EGO1 FPGA 部署，含硬體自動檢查器 | 跨時脈域、reset 極性、記憶體推斷、時序不足 |

形式化驗證另涵蓋計時器比較邏輯、記憶體讀寫一致性、中斷優先權邏輯，以及分支預測器的安全性質。各項性質都以刻意植入錯誤的健全性檢查確認能偵測違反（`formal/run_sanity.py`，16 種植入錯誤全部被偵測）。

## 推測性協同處理器卸載之安全邊界

採用「具體安全層 → 具體時序層 → 抽象邊界層」三層互補架構：

1. **具體安全層**：
   - **Theorem A1**：ID/EX 管線暫存器收到 flush 後，下一個 cycle 輸出必為 bubble，且 flush 優先於 stall。
   - **S1–S7**：在處理器頂層 RTL 上證明，分支誤判、trap 與 mret 之後錯誤路徑上的指令不會啟動協同處理器，控制流程的改變不會因 stall 而遺失，被取消的指令不留下結果。資料路徑以 cutpoint 抽象為任意值，指令串流不設限。
2. **具體時序層（Ghost Timing Model）**：以不干預電路行為的 ghost 訊號，從真實 RTL 時序導出推測距離 **D = 0**。
3. **抽象邊界層**：以參數化模型求出三條邊界關係，先以參數掃描觀察（792 組），再將參數改為 8-bit 符號化變數，以 k-induction 證明關係雙向成立：

| 報告章節 | 考慮的因素 | 邊界關係 |
|---|---|---|
| 4.6 基準情境 | 推測距離 D、flush 延遲 F | F ≤ D + 1 |
| 4.7 協同處理器延遲 | 加入 kill/commit 與協同處理器延遲 L_LAT | F ≤ D + 1 + L_LAT |
| 4.8 管線 stall | 加入有效 stall cycle 數 S | F ≤ D + 1 + S |

D：分支解析級到協同處理器啟動級相差的管線級數；F：偵測到誤判到 flush 生效的 cycle 數。

這顆處理器的分支解析與向量指令啟動都在 EX 級（D = 0），flush 為同步清除（F = 1），因此恰好位於基準邊界 F = D + 1 上：錯誤路徑指令與 flush 在同一拍到達，靠 flush 優先擋下。flush 路徑若再多一拍延遲就會越過邊界。

### 限制

- 邊界關係證明於抽象模型（參數 8-bit）；真實硬體上只驗證了本設計自己的參數。
- kill/commit 只實作於向量單元；`vst` 開始寫入記憶體後就不能取消。
- 形式化驗證只涵蓋控制性質，資料正確性由 RISCOF 與定向測試確認。
- 邊界公式只分析單一推測事件；處理器的 RTL 證明不限制指令串流，連續多次誤判都已涵蓋。

完整討論見報告第五章。

## 目錄結構

```
rtl/            處理器與周邊 RTL；*_model.v、*_formal.v 為形式化驗證用模型（不參與合成）
sim/            通用模擬 testbench（RISCOF 與一般程式共用）
sim/directed/   定向回歸測試（195 個自我檢查測試）
riscof/         RISCOF 設定（config.ini）、DUT plugin（mycpu）與 Spike 參考模型 plugin
formal/         SymbiYosys 設定檔（.sby）與健全性檢查（run_sanity.py）
formal/sweep/   邊界關係的逐點參數掃描（run_sweep.py）與結果（results.csv）
fpga/           EGO1 頂層（ego1_top.v）、腳位約束（ego1.xdc）、測試與展示程式（programs/*.S）
fpga/tb/        防彈跳、UART 傳送路徑與互動式展示程式的模擬 testbench
docs/           專題報告（report.pdf）
```

## 開發環境

| 工具 | 版本 |
|---|---|
| 作業系統 | Ubuntu 26.04 LTS（WSL） |
| Verilator | 5.032 |
| RISC-V GCC（riscv32／riscv64-unknown-elf） | 14.2.0 |
| Spike | 1.1.1-dev |
| RISCOF | 1.25.3 |
| riscv-arch-test | 2.3.1 |
| Yosys / SymbiYosys | Yosys 0.52 |
| Z3 | 4.13.3 |
| Python | 3.14 |
| Vivado | 2026.1 |
| FPGA 板 | EGO1（Xilinx Artix-7 XC7A35T） |

## 執行方式

以下指令都在 repo 根目錄執行。

**模擬**

```bash
verilator -Wno-fatal --trace --timing --cc rtl/*.v sim/testbench.v \
  --top-module cpu_tb --exe sim/sim_main.cpp -o Vcpu_tb --build
./obj_dir/Vcpu_tb +hex=program.hex +tohost=<tohost 位址>
```

`<tohost 位址>` 可用 `riscv32-unknown-elf-objdump -t` 查詢程式中的 `tohost` symbol 取得。加上 `+vcd` 會輸出波形，`+trace` 會逐 cycle 印出各級 PC；其他參數見 `sim/testbench.v` 開頭的說明。

**程式轉成 hex**（模擬與 FPGA 共用）

```bash
riscv32-unknown-elf-gcc -march=rv32im_zicsr -mabi=ilp32 -nostdlib -nostartfiles \
  -T sim/directed/link.ld -o program.elf fpga/programs/demo_interactive.S
riscv32-unknown-elf-objcopy -O binary program.elf program.bin
od -An -tx4 -v -w4 program.bin | tr -d ' ' > program.hex
```

**定向測試**

```bash
./sim/directed/run_directed.sh
```

**互動式展示程式的模擬**（先用上面的指令把 `demo_interactive.S` 轉成 `program.hex`）

```bash
verilator -Wno-fatal --binary $(ls rtl/*.v | grep -v -E '_formal\.v$|_model\.v$') \
  fpga/tb/tb_demo.v --top-module tb_demo -o Vtb_demo
./obj_dir/Vtb_demo +hex=program.hex
```

約一分鐘跑完全部 12 個階段，結束時印出 UART 送出的文字。

**形式化驗證**

```bash
cd formal
sby -f theorem_A1.sby                # Theorem A1：ID/EX 的 flush 完整性
sby -f cpu_top_safety.sby            # S1–S7：處理器頂層的管線控制性質
sby -f vector_unit_kill.sby          # 向量單元 kill/commit
sby -f symbolic_boundary.sby         # 三條邊界關係的符號化證明（tasks：base / kill / stall）
python3 run_sanity.py                # 全部性質的 baseline 與健全性檢查（植入錯誤，預期每一個都 FAIL）
python3 sweep/run_sweep.py -j 8      # 逐點參數掃描（1,089 組，結果寫入 sweep/results.csv）
```

其餘 `.sby` 分別驗證計時器（`mtime_unit`）、資料記憶體（`dmem`）、IF/ID reset（`if_id_register`）、中斷優先權（`interrupt_priority`）、分支預測器安全性質（`branch_predictor_security`）與 Ghost Timing Model（`ghost_timing`）。

**RISCOF**（先用上面的「模擬」指令建好 `obj_dir/Vcpu_tb`）

```bash
cd riscof
riscof run --config=config.ini \
  --suite=<riscv-arch-test>/riscv-test-suite \
  --env=<riscv-arch-test>/riscv-test-suite/env
```

**FPGA**：在 Vivado 建立專案，加入 `rtl/` 中除 `*_model.v`、`*_formal.v` 以外的檔案，以及 `fpga/ego1_top.v`、`fpga/ego1.xdc`。要執行的程式先轉成 hex，再由 `ego1_top.v` 的 `IMEM_INIT_FILE` 指定。

## 使用工具

Verilator · RISCOF · Spike · Yosys / SymbiYosys（Z3）· Vivado · Xilinx EGO1（Artix-7）
