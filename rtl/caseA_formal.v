`timescale 1ns / 1ps

// =========================================================================
// Case A / Theorem A1 + A2 —— 形式驗證專用抽出模組
// 抽出自 id_ex_register.v (pc_out_o/is_vec_op_o/funct3_o/funct7_o 的處理)
// 以及 cpu_top.v (vec_start/valid_ex 的判斷邏輯)。
// 關鍵發現：非同步reset條件不能跟同步訊號(flush)用||混寫在同一個if裡，
// 這裡刻意拆成兩個獨立的if分支繞開這個工具相容性限制。
// =========================================================================
module caseA_formal (
    input  wire        clk,
    input  wire         rst_n,
    input  wire        flush,
    input  wire        stall,

    input  wire [31:0] pc_out_in,
    input  wire        is_vec_op_in,
    input  wire [2:0]  funct3_in,
    input  wire [6:0]  funct7_in,

    output reg  [31:0] pc_out_o,
    output reg          is_vec_op_o,
    output reg  [2:0]  funct3_o,
    output reg  [6:0]  funct7_o
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out_o    <= 32'b0;
            is_vec_op_o <= 1'b0;
            funct3_o    <= 3'b0;
            funct7_o    <= 7'b0;
        end
        else if (flush) begin
            pc_out_o    <= 32'b0;
            is_vec_op_o <= 1'b0;
            funct3_o    <= 3'b0;
            funct7_o    <= 7'b0;
        end
        else if (stall) begin
            pc_out_o    <= pc_out_o;
            is_vec_op_o <= is_vec_op_o;
            funct3_o    <= funct3_o;
            funct7_o    <= funct7_o;
        end
        else begin
            pc_out_o    <= pc_out_in;
            is_vec_op_o <= is_vec_op_in;
            funct3_o    <= funct3_in;
            funct7_o    <= funct7_in;
        end
    end

    // ---- 逐字複製自 cpu_top.v 的 vec_start 完整判斷邏輯 ----
    wire is_vld_ex   = is_vec_op_o && (funct3_o == 3'b001);
    wire is_vst_ex   = is_vec_op_o && (funct3_o == 3'b010);
    wire is_vadd_ex  = is_vec_op_o && (funct3_o == 3'b011);
    wire is_vmul_ex  = is_vec_op_o && (funct3_o == 3'b100);
    wire is_vsub_ex  = is_vec_op_o && (funct3_o == 3'b101) && (funct7_o == 7'b0000000);
    wire is_vand_ex  = is_vec_op_o && (funct3_o == 3'b101) && (funct7_o == 7'b0000001);
    wire is_vor_ex   = is_vec_op_o && (funct3_o == 3'b101) && (funct7_o == 7'b0000010);
    wire is_vxor_ex  = is_vec_op_o && (funct3_o == 3'b101) && (funct7_o == 7'b0000011);
    wire is_vaddx_ex = is_vec_op_o && (funct3_o == 3'b110);

    wire valid_ex = (pc_out_o != 32'b0);

    // vec_stall 在這個抽出模組裡沒有真正的向量單元可以產生它，
    // 保守起見假設它恆為0(最寬鬆的情境，最有可能讓vec_start成立，
    // 這樣證明出來的結果對真實系統而言只會更強、不會更弱)
    wire vec_stall_dummy = 1'b0;

    wire vec_start = (is_vld_ex || is_vst_ex || is_vadd_ex || is_vmul_ex ||
                       is_vsub_ex || is_vand_ex || is_vor_ex || is_vxor_ex || is_vaddx_ex)
                      && valid_ex && !vec_stall_dummy;

`ifdef FORMAL
    reg f_flush_prev;
    initial f_flush_prev = 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            f_flush_prev <= 1'b0;
        end else begin
            f_flush_prev <= flush;
        end
    end

    always @(*) begin
        // Theorem A1
        if (!rst_n) begin
            assert (pc_out_o == 32'b0);
            assert (is_vec_op_o == 1'b0);
        end
        if (f_flush_prev) begin
            assert (pc_out_o == 32'b0);
            assert (is_vec_op_o == 1'b0);
        end

        // Theorem A2：flush觸發的下一拍，vec_start恆為0
        if (f_flush_prev) begin
            assert (vec_start == 1'b0);
        end
    end
`endif

endmodule
