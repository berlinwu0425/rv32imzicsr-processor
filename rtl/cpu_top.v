`timescale 1ns / 1ps

module cpu_top #(
    parameter IMEM_WORDS = 1048576,   // 預設維持模擬用大小，不影響既有RISCOF驗證流程
    parameter DMEM_BYTES = 4194304,
    parameter IMEM_INIT_FILE = ""      // FPGA合成時由外層頂層模組指定實際.hex檔路徑
)(
    input wire clk,
    input wire rst_n,   // 系統重置訊號 (Active low)
    output wire [7:0] led_out,   // 記憶體映射LED輸出，給FPGA實機驗證用；模擬時可直接忽略此埠
    output wire [31:0] result_out,  // 記憶體映射32-bit運算結果輸出，給7段顯示器用
    output wire [7:0]  pass_led,    // 自動驗證檢查器的PASS燈號輸出

    // ---- UART 外部觸發介面 ----
    input  wire        uart_rx_valid,   // UART收到一個byte時脈衝1cycle，硬體自動觸發中斷
    input  wire [7:0]  uart_rx_data,    // 收到的byte
    output wire         uart_tx_start,   // 觸發傳送(CPU寫入0x08000004時脈衝)
    output wire [7:0]  uart_tx_data,    // 要傳送的byte
    input  wire         uart_tx_busy,    // 傳送忙碌狀態，CPU可讀取判斷能不能送下一個

    // ---- 實體按鍵/開關互動介面 ----
    input  wire        btn_s0_raw,      // S0按鍵原始訊號(需要防彈跳)
    input  wire [7:0]  switches_raw     // SW0~SW7原始訊號
);
    // ---- 以下訊號在 next_pc / if_id_register.flush 就會被提前引用，
    // 必須先在這裡宣告好寬度，避免 Vivado 合成時把提前引用當成隱性1-bit宣告，
    // 導致跟後面真正的定義互相打架 (Verilator對此較寬容，但Vivado會出錯) ----
    wire        trap_taken_ex;
    wire        is_mret_ex_r;
    wire [31:0] mtvec_out;
    wire [31:0] mepc_out;
    wire [31:0] mstatus_out;
    wire [31:0] mie_out;
    reg         msip_reg;
    wire        is_done_addr_mem;
    wire        btn_s0_pulse;   // S0防彈跳後的乾淨脈衝，需提前宣告
    wire        mtip_ext;   // 計時器中斷pending，來自mtime_unit的硬體比較器，需提前宣告
    wire        vec_stall;   // 向量單元忙碌訊號，需要提前宣告餵給 hazard_stall (跟trap_taken_ex同樣道理)
    wire        is_vsetvl_ex, is_vec_op_ex;  // id_ex_register輸出，vector_unit具現化會用到
    wire        predict_taken_if;   // IF階段查詢分支預測器的結果，需提前宣告餵給 next_pc mux
    wire [31:0] predict_target_if;

    // =========================================================================
    // 0. Hazard Detection Unit 已接上，負責處理 load-use hazard
    //    Forwarding Unit 尚未接，一般 data hazard 目前還是靠 stall 硬撐
    // =========================================================================
    wire hazard_stall;   // 來自 hazard_detect_unit，1 = 偵測到 load-use hazard
    // stall_all：把向量單元忙碌訊號也納入凍結判斷，跟load-use hazard共用同一套凍結機制
    wire stall_all = hazard_stall || vec_stall;

    wire if_id_stall        = stall_all;
    wire id_ex_hazard_flush = hazard_stall;  // 只給load-use hazard用，向量單元忙碌改用stall(見下方)不是flush
    // 註：PC 的凍結不透過額外的 enable port，而是直接在 next_pc 的 mux 裡處理
    //     （見下方 IF 階段的 assign next_pc = ...），這樣就不用修改 pc 模組介面

    // =========================================================================
    // [Instruction Fetch (IF) 階段]
    // =========================================================================
    wire [31:0] next_pc;
    wire [31:0] pc_out;
    wire [31:0] pc_seq_if;      // IF 階段自己算的 PC+4 (預設的下一個PC)
    wire [31:0] inst_if;

    // branch/jump 是在 EX 級才判斷出來的，所以要先往前宣告 EX 級算出的 redirect 訊號
    wire        redirect_ex;
    wire [31:0] next_pc_ex;

    assign pc_seq_if = pc_out + 32'd4;

    // ---- 動態分支預測器：IF階段用當下pc_out查詢，同一拍組合邏輯就有結果 ----
    // EX階段驗證後的更新介面(update_*)在下面EX階段區塊具現化時一併接上
    branch_predictor u_branch_predictor (
        .clk             (clk),
        .rst_n           (rst_n),
        .query_pc        (pc_out),
        .predict_taken   (predict_taken_if),
        .predict_target  (predict_target_if),
        .update_en       (bp_update_en_ex),
        .update_pc       (pc_out_ex),
        .update_taken    (branch_taken_actual_ex),
        .update_target   (next_pc_ex)
    );

    // 優先權：trap進入/mret > redirect_ex(EX階段驗證後確定要跳轉，含猜錯復原) >
    //         predict_taken(IF階段預測猜跳，還沒驗證) > hazard_stall凍結 > 正常PC+4
    assign next_pc   = trap_taken_ex ? mtvec_out :
                        is_mret_ex_r ? mepc_out :
                        redirect_ex ? next_pc_ex :
                        (predict_taken_if && !stall_all) ? predict_target_if :
                        stall_all ? pc_out :
                                    pc_seq_if;

    wire pc_write_en = ~stall_all;

    pc u_pc (
        .clk         (clk),
        .rst_n       (rst_n),
        .next_pc     (next_pc),
        .pc_out      (pc_out),
        .pc_write_en (pc_write_en)
        // TODO: pc_write_en 之後要接進 pc 模組做 clock enable (目前 pc 模組還沒有這個埠位)
    );

    imem #(
        .MEM_WORDS(IMEM_WORDS),
        .INIT_FILE(IMEM_INIT_FILE)
    ) u_imem (
        .iaddr        (pc_out),
        .inst        (inst_if)
    );

    // =========================================================================
    // [IF/ID pipeline register]
    // =========================================================================
    wire [31:0] pc_out_id;
    wire        predicted_taken_id;
    wire [31:0] predicted_target_id;
    wire [31:0] inst_id;

    if_id_register u_if_id_register (
        .clk        (clk),
        .rst_n      (rst_n),
        .stall      (if_id_stall),
        .flush      (redirect_ex || trap_taken_ex || is_mret_ex_r),  // branch/jump/trap/mret 都要flush誤抓的指令
        .pc_out_in  (pc_out),
        .inst_in    (inst_if),
        .predicted_taken_in  (predict_taken_if),
        .predicted_target_in (predict_target_if),
        .pc_out_o   (pc_out_id),
        .inst_o     (inst_id),
        .predicted_taken_o  (predicted_taken_id),
        .predicted_target_o (predicted_target_id)
    );

    // =========================================================================
    // [Instruction Decode (ID) 階段]
    // =========================================================================
    wire [31:0] imm_id, imm_b_id, imm_j_id, imm_u_id;
    wire [31:0] rdata1_id, rdata2_id;

    wire [6:0] opcode_id;
    wire [4:0] rd_id;
    wire [4:0] rs1_id;
    wire [4:0] rs2_id;
    wire [2:0] funct3_id;
    wire [6:0] funct7_id;
    wire [11:0] csr_addr_id;

    wire        branch_en_id;
    wire        jump_en_id;
    wire        jalr_en_id;
    wire        mem_read_en_id;
    wire        mem_write_en_id;
    wire        reg_write_en_id;
    wire        ALUSrc_id;
    wire        ALUSrcA_id;
    wire        ALUAUIPC_id;
    wire [2:0]  MemtoReg_id;
    wire [1:0]  ALUOp_id;
    wire        is_ecall_id, is_ebreak_id, is_mret_id, is_csr_id, csr_imm_id;

    // WB 階段寫回訊號，回接給 regfile 同一份模組使用
    wire [31:0] wb_data;
    wire [4:0]  rd_wb;
    wire        reg_write_en_wb;

    imm_gen u_imm_gen (
        .inst   (inst_id),
        .imm    (imm_id),
        .imm_b  (imm_b_id),
        .imm_j  (imm_j_id),
        .imm_u  (imm_u_id)
    );

    decoder u_decoder (
        .inst        (inst_id),
        .opcode      (opcode_id),
        .rd          (rd_id),
        .funct3      (funct3_id),
        .rs1         (rs1_id),
        .rs2         (rs2_id),
        .funct7      (funct7_id),
        .csr_addr    (csr_addr_id)
    );

    wire is_vsetvl_id, is_vec_op_id;

    control u_control (
        .opcode      (opcode_id),
        .funct3      (funct3_id),
        .csr_addr    (csr_addr_id),
        .branch_en   (branch_en_id),
        .jump_en      (jump_en_id),
        .jalr_en     (jalr_en_id),
        .mem_read_en    (mem_read_en_id),
        .mem_write_en   (mem_write_en_id),
        .reg_write_en   (reg_write_en_id),
        .ALUSrc     (ALUSrc_id),
        .ALUSrcA     (ALUSrcA_id),
        .ALUAUIPC     (ALUAUIPC_id),
        .MemtoReg      (MemtoReg_id),
        .ALUOp      (ALUOp_id),
        .is_ecall    (is_ecall_id),
        .is_ebreak   (is_ebreak_id),
        .is_mret     (is_mret_id),
        .is_csr      (is_csr_id),
        .csr_imm     (csr_imm_id),
        .is_vsetvl   (is_vsetvl_id),
        .is_vec_op   (is_vec_op_id)
    );

    regfile u_regfile (
        .clk         (clk),
        .rst_n       (rst_n),
        .rs1         (rs1_id),
        .rs2         (rs2_id),
        .rd          (rd_wb),            // 寫入位址來自 WB 階段
        .wb_data       (wb_data),        // 寫入資料來自 WB 階段
        .reg_write_en   (reg_write_en_wb),  // 寫入啟用來自 WB 階段
        .rdata1      (rdata1_id),
        .rdata2      (rdata2_id)
    );

    //ID/EX 提前宣告
    wire [31:0] pc_out_ex, rdata1_ex, rdata2_ex;
    wire        predicted_taken_ex;
    wire [31:0] predicted_target_ex;
    wire [31:0] imm_ex, imm_b_ex, imm_j_ex, imm_u_ex;
    wire [4:0]  rd_ex, rs1_ex, rs2_ex;
    wire [2:0]  funct3_ex;
    wire [6:0]  funct7_ex;
    wire        branch_en_ex;
    wire        jump_en_ex;
    wire        jalr_en_ex;
    wire        mem_read_en_ex;
    wire        mem_write_en_ex;
    wire        reg_write_en_ex;
    wire        ALUSrc_ex;
    wire        ALUSrcA_ex;
    wire        ALUAUIPC_ex;
    wire [2:0]  MemtoReg_ex;
    wire [11:0] csr_addr_ex;
    wire        is_ecall_ex_r, is_ebreak_ex_r, is_csr_ex, csr_imm_ex; // is_mret_ex_r 已在檔案開頭提前宣告
    wire [1:0]  ALUOp_ex;

    // =========================================================================
    // [Hazard Detection Unit]
    // 放在這裡是因為它需要「即將進EX的ID/EX輸出(mem_read_en_ex, rd_ex)」
    // 跟「目前正在ID解碼的rs1_id/rs2_id」做比對，兩者在下面才會被具現化，
    // 所以先用 forward reference 的方式宣告 wire，實際接線在 id_ex_reg 之後
    // =========================================================================
    hazard_detect_unit u_hazard_detect_unit (
        .mem_read_en_ex (mem_read_en_ex),
        .rd_ex          (rd_ex),
        .rs1_id         (rs1_id),
        .rs2_id         (rs2_id),
        .hazard_stall   (hazard_stall)
    );

    // =========================================================================
    // [ID/EX pipeline register]
    // =========================================================================

    id_ex_register u_id_ex_register (
        .clk (clk), .rst_n (rst_n),
        .flush (redirect_ex || id_ex_hazard_flush || trap_taken_ex),
        .stall (vec_stall),  // 向量單元忙碌期間，EX階段保持原地不動(不清空)
        .pc_out_in(pc_out_id),
        .rdata1_in(rdata1_id), .rdata2_in(rdata2_id),
        .imm_in(imm_id), .imm_b_in(imm_b_id), .imm_j_in(imm_j_id), .imm_u_in(imm_u_id),
        .rd_in(rd_id), .rs1_in(rs1_id), .rs2_in(rs2_id),
        .funct3_in(funct3_id), .funct7_in(funct7_id), .csr_addr_in(csr_addr_id),
        .branch_en_in(branch_en_id), .jump_en_in(jump_en_id), .jalr_en_in(jalr_en_id),
        .mem_read_en_in(mem_read_en_id), .mem_write_en_in(mem_write_en_id),
        .reg_write_en_in(reg_write_en_id),
        .ALUSrc_in(ALUSrc_id), .ALUSrcA_in(ALUSrcA_id), .ALUAUIPC_in(ALUAUIPC_id),
        .ALUOp_in(ALUOp_id), .MemtoReg_in(MemtoReg_id),
        .is_ecall_in(is_ecall_id), .is_ebreak_in(is_ebreak_id), .is_mret_in(is_mret_id),
        .is_csr_in(is_csr_id), .csr_imm_in(csr_imm_id),
        .is_vsetvl_in(is_vsetvl_id), .is_vec_op_in(is_vec_op_id),
        .predicted_taken_in(predicted_taken_id), .predicted_target_in(predicted_target_id),
        .pc_out_o(pc_out_ex),
        .rdata1_o(rdata1_ex), .rdata2_o(rdata2_ex),
        .imm_o(imm_ex), .imm_b_o(imm_b_ex), .imm_j_o(imm_j_ex), .imm_u_o(imm_u_ex),
        .rd_o(rd_ex), .rs1_o(rs1_ex), .rs2_o(rs2_ex),
        .funct3_o(funct3_ex), .funct7_o(funct7_ex), .csr_addr_o(csr_addr_ex),
        .branch_en_o(branch_en_ex), .jump_en_o(jump_en_ex), .jalr_en_o(jalr_en_ex),
        .mem_read_en_o(mem_read_en_ex), .mem_write_en_o(mem_write_en_ex),
        .reg_write_en_o(reg_write_en_ex),
        .ALUSrc_o(ALUSrc_ex), .ALUSrcA_o(ALUSrcA_ex), .ALUAUIPC_o(ALUAUIPC_ex),
        .ALUOp_o(ALUOp_ex), .MemtoReg_o(MemtoReg_ex),
        .is_ecall_o(is_ecall_ex_r), .is_ebreak_o(is_ebreak_ex_r), .is_mret_o(is_mret_ex_r),
        .is_csr_o(is_csr_ex), .csr_imm_o(csr_imm_ex),
        .is_vsetvl_o(is_vsetvl_ex), .is_vec_op_o(is_vec_op_ex),
        .predicted_taken_o(predicted_taken_ex), .predicted_target_o(predicted_target_ex)
    );

    // =========================================================================
    // [Execute (EX) 階段]
    // =========================================================================
    wire [31:0] alu_a_in, alu_b_in, alu_result;
    wire [3:0]  alu_ctrl;
    wire        branch_taken;
    wire [31:0] pc_plus4_ex;

    //EX/MEM 提前宣告
    wire [31:0] alu_result_mem, rdata2_mem, imm_u_mem, pc_plus4_mem;
    wire [4:0]  rd_mem;
    wire [2:0]  funct3_mem;
    wire        mem_read_en_mem, mem_write_en_mem, reg_write_en_mem;
    wire [2:0]  MemtoReg_mem;
    wire [31:0] csr_rdata_mem;

    // ---- Forwarding Unit ----
    // 需要 EX/MEM、MEM/WB 的 reg_write/rd (下面才會具現化,但Verilog wire可以先用)
    wire [1:0] forward_a, forward_b;

    forwarding_unit u_forwarding_unit (
        .ex_mem_reg_write (reg_write_en_mem),
        .ex_mem_rd        (rd_mem),
        .mem_wb_reg_write (reg_write_en_wb),
        .mem_wb_rd        (rd_wb),
        .id_ex_rs1        (rs1_ex),
        .id_ex_rs2        (rs2_ex),
        .forward_a        (forward_a),
        .forward_b        (forward_b)
    );

    // EX/MEM 階段這條指令「真正」要寫回的值，邏輯跟 writeback_mux 一致
    // (轉發時不能只看 alu_result_mem，LUI/JAL/JALR 的結果不是走 ALU)
    // 註: MemtoReg_mem == 2'b01 (load) 的情況不會出現在這裡，
    //     因為 hazard_detect_unit 已經用 stall 處理了 load-use hazard，
    //     load 指令要轉發時一定已經到了 MEM/WB 階段 (走 forward_a/b == 2'b10 那條路，用 wb_data)
    reg [31:0] fwd_value_mem;
    always @(*) begin
        case (MemtoReg_mem)
            3'b000:  fwd_value_mem = alu_result_mem;
            3'b001:  fwd_value_mem = alu_result_mem; // load: 理論上不會被選到，見上方註解
            3'b010:  fwd_value_mem = pc_plus4_mem;
            3'b011:  fwd_value_mem = imm_u_mem;
            3'b100:  fwd_value_mem = csr_rdata_mem;
            default: fwd_value_mem = alu_result_mem;
        endcase
    end

    // 轉發後真正要送進EX級運算的rs1/rs2值
    // 00=用ID/EX原始值(沒有hazard)  01=從EX/MEM轉發(fwd_value_mem)  10=從MEM/WB轉發(wb_data)
    wire [31:0] fwd_rs1_ex = (forward_a == 2'b01) ? fwd_value_mem :
                            (forward_a == 2'b10) ? wb_data :
                                                    rdata1_ex;

    wire [31:0] fwd_rs2_ex = (forward_b == 2'b01) ? fwd_value_mem :
                            (forward_b == 2'b10) ? wb_data :
                                                    rdata2_ex;

    // 這兩個mux的輸入現在改用轉發後的值，不再直接吃ID/EX的原始rdata1_ex/rdata2_ex
    assign alu_a_in = (ALUSrcA_ex == 1'b1) ? pc_out_ex : fwd_rs1_ex;
    assign alu_b_in = (ALUSrc_ex == 1'b1) ? (ALUAUIPC_ex == 1'b1 ? imm_u_ex : imm_ex) : fwd_rs2_ex;

    alu_control u_alu_control (
        .ALUOp      (ALUOp_ex),
        .funct3     (funct3_ex),
        .funct7     (funct7_ex),
        .alu_ctrl   (alu_ctrl)
    );

    alu u_alu (
        .alu_a           (alu_a_in),
        .alu_b           (alu_b_in),
        .alu_ctrl    (alu_ctrl),
        .alu_result  (alu_result)
    );

    // =========================================================================
    // [M 擴充] 乘除法單元
    // R-type 指令 funct7==0000001 代表這是 M 擴充指令，不是一般算術指令
    // =========================================================================
    wire is_muldiv_ex = (funct7_ex == 7'b0000001) && (ALUOp_ex == 2'b10);
    wire [31:0] mul_div_result;

    mul_div_unit u_mul_div_unit (
        .a       (fwd_rs1_ex),
        .b       (fwd_rs2_ex),
        .funct3  (funct3_ex),
        .result  (mul_div_result)
    );

    // 最終送進 EX/MEM 的結果：是 M 指令就用乘除法單元的值，否則用一般 ALU 的值
    wire [31:0] alu_result_final = is_muldiv_ex ? mul_div_result : alu_result;

    // =========================================================================
    // [自訂向量擴充] custom-0 opcode，透過 vector_unit 獨立協同處理器接管
    // =========================================================================
    // funct3_ex 區分向量指令種類 (跟 control.v 裡的 case 對應):
    // 001=vld, 010=vst, 011=vadd.vv, 100=vmul.vv
    wire is_vld_ex   = is_vec_op_ex && (funct3_ex == 3'b001);
    wire is_vst_ex   = is_vec_op_ex && (funct3_ex == 3'b010);
    wire is_vadd_ex  = is_vec_op_ex && (funct3_ex == 3'b011);
    wire is_vmul_ex  = is_vec_op_ex && (funct3_ex == 3'b100);
    wire is_vsub_ex  = is_vec_op_ex && (funct3_ex == 3'b101) && (funct7_ex == 7'b0000000);
    wire is_vand_ex  = is_vec_op_ex && (funct3_ex == 3'b101) && (funct7_ex == 7'b0000001);
    wire is_vor_ex   = is_vec_op_ex && (funct3_ex == 3'b101) && (funct7_ex == 7'b0000010);
    wire is_vxor_ex  = is_vec_op_ex && (funct3_ex == 3'b101) && (funct7_ex == 7'b0000011);
    wire is_vaddx_ex = is_vec_op_ex && (funct3_ex == 3'b110);

    // 只在指令"首次"進入EX那一拍觸發start，靠valid_ex(pc_out_ex!=0避開bubble)
    // 並且 vec_stall 還沒拉高時才算是"首次"，避免同一條指令在多cycle期間重複觸發
    wire [31:0] vl_result_ex;
    wire        vec_active;
    wire [31:0] vec_daddr, vec_wdata;
    wire        vec_mem_read_en, vec_mem_write_en;
    wire [31:0] vec_mem_rdata;

    wire vec_start = (is_vld_ex || is_vst_ex || is_vadd_ex || is_vmul_ex ||
                       is_vsub_ex || is_vand_ex || is_vor_ex || is_vxor_ex || is_vaddx_ex)
                      && valid_ex && !vec_stall;

    vector_unit u_vector_unit (
        .clk              (clk),
        .rst_n            (rst_n),
        .start            (vec_start),
        .is_vld           (is_vld_ex),
        .is_vst           (is_vst_ex),
        .is_vadd          (is_vadd_ex),
        .is_vmul          (is_vmul_ex),
        .is_vsub          (is_vsub_ex),
        .is_vand          (is_vand_ex),
        .is_vor           (is_vor_ex),
        .is_vxor          (is_vxor_ex),
        .is_vaddx         (is_vaddx_ex),
        .scalar_val       (fwd_rs2_ex),
        .vd_idx           (rd_ex[2:0]),
        .vs1_idx          (rs1_ex[2:0]),
        .vs2_idx          (rs2_ex[2:0]),
        .base_addr        (fwd_rs1_ex),
        .vsetvl_en        (is_vsetvl_ex && valid_ex),
        .vsetvl_rs1_val   (fwd_rs1_ex),
        .vl_out           (vl_result_ex),
        .vec_stall        (vec_stall),
        .vec_active       (vec_active),
        .vec_daddr        (vec_daddr),
        .vec_wdata        (vec_wdata),
        .vec_mem_read_en  (vec_mem_read_en),
        .vec_mem_write_en (vec_mem_write_en),
        .vec_mem_rdata    (vec_mem_rdata)
    );

    branch_unit u_branch_unit (
        .rdata1      (fwd_rs1_ex),
        .rdata2      (fwd_rs2_ex),
        .funct3      (funct3_ex),
        .branch_taken(branch_taken)
    );

    // next_pc 的目標位址、以及 link value (pc+4) 都在 EX 級一次算好
    npc u_npc (
        .pc_out      (pc_out_ex),
        .imm_b     (imm_b_ex),
        .imm_j (imm_j_ex),
        .alu_result  (alu_result),
        .branch_en   (branch_en_ex),
        .branch_taken(branch_taken),
        .jump_en     (jump_en_ex),
        .jalr_en     (jalr_en_ex),
        .next_pc     (next_pc_ex),
        .pc_plus4   (pc_plus4_ex)
    );

    // ---- 動態分支預測驗證：只有「猜錯」才需要flush，猜對完全不用付出代價 ----
    // branch_taken_actual_ex：這條條件分支指令實際上有沒有跳(給預測器回頭學習用)
    wire branch_taken_actual_ex = branch_en_ex & branch_taken;

    // 只有條件分支(branch_en_ex)才需要跟預測比較；jump/jalr永遠跳，不受預測影響，直接redirect
    // 猜錯的判斷：預測跳但實際沒跳、或預測沒跳但實際跳了、或兩者都跳但目標位址對不上
    wire branch_mispredict_ex = branch_en_ex &&
        ((predicted_taken_ex != branch_taken_actual_ex) ||
         (branch_taken_actual_ex && predicted_taken_ex && (predicted_target_ex != next_pc_ex)));

    // redirect 成立條件：條件分支猜錯了、或是 JAL、或是 JALR(這兩種目前還沒做預測，永遠redirect)
    assign redirect_ex = branch_mispredict_ex | jump_en_ex | jalr_en_ex;

    // 猜錯時的正確去向：如果實際上沒跳，正確位址是pc+4；如果實際上跳了(但目標猜錯)，正確位址是next_pc_ex
    // 這個訊號會取代原本redirect_ex成立時next_pc_ex的角色，所以直接讓next_pc_ex在"沒跳"的情況下等於pc_plus4_ex
    // (透過修改npc.v的next_pc輸出邏輯本身處理，這裡不用額外訊號)

    // 分支預測器更新介面：只有條件分支才需要更新預測器內容(jump/jalr不用，因為沒有對應的預測)
    wire bp_update_en_ex = branch_en_ex && valid_ex;

    // =========================================================================
    // [Zicsr / Trap 處理] 全部判斷都放在 EX 階段，跟 redirect_ex 同一層，
    // 這樣可以沿用現有的 flush 機制，不用額外設計更深層的 pipeline flush
    // =========================================================================

    // ---- CSR 寫入值計算 ----
    // csrrw: 直接用 rs1(或立即值) 蓋掉整個CSR
    // csrrs: CSR舊值 OR rs1(或立即值)
    // csrrc: CSR舊值 AND NOT rs1(或立即值)
    wire [31:0] csr_operand   = csr_imm_ex ? {27'b0, rs1_ex} : fwd_rs1_ex; // rs1_ex本身就是5-bit立即值(csrrwi等指令把imm塞在rs1欄位)
    wire [31:0] csr_rdata_ex;
    reg  [31:0] csr_wdata_ex;
    always @(*) begin
        case (funct3_ex[1:0])
            2'b01:   csr_wdata_ex = csr_operand;                    // csrrw/csrrwi
            2'b10:   csr_wdata_ex = csr_rdata_ex | csr_operand;      // csrrs/csrrsi
            2'b11:   csr_wdata_ex = csr_rdata_ex & (~csr_operand);   // csrrc/csrrci
            default: csr_wdata_ex = csr_rdata_ex;
        endcase
    end
    // csrrs/csrrc 若 rs1(或立即值)為0，代表只讀不寫；其餘 CSR 指令一律寫入
    wire csr_skip_write = (funct3_ex[1:0] != 2'b01) && (csr_operand == 32'b0);
    wire csr_write_en_ex = is_csr_ex && !csr_skip_write;

    // ---- Misaligned load/store 判斷：用 EX 階段就已經算好的 alu_result(有效位址) ----
    wire load_halfword_misalign  = mem_read_en_ex  && (funct3_ex == 3'b001 || funct3_ex == 3'b101) && alu_result[0];
    wire load_word_misalign      = mem_read_en_ex  && (funct3_ex == 3'b010) && (alu_result[1:0] != 2'b00);
    wire store_halfword_misalign = mem_write_en_ex && (funct3_ex == 3'b001) && alu_result[0];
    wire store_word_misalign     = mem_write_en_ex && (funct3_ex == 3'b010) && (alu_result[1:0] != 2'b00);
    wire load_misalign_ex  = load_halfword_misalign  || load_word_misalign;
    wire store_misalign_ex = store_halfword_misalign || store_word_misalign;

    // ---- 指令未對齊判斷：redirect_ex 成立時，算出來的跳轉目標低2bit不為0 ----
    wire instr_misalign_ex = redirect_ex && (next_pc_ex[1:0] != 2'b00);

    // ---- 軟體中斷 (MSIP) 偵測：valid_ex 用 pc_out_ex!=0 判斷 EX 是否持有真正指令
    // (flush/bubble時 pc_out_ex 會是 0，避免在 bubble 上誤觸發中斷、錯記 mepc) ----
    wire valid_ex = (pc_out_ex != 32'b0);
    // 軟體中斷跟計時器中斷各自獨立的致能位元 (MSIE=bit3, MTIE=bit7)，
    // 全域中斷開關(mstatus.MIE)兩者共用
    wire msi_pending = valid_ex && mstatus_out[3] && mie_out[3] && msip_reg;
    wire mti_pending = valid_ex && mstatus_out[3] && mie_out[7] && mtip_ext;
    // RISC-V規格規定的中斷優先權：軟體中斷 > 計時器中斷 (我們沒有外部中斷)
    wire interrupt_pending = msi_pending || mti_pending;

    // ---- 統整 trap 來源與優先權 (由高到低: 中斷 > 指令未對齊 > ecall/ebreak > load/store未對齊) ----
    // 中斷優先權最高是 RISC-V 規格要求：同一指令若中斷跟例外同時成立，中斷優先
    assign trap_taken_ex = interrupt_pending || is_ecall_ex_r || is_ebreak_ex_r || instr_misalign_ex || load_misalign_ex || store_misalign_ex;

    reg [31:0] trap_cause_ex;
    always @(*) begin
        if (msi_pending)            trap_cause_ex = {1'b1, 31'd3}; // machine software interrupt (帶中斷位元)
        else if (mti_pending)       trap_cause_ex = {1'b1, 31'd7}; // machine timer interrupt (帶中斷位元)
        else if (instr_misalign_ex) trap_cause_ex = 32'd0;   // instruction address misaligned
        else if (is_ecall_ex_r)     trap_cause_ex = 32'd11;  // environment call
        else if (is_ebreak_ex_r)    trap_cause_ex = 32'd3;   // breakpoint
        else if (load_misalign_ex)  trap_cause_ex = 32'd4;   // load address misaligned
        else if (store_misalign_ex) trap_cause_ex = 32'd6;   // store address misaligned
        else                        trap_cause_ex = 32'd0;
    end

    // ---- CSR 檔案本體 ----
    // mepc_out, mtvec_out 已在檔案開頭提前宣告
    // mtval 語意：指令未對齊存目標PC，load/store未對齊存有效位址，
    // ebreak存指令自己的PC(跟mepc同值，這是spike的實作選擇，比對需與其一致)，
    // ecall則維持存0
    reg [31:0] trap_value_ex;
    always @(*) begin
        if (instr_misalign_ex)                      trap_value_ex = next_pc_ex;
        else if (load_misalign_ex || store_misalign_ex) trap_value_ex = alu_result;
        else if (is_ebreak_ex_r)                     trap_value_ex = pc_out_ex;
        else                                          trap_value_ex = 32'b0;
    end

    csr_file u_csr_file (
        .clk          (clk),
        .rst_n        (rst_n),
        .csr_addr     (csr_addr_ex),
        .csr_wdata    (csr_wdata_ex),
        .csr_write_en (csr_write_en_ex),
        .csr_rdata    (csr_rdata_ex),
        .trap_taken   (trap_taken_ex),
        .trap_pc      (pc_out_ex),
        .trap_cause   (trap_cause_ex),
        .trap_value   (trap_value_ex),
        .mret_taken   (is_mret_ex_r),
        .mepc_out     (mepc_out),
        .mtvec_out    (mtvec_out),
        .mstatus_out  (mstatus_out),
        .mie_out      (mie_out),
        .msip_ext     (msip_reg),
        .mtip_ext     (mtip_ext)
    );

    // ---- mtime/mtimecmp 計時器單元 ----
    wire is_mtime_addr_mem    = (alu_result_mem == 32'h09000000);
    wire is_mtimeh_addr_mem   = (alu_result_mem == 32'h09000004);
    wire is_mtimecmp_addr_mem = (alu_result_mem == 32'h09000008);
    wire is_mtimecmph_addr_mem= (alu_result_mem == 32'h0900000C);
    wire is_mtime_any_addr_mem = is_mtime_addr_mem || is_mtimeh_addr_mem || is_mtimecmp_addr_mem || is_mtimecmph_addr_mem;
    wire [31:0] mtime_rdata;

    mtime_unit u_mtime_unit (
        .clk       (clk),
        .rst_n     (rst_n),
        .addr      (alu_result_mem),
        .wdata     (rdata2_mem),
        .write_en  (mem_write_en_mem && is_mtime_any_addr_mem),
        .rdata     (mtime_rdata),
        .mtip_pending (mtip_ext)
    );
    // mstatus_out, mie_out 已在檔案開頭提前宣告

    // ---- trap/mret 的跳轉目標 ----
    wire [31:0] trap_target_pc = trap_taken_ex ? mtvec_out : mepc_out; // mret 用 mepc, trap進入用 mtvec

    // =========================================================================
    // [EX/MEM pipeline register]
    // =========================================================================


    wire [31:0] vl_result_mem;
    ex_mem_register u_ex_mem_register (
        .clk(clk), .rst_n(rst_n),
        .flush(trap_taken_ex || is_mret_ex_r),  // trap/mret 成立時，觸發指令本身也不能繼續寫回
        .alu_result_in(alu_result_final), .rdata2_in(fwd_rs2_ex),
        .imm_u_in(imm_u_ex), .pc_plus4_in(pc_plus4_ex), .csr_rdata_in(csr_rdata_ex),
        .vl_result_in(vl_result_ex),
        .rd_in(rd_ex), .funct3_in(funct3_ex),
        .mem_read_en_in(mem_read_en_ex), .mem_write_en_in(mem_write_en_ex),
        .reg_write_en_in(reg_write_en_ex), .MemtoReg_in(MemtoReg_ex),
        .alu_result_o(alu_result_mem), .rdata2_o(rdata2_mem),
        .imm_u_o(imm_u_mem), .pc_plus4_o(pc_plus4_mem), .csr_rdata_o(csr_rdata_mem),
        .vl_result_o(vl_result_mem),
        .rd_o(rd_mem), .funct3_o(funct3_mem),
        .mem_read_en_o(mem_read_en_mem), .mem_write_en_o(mem_write_en_mem),
        .reg_write_en_o(reg_write_en_mem), .MemtoReg_o(MemtoReg_mem)
    );

    // =========================================================================
    // [Memory (MEM) 階段]
    // =========================================================================
    wire [31:0] mem_rdata_dmem;
    reg  [31:0] mem_rdata;

    // ---- 軟體中斷觸發暫存器 (msip)，記憶體映射位址 0x02000000，符合CLINT慣例 ----
    // model_test.h 的 RVMODEL_SET_MSW_INT/RVMODEL_CLEAR_MSW_INT 巨集本來就預期這個位址
    // 這個位址攔截在 dmem 之前，避免跟真正的資料記憶體位址(遮罩後會alias到0)衝突
    wire is_msip_addr_mem = (alu_result_mem == 32'h02000000);
    // msip_reg 已在檔案開頭提前宣告
    // 優先權: UART硬體自動觸發(外部非同步事件) > CPU軟體手動寫入(自我測試/清除中斷源用)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            msip_reg <= 1'b0;
        end else if (uart_rx_valid) begin
            msip_reg <= 1'b1;
        end else if (mem_write_en_mem && is_msip_addr_mem) begin
            msip_reg <= rdata2_mem[0];
        end
    end

    // ---- UART 收到的資料鎖存暫存器 (記憶體映射位址 0x08000000，唯讀) ----
    wire is_uart_rx_addr_mem = (alu_result_mem == 32'h08000000);
    reg [7:0] uart_rx_data_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_rx_data_reg <= 8'b0;
        end else if (uart_rx_valid) begin
            uart_rx_data_reg <= uart_rx_data;
        end
    end

    // ---- UART 傳送觸發 (記憶體映射位址 0x08000004，可寫)：CPU寫入這裡就送出一個byte ----
    wire is_uart_tx_addr_mem = (alu_result_mem == 32'h08000004);
    assign uart_tx_start = mem_write_en_mem && is_uart_tx_addr_mem;
    // 把要傳送的資料鎖存起來，避免CDC同步延遲期間rdata2_mem被後續指令覆蓋掉，
    // 這樣uart_tx模組不管延遲多久才收到觸發訊號，讀到的都會是正確、穩定的資料
    reg [7:0] uart_tx_data_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_tx_data_reg <= 8'b0;
        end else if (mem_write_en_mem && is_uart_tx_addr_mem) begin
            uart_tx_data_reg <= rdata2_mem[7:0];
        end
    end
    assign uart_tx_data = uart_tx_data_reg;

    // ---- S0 按鍵：防彈跳 + 單脈衝，觸發後鎖存成CPU可輪詢/清除的sticky flag ----
    button_debounce #(.DEBOUNCE_CYCLES(20)) u_btn_s0_debounce (
        .clk       (clk),
        .rst_n     (rst_n),
        .btn_raw   (btn_s0_raw),
        .btn_pulse (btn_s0_pulse)
    );

    // 記憶體映射位址 0x0A000000：S0按鍵事件(唯讀，讀到1代表按過，CPU處理完要寫0清除)
    wire is_btn_addr_mem = (alu_result_mem == 32'h0A000000);
    reg btn_s0_pending;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_s0_pending <= 1'b0;
        end else if (btn_s0_pulse) begin
            btn_s0_pending <= 1'b1;
        end else if (mem_write_en_mem && is_btn_addr_mem) begin
            btn_s0_pending <= rdata2_mem[0];   // CPU寫0清除
        end
    end

    // 記憶體映射位址 0x0B000000：8個開關目前的狀態(唯讀，直接讀取，經兩級同步器降低metastability風險)
    wire is_switch_addr_mem = (alu_result_mem == 32'h0B000000);
    reg [7:0] switches_sync0, switches_sync1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            switches_sync0 <= 8'b0;
            switches_sync1 <= 8'b0;
        end else begin
            switches_sync0 <= switches_raw;
            switches_sync1 <= switches_sync0;
        end
    end

    // ---- UART 傳送忙碌狀態 (記憶體映射位址 0x08000008，唯讀) ----
    wire is_uart_busy_addr_mem = (alu_result_mem == 32'h08000008);

    // ---- LED 輸出暫存器 (記憶體映射位址 0x03000000)，FPGA實機bring-up驗證用 ----
    // 軟體對這個位址執行 sw，低8bit會直接反映到板子上的LED，可以不靠UART就看到CPU執行到哪個階段
    wire is_led_addr_mem = (alu_result_mem == 32'h03000000);
    reg [7:0] led_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_reg <= 8'b0;
        end else if (mem_write_en_mem && is_led_addr_mem) begin
            led_reg <= rdata2_mem[7:0];
        end
    end
    assign led_out = led_reg;

    // ---- 32-bit 運算結果輸出暫存器 (記憶體映射位址 0x05000000)，給7段顯示器顯示用 ----
    // 軟體算完想驗證的東西後，對這個位址執行 sw，結果就會直接顯示在板子上8位7段顯示器
    wire is_result_addr_mem = (alu_result_mem == 32'h05000000);
    reg [31:0] result_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 32'b0;
        end else if (mem_write_en_mem && is_result_addr_mem) begin
            result_reg <= rdata2_mem;
        end
    end
    assign result_out = result_reg;

    wire [31:0] chk_addr_w;
    wire [31:0] chk_rdata_w;

    // vec_active=1 時，dmem 的存取權交給 vector_unit(vld/vst 借用)；
    // vec_active=0 時，維持主管線原本的存取行為，兩者互斥、不會同時發生
    // (因為 vec_active 拉高時主管線已經被 stall_all 凍結，MEM 階段不會有新指令在動 dmem)
    wire [31:0] dmem_daddr_final     = vec_active ? vec_daddr : alu_result_mem;
    wire [31:0] dmem_wdata_final     = vec_active ? vec_wdata : rdata2_mem;
    wire        dmem_mem_read_final  = vec_active ? vec_mem_read_en  : (mem_read_en_mem && !is_msip_addr_mem && !is_led_addr_mem && !is_result_addr_mem && !is_done_addr_mem && !is_uart_rx_addr_mem && !is_uart_tx_addr_mem && !is_uart_busy_addr_mem && !is_mtime_any_addr_mem && !is_btn_addr_mem && !is_switch_addr_mem);
    wire        dmem_mem_write_final = vec_active ? vec_mem_write_en : (mem_write_en_mem && !is_msip_addr_mem && !is_led_addr_mem && !is_result_addr_mem && !is_done_addr_mem && !is_uart_rx_addr_mem && !is_uart_tx_addr_mem && !is_uart_busy_addr_mem && !is_mtime_any_addr_mem && !is_btn_addr_mem && !is_switch_addr_mem);
    wire [2:0]  dmem_funct3_final    = vec_active ? 3'b010 : funct3_mem;  // 向量存取固定當作word(SW/LW)存取

    assign vec_mem_rdata = mem_rdata_dmem;

    dmem #(
        .MEM_BYTES(DMEM_BYTES)
    ) u_dmem (
        .clk         (clk),
        .daddr        (dmem_daddr_final),
        .wdata       (dmem_wdata_final),
        .mem_read_en    (dmem_mem_read_final),
        .mem_write_en   (dmem_mem_write_final),
        .funct3      (dmem_funct3_final),
        .mem_rdata       (mem_rdata_dmem),
        .chk_addr    (chk_addr_w),
        .chk_rdata   (chk_rdata_w)
    );

    // ---- 完成旗標 (記憶體映射位址 0x07000000)：CPU軟體算完所有pattern後寫1觸發檢查器 ----
    assign is_done_addr_mem = (alu_result_mem == 32'h07000000);
    reg  done_flag;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done_flag <= 1'b0;
        end else if (mem_write_en_mem && is_done_addr_mem) begin
            done_flag <= rdata2_mem[0];
        end
    end

    // ---- 獨立硬體自動驗證檢查器：偵測done_flag，自動讀BRAM比對golden值 ----
    auto_checker u_auto_checker (
        .clk       (clk),
        .rst_n     (rst_n),
        .done      (done_flag),
        .chk_addr  (chk_addr_w),
        .chk_rdata (chk_rdata_w),
        .pass_led  (pass_led)
    );

    // 讀取 mux：msip/led 位址讀回目前狀態，其餘走 dmem 正常路徑
    always @(*) begin
        if (is_msip_addr_mem && mem_read_en_mem)
            mem_rdata = {31'b0, msip_reg};
        else if (is_led_addr_mem && mem_read_en_mem)
            mem_rdata = {24'b0, led_reg};
        else if (is_result_addr_mem && mem_read_en_mem)
            mem_rdata = result_reg;
        else if (is_done_addr_mem && mem_read_en_mem)
            mem_rdata = {31'b0, done_flag};
        else if (is_uart_rx_addr_mem && mem_read_en_mem)
            mem_rdata = {24'b0, uart_rx_data_reg};
        else if (is_uart_busy_addr_mem && mem_read_en_mem)
            mem_rdata = {31'b0, uart_tx_busy};
        else if (is_mtime_any_addr_mem && mem_read_en_mem)
            mem_rdata = mtime_rdata;
        else if (is_btn_addr_mem && mem_read_en_mem)
            mem_rdata = {31'b0, btn_s0_pending};
        else if (is_switch_addr_mem && mem_read_en_mem)
            mem_rdata = {24'b0, switches_sync1};
        else
            mem_rdata = mem_rdata_dmem;
    end

    // =========================================================================
    // [MEM/WB pipeline register]
    // =========================================================================
    wire [31:0] alu_result_wb, mem_rdata_wb, imm_u_wb, pc_plus4_wb, csr_rdata_wb;
    wire [2:0]  MemtoReg_wb;

    wire [31:0] vl_result_wb;
    mem_wb_register u_mem_wb_register (
        .clk(clk), .rst_n(rst_n),
        .flush(1'b0),
        .alu_result_in(alu_result_mem), .mem_rdata_in(mem_rdata),
        .imm_u_in(imm_u_mem), .pc_plus4_in(pc_plus4_mem), .csr_rdata_in(csr_rdata_mem),
        .vl_result_in(vl_result_mem),
        .rd_in(rd_mem),
        .reg_write_en_in(reg_write_en_mem), .MemtoReg_in(MemtoReg_mem),
        .alu_result_o(alu_result_wb), .mem_rdata_o(mem_rdata_wb),
        .imm_u_o(imm_u_wb), .pc_plus4_o(pc_plus4_wb), .csr_rdata_o(csr_rdata_wb),
        .vl_result_o(vl_result_wb),
        .rd_o(rd_wb),
        .reg_write_en_o(reg_write_en_wb), .MemtoReg_o(MemtoReg_wb)
    );

    // =========================================================================
    // [Write Back (WB) 階段]
    // =========================================================================
    writeback_mux u_writeback_mux (
        .alu_result  (alu_result_wb),
        .mem_rdata   (mem_rdata_wb),
        .pc_plus4    (pc_plus4_wb),
        .imm_u       (imm_u_wb),
        .csr_rdata   (csr_rdata_wb),
        .vl_result   (vl_result_wb),
        .MemtoReg    (MemtoReg_wb),
        .wb_data     (wb_data)
    );

endmodule