`timescale 1ns / 1ps

module seven_seg_driver (
    input  wire        clk,
    input  wire         rst_n,
    input  wire [31:0] value,
    output reg  [7:0]  seg0,
    output reg  [7:0]  seg1,
    output reg  [7:0]  digit_sel
);

    reg [15:0] scan_div;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) scan_div <= 16'b0;
        else        scan_div <= scan_div + 1'b1;
    end
    wire [1:0] scan_phase = scan_div[15:14];

    function [7:0] hex_to_seg;
        input [3:0] nibble;
        begin
            case (nibble)
                4'h0: hex_to_seg = 8'b00111111;
                4'h1: hex_to_seg = 8'b00000110;
                4'h2: hex_to_seg = 8'b01011011;
                4'h3: hex_to_seg = 8'b01001111;
                4'h4: hex_to_seg = 8'b01100110;
                4'h5: hex_to_seg = 8'b01101101;
                4'h6: hex_to_seg = 8'b01111101;
                4'h7: hex_to_seg = 8'b00000111;
                4'h8: hex_to_seg = 8'b01111111;
                4'h9: hex_to_seg = 8'b01101111;
                4'ha: hex_to_seg = 8'b01110111;
                4'hb: hex_to_seg = 8'b01111100;
                4'hc: hex_to_seg = 8'b00111001;
                4'hd: hex_to_seg = 8'b01011110;
                4'he: hex_to_seg = 8'b01111001;
                4'hf: hex_to_seg = 8'b01110001;
                default: hex_to_seg = 8'b00000000;
            endcase
        end
    endfunction

    // 實測發現顯示順序整組左右鏡射，這裡把 nibble<->位置 的對應關係反過來修正
    always @(*) begin
        case (scan_phase)
            2'b00: begin
                digit_sel = 8'b00010001;
                seg0 = hex_to_seg(value[31:28]);
                seg1 = hex_to_seg(value[15:12]);
            end
            2'b01: begin
                digit_sel = 8'b00100010;
                seg0 = hex_to_seg(value[27:24]);
                seg1 = hex_to_seg(value[11:8]);
            end
            2'b10: begin
                digit_sel = 8'b01000100;
                seg0 = hex_to_seg(value[23:20]);
                seg1 = hex_to_seg(value[7:4]);
            end
            2'b11: begin
                digit_sel = 8'b10001000;
                seg0 = hex_to_seg(value[19:16]);
                seg1 = hex_to_seg(value[3:0]);
            end
        endcase
    end

endmodule
