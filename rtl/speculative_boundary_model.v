`timescale 1ns / 1ps

// =========================================================================
// Contribution 2：推測性協處理器安全邊界的參數化抽象模型
// D = L - R (協處理器啟動級 減去 分支解決級，"推測距離")
// F = flush 生效延遲(分支解決後，要再等幾拍flush才真正清空管線)
//
// 這是一個真正會動態計數、逐拍判斷的模型，不是把推導出的公式原封不動
// 寫成assert(那樣毫無驗證意義，等於自己證明自己)。用age計數器模擬時間流逝，
// 分別獨立判斷"flush是否已生效"跟"年輕指令是否已走到協處理器啟動級"，
// 讓SymbiYosys真正動態檢驗這兩個獨立計算出來的條件會不會撞在一起。
// =========================================================================
module speculative_boundary_model #(
    parameter integer D = 0,   // 推測距離 = L - R
    parameter integer F = 0    // flush生效延遲
)(
    input  wire clk,
    input  wire rst_n,
    output wire wrong_path_launch
);

    reg [7:0] age;
    reg       started;
    initial started = 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            age     <= 8'b0;
            started <= 1'b0;
        end
        else if (!started) begin
            started <= 1'b1;
            age     <= 8'b0;
        end
        else begin
            age <= age + 8'b1;
        end
    end

    // flush生效條件：age(從分支解決那拍算起)必須 >= F
    wire flush_active = started && (age >= F);

    // 年輕指令走到協處理器啟動級的條件：age == D+1
    // (推導：年輕指令在分支解決當下落後R-1級，走到L級要花 L-(R-1)=D+1 拍)
    wire instr_at_launch = started && (age == D + 1);

    // 危險情境：指令走到啟動級的那一拍，flush竟然還沒生效
    assign wrong_path_launch = instr_at_launch && !flush_active;

`ifdef FORMAL
    always @(*) begin
        assert (!wrong_path_launch);
    end
`endif

endmodule
