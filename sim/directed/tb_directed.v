`timescale 1ns / 1ps
// 定向測試用 testbench：程式把結果碼寫到 0x03000004 (1 = PASS)，
// 這裡負責載入程式、偵測結果碼、計算UART送出次數
module tb_directed;
    reg clk = 0, rst_n = 0;
    always #5 clk = ~clk;

    wire uart_tx_start;
    cpu_top #(.IMEM_WORDS(4096), .DMEM_BYTES(16384)) uut (
        .clk(clk), .rst_n(rst_n),
        .led_out(), .result_out(), .pass_led(),
        .uart_rx_valid(1'b0), .uart_rx_data(8'b0),
        .uart_tx_start(uart_tx_start), .uart_tx_data(), .uart_tx_busy(1'b0),
        .btn_s0_raw(1'b0), .switches_raw(8'b0)
    );

    reg [8191:0] hex_file;
    integer cyc, max_cyc, uart_cnt, code, done_cyc, vec_cnt;

    always @(posedge clk) if (rst_n) begin
        if (uart_tx_start) uart_cnt = uart_cnt + 1;
        if (uut.vec_start) vec_cnt = vec_cnt + 1;
        if (uut.mem_write_en_mem && uut.alu_result_mem == 32'h03000004 && code == 0) begin
            code = uut.rdata2_mem; done_cyc = cyc;
        end
    end

    initial begin
        uart_cnt = 0; code = 0; done_cyc = 0; vec_cnt = 0;
        if (!$value$plusargs("hex=%s", hex_file)) hex_file = "program.hex";
        if (!$value$plusargs("max=%d", max_cyc)) max_cyc = 20000;
        $readmemh(hex_file, uut.u_imem.inst_mem);
        #15 rst_n = 1;
        for (cyc = 0; cyc < max_cyc && code == 0; cyc = cyc + 1) @(posedge clk);
        repeat (8) @(posedge clk);
        $display("RESULT code=%0d uart=%0d cycles=%0d vec_starts=%0d", code, uart_cnt, done_cyc, vec_cnt);
        $finish;
    end
endmodule
