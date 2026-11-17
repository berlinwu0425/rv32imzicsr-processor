`timescale 1ns / 1ps

// =========================================================================
// 互動式展示程式 (demo_interactive.S) 的模擬 testbench
//
// 在沒有實體按鍵與開關的模擬環境中，自動扮演操作者：
//   - LED 顯示 0x06 (等待第一個數值) 時，把開關設為 10
//   - LED 顯示 0x07 (等待第二個數值) 時，把開關設為 5
//   - 每隔一段時間送出一次 S0 按鍵事件，讓程式往下一個階段前進
// 按鍵事件直接寫入 CPU 端的按鍵旗標，略過防彈跳電路
// (防彈跳本身由 tb_debounce.v 另外驗證)。
//
// 模擬過程中印出 LED、7 段顯示器數值的變化，結束時印出 UART 送出的全部文字。
//
// 命令列參數：
//   +hex=<file>     程式 (預設 program.hex)
//   +cycles=<n>     模擬的 cycle 數 (預設 140000000，約可跑完全部 12 個階段)
// =========================================================================
module tb_demo;

    reg        clk;
    reg        rst_n;
    reg  [7:0] switches;
    reg [8191:0] hex_file;
    integer    max_cycles, i;
    integer    cycles = 0;

    cpu_top uut (
        .clk           (clk),
        .rst_n         (rst_n),
        .uart_rx_valid (1'b0),
        .uart_rx_data  (8'b0),
        .uart_tx_busy  (1'b0),
        .btn_s0_raw    (1'b0),
        .switches_raw  (switches)
    );

    always #5 clk = ~clk;

    // ---- 自動操作：依 LED 階段設定開關，並定期送出按鍵事件 ----
    reg [15:0] btn_counter;
    reg [1:0]  phase;   // 0 = 尚未設定, 1 = 已設定第一個數值, 2 = 已設定第二個數值

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_counter <= 16'b0;
            phase       <= 2'd0;
            switches    <= 8'h00;
        end else begin
            btn_counter <= btn_counter + 1'b1;
            if (uut.led_out == 8'h06 && phase == 2'd0) begin
                switches    <= 8'h0A;
                phase       <= 2'd1;
                btn_counter <= 16'b0;
            end else if (uut.led_out == 8'h07 && phase != 2'd2) begin
                switches    <= 8'h05;
                phase       <= 2'd2;
                btn_counter <= 16'b0;
            end else if (btn_counter == 16'd300) begin
                force uut.btn_s0_pending = 1'b1;
            end else if (btn_counter == 16'd310) begin
                release uut.btn_s0_pending;
                btn_counter <= 16'b0;
            end
        end
    end

    // ---- 觀察輸出 ----
    reg [7:0]  led_prev;
    reg [31:0] result_prev;
    initial begin
        led_prev    = 8'hFF;
        result_prev = 32'hFFFFFFFF;
    end

    always @(posedge clk) begin
        if (uut.led_out !== led_prev) begin
            $display("[LED]    cycle=%0d  led=0x%h", cycles, uut.led_out);
            led_prev = uut.led_out;
        end
        if (uut.result_out !== result_prev) begin
            $display("[RESULT] cycle=%0d  value=0x%h (%0d)", cycles, uut.result_out, uut.result_out);
            result_prev = uut.result_out;
        end
    end

    reg [7:0] uart_buf [0:4095];
    integer   uart_count = 0;
    always @(posedge clk) begin
        if (rst_n && uut.uart_tx_start && uart_count < 4096) begin
            uart_buf[uart_count] = uut.uart_tx_data;
            uart_count = uart_count + 1;
        end
    end

    initial begin
        clk   = 1'b0;
        rst_n = 1'b0;
        if (!$value$plusargs("hex=%s", hex_file))     hex_file = "program.hex";
        if (!$value$plusargs("cycles=%d", max_cycles)) max_cycles = 140000000;
        $readmemh(hex_file, uut.u_imem.inst_mem);

        #15 rst_n = 1'b1;
        for (cycles = 0; cycles < max_cycles; cycles = cycles + 1)
            @(posedge clk);

        $display("[UART] %0d bytes:", uart_count);
        for (i = 0; i < uart_count; i = i + 1)
            if (uart_buf[i] != 8'h0D) $write("%c", uart_buf[i]);
        $write("\n");
        $finish;
    end

endmodule
