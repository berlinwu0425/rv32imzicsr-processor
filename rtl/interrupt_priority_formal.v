`timescale 1ns / 1ps

// =========================================================================
// 中斷優先權邏輯 —— 形式驗證用的獨立模組
// 內容與 cpu_top.v 中的中斷判斷與 trap 原因選擇相同，單獨抽出來驗證，
// 不必把整個 cpu_top 交給形式化引擎。本模組不參與合成；
// 修改 cpu_top.v 的對應邏輯時，必須同步更新這裡。
// =========================================================================
module interrupt_priority_formal (
    input  wire valid_ex,
    input  wire vec_stall,        // 向量單元執行中
    input  wire vec_killable,     // 執行中的向量指令還可以被取消
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

    wire irq_allowed = valid_ex && (!vec_stall || vec_killable);
    wire msi_pending = irq_allowed && mstatus_mie && mie_msie && msip_reg;
    wire mti_pending = irq_allowed && mstatus_mie && mie_mtie && mtip_ext;
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
