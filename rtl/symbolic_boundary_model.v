`timescale 1ns / 1ps

// =========================================================================
// 邊界關係的符號化證明 (symbolic proof)
// 4.6~4.8 節的掃描是把 D、F、L_LAT、S 設成固定數字一組一組驗證；
// 這裡把它們改成 (* anyconst *)：求解器可以任選、但選定後不再改變的值，
// 一次證明就涵蓋 8-bit 範圍內的所有參數組合。
//
// A = D + 1 是「被取消的指令抵達啟動級」的拍數。
// 每個模型都證明兩個方向：
//   邊界內  ->  永遠不會發生違反
//   邊界外  ->  指令抵達的那一拍一定違反 (而且抵達一定會發生，不會被跳過)
// =========================================================================

// ---- 4.6 基準模型：Safe <=> F <= D + 1 ----
module sym_boundary (input wire clk, input wire rst_n);
    (* anyconst *) reg [7:0] A;     // D + 1
    (* anyconst *) reg [7:0] F;

    reg [9:0] age;
    reg       started, arrived;
    wire at_launch    = started && (age == A);
    wire flush_active = started && (age >= F);
    wire violation    = at_launch && !flush_active;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            age <= 10'd0; started <= 1'b0; arrived <= 1'b0;
        end else if (!started) begin
            started <= 1'b1;
        end else begin
            if (at_launch) arrived <= 1'b1;
            if (!arrived && !at_launch) age <= age + 10'd1;
        end
    end

`ifdef FORMAL
    reg f_init; initial f_init = 1'b1;
    always @(posedge clk) f_init <= 1'b0;
    always @(*) if (f_init) assume (!rst_n);

    always @(*) if (rst_n) begin
        assert (arrived || age <= A);              // 抵達不會被跳過
        if (!started) assert (age == 0 && !arrived);
        if (F <= A) assert (!violation);           // 邊界內：安全
        if (F >  A) assert (!at_launch || violation);   // 邊界外：抵達即違反
    end
`endif
endmodule

// ---- 4.7 kill/commit 模型：Safe <=> F <= D + 1 + L_LAT ----
module sym_kill (input wire clk, input wire rst_n);
    (* anyconst *) reg [7:0] A;     // D + 1
    (* anyconst *) reg [7:0] F;
    (* anyconst *) reg [7:0] L;     // L_LAT

    wire [9:0] commit_at = {2'b0, A} + {2'b0, L};
    reg [9:0] age;
    reg       started, arrived;
    wire at_commit    = started && (age == commit_at);
    wire kill_arrived = started && (age >= F);
    wire violation    = at_commit && !kill_arrived;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            age <= 10'd0; started <= 1'b0; arrived <= 1'b0;
        end else if (!started) begin
            started <= 1'b1;
        end else begin
            if (at_commit) arrived <= 1'b1;
            if (!arrived && !at_commit) age <= age + 10'd1;
        end
    end

`ifdef FORMAL
    reg f_init; initial f_init = 1'b1;
    always @(posedge clk) f_init <= 1'b0;
    always @(*) if (f_init) assume (!rst_n);

    always @(*) if (rst_n) begin
        assert (arrived || age <= commit_at);
        if (!started) assert (age == 0 && !arrived);
        if ({2'b0, F} <= commit_at) assert (!violation);
        if ({2'b0, F} >  commit_at) assert (!at_commit || violation);
    end
`endif
endmodule

// ---- 4.8 stall 模型 ----
//   A >= 1：Safe <=> F <= D + 1 + S
//   A == 0 (指令在偵測當拍已在啟動級)：Safe <=> F == 0，stall 無法再延後它
module sym_stall (input wire clk, input wire rst_n);
    (* anyconst *) reg [7:0] A;     // D + 1
    (* anyconst *) reg [7:0] F;
    (* anyconst *) reg [7:0] S;

    reg [9:0] instr_age, flush_age;   // 指令前進的拍數(會被stall凍結) / flush訊號的進度(不受stall影響)
    reg [8:0] stall_cnt;
    reg       started, arrived;
    wire at_launch    = started && !arrived && (instr_age == A);
    wire flush_active = started && (flush_age >= F);
    wire violation    = at_launch && !flush_active;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instr_age <= 10'd0; flush_age <= 10'd0; stall_cnt <= 9'd0;
            started <= 1'b0; arrived <= 1'b0;
        end else if (!started) begin
            started <= 1'b1;
        end else if (!arrived) begin
            flush_age <= flush_age + 10'd1;
            if (stall_cnt < {1'b0, S}) stall_cnt <= stall_cnt + 9'd1;   // 前S拍：指令被凍結
            else begin
                if (instr_age == A) arrived <= 1'b1;
                else instr_age <= instr_age + 10'd1;
            end
        end
    end

`ifdef FORMAL
    reg f_init; initial f_init = 1'b1;
    always @(posedge clk) f_init <= 1'b0;
    always @(*) if (f_init) assume (!rst_n);

    wire [9:0] bound = {2'b0, A} + {2'b0, S};

    always @(*) if (rst_n) begin
        // 輔助不變量
        assert (stall_cnt <= {1'b0, S});
        assert (instr_age <= A);
        assert (flush_age == instr_age + {1'b0, stall_cnt} + (arrived ? 10'd1 : 10'd0));
        if (stall_cnt < {1'b0, S}) assert (instr_age == 0);
        if (!started) assert (flush_age == 0 && !arrived);

        if (A != 0) begin
            if ({2'b0, F} <= bound) assert (!violation);
            if ({2'b0, F} >  bound) assert (!(at_launch && stall_cnt == {1'b0, S}) || violation);
        end else begin
            if (F == 0) assert (!violation);
            if (F != 0) assert (!(started && flush_age == 0) || violation);   // 事件當拍就違反，S幫不上忙
        end
    end
`endif
endmodule
