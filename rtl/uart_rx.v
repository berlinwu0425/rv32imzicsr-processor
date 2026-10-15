`timescale 1ns / 1ps

module uart_rx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire        rst_n,
    input  wire        rx_pin,

    output reg  [7:0]  rx_data,
    output reg          rx_valid
);

    localparam integer BAUD_DIV = CLK_FREQ / BAUD_RATE;
    localparam integer HALF_BAUD_DIV = BAUD_DIV / 2;

    reg rx_sync0, rx_sync1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync0 <= 1'b1;
            rx_sync1 <= 1'b1;
        end else begin
            rx_sync0 <= rx_pin;
            rx_sync1 <= rx_sync0;
        end
    end

    localparam S_IDLE  = 2'd0;
    localparam S_START = 2'd1;
    localparam S_DATA  = 2'd2;
    localparam S_STOP  = 2'd3;

    reg [1:0]  state;
    reg [15:0] baud_counter;
    reg [2:0]  bit_idx;
    reg [7:0]  shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            baud_counter <= 16'b0;
            bit_idx      <= 3'b0;
            shift_reg    <= 8'b0;
            rx_data      <= 8'b0;
            rx_valid     <= 1'b0;
        end else begin
            rx_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (rx_sync1 == 1'b0) begin
                        baud_counter <= 16'b0;
                        state        <= S_START;
                    end
                end
                S_START: begin
                    if (baud_counter == HALF_BAUD_DIV - 1) begin
                        if (rx_sync1 == 1'b0) begin
                            baud_counter <= 16'b0;
                            bit_idx      <= 3'b0;
                            state        <= S_DATA;
                        end else begin
                            state <= S_IDLE;
                        end
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end
                S_DATA: begin
                    if (baud_counter == BAUD_DIV - 1) begin
                        baud_counter        <= 16'b0;
                        shift_reg[bit_idx]   <= rx_sync1;
                        if (bit_idx == 3'd7) begin
                            state <= S_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end
                S_STOP: begin
                    if (baud_counter == BAUD_DIV - 1) begin
                        rx_data  <= shift_reg;
                        rx_valid <= 1'b1;
                        state    <= S_IDLE;
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
