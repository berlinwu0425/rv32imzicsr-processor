`timescale 1ns / 1ps

module cpu_tb;

    reg clk;
    reg rst_n;
    integer fd;
    integer i;

    // -----------------------------
    // 可由命令列參數覆寫的設定
    // -----------------------------
    reg [1023:0] hex_file;
    reg [1023:0] sig_file;
    reg [1023:0] data_file;
    integer has_data_file;
    integer sig_start;
    integer sig_end;
    integer tohost_addr;   // tohost 位址不固定，每個測試的 .tohost section 位址可能不同

    // -----------------------------
    // tohost 偵測用
    // -----------------------------
    reg tohost_written;
    integer timeout_cycles;

    cpu_top uut (
        .clk(clk),
        .rst_n(rst_n)
    );

    always begin
        #5 clk = ~clk;
    end

    // 監看寫入 tohost 的動作，這是 riscv-arch-test
    // 框架用來表示「程式執行完畢」的標準信號，比用固定delay猜測時間可靠
    // tohost_addr 由外部參數 +tohost= 傳入，因為不同測試這個位址可能不一樣
    always @(posedge clk) begin
        if (rst_n && uut.mem_write_en_mem && (uut.alu_result_mem == tohost_addr)) begin
            tohost_written <= 1'b1;
        end
    end

    initial begin
        $display("======= Simulation Started =======");
        clk = 0;
        rst_n = 0;
        tohost_written = 1'b0;

        // 若未由 +hex= 傳入，預設用 program.hex
        if (!$value$plusargs("hex=%s", hex_file)) begin
            hex_file = "program.hex";
        end
        // 若未由 +sig= 傳入，預設用 mycpu.signature
        if (!$value$plusargs("sig=%s", sig_file)) begin
            sig_file = "mycpu.signature";
        end
        // signature 記憶體範圍（byte offset，對應 dmem.memory[] 的 index）
        if (!$value$plusargs("sigstart=%d", sig_start)) begin
            sig_start = 0;
        end
        if (!$value$plusargs("sigend=%d", sig_end)) begin
            sig_end = 256;
        end
        // tohost 位址（byte offset，對應 dmem 的絕對位址，因為是跟 alu_result_mem 直接比較）
        if (!$value$plusargs("tohost=%d", tohost_addr)) begin
            tohost_addr = 32'h80038000;
        end

        $readmemh(hex_file, uut.u_imem.inst_mem);

        // 若有傳入 +data=，載入 .data section 的初始資料到 dmem
        // (load 類測試 (lb/lh/lw...) 依賴這段資料，沒載入的話讀出來永遠是0)
        // hex 檔本身用 @address 開頭指定起始位址，$readmemh 讀到 @xxx 會自動處理
        has_data_file = $value$plusargs("data=%s", data_file);
        if (has_data_file) begin
            $readmemh(data_file, uut.u_dmem.memory);
        end

        $dumpfile("cpu_simulation.vcd");
        $dumpvars(0, cpu_tb);

        #15;
        rst_n = 1;

        // 等待 tohost 被寫入，或是逾時(保護機制，避免某個測試沒寫tohost時卡死)
        // 用 while + @(posedge clk) 逐拍檢查，避開 Verilator 對 fork/disable 的限制
        timeout_cycles = 0;
        while (!tohost_written && timeout_cycles < 600000) begin
            @(posedge clk);
            timeout_cycles = timeout_cycles + 1;
        end

        if (!tohost_written) begin
            $display("[WARNING] Timeout reached before tohost was written!");
        end

        // 讓寫入tohost那條指令之後，pipeline 裡還沒寫完 signature 記憶體的
        // 少數幾條指令有機會跑完 (通常 write_tohost 後還有幾條收尾指令)
        #50;

        // -----------------------------
        // 輸出 RISCOF signature
        // -----------------------------
        // dmem.v 現在改成以 word(32-bit) 為單位的陣列(方便FPGA合成推斷成Block RAM)，
        // 所以這裡改成直接印出整個word，不再用4個獨立byte索引拼湊
        fd = $fopen(sig_file, "w");
        for (i = sig_start; i < sig_end; i = i + 4) begin
            $fwrite(fd, "%08x\n", uut.u_dmem.memory[i >> 2]);
        end
        $fclose(fd);

        $display("======= Simulation Finished =======");
        $finish;
    end

    // ==========================================
    // 文字除錯監視器 (Text Monitor) — Pipeline版
    // ==========================================
    always @(posedge clk) begin
        if (rst_n) begin
            $display("[Time=%0d ns] IF_PC=0x%h | ID_PC=0x%h | EX_PC=0x%h | MEM_ALU=0x%h | WB_Data=0x%h (rd=%0d, we=%b)",
                $time,
                uut.pc_out,
                uut.pc_out_id,
                uut.pc_out_ex,
                uut.alu_result_mem,
                uut.wb_data,
                uut.rd_wb,
                uut.reg_write_en_wb);
        end
    end

    // ==========================================
    // Trap 除錯監視器：trap_taken_ex 成立時，印出位址計算相關的中間值
    // 用來追查 mtval (misaligned 有效位址) 跟 spike 對不上時的根因
    // ==========================================
    always @(posedge clk) begin
        if (rst_n && uut.trap_taken_ex) begin
            $display("[TRAP] Time=%0d ns | PC=0x%h | cause=%0d | alu_result=0x%h | fwd_rs1_ex=0x%h | imm_ex=0x%h | funct3_ex=%b | rs1_ex=%0d | rdata1_ex=0x%h",
                $time,
                uut.pc_out_ex,
                uut.trap_cause_ex,
                uut.alu_result,
                uut.fwd_rs1_ex,
                uut.imm_ex,
                uut.funct3_ex,
                uut.rs1_ex,
                uut.rdata1_ex);
        end
    end

    // ==========================================
    // x11 (a1) 寫入追蹤：追查 misaligned load trap 後，destreg 殘留值跟 spike 對不上的問題
    // ==========================================
    always @(posedge clk) begin
        if (rst_n && uut.reg_write_en_wb && uut.rd_wb == 5'd11) begin
            $display("[X11-WRITE] Time=%0d ns | value=0x%h", $time, uut.wb_data);
        end
    end

    // ==========================================
    // CSR 讀寫追蹤：追查 ebreak.S trap handler 內部 CSR 操作序列跟 spike 對不上的問題
    // ==========================================
    always @(posedge clk) begin
        if (rst_n && (uut.is_csr_ex || uut.is_mret_ex_r)) begin
            $display("[CSR] Time=%0d ns | PC=0x%h | addr=0x%h | wdata=0x%h | rdata=0x%h | write_en=%b | is_mret=%b",
                $time,
                uut.pc_out_ex,
                uut.csr_addr_ex,
                uut.csr_wdata_ex,
                uut.csr_rdata_ex,
                uut.csr_write_en_ex,
                uut.is_mret_ex_r);
        end
    end

    // ==========================================
    // mtrap_sigptr 區域寫入追蹤 (0x80002078 ~ 0x80002084)
    // ==========================================
    always @(posedge clk) begin
        if (rst_n && uut.mem_write_en_mem &&
            uut.alu_result_mem >= 32'h80002078 && uut.alu_result_mem < 32'h80002088) begin
            $display("[SIGWRITE] Time=%0d ns | PC(mem stage不直接有,用alu_result推) addr=0x%h | wdata=0x%h",
                $time,
                uut.alu_result_mem,
                uut.rdata2_mem);
        end
    end

    // (向量單元逐元素除錯追蹤已於平行化重構後移除，任務已完成)


    // ==========================================
    // 向量指令觸發次數精確計數器 (排除人工判讀誤差)
    // ==========================================
    integer vec_start_count = 0;
    always @(posedge clk) begin
        if (rst_n && uut.vec_start) begin
            vec_start_count = vec_start_count + 1;
        end
    end

    // ---- 分支預測相關訊號追蹤 ----
    always @(posedge clk) begin
        if (rst_n) begin
            $display("[BP] Time=%0d ns | predict_taken_if=%b predict_target_if=0x%h | redirect_ex=%b branch_mispredict_ex=%b bp_update_en_ex=%b | branch_en_ex=%b predicted_taken_ex=%b | stall_all=%b vec_stall=%b hazard_stall=%b",
                $time,
                uut.predict_taken_if,
                uut.predict_target_if,
                uut.redirect_ex,
                uut.branch_mispredict_ex,
                uut.bp_update_en_ex,
                uut.branch_en_ex,
                uut.predicted_taken_ex,
                uut.stall_all,
                uut.vec_stall,
                uut.hazard_stall);
        end
    end

    final begin
        $display("[VEC_COUNT] 總共觸發 vec_start 次數 = %0d", vec_start_count);
    end

    // ---- Demo Full 追蹤：監控 led_out 變化，判斷各階段是否依序正確執行 ----
    reg [7:0] led_prev;
    initial led_prev = 8'hFF;
    always @(posedge clk) begin
        if (uut.led_out !== led_prev) begin
            $display("[LED] Time=%0d ns | led_out=0x%h", $time, uut.led_out);
            led_prev = uut.led_out;
        end
    end

    // ---- 測試專用：自動模擬S0按鍵，每隔一段時間注入一次乾淨脈衝，
    //      讓demo_interactive.S這種"按鍵才推進"的程式，能在無人操作的
    //      模擬環境裡自動跑完，驗證邏輯正確性(不是驗證真實防彈跳行為，
    //      那部分已經用tb_debounce.v獨立驗證過了) ----
    initial begin
        force uut.btn_s0_raw = 1'b0;
        force uut.switches_raw = 8'h00;
    end

    always @(posedge clk) begin
        if (rst_n && uut.btn_s0_pending) begin
            // 偵測到CPU還沒清除的按鍵事件時，不重複觸發，等CPU清除後再等一段時間觸發下一次
        end
    end

    // ---- 改成"感知LED階段"的智慧觸發，而不是盲目定時觸發 ----
    // 這樣才能在"輸入第一個數字"跟"輸入第二個數字"這兩個階段，
    // 各自設定成不同的開關數值，真正驗證鎖存邏輯有沒有正確分辨兩次輸入
    reg [15:0] auto_btn_counter;
    reg [1:0]  press_phase;   // 0=尚未動作 1=已設定開關 2=已觸發按鍵
    initial auto_btn_counter = 16'b0;
    initial press_phase = 2'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            auto_btn_counter <= 16'b0;
            press_phase <= 2'b0;
            force uut.switches_raw = 8'h00;
        end else begin
            auto_btn_counter <= auto_btn_counter + 1'b1;

            if (uut.led_out == 8'h71 && press_phase == 2'b0) begin
                // 第一個數字階段：設定開關=10，等待穩定後觸發按鍵
                release uut.switches_raw;
                force uut.switches_raw = 8'h0A;
                press_phase <= 2'b1;
                auto_btn_counter <= 16'b0;
            end
            else if (uut.led_out == 8'h72 && press_phase != 2'b10) begin
                // 第二個數字階段：設定開關=5，等待穩定後觸發按鍵
                release uut.switches_raw;
                force uut.switches_raw = 8'h05;
                press_phase <= 2'b10;
                auto_btn_counter <= 16'b0;
            end
            else if (auto_btn_counter == 16'd300) begin
                force uut.btn_s0_pending = 1'b1;
            end
            else if (auto_btn_counter == 16'd310) begin
                release uut.btn_s0_pending;
                auto_btn_counter <= 16'b0;
            end
        end
    end

    // ---- 追蹤result_out(7段顯示器來源)變化，驗證即時運算結果 ----
    reg [31:0] result_prev;
    initial result_prev = 32'hFFFFFFFF;
    always @(posedge clk) begin
        if (uut.result_out !== result_prev) begin
            $display("[RESULT] Time=%0d ns | result_out=0x%h (十進位=%0d)", $time, uut.result_out, uut.result_out);
            result_prev = uut.result_out;
        end
    end

    // ---- 追蹤UART TX：每次uut.uart_tx_start觸發，把送出的位元組印成可讀字元 ----
    // 因為testbench具現化的是cpu_top(不含uart_tx.v序列化那一層)，
    // 直接在uart_tx_start/uart_tx_data這兩個內部訊號攔截驗證，
    // 比真的解碼序列訊號更直接、更適合驗證"CPU到底想送出什麼內容"
    reg [7:0] uart_tx_buffer [0:2047];  // 加大到2048，原本256太小，這次demo需要430個位元組
    integer uart_tx_count = 0;
    always @(posedge clk) begin
        if (rst_n && uut.uart_tx_start) begin
            uart_tx_buffer[uart_tx_count] = uut.uart_tx_data;
            $display("[UART_TX] Time=%0t | 送出位元組=0x%h ('%c')", $time, uut.uart_tx_data, uut.uart_tx_data);
            uart_tx_count = uart_tx_count + 1;
        end
    end

    // 模擬結束時，把整個緩衝區轉成字串印出來，方便人眼閱讀
    final begin
        integer i;
        $write("[UART輸出內容] ");
        for (i = 0; i < uart_tx_count; i = i + 1) begin
            if (uart_tx_buffer[i] == 8'h0D)
                $write("\\r");
            else if (uart_tx_buffer[i] == 8'h0A)
                $write("\\n\n[UART輸出內容] ");
            else
                $write("%c", uart_tx_buffer[i]);
        end
        $write("\n");
    end

endmodule
