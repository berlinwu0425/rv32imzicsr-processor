`timescale 1ns / 1ps

// =========================================================================
// Contribution 3：kill/commit 協定的安全邊界，含協處理器自身執行延遲(L_LAT)
// D = 推測距離 (同Contribution 2)
// F = flush/kill訊號生效延遲 (同Contribution 2)
// L_LAT = 協處理器自身執行延遲(從啟動到"自然提交時刻"要等幾拍，
//         這正好對應循序版向量單元17拍 vs 平行版1拍的真實差異)
//
// 核心保護機制：協處理器在"自然提交時刻"那一拍，會檢查kill有沒有已經到達，
// 有的話就丟棄結果(不提交)，沒有才真的提交——這正是CV-X-IF commit_kill的邏輯。
// =========================================================================
module speculative_kill_model #(
    parameter integer D     = 0,
    parameter integer F     = 0,
    parameter integer L_LAT = 0
)(
    input  wire clk,
    input  wire rst_n,
    output wire ghost_commit   // 危險事件：kill還沒到，指令卻已經提交了
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

    wire kill_arrived      = started && (age >= F);
    wire commit_point_reached = started && (age == D + 1 + L_LAT);

    // 幽靈提交：走到自然提交時刻，但kill訊號竟然還沒到
    assign ghost_commit = commit_point_reached && !kill_arrived;

`ifdef FORMAL
    always @(*) begin
        assert (!ghost_commit);
    end
`endif

endmodule
