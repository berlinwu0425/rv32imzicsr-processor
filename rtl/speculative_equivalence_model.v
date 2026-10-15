`timescale 1ns / 1ps

// =========================================================================
// Contribution 3 (完整版)：架構等價性
// 加入 mispredicted 這個自由變數(SymbiYosys會窮舉true/false兩種情況)，
// 分別驗證：
//   Safety(對應wrong-path)：誤判時，結果絕對不能提交(不能"復活")
//   Liveness(對應correct-path)：沒誤判時，結果最終一定要提交，
//                                不能因為kill機制設計錯誤而平白誤殺
// 兩者合起來，就是"有推測+kill" 跟 "無推測參考版" 架構狀態等價的完整證明。
// =========================================================================
module speculative_equivalence_model #(
    parameter integer D     = 0,
    parameter integer F     = 0,
    parameter integer L_LAT = 0
)(
    input  wire clk,
    input  wire rst_n,
    input  wire mispredicted_raw,   // 原始自由輸入

    output wire committed_sticky,
    output wire safety_violation,
    output wire liveness_violation
);

    // 把mispredicted鎖定成第一拍就固定、之後不再改變的值，
    // 符合"一條指令是否在錯誤路徑上，從它進入管線那一刻就已經確定"的物理事實。
    // 沒有這個限制，SymbiYosys會構造出"同一條指令的誤判狀態中途改變"這種
    // 不合理、物理上不可能發生的反例。
    reg        mispredicted_latched;
    reg        mispredicted_locked;
    initial mispredicted_latched = 1'b0;
    initial mispredicted_locked  = 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mispredicted_latched <= 1'b0;
            mispredicted_locked  <= 1'b0;
        end else if (!mispredicted_locked) begin
            mispredicted_latched <= mispredicted_raw;
            mispredicted_locked  <= 1'b1;
        end
    end

    wire mispredicted = mispredicted_latched;

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

    // kill只在真的誤判時才會發出，且固定在age==F那一拍發出一次
    wire kill_pulse   = mispredicted && started && (age == F);
    wire commit_point = started && (age == D + 1 + L_LAT);

    reg killed_sticky_r;
    reg committed_sticky_r;
    initial killed_sticky_r    = 1'b0;
    initial committed_sticky_r = 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            killed_sticky_r    <= 1'b0;
            committed_sticky_r <= 1'b0;
        end else begin
            if (kill_pulse) begin
                killed_sticky_r <= 1'b1;
            end
            // kill優先權比commit高：同一拍撞在一起，保守起見算作被殺掉
            if (commit_point && !killed_sticky_r && !kill_pulse) begin
                committed_sticky_r <= 1'b1;
            end
        end
    end

    assign committed_sticky = committed_sticky_r;

    // Safety：誤判的instruction，任何時候都不能處於"已提交"狀態(不能復活)
    assign safety_violation = committed_sticky_r && mispredicted;

    // Liveness(bounded)：沒誤判的instruction，走到commit_point"下一拍"，必須已提交
    // (commit_point那一拍才剛觸發非同步賦值，committed_sticky_r要等下一拍才反映新值，
    //  這裡用跟Contribution 1相同手法：手動維護影子暫存器記錄"上一拍是否為commit_point")
    reg commit_point_prev;
    reg mispredicted_prev;
    initial commit_point_prev = 1'b0;
    initial mispredicted_prev = 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            commit_point_prev <= 1'b0;
            mispredicted_prev <= 1'b0;
        end else begin
            commit_point_prev <= commit_point;
            mispredicted_prev <= mispredicted;
        end
    end

    assign liveness_violation = commit_point_prev && !mispredicted_prev && !committed_sticky_r;

`ifdef FORMAL
    // ---- 用assume強制要求：驗證一開始必須先經過一次真正的reset ----
    // (解決 mode prove 的 basecase 允許暫存器帶著任意垃圾初始值開始的問題，
    //  這是SymbiYosys處理"未提供明確reset保證"時的標準做法)
    reg f_initial_state;
    initial f_initial_state = 1'b1;
    always @(posedge clk) f_initial_state <= 1'b0;

    always @(*) begin
        if (f_initial_state) begin
            assume (!rst_n);
        end
    end

    // ---- 輔助不變量：把狀態變數之間隱含的一致性關係明確告訴求解器 ----
    // 這些對真實電路而言"顯然為真"，但k-induction在探索"任意連續k拍"時，
    // 可能會構造出違反這些隱含關係、電路實際上永遠不會走到的"不可能狀態"，
    // 導致induction步驟產生假陰性。明確寫出來，縮小搜索範圍到真正可能發生的狀態。
    always @(*) begin
        // 還沒開始時，age必為0
        if (!started) begin
            assert (age == 8'b0);
        end
        // mispredicted被鎖定之前，mispredicted_latched必為初始值0
        if (!mispredicted_locked) begin
            assert (mispredicted_latched == 1'b0);
        end
        // 一旦started了，之後不會再變回0 (這是個單調的旗標)
    end

    always @(*) begin
        assert (!safety_violation);
        assert (!liveness_violation);
    end
`endif

endmodule
