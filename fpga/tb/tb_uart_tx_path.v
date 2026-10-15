`timescale 1ns/1ps
module tb_uart_tx_path;
    reg cpu_clk = 0;
    reg sysclk = 0;
    reg rst_n = 0;
    reg tx_start_cpu = 0;
    reg [7:0] tx_data = 8'h41; // 'A'

    always #5   sysclk  = ~sysclk;    // 10ns週期，模擬100MHz
    always #160 cpu_clk = ~cpu_clk;   // 320ns週期，模擬cpu_clk(sysclk除32)

    wire tx_start_synced;
    cdc_pulse_sync u_cdc (
        .src_clk(cpu_clk), .src_rst_n(rst_n), .src_pulse(tx_start_cpu),
        .dst_clk(sysclk), .dst_rst_n(rst_n), .dst_pulse(tx_start_synced)
    );

    wire tx_busy, tx_pin;
    uart_tx #(.CLK_FREQ(100_000_000), .BAUD_RATE(115200)) u_tx (
        .clk(sysclk), .rst_n(rst_n),
        .tx_data(tx_data), .tx_start(tx_start_synced),
        .tx_busy(tx_busy), .tx_pin(tx_pin)
    );

    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
        #1000;

        @(posedge cpu_clk);
        tx_start_cpu = 1;
        @(posedge cpu_clk);
        tx_start_cpu = 0;

        #200000;
        $display("Final tx_busy=%b tx_pin=%b", tx_busy, tx_pin);
        $finish;
    end

    always @(tx_pin) begin
        $display("[TXPIN] Time=%0t tx_pin=%b tx_busy=%b", $time, tx_pin, tx_busy);
    end

    always @(tx_start_synced) begin
        if (tx_start_synced)
            $display("[TX_START_SYNCED] Time=%0t 觸發!", $time);
    end

endmodule
