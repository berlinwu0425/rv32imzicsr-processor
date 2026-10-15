`timescale 1ns / 1ps

// =========================================================================
// Bounded-Stall Extension (修正版)：把"指令物理移動"跟"flush訊號生效進度"
// 拆成兩個獨立的計數器，不再共用同一個age，避免兩者被stall一起延遲、
// 彼此抵銷，製造出"stall沒有影響"的假象。
//
// instr_age：指令走到啟動點需要的步數，會被stall凍結(物理移動)
// flush_age：flush訊號本身生效的進度，不受stall影響(這是保護機制的
//            內部時序，跟"指令有沒有被stall卡住"是兩件獨立的事)
// =========================================================================
module bounded_stall_model #(
    parameter integer D = 0,
    parameter integer F = 0,
    parameter integer S = 0
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [7:0] stall_duration,
    output wire wrong_path_launch
);

    reg [7:0] instr_age;
    reg [7:0] flush_age;
    reg       has_flushed_once;
    reg [7:0] stall_counter;

    reg flush_event_r;
    wire flush_event = flush_event_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) flush_event_r <= 1'b0;
        else if (!has_flushed_once) flush_event_r <= 1'b1;
        else flush_event_r <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instr_age        <= 8'b0;
            flush_age        <= 8'b0;
            has_flushed_once <= 1'b0;
            stall_counter     <= 8'b0;
        end
        else if (flush_event) begin
            instr_age        <= 8'b0;
            flush_age        <= 8'b0;
            has_flushed_once <= 1'b1;
            stall_counter     <= 8'b0;
        end
        else if (has_flushed_once) begin
            // flush_age 不受stall影響，獨立、持續前進
            flush_age <= flush_age + 8'b1;

            // instr_age 會被stall凍結
            if (stall_counter < stall_duration) begin
                stall_counter <= stall_counter + 8'b1;
            end else begin
                instr_age <= instr_age + 8'b1;
            end
        end
    end

    wire abstract_flush_active    = has_flushed_once && (flush_age >= F);
    wire abstract_instr_at_launch = has_flushed_once && (instr_age == D + 1);

    assign wrong_path_launch = abstract_instr_at_launch && !abstract_flush_active;

`ifdef FORMAL
    reg f_initial_state;
    initial f_initial_state = 1'b1;
    always @(posedge clk) f_initial_state <= 1'b0;

    always @(*) begin
        if (f_initial_state) begin
            assume (!rst_n);
        end
        // 改成恰好S拍而不是最多S拍，因為最多S拍永遠包含stall_duration=0
        // 這個最壞情況，導致S再怎麼變化，邊界結構上都不可能改變
        assume (stall_duration == S);
    end

    always @(*) begin
        assert (!wrong_path_launch);
    end
`endif

endmodule
