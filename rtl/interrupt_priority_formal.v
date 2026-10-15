`timescale 1ns / 1ps

// =========================================================================
// 中斷優先權邏輯 —— 形式驗證專用抽出模組
// 這裡的邏輯逐字複製自 cpu_top.v 裡真正的實作(第524~540行附近)，
// 目的是把「中斷優先權判斷」這一小段組合邏輯獨立出來，單獨驗證，
// 不需要把整個cpu_top.v(含管線/向量單元/分支預測器等大量無關邏輯)
// 一起餵給形式驗證引擎。這個模組本身不會被實際合成/使用，純粹是
// 驗證用的鏡像，維護時務必跟cpu_top.v裡的真正實作保持同步。
// =========================================================================
module interrupt_priority_formal (
    input  wire valid_ex,
    input  wire mstatus_mie,      // mstatus_out[3]
    input  wire mie_msie,         // mie_out[3]
    input  wire mie_mtie,         // mie_out[7]
    input  wire msip_reg,
    input  wire mtip_ext,
    input  wire is_ecall_ex_r,
    input  wire is_ebreak_ex_r,
    input  wire instr_misalign_ex,
    input  wire load_misalign_ex,
    input  wire store_misalign_ex,

    output wire        trap_taken_ex,
    output reg  [31:0] trap_cause_ex
);

    wire msi_pending = valid_ex && mstatus_mie && mie_msie && msip_reg;
    wire mti_pending = valid_ex && mstatus_mie && mie_mtie && mtip_ext;
    wire interrupt_pending = msi_pending || mti_pending;

    assign trap_taken_ex = interrupt_pending || is_ecall_ex_r || is_ebreak_ex_r || instr_misalign_ex || load_misalign_ex || store_misalign_ex;

    always @(*) begin
        if (msi_pending)            trap_cause_ex = {1'b1, 31'd3};
        else if (mti_pending)       trap_cause_ex = {1'b1, 31'd7};
        else if (instr_misalign_ex) trap_cause_ex = 32'd0;
        else if (is_ecall_ex_r)     trap_cause_ex = 32'd11;
        else if (is_ebreak_ex_r)    trap_cause_ex = 32'd3;
        else if (load_misalign_ex)  trap_cause_ex = 32'd4;
        else if (store_misalign_ex) trap_cause_ex = 32'd6;
        else                        trap_cause_ex = 32'd0;
    end

`ifdef FORMAL
    // ---- 核心性質：軟體中斷跟計時器中斷同時pending時，必須反映軟體中斷優先 ----
    always @(*) begin
        if (msi_pending && mti_pending) begin
            assert (trap_cause_ex == {1'b1, 31'd3});
        end
    end

    // ---- 額外性質：只要有任何一種中斷pending，trap_taken_ex一定要成立 ----
    always @(*) begin
        if (msi_pending || mti_pending) begin
            assert (trap_taken_ex == 1'b1);
        end
    end
`endif

endmodule
