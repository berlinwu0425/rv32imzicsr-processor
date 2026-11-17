`timescale 1ns / 1ps

// =========================================================================
// 通用模擬 testbench (RISCOF 合規測試與一般程式模擬共用)
//
// 命令列參數：
//   +hex=<file>        指令記憶體內容 (預設 program.hex)
//   +data=<file>       資料記憶體初始內容 (可省略；hex 檔可用 @address 指定起始位址)
//   +sig=<file>        signature 輸出檔 (預設 mycpu.signature)
//   +sigstart=<n>      signature 起始位址 (相對 0x80000000 的 byte offset)
//   +sigend=<n>        signature 結束位址 (相對 0x80000000 的 byte offset)
//   +tohost=<n>        tohost 的絕對位址；程式寫入此位址代表執行結束
//   +timeout=<n>       最多執行的 cycle 數 (預設 600000)
//   +vcd               輸出波形 cpu_simulation.vcd
//   +trace             每個 cycle 印出各級的 PC 與寫回資料
// =========================================================================
module cpu_tb;

    reg clk;
    reg rst_n;

    reg [8191:0] hex_file;
    reg [8191:0] sig_file;
    reg [8191:0] data_file;
    integer sig_start, sig_end, tohost_addr, timeout;
    integer fd, i, cycles;
    reg     tohost_written;
    reg     trace_en;

    cpu_top uut (
        .clk           (clk),
        .rst_n         (rst_n),
        .uart_rx_valid (1'b0),
        .uart_rx_data  (8'b0),
        .uart_tx_busy  (1'b0),
        .btn_s0_raw    (1'b0),
        .switches_raw  (8'b0)
    );

    always #5 clk = ~clk;

    // riscv-arch-test 以寫入 tohost 表示程式執行結束
    always @(posedge clk) begin
        if (rst_n && uut.mem_write_en_mem && (uut.alu_result_mem == tohost_addr))
            tohost_written <= 1'b1;
    end

    initial begin
        clk = 1'b0;
        rst_n = 1'b0;
        tohost_written = 1'b0;

        if (!$value$plusargs("hex=%s", hex_file))         hex_file = "program.hex";
        if (!$value$plusargs("sig=%s", sig_file))         sig_file = "mycpu.signature";
        if (!$value$plusargs("sigstart=%d", sig_start))   sig_start = 0;
        if (!$value$plusargs("sigend=%d", sig_end))       sig_end = 256;
        if (!$value$plusargs("tohost=%d", tohost_addr))   tohost_addr = 32'h80038000;
        if (!$value$plusargs("timeout=%d", timeout))      timeout = 600000;
        trace_en = $test$plusargs("trace");

        $readmemh(hex_file, uut.u_imem.inst_mem);
        if ($value$plusargs("data=%s", data_file))
            $readmemh(data_file, uut.u_dmem.memory);

        if ($test$plusargs("vcd")) begin
            $dumpfile("cpu_simulation.vcd");
            $dumpvars(0, cpu_tb);
        end

        #15 rst_n = 1'b1;

        cycles = 0;
        while (!tohost_written && cycles < timeout) begin
            @(posedge clk);
            cycles = cycles + 1;
        end
        if (!tohost_written)
            $display("[WARNING] timeout after %0d cycles, tohost was not written", timeout);

        // 讓寫入 tohost 之後還在管線中的指令完成
        #50;

        // signature：資料記憶體以 32-bit word 為單位，逐 word 輸出
        fd = $fopen(sig_file, "w");
        for (i = sig_start; i < sig_end; i = i + 4)
            $fwrite(fd, "%08x\n", uut.u_dmem.memory[i >> 2]);
        $fclose(fd);

        $finish;
    end

    // +trace：逐 cycle 印出各級的 PC 與寫回資料
    always @(posedge clk) begin
        if (rst_n && trace_en)
            $display("[%0t] IF=%h ID=%h EX=%h MEM_ALU=%h WB=%h rd=%0d we=%b",
                     $time, uut.pc_out, uut.pc_out_id, uut.pc_out_ex,
                     uut.alu_result_mem, uut.wb_data, uut.rd_wb, uut.reg_write_en_wb);
    end

endmodule
