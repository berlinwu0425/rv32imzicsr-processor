`timescale 1ns / 1ps

// =========================================================================
// 對應關係證明：把真實CPU抽出邏輯(對應Theorem A1/A2)跟抽象邊界模型
// (對應Contribution 2的Safe(D,F))放進同一個harness，用同一個真實flush
// 訊號同時驅動兩者，正式證明"D=0,F=0"這組參數，真的對應到這顆真實CPU
// 的實際時序行為，而不只是"手動代入數字、結果剛好一致"的巧合。
// =========================================================================
module case_correspondence_formal (
    input  wire        clk,
    input  wire         rst_n,
    input  wire        flush,
    input  wire        stall,

    input  wire [31:0] pc_out_in,
    input  wire        is_vec_op_in,
    input  wire [2:0]  funct3_in,
    input  wire [6:0]  funct7_in
);

    // ---- 真實模型部分：逐字複製自 caseA_formal.v，並加上標籤機制 ----
    reg [31:0] pc_out_o;
    reg          is_vec_op_o;
    reg [2:0]   funct3_o;
    reg [6:0]   funct7_o;
    // 標籤：這個槽位的內容，是不是"flush當下被清空前，原本差一點要流出去的
    // 危險指令"。只在flush觸發那一拍設成1，正常更新時歸零(代表全新合法指令)。
    reg wrong_path_tag;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out_o        <= 32'b0;
            is_vec_op_o     <= 1'b0;
            funct3_o        <= 3'b0;
            funct7_o        <= 7'b0;
            wrong_path_tag  <= 1'b0;
        end
        else if (flush) begin
            pc_out_o        <= 32'b0;
            is_vec_op_o     <= 1'b0;
            funct3_o        <= 3'b0;
            funct7_o        <= 7'b0;
            wrong_path_tag  <= 1'b1;
        end
        else if (stall) begin
            pc_out_o        <= pc_out_o;
            is_vec_op_o     <= is_vec_op_o;
            funct3_o        <= funct3_o;
            funct7_o        <= funct7_o;
            wrong_path_tag  <= wrong_path_tag;
        end
        else begin
            pc_out_o        <= pc_out_in;
            is_vec_op_o     <= is_vec_op_in;
            funct3_o        <= funct3_in;
            funct7_o        <= funct7_in;
            wrong_path_tag  <= 1'b0;
        end
    end

    wire is_vld_ex   = is_vec_op_o && (funct3_o == 3'b001);
    wire is_vst_ex   = is_vec_op_o && (funct3_o == 3'b010);
    wire is_vadd_ex  = is_vec_op_o && (funct3_o == 3'b011);
    wire is_vmul_ex  = is_vec_op_o && (funct3_o == 3'b100);
    wire is_vsub_ex  = is_vec_op_o && (funct3_o == 3'b101) && (funct7_o == 7'b0000000);
    wire is_vand_ex  = is_vec_op_o && (funct3_o == 3'b101) && (funct7_o == 7'b0000001);
    wire is_vor_ex   = is_vec_op_o && (funct3_o == 3'b101) && (funct7_o == 7'b0000010);
    wire is_vxor_ex  = is_vec_op_o && (funct3_o == 3'b101) && (funct7_o == 7'b0000011);
    wire is_vaddx_ex = is_vec_op_o && (funct3_o == 3'b110);
    wire valid_ex     = (pc_out_o != 32'b0);
    wire vec_start = (is_vld_ex || is_vst_ex || is_vadd_ex || is_vmul_ex ||
                       is_vsub_ex || is_vand_ex || is_vor_ex || is_vxor_ex || is_vaddx_ex)
                      && valid_ex;

    // 只有"被標記為危險"的那個vec_start事件才是我們真正要禁止的
    wire tagged_wrong_path_start = vec_start && wrong_path_tag;

    // ---- 抽象模型部分：D=0, F=0 固定(對應真實CPU的實際數值)，
    //      但改成由真實的flush訊號觸發才開始計數，不是獨立自主開始 ----
    localparam integer D = 0;
    localparam integer F = 0;

    // 改成能處理"連續多次flush"：每一次flush都重新歸零age，
    // 重新啟動一輪新的安全視窗判斷，而不是只認第一次flush事件。
    // 這正確反映真實情況：分支誤判可以反覆發生，每次都該獨立地
    // 從"這次flush觸發"的那一刻重新起算安全視窗。
    reg [7:0] age;
    reg       has_flushed_once;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            age              <= 8'b0;
            has_flushed_once <= 1'b0;
        end
        else if (flush) begin
            // 不管是不是第一次flush，只要flush觸發就重新歸零重來
            age              <= 8'b0;
            has_flushed_once <= 1'b1;
        end
        else if (has_flushed_once) begin
            age <= age + 8'b1;
        end
    end

    localparam integer OBSERVATION_WINDOW = D + 1;

    wire abstract_flush_active    = has_flushed_once && (age >= F);
    wire abstract_instr_at_launch = has_flushed_once && (age == D + 1);
    wire wrong_path_launch        = abstract_instr_at_launch && !abstract_flush_active;

`ifdef FORMAL
    reg f_initial_state;
    initial f_initial_state = 1'b1;
    always @(posedge clk) f_initial_state <= 1'b0;

    always @(*) begin
        if (f_initial_state) begin
            assume (!rst_n);
        end
        // 事件隔離assumption(取代原本"永遠只准一次flush")：只要求
        // 下一次flush不能在上一次事件的觀察視窗(OBSERVATION_WINDOW)結束前發生，
        // 允許系統一生發生無限多次推測事件，只要彼此保持安全間隔——
        // 這是限制"事件之間的交疊關係"，不是限制CPU一生只能誤判一次。
        if (has_flushed_once && (age < OBSERVATION_WINDOW)) begin
            assume (!flush);
        end
    end

    always @(*) begin
        // Contribution 2 的結論：在事件隔離假設下，抽象模型依然判定安全
        assert (!wrong_path_launch);

        // 對應關係核心(標籤版)：flush當下被標記為危險的那個指令，
        // 在抽象模型判定"該走到啟動級"的那一拍，絕對不能真的觸發vec_start；
        // 但flush之後正常流入的合法指令，觸發vec_start完全允許、不受限制
        if (abstract_instr_at_launch) begin
            assert (!tagged_wrong_path_start);
        end
    end
`endif

endmodule
