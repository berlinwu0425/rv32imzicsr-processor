`timescale 1ns / 1ps

// =========================================================================
// 自訂輕量向量處理單元 (custom-0 opcode, 0001011) —— 平行版本
// 8個向量暫存器(v0~v7)，每個裝8個32-bit元素。
//
// ALU類運算(vadd.vv/vmul.vv/vsub.vv/vand.vv/vor.vv/vxor.vv/vadd.vx)採用
// 「單一cycle平行處理」，用generate迴圈展開成8組獨立的硬體
// (8個加法器/8個乘法器等)，一拍算完全部8個元素、一次寫回。
//
// vld/vst 維持循序多週期：向量單元與主管線共用資料記憶體的單一存取埠，
// 每拍只能搬移一個元素。要一拍讀寫8個元素需要另一塊256-bit寬的專用記憶體，
// 超出本設計的範圍，也反映了向量處理器常見的「運算寬、記憶體頻寬窄」取捨。
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
    output wire        vec_hold,     // 1 = 這條向量指令這一拍還不能離開EX級，主管線要凍結
    input  wire        kill,         // 執行中的向量指令被取消(中斷)：丟棄尚未commit的結果
    output wire        vec_killable, // 1 = 目前執行中的指令還沒有留下任何架構可見的改變，可以被kill

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
    // vld 的暫存區：讀進來的元素先放這裡，最後一拍(commit)才一次寫進vregs。
    // 這樣執行到一半被kill時，向量暫存器完全沒有被動到。
    reg [31:0] ld_buf [0:ELEMS_PER_V-1];
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

    // vec_hold：向量指令本身留在EX級直到運算完成(標準的多週期EX stall)。
    //   啟動那一拍(start成立且vl不為0)到「倒數第二拍」都要hold；
    //   最後一拍(S_PARALLEL，或vld/vst最後一個元素的S_PHASE_B)放行，
    //   向量指令跟著管線往下走，下一條指令才進EX。
    // 這樣EX級在整個運算期間只會有向量指令自己，後面的指令停在ID級，
    // 不會被重複執行、也不會拿到過期的運算元。
    wire vec_last = (state == S_PARALLEL) ||
                    ((state == S_PHASE_B) && ({1'b0, elem_idx} == op_vl - 4'b1));
    assign vec_hold = ((state == S_IDLE) && start && (vl_reg != 4'b0)) ||
                      ((state != S_IDLE) && !vec_last);

    // kill/commit：
    //   ALU類(S_PARALLEL)與vld：結果在最後一拍才寫入vregs(commit)，之前任何一拍都可以kill
    //   vst：資料直接寫進記憶體、寫了就收不回來，只有在第一筆寫入發出之前可以kill
    assign vec_killable = (state == S_PARALLEL) ||
                          ((state != S_IDLE) && op_is_vld) ||
                          ((state == S_PHASE_A) && op_is_vst && (elem_idx == 3'b0));
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
            // op_* 鎖存訊號也在 reset 時清除，避免合成後 reset 值不確定
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
            for (e = 0; e < ELEMS_PER_V; e = e + 1)
                ld_buf[e] <= 32'b0;
        end else begin
            vec_mem_read_en  <= 1'b0;
            vec_mem_write_en <= 1'b0;

            if (vsetvl_en) begin
                vl_reg <= vsetvl_clamped;
            end

            if (kill && (state != S_IDLE)) begin
                // 被kill：回到IDLE，不寫vregs、不發出記憶體寫入(上方已預設清為0)
                state <= S_IDLE;
            end else
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
                        ld_buf[elem_idx] <= vec_mem_rdata;
                    end

                    if ({1'b0, elem_idx} == op_vl - 4'b1) begin
                        // 最後一拍 = commit：暫存區的元素加上剛讀到的最後一個，一次寫進vregs
                        if (op_is_vld) begin
                            for (k = 0; k < ELEMS_PER_V; k = k + 1) begin
                                if (k < op_vl) begin
                                    vregs[op_vd][k] <= (k == {29'b0, elem_idx}) ? vec_mem_rdata : ld_buf[k];
                                end
                            end
                        end
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

`ifdef FORMAL_VECTOR_UNIT
    // ---- kill/commit 的性質：被kill的指令不留下任何架構可見的改變 ----
    // (獨立用 formal/vector_unit_kill.sby 證明；用另一個巨集名稱，
    //  避免cpu_top的系統層級證明把這些比較大的性質也一起帶進去)
    reg f_past_valid;
    initial f_past_valid = 1'b0;
    always @(posedge clk) f_past_valid <= 1'b1;
    always @(*) if (!f_past_valid) assume (!rst_n);

    // 把64個向量暫存器元素攤平，方便整體比較
    wire [NUM_VREGS*ELEMS_PER_V*32-1:0] f_vregs_flat;
    genvar fr, fe;
    generate
        for (fr = 0; fr < NUM_VREGS; fr = fr + 1) begin : F_R
            for (fe = 0; fe < ELEMS_PER_V; fe = fe + 1) begin : F_E
                assign f_vregs_flat[(fr*ELEMS_PER_V+fe)*32 +: 32] = vregs[fr][fe];
            end
        end
    endgenerate

    always @(*) begin
        // 記憶體寫入只會發生在vst的S_PHASE_B，這時已經不可kill
        if (rst_n && vec_mem_write_en) begin
            assert (state == S_PHASE_B && op_is_vst && !op_is_vld);
            assert (!vec_killable);
        end
    end

    always @(posedge clk) begin
        if (f_past_valid && rst_n && $past(rst_n)) begin
            // K1：可kill的階段被kill -> 下一拍回到IDLE，向量暫存器完全不變，沒有記憶體寫入
            if ($past(kill) && $past(vec_killable)) begin
                assert (state == S_IDLE);
                assert (f_vregs_flat == $past(f_vregs_flat));
                assert (!vec_mem_write_en);
            end
            // K2：執行中且沒有走到最後一拍(也沒有被kill) -> 向量暫存器不變 (結果只在commit時寫入)
            if ($past(state != S_IDLE) && !$past(vec_last)) begin
                assert (f_vregs_flat == $past(f_vregs_flat));
            end
        end
    end
`endif

endmodule
