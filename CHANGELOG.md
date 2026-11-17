# 更新紀錄

## 2026-11

### 處理器 RTL

- 修正向量指令執行期間，下一條指令被重複執行的問題。
- 修正緊接在向量指令之後的跳躍、分支或 ecall 遺失的問題。
- 修正 stall 期間到達的中斷遺失的問題。
- 修正 mret 之後的下一條指令仍被執行的問題（mret 現在也會 flush ID/EX 與 EX/MEM）。
- 修正中斷打斷向量指令時，該指令被執行兩次的問題。
- 向量單元加入 kill/commit：`vld` 的結果先暫存、最後一拍才寫入向量暫存器；`vst` 在第一筆寫入前可被取消。
- `mstatus.MPP` 讀值固定為 11（只實作機器模式）。
- 三個管線暫存器將非同步 reset 與同步 flush 寫成兩個獨立的分支，方便形式化工具直接讀取原始 RTL。

### 驗證

- 新增 `sim/directed/`：195 個定向回歸測試，涵蓋向量指令、load-use、trap 與 mret 交錯的情況。
- Theorem A1 改為直接證明於 `id_ex_register.v`（`theorem_A1.sby`）。
- 新增 `cpu_top_safety.sby`：在處理器頂層 RTL 上證明系統層級性質 S1–S7。
- 新增 `vector_unit_kill.sby`：證明被取消的向量指令不改變向量暫存器、也不發出記憶體寫入。
- 新增 `symbolic_boundary.sby` 與 `rtl/symbolic_boundary_model.v`：三條邊界關係以 8-bit 符號化參數證明雙向成立。
- 新增 `run_sanity.py`：所有形式化性質的 baseline 與 16 種植入錯誤的健全性檢查，全部被偵測。
- 修正後重新驗證：RISCOF 62/62、定向測試 195/195、FPGA 實機展示正常；Vivado 合成 LUT 18,066、DSP 36、WNS 4.360 ns。

### Repo 整理

- `sim/testbench.v` 只保留 RISCOF 與一般模擬需要的功能，波形與逐 cycle 追蹤改為 `+vcd`、`+trace` 參數；除錯用的監視器移除。
- 互動式展示程式的自動操作邏輯移到 `fpga/tb/tb_demo.v`，並更新為目前展示程式的階段編號。
- 舊的 `*_broken*.sby` 依賴不在 repo 中的 `/tmp` 檔案，改為併入 `run_sanity.py` 以植入錯誤的方式執行。
- 參數掃描改由 `formal/sweep/run_sweep.py` 產生並執行全部 1,089 組，結果整理為 `formal/sweep/results.csv`；移除逐一列出的掃描 `.sby` 與補跑腳本。
- 移除已由真實 RTL 上的證明取代的鏡像模型（`caseA_formal.v`、`case_correspondence_formal.v` 與相關 `.sby`）；`caseA_theorem_A1.sby` 更名為 `theorem_A1.sby`。
- `interrupt_priority_formal.v` 與 `cpu_top.v` 的中斷允許條件同步（加入 `vec_killable`）。
- RISCOF 設定與 plugin 改用相對路徑，模擬器路徑可在 `config.ini` 設定；`run_dut.py` 自動偵測 RISC-V toolchain 前綴。
- 移除內容已過時的 `fpga/programs/gen_string_writer.py`。
- 更新過時的註解（記憶體類型、優先順序、補洞式說明）。

### 文件

- README 重寫，加入開發環境版本；原 `docs/ERRATA.md` 的內容併入本紀錄。
- 專題報告更新為修訂版（`docs/report.pdf`）。
- 分支預測器的效能改以 cycle 數呈現：5,009 → 3,015 cycles（−39.8%），減少的 1,994 cycles 對應 997 次誤判 × 2 cycle 的 flush 懲罰；原先寫的 39.7% 為四捨五入錯誤。

## 2026-10-18

- baseline 在安全邊界上的位置更正為 (D, F) = (0, 1)，恰位於邊界 F = D + 1 上，而非安全區內側。

## 2026-10-16

- 第 4.8 節掃描組數更正為 396 組（9 × 11 × 4），並補跑缺少的 12 組；三組掃描合計 792 組。
- 圖八 Safe 區的驗證組數標示更正。
- 第 4.7 節「safety 與 liveness 安全區重合」補充說明：模型中正確路徑的指令不會被 kill，liveness 必然成立，重合是模型設定的結果。

## 2026-10-15

- 初版：處理器 RTL、RISCOF、FPGA、形式化驗證與專題報告。
