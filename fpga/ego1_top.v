`timescale 1ns / 1ps

module ego1_top (
    input  wire        sysclk,
    input  wire         btn_reset,
    output wire [7:0]  led,
    output wire [7:0]  pass_led,
    output wire [7:0]  seg0,
    output wire [7:0]  seg1,
    output wire [7:0]  digit_sel,

    input  wire        uart_rx_pin,
    output wire         uart_tx_pin,

    // ---- 新增：S0按鍵、SW0~SW7開關 ----
    input  wire        btn_s0,
    input  wire [7:0]  switches
);

    wire rst_n = btn_reset;

    reg [3:0] clk_div_counter;
    reg       cpu_clk;
    always @(posedge sysclk or negedge rst_n) begin
        if (!rst_n) begin
            clk_div_counter <= 4'b0;
            cpu_clk <= 1'b0;
        end else begin
            clk_div_counter <= clk_div_counter + 1'b1;
            if (clk_div_counter == 4'b0)
                cpu_clk <= ~cpu_clk;
        end
    end

    wire [31:0] result_value;

    wire        uart_rx_valid_raw;
    wire [7:0]  uart_rx_data;
    wire        uart_tx_start_raw;
    wire [7:0]  uart_tx_data;
    wire        uart_tx_busy;

    uart_rx #(.CLK_FREQ(100_000_000), .BAUD_RATE(115200)) u_uart_rx (
        .clk(sysclk), .rst_n(rst_n), .rx_pin(uart_rx_pin),
        .rx_data(uart_rx_data), .rx_valid(uart_rx_valid_raw)
    );

    wire uart_rx_valid_synced;
    cdc_pulse_sync u_uart_rx_cdc (
        .src_clk(sysclk), .src_rst_n(rst_n), .src_pulse(uart_rx_valid_raw),
        .dst_clk(cpu_clk), .dst_rst_n(rst_n), .dst_pulse(uart_rx_valid_synced)
    );

    wire uart_tx_start_synced;
    cdc_pulse_sync u_uart_tx_cdc (
        .src_clk(cpu_clk), .src_rst_n(rst_n), .src_pulse(uart_tx_start_raw),
        .dst_clk(sysclk), .dst_rst_n(rst_n), .dst_pulse(uart_tx_start_synced)
    );

    uart_tx #(.CLK_FREQ(100_000_000), .BAUD_RATE(115200)) u_uart_tx (
        .clk(sysclk), .rst_n(rst_n), .tx_data(uart_tx_data),
        .tx_start(uart_tx_start_synced), .tx_busy(uart_tx_busy), .tx_pin(uart_tx_pin)
    );

    cpu_top #(
        .IMEM_WORDS     (4096),
        .DMEM_BYTES     (16384),
        .IMEM_INIT_FILE ("led_test.hex")
    ) uut (
        .clk            (cpu_clk),
        .rst_n          (rst_n),
        .led_out        (led),
        .result_out     (result_value),
        .pass_led       (pass_led),
        .uart_rx_valid  (uart_rx_valid_synced),
        .uart_rx_data   (uart_rx_data),
        .uart_tx_start  (uart_tx_start_raw),
        .uart_tx_data   (uart_tx_data),
        .uart_tx_busy   (uart_tx_busy),
        // 新增：按鍵/開關直接接進去，防彈跳邏輯在cpu_top.v內部處理，
        // 不需要額外的CDC同步器(button_debounce模組內部已經有兩級同步器)
        .btn_s0_raw     (btn_s0),
        .switches_raw   (switches)
    );

    seven_seg_driver u_seven_seg (
        .clk        (sysclk),
        .rst_n      (rst_n),
        .value      (result_value),
        .seg0       (seg0),
        .seg1       (seg1),
        .digit_sel  (digit_sel)
    );

endmodule
