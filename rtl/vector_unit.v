`timescale 1ns / 1ps

// =========================================================================
// 自訂輕量向量處理單元 (custom-0 opcode, 0001011) —— 平行版本
// 8個向量暫存器(v0~v7)，每個裝8個32-bit元素。
//
// 這次的關鍵架構決定：ALU類運算(vadd.vv/vmul.vv/vsub.vv/vand.vv/vor.vv/
// vxor.vv/vadd.vx)全部改成「單一cycle平行處理」，用generate迴圈展開成8組
// 獨立的硬體(8個加法器/8個乘法器等)，一拍算完全部8個元素、一次寫回。
//
// vld/vst 刻意維持循序多週期：因為它們要跟dmem溝通，真實的Block RAM硬體
// 最多只有2個存取埠，要做到「8個元素同一拍全部讀寫完成」需要一塊全新的
// 256-bit寬專用記憶體，已經超出「平行化運算單元」這個比較研究的範圍，
// 也剛好demonstrate了真實向量處理器常見的「運算寬、記憶體頻寬窄」取捨。
// =========================================================================
module vector_unit (
    input  wire        clk,
    input  wire         rst_n,

    input  wire        start,
    input  wire        is_vld,
    input  wire        is_vst,
    input  wire        is_vadd,
    input  wire        is_vmul,
    input  wire        is_vsub,
    input  wire        is_vand,
    input  wire        is_vor,
    input  wire        is_vxor,
    input  wire        is_vaddx,
    input  wire [2:0]  vd_idx,
    input  wire [2:0]  vs1_idx,
    input  wire [2:0]  vs2_idx,
    input  wire [31:0] base_addr,
    input  wire [31:0] scalar_val,

    input  wire        vsetvl_en,
    input  wire [31:0] vsetvl_rs1_val,
    output wire [31:0] vl_out,

    output wire        vec_stall,

    output wire         vec_active,
    output reg  [31:0] vec_daddr,
    output reg  [31:0] vec_wdata,
    output reg          vec_mem_read_en,
    output reg          vec_mem_write_en,
    input  wire [31:0] vec_mem_rdata
);

    localparam NUM_VREGS   = 8;
    localparam ELEMS_PER_V = 8;

    reg [31:0] vregs [0:NUM_VREGS-1][0:ELEMS_PER_V-1];
    reg [3:0]  vl_reg;

    wire [3:0] vsetvl_clamped = (vsetvl_rs1_val > 32'd8) ? 4'd8 : vsetvl_rs1_val[3:0];
    assign vl_out = vsetvl_en ? {28'b0, vsetvl_clamped} : {28'b0, vl_reg};

    localparam S_IDLE     = 3'd0;
    localparam S_PHASE_A  = 3'd1;
    localparam S_PHASE_B  = 3'd2;
    localparam S_PARALLEL = 3'd3;   // 新增：ALU類運算，單cycle平行處理完所有元素

    reg [2:0] state;
    reg [2:0] elem_idx;
    reg [2:0] op_vd, op_vs1, op_vs2;
    reg       op_is_vld, op_is_vst, op_is_vadd, op_is_vmul;
    reg       op_is_vsub, op_is_vand, op_is_vor, op_is_vxor, op_is_vaddx;
    reg [31:0] op_scalar_val;
    reg [31:0] op_base_addr;
    reg [3:0] op_vl;

    assign vec_stall  = (state != S_IDLE);
    assign vec_active = (state != S_IDLE) && (op_is_vld || op_is_vst);

    // ---- 平行ALU運算：generate迴圈展開成8組完全獨立的硬體，一拍全部算完 ----
    genvar gi;
    wire [31:0] par_result [0:ELEMS_PER_V-1];
    generate
        for (gi = 0; gi < ELEMS_PER_V; gi = gi + 1) begin : PAR_ALU
            assign par_result[gi] =
                op_is_vadd  ? (vregs[op_vs1][gi] + vregs[op_vs2][gi]) :
                op_is_vmul  ? (vregs[op_vs1][gi] * vregs[op_vs2][gi]) :
                op_is_vsub  ? (vregs[op_vs1][gi] - vregs[op_vs2][gi]) :
                op_is_vand  ? (vregs[op_vs1][gi] & vregs[op_vs2][gi]) :
                op_is_vor   ? (vregs[op_vs1][gi] | vregs[op_vs2][gi]) :
                op_is_vxor  ? (vregs[op_vs1][gi] ^ vregs[op_vs2][gi]) :
                op_is_vaddx ? (vregs[op_vs1][gi] + op_scalar_val) :
                              32'b0;
        end
    endgenerate

    integer r, e, k;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state            <= S_IDLE;
            elem_idx         <= 3'b0;
            vl_reg           <= 4'b0;
            vec_daddr        <= 32'b0;
            vec_wdata        <= 32'b0;
            vec_mem_read_en  <= 1'b0;
            vec_mem_write_en <= 1'b0;
            for (r = 0; r < NUM_VREGS; r = r + 1)
                for (e = 0; e < ELEMS_PER_V; e = e + 1)
                    vregs[r][e] <= 32'b0;
            // 修正：以下15個op_*鎖存訊號，原本只在S_IDLE的start分支被賦值，
            // reset分支完全沒有涵蓋，導致Vivado合成後這些暫存器reset後為
            // 不確定值(跟branch_predictor.v同一種疏漏模式)，一次性補齊
            op_vd         <= 3'b0;
            op_vs1        <= 3'b0;
            op_vs2        <= 3'b0;
            op_is_vld     <= 1'b0;
            op_is_vst     <= 1'b0;
            op_is_vadd    <= 1'b0;
            op_is_vmul    <= 1'b0;
            op_is_vsub    <= 1'b0;
            op_is_vand    <= 1'b0;
            op_is_vor     <= 1'b0;
            op_is_vxor    <= 1'b0;
            op_is_vaddx   <= 1'b0;
            op_scalar_val <= 32'b0;
            op_base_addr  <= 32'b0;
            op_vl         <= 4'b0;
        end else begin
            vec_mem_read_en  <= 1'b0;
            vec_mem_write_en <= 1'b0;

            if (vsetvl_en) begin
                vl_reg <= vsetvl_clamped;
            end

            case (state)
                S_IDLE: begin
                    if (start) begin
                        op_vd        <= vd_idx;
                        op_vs1       <= vs1_idx;
                        op_vs2       <= vs2_idx;
                        op_is_vld    <= is_vld;
                        op_is_vst    <= is_vst;
                        op_is_vadd   <= is_vadd;
                        op_is_vmul   <= is_vmul;
                        op_is_vsub   <= is_vsub;
                        op_is_vand   <= is_vand;
                        op_is_vor    <= is_vor;
                        op_is_vxor   <= is_vxor;
                        op_is_vaddx  <= is_vaddx;
                        op_scalar_val<= scalar_val;
                        op_base_addr <= base_addr;
                        op_vl        <= vl_reg;
                        elem_idx     <= 3'b0;
                        if (vl_reg != 4'b0) begin
                            if (is_vld || is_vst) begin
                                state <= S_PHASE_A;      // 記憶體類：維持循序多週期
                            end else begin
                                state <= S_PARALLEL;     // ALU類：單cycle平行處理
                            end
                        end
                    end
                end

                // ---- 平行處理：一拍寫回所有(vl個)元素的結果 ----
                S_PARALLEL: begin
                    for (k = 0; k < ELEMS_PER_V; k = k + 1) begin
                        if (k < op_vl) begin
                            vregs[op_vd][k] <= par_result[k];
                        end
                    end
                    state <= S_IDLE;
                end

                // ---- vld/vst：完全沿用循序版本邏輯，不做任何修改 ----
                S_PHASE_A: begin
                    if (op_is_vld) begin
                        vec_daddr       <= op_base_addr + (elem_idx * 4);
                        vec_mem_read_en <= 1'b1;
                    end else if (op_is_vst) begin
                        vec_daddr        <= op_base_addr + (elem_idx * 4);
                        vec_wdata        <= vregs[op_vs2][elem_idx];
                        vec_mem_write_en <= 1'b1;
                    end
                    state <= S_PHASE_B;
                end

                S_PHASE_B: begin
                    if (op_is_vld) begin
                        vregs[op_vd][elem_idx] <= vec_mem_rdata;
                    end

                    if ({1'b0, elem_idx} == op_vl - 4'b1) begin
                        state <= S_IDLE;
                    end else begin
                        elem_idx <= elem_idx + 1'b1;
                        state    <= S_PHASE_A;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
