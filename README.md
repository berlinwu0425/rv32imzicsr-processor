# A RISC-V RV32IMZicsr Processor with Multi-Layer Verification

**From RISCOF Compliance and FPGA Deployment to Formal Characterization of the Safety Boundary for Speculative Coprocessor Offloading in In-Order Pipelines**

自製 RV32IMZicsr 處理器：從 RISCOF 合規與 FPGA 部署，到循序管線中推測性協同處理器卸載之安全邊界形式化刻畫

國立中興大學電機工程學系 專題研究 ｜ 電機四 伍柏霖 ｜ 指導老師：范志鵬 教授

📄 完整專題報告：[docs/report.pdf](docs/report.pdf)　｜　📝 [勘誤表](docs/ERRATA.md)（報告提交後發現的更正）

---

## 概要

本專題設計並實作一顆自訂的 RV32IM + Zicsr 五級管線處理器，以 RISCOF 官方合規測試（62/62 通過）與 FPGA 實機部署驗證其正確性，再擴充自訂向量處理器與動態分支預測器兩項微架構。

在此過程中浮現一個具體的時序問題：當多週期協同處理器指令與分支預測驅動的推測執行同時存在時，什麼樣的時序關係決定了「推測性污染」是否可能發生？協同處理器擴充介面規格 CV-X-IF 要求被 kill 的指令不得改變 architectural state，但其主流參考實作 CVA6 的公開文件將 offloaded-instruction killing 標示為未支援。本專題以三層互補的形式化方法分析此問題，求出參數化的安全邊界。

## 成果摘要

| 項目 | 成果 |
|---|---|
| ISA 合規 | RISCOF 與 Spike 參考模型 signature 逐位元比對：**62 / 62 通過**（RV32I 38、M 8、Zicsr 與特權架構 16） |
| FPGA 實機 | EGO1（Xilinx Artix-7 XC7A35T）；獨立硬體自動檢查器 16/16、UART 外部觸發雙向互動、計時器中斷實機驗證、12 階段互動式展示系統 |
| 向量處理器 | custom-0 opcode 自訂 9 條向量指令；平行版本 **約 2.84× speedup**（6,952 → 2,452 cycles），LUT +13.4%、DSP +140%；以 Amdahl 定律分析記憶體存取瓶頸 |
| 動態分支預測器 | 2-bit 飽和計數器 + BTB（含 tag 比對）；基準測試執行時間 **降低 39.7%**（50,155 → 30,215 ns） |
| 形式化安全邊界 | 三組參數化掃描共 792 組（99 + 297 + 396），支持 **F ≤ D + 1**、**F ≤ D + 1 + L_LAT**、**F ≤ D + 1 + S** 三個邊界關係；真實 baseline CPU（D = 0, F = 0）位於安全區內 |

## 處理器架構

- **管線**：IF / ID / EX / MEM / WB 五級管線，含 forwarding 與 hazard detection
- **ISA**：RV32I + M（乘除法）+ Zicsr，含機器模式特權架構
- **中斷/例外**：ecall、ebreak、指令/資料位址未對齊；記憶體映射軟體中斷（可由外部 UART 觸發）；mtime/mtimecmp（64-bit）計時器中斷
- **向量處理器**：`vsetvl`、`vld`、`vst` 與六種向量-向量/向量-純量 ALU 運算，以獨立協同處理器架構、管線凍結機制與主管線整合
- **分支預測器**：IF 階段預測、EX 階段驗證與更新，猜錯才觸發 flush

## 驗證方法

| 層次 | 方法 | 目的 |
|---|---|---|
| 模擬驗證 | RISCOF + Spike 參考模型比對、自行設計的定向測試 | 確保 ISA 語意正確 |
| 實機驗證 | EGO1 FPGA 部署，含獨立硬體自動檢查器 | 確保在真實時序與 I/O 條件下行為正確 |
| 形式化驗證 | Yosys + SymbiYosys：k-induction 與有界模型檢查（BMC） | 對關鍵不變量提供無界證明；對參數化時序模型進行有界系統性掃描 |

形式化驗證涵蓋計時器比較邏輯、記憶體讀寫一致性、管線暫存器 reset 完整性、中斷優先權邏輯，以及分支預測器安全性質（發現並修補 `predict_target` 在 tag miss 時未受保護的資訊洩漏缺口）。驗證流程中搭配刻意植入錯誤的健全性檢查，確認性質確實能偵測違反。

## 推測性協同處理器卸載之安全邊界

採用「具體安全層 → 具體時序層 → 抽象邊界層」三層互補架構：

1. **具體安全層（Theorem A1/A2）**：以 k-induction 證明 flush 觸發後下一個 cycle，`pc_out_o` 與 `is_vec_op_o` 恆為 0，且完整的 `vec_start` 判斷式恆為假。
2. **具體時序層（Ghost Timing Model）**：以不干預電路功能的 ghost 訊號，從真實 RTL 時序中導出 stall-free 條件下的推測距離 **D = 0**。
3. **抽象邊界層（BMC 參數掃描）**：

| 報告章節 | 模型 | 參數範圍 | 組數 | 邊界關係 |
|---|---|---|---|---|
| 4.6 基準情境 | `speculative_boundary_model.v` | D 0–8、F 0–10 | 99 | F ≤ D + 1 |
| 4.7 納入協同處理器延遲 | `speculative_kill_model.v`（safety）<br>`speculative_equivalence_model.v`（safety + liveness） | D 0–8、F 0–10、L_LAT ∈ {0, 2, 4} | 各 297 | F ≤ D + 1 + L_LAT |
| 4.8 納入管線 stall | `bounded_stall_model.v` | D 0–8、F 0–10、S 0–3 | 396 | F ≤ D + 1 + S |

D：分支解決到協同處理器啟動點的管線推進距離；F：誤判偵測到 flush 生效的延遲；L_LAT：協同處理器運算完成/結果可見延遲；S：有效 stall cycle 數。

掃描範圍內全部結果與邊界公式一致：邊界內 PASS，邊界外產生形式化反例。邊界值超過 F 掃描上限的格子，其 PASS／FAIL 交界點另以 F = 11–14 補驗（4.7 節兩個模型各 10 點、4.8 節 9 點），也全部一致。協同處理器延遲與管線 stall 這兩個從未在同一模型中聯合驗證的因素，呈現完全相同的線性位移。

### 限制

- 邊界關係為有限離散參數組合下、經形式化掃描支持的猜想，並非符號化的數學歸納證明。
- kill/commit 復原機制僅於抽象模型層級評估，尚未在 `vector_unit.v` 上實作。
- Theorem A1/A2 證明於改寫判斷式寫法的鏡像模型上，鏡像與原始 RTL 的忠實對應為人工建立、尚未形式化驗證的 assumption。
- 僅涵蓋單一獨立推測事件；stall 對 D 的影響尚未在真實 RTL 上驗證。

完整討論見報告第五章；報告中已知的錯誤與更正見 [docs/ERRATA.md](docs/ERRATA.md)。

## 目錄結構

```
rtl/        處理器與周邊 RTL；*_model.v、*_formal.v 為形式化驗證用模型
            （caseA_formal.v：Theorem A1/A2；ghost_timing_model.v：Ghost Timing Model）
sim/        Verilator testbench（testbench.v、sim_main.cpp）
riscof/     RISCOF DUT plugin（mycpu）與 Spike 參考模型 plugin
formal/     SymbiYosys 設定檔（.sby）、參數掃描腳本與結果（.csv）
fpga/       EGO1 頂層（ego1_top.v）、腳位約束（ego1.xdc）、測試與展示程式（programs/*.S）
docs/       專題報告（report.pdf）與勘誤表（ERRATA.md）
```

## 執行方式

**模擬**（Verilator 5.x）

```bash
verilator -Wno-fatal --trace --timing --cc rtl/*.v sim/testbench.v \
  --top-module cpu_tb --exe sim/sim_main.cpp -o Vcpu_tb --build
./obj_dir/Vcpu_tb +hex=program.hex +sig=out.signature +sigstart=0 +sigend=2048 +tohost=<tohost 位址>
```

`<tohost 位址>` 可用 `riscv32-unknown-elf-objdump -t` 查詢程式中的 `tohost` symbol 取得。

**形式化驗證**（Yosys + SymbiYosys + Z3）

```bash
cd formal
sby -f boundary_D3_F4.sby      # 邊界內（F ≤ D+1），預期 PASS
sby -f boundary_D2_F4.sby      # 邊界外（F > D+1），預期 FAIL 並產生反例
```

**RISCOF**（RISCOF、Spike、riscv32-unknown-elf toolchain、Verilator）

```bash
cd riscof
riscof run --config=config.ini \
  --suite=<riscv-arch-test>/riscv-test-suite \
  --env=<riscv-arch-test>/riscv-test-suite/env
```

**FPGA**：在 Vivado 建立專案，加入 `rtl/` 中除 `*_model.v`、`*_formal.v` 以外的檔案，以及 `fpga/ego1_top.v`、`fpga/ego1.xdc`。

## 使用工具

Verilator · RISCOF · Spike · Yosys / SymbiYosys（Z3）· Vivado · Xilinx EGO1（Artix-7）
