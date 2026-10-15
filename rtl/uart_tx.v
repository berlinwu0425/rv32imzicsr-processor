`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input  wire       clk,
    input  wire        rst_n,

    input  wire [7:0]  tx_data,
    input  wire         tx_start,
    output reg          tx_busy,

    output reg          tx_pin
);

    localparam integer BAUD_DIV = CLK_FREQ / BAUD_RATE;

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
            tx_busy      <= 1'b0;
            tx_pin       <= 1'b1;
        end else begin
            case (state)
                S_IDLE: begin
                    tx_pin <= 1'b1;
                    if (tx_start) begin
                        shift_reg    <= tx_data;
                        baud_counter <= 16'b0;
                        tx_busy      <= 1'b1;
                        state        <= S_START;
                    end else begin
                        tx_busy <= 1'b0;
                    end
                end
                S_START: begin
                    tx_pin <= 1'b0;
                    if (baud_counter == BAUD_DIV - 1) begin
                        baud_counter <= 16'b0;
                        bit_idx      <= 3'b0;
                        state        <= S_DATA;
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end
                S_DATA: begin
                    tx_pin <= shift_reg[bit_idx];
                    if (baud_counter == BAUD_DIV - 1) begin
                        baud_counter <= 16'b0;
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
                    tx_pin <= 1'b1;
                    if (baud_counter == BAUD_DIV - 1) begin
                        tx_busy <= 1'b0;
                        state   <= S_IDLE;
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
