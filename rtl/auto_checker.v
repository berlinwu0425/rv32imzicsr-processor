`timescale 1ns / 1ps

// =========================================================================
// 獨立硬體自動驗證檢查器 (不經過CPU指令，純RTL FSM)
// 涵蓋16種指令類型：ADD/SUB/AND/OR/XOR/SLL/SRL/SRA/SLT/SLTU/MUL/MULH/DIV/REM/SLLI/分支迴圈
// 用pattern索引計數器取代手寫大量狀態，方便之後繼續擴充測試數量
// =========================================================================
module auto_checker (
    input  wire        clk,
    input  wire         rst_n,
    input  wire         done,          // CPU完成訊號(來自0x07000000)
    output reg  [31:0] chk_addr,       // 要讀取的BRAM位址(接到dmem第二埠)
    input  wire [31:0] chk_rdata,      // 從dmem讀回的資料
    output reg  [7:0]  pass_led        // bit7=全部通過總燈號, bit[4:0]=通過項目數量(0~16)
);

    localparam [4:0] NUM_PATTERNS = 5'd16;
    localparam RESULT_BASE  = 32'h00000200;   // 結果存放起始位址，每組間隔4 bytes

    // 依 pattern 索引取得對應的正確答案 (golden，因為DUT已跟spike逐位元驗證過)
    function [31:0] golden_value;
        input [3:0] idx;
        begin
            case (idx)
                4'd0:  golden_value = 32'h12345679; // ADD
                4'd1:  golden_value = 32'h00000FFF; // SUB
                4'd2:  golden_value = 32'h0F000F00; // AND
                4'd3:  golden_value = 32'h12345678; // OR
                4'd4:  golden_value = 32'hFFFF0000; // XOR
                4'd5:  golden_value = 32'h00000100; // SLL
                4'd6:  golden_value = 32'h08000000; // SRL
                4'd7:  golden_value = 32'hF8000000; // SRA
                4'd8:  golden_value = 32'h00000001; // SLT
                4'd9:  golden_value = 32'h00000000; // SLTU
                4'd10: golden_value = 32'h006AE9BC; // MUL
                4'd11: golden_value = 32'h00000000; // MULH
                4'd12: golden_value = 32'h000037CD; // DIV
                4'd13: golden_value = 32'h00000005; // REM
                4'd14: golden_value = 32'h00010000; // SLLI (立即值移位)
                4'd15: golden_value = 32'h00000064; // 分支/迴圈計數(100)
                default: golden_value = 32'h00000000;
            endcase
        end
    endfunction

    localparam S_IDLE    = 2'd0;
    localparam S_ADDR    = 2'd1;
    localparam S_CHECK   = 2'd2;
    localparam S_SUMMARY = 2'd3;

    reg [1:0]  state;
    reg [3:0]  pattern_idx;
    reg        done_prev;
    reg [15:0] pass_bits;

    // 統計 pass_bits 裡有幾個1 (popcount)，for迴圈在合成時會展開成加法樹
    integer i;
    reg [4:0] pass_count;
    always @(*) begin
        pass_count = 5'd0;
        for (i = 0; i < NUM_PATTERNS; i = i + 1) begin
            pass_count = pass_count + {4'b0, pass_bits[i]};
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            chk_addr    <= 32'b0;
            pass_led    <= 8'b0;
            done_prev   <= 1'b0;
            pattern_idx <= 4'b0;
            pass_bits   <= 16'b0;
        end else begin
            done_prev <= done;

            case (state)
                S_IDLE: begin
                    // 偵測 done 訊號的上升緣，啟動一輪檢查
                    if (done && !done_prev) begin
                        pattern_idx <= 4'd0;
                        chk_addr    <= RESULT_BASE;
                        state       <= S_ADDR;
                    end
                end
                S_ADDR: begin
                    state <= S_CHECK;  // 等一拍讓chk_rdata穩定(組合邏輯讀取)
                end
                S_CHECK: begin
                    pass_bits[pattern_idx] <= (chk_rdata == golden_value(pattern_idx));
                    if ({1'b0, pattern_idx} == NUM_PATTERNS - 5'd1) begin
                        state <= S_SUMMARY;
                    end else begin
                        pattern_idx <= pattern_idx + 1'b1;
                        chk_addr    <= RESULT_BASE + (({28'b0, pattern_idx} + 32'd1) * 32'd4);
                        state       <= S_ADDR;
                    end
                end
                S_SUMMARY: begin
                    pass_led <= {(pass_count == NUM_PATTERNS), 2'b00, pass_count};
                    state    <= S_IDLE;
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
