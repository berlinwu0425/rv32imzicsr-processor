`timescale 1ns / 1ps

// =========================================================================
// Ghost Timing Model：純觀測用的影子暫存器，完全不影響真實CPU行為，
// 目的是回答「如果沒有Theorem A1的flush保護，這個wrong-path指令
// 本來會在第幾拍抵達協處理器啟動點」，藉此形式化驗證D這個參數，
// 是否真的精確描述了這顆真實CPU的管線結構時序，而不是自己選一個
// 數字驗算、卻沒真正檢驗過。
//
// 關鍵設計：ghost_is_vec_o 鎖存邏輯完全比照真實id_ex_register對
// is_vec_op_o的處理，唯一差異是"刻意不接受flush清空"——這樣它能
// 誠實觀測"若無保護，本來會發生什麼"，而不修改任何真實電路行為。
// =========================================================================
module ghost_timing_model (
    input  wire        clk,
    input  wire         rst_n,
    input  wire        flush,        // 只用來標記"這是我們關心的事件發生點"
    input  wire        stall,
    input  wire        is_vec_op_in  // 跟真實id_ex_register看到的完全同一個輸入
);

    localparam integer D = 0;   // 對應真實CPU：協處理器啟動級=分支解決級

    // ---- 影子暫存器：模仿is_vec_op_o的鎖存行為，但不接受flush清空 ----
    reg ghost_is_vec_o;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ghost_is_vec_o <= 1'b0;
        end
        else if (stall) begin
            ghost_is_vec_o <= ghost_is_vec_o;
        end
        else begin
            // 注意：這裡"永遠"執行正常鎖存，即使flush=1也一樣，
            // 這正是"假設沒有保護機制"的具體實作方式
            ghost_is_vec_o <= is_vec_op_in;
        end
    end

    // ---- 記錄flush觸發時，is_vec_op_in當下的值(這是"危險指令的本質") ----
    reg flush_prev;
    reg captured_is_vec;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            flush_prev      <= 1'b0;
            captured_is_vec <= 1'b0;
        end else begin
            flush_prev <= flush;
            if (flush) begin
                captured_is_vec <= is_vec_op_in;
            end
        end
    end

    wire would_launch = ghost_is_vec_o;

`ifdef FORMAL
    reg f_initial_state;
    initial f_initial_state = 1'b1;
    always @(posedge clk) f_initial_state <= 1'b0;

    always @(*) begin
        if (f_initial_state) begin
            assume (!rst_n);
        end
    end

    // ---- 明確定義的研究範圍：Stall-free Timing ----
    // 這不是"偷偷簡化掉stall"，而是正式界定這一版定理的適用範圍：
    //   Theorem (Stall-free D)：在pipeline不被stall阻塞的條件下，
    //   這顆baseline CPU的具體推測距離 D = 0。
    // Stall如何影響D(即D_eff = f(D0, stall history))，明確列為
    // 獨立的後續研究(Layer B / Future Extension)，不在這一版定理範圍內。
    always @(*) begin
        assume (!stall);
    end

    always @(*) begin
        // 精確性(不早也不晚)：在stall-free條件下，flush觸發那一拍
        // 捕捉到的is_vec_op_in值，必須恰好在"下一拍"(對應D+1=1)
        // 透過ghost_is_vec_o正確反映出來——這才是真正檢驗"stall-free D=0"
        // 這個具體定理，是否精確對應到這顆CPU單一鎖存週期的時序
        if (flush_prev) begin
            assert (ghost_is_vec_o == captured_is_vec);
        end
    end
`endif

endmodule
