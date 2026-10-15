module id_ex_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        flush,        // branch/jump redirect、trap 等會觸發，清空成bubble
    input  wire        stall,        // 向量單元忙碌期間用，保持內容不變(不清空、不吃新指令)

    // 資料
    input  wire [31:0] pc_out_in,
    input  wire [31:0] rdata1_in,
    input  wire [31:0] rdata2_in,
    input  wire [31:0] imm_in,
    input  wire [31:0] imm_b_in,
    input  wire [31:0] imm_j_in,
    input  wire [31:0] imm_u_in,
    input  wire [4:0]  rd_in,
    input  wire [4:0]  rs1_in,
    input  wire [4:0]  rs2_in,
    input  wire [2:0]  funct3_in,
    input  wire [6:0]  funct7_in,
    input  wire [11:0] csr_addr_in,
    input  wire        predicted_taken_in,
    input  wire [31:0] predicted_target_in,

    // 控制訊號
    input  wire        branch_en_in,
    input  wire        jump_en_in,
    input  wire        jalr_en_in,
    input  wire        mem_read_en_in,
    input  wire        mem_write_en_in,
    input  wire        reg_write_en_in,
    input  wire        ALUSrc_in,
    input  wire        ALUSrcA_in,
    input  wire        ALUAUIPC_in,
    input  wire [1:0]  ALUOp_in,
    input  wire [2:0]  MemtoReg_in,
    input  wire        is_ecall_in,
    input  wire        is_ebreak_in,
    input  wire        is_mret_in,
    input  wire        is_csr_in,
    input  wire        csr_imm_in,
    input  wire        is_vsetvl_in,
    input  wire        is_vec_op_in,

    output reg  [31:0] pc_out_o,
    output reg  [31:0] rdata1_o,
    output reg  [31:0] rdata2_o,
    output reg  [31:0] imm_o,
    output reg  [31:0] imm_b_o,
    output reg  [31:0] imm_j_o,
    output reg  [31:0] imm_u_o,
    output reg  [4:0]  rd_o,
    output reg  [4:0]  rs1_o,
    output reg  [4:0]  rs2_o,
    output reg  [2:0]  funct3_o,
    output reg  [6:0]  funct7_o,
    output reg  [11:0] csr_addr_o,

    output reg          branch_en_o,
    output reg          jump_en_o,
    output reg          jalr_en_o,
    output reg          mem_read_en_o,
    output reg          mem_write_en_o,
    output reg          reg_write_en_o,
    output reg          ALUSrc_o,
    output reg          ALUSrcA_o,
    output reg          ALUAUIPC_o,
    output reg  [1:0]   ALUOp_o,
    output reg  [2:0]   MemtoReg_o,
    output reg           is_ecall_o,
    output reg           is_ebreak_o,
    output reg           is_mret_o,
    output reg           is_csr_o,
    output reg           csr_imm_o,
    output reg           is_vsetvl_o,
    output reg           is_vec_op_o,
    output reg           predicted_taken_o,
    output reg  [31:0]  predicted_target_o
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            pc_out_o        <= 32'b0;
            rdata1_o        <= 32'b0;
            rdata2_o        <= 32'b0;
            imm_o           <= 32'b0;
            imm_b_o         <= 32'b0;
            imm_j_o         <= 32'b0;
            imm_u_o         <= 32'b0;
            rd_o            <= 5'b0;
            rs1_o           <= 5'b0;
            rs2_o           <= 5'b0;
            funct3_o        <= 3'b0;
            funct7_o        <= 7'b0;
            csr_addr_o      <= 12'b0;

            branch_en_o     <= 1'b0;   // 確保bubble不會誤判branch
            jump_en_o       <= 1'b0;   // 確保bubble不會誤跳轉
            jalr_en_o       <= 1'b0;
            mem_read_en_o   <= 1'b0;   // 確保bubble不會讀DMEM
            mem_write_en_o  <= 1'b0;   // 確保bubble不會寫DMEM
            reg_write_en_o  <= 1'b0;   // 確保bubble不會寫回暫存器
            ALUSrc_o        <= 1'b0;
            ALUSrcA_o       <= 1'b0;
            ALUAUIPC_o      <= 1'b0;
            ALUOp_o         <= 2'b0;
            MemtoReg_o      <= 3'b0;
            is_ecall_o      <= 1'b0;   // 確保bubble不會誤觸發trap
            is_ebreak_o     <= 1'b0;
            is_mret_o       <= 1'b0;
            is_csr_o        <= 1'b0;
            csr_imm_o       <= 1'b0;
            is_vsetvl_o     <= 1'b0;   // 確保bubble不會誤觸發向量單元
            is_vec_op_o     <= 1'b0;
            predicted_taken_o  <= 1'b0;   // bubble/flush時不能誤判成有預測跳
            predicted_target_o <= 32'b0;
        end
        else if (stall) begin
            // 向量單元忙碌期間，EX階段保持原地不動，不清空也不吃新指令
            pc_out_o        <= pc_out_o;
            rdata1_o        <= rdata1_o;
            rdata2_o        <= rdata2_o;
            imm_o           <= imm_o;
            imm_b_o         <= imm_b_o;
            imm_j_o         <= imm_j_o;
            imm_u_o         <= imm_u_o;
            rd_o            <= rd_o;
            rs1_o           <= rs1_o;
            rs2_o           <= rs2_o;
            funct3_o        <= funct3_o;
            funct7_o        <= funct7_o;
            csr_addr_o      <= csr_addr_o;
            branch_en_o     <= branch_en_o;
            jump_en_o       <= jump_en_o;
            jalr_en_o       <= jalr_en_o;
            mem_read_en_o   <= mem_read_en_o;
            mem_write_en_o  <= mem_write_en_o;
            reg_write_en_o  <= reg_write_en_o;
            ALUSrc_o        <= ALUSrc_o;
            ALUSrcA_o       <= ALUSrcA_o;
            ALUAUIPC_o      <= ALUAUIPC_o;
            ALUOp_o         <= ALUOp_o;
            MemtoReg_o      <= MemtoReg_o;
            is_ecall_o      <= is_ecall_o;
            is_ebreak_o     <= is_ebreak_o;
            is_mret_o       <= is_mret_o;
            is_csr_o        <= is_csr_o;
            csr_imm_o       <= csr_imm_o;
            is_vsetvl_o     <= is_vsetvl_o;
            is_vec_op_o     <= is_vec_op_o;
            predicted_taken_o  <= predicted_taken_o;
            predicted_target_o <= predicted_target_o;
        end
        else begin
            pc_out_o        <= pc_out_in;
            rdata1_o        <= rdata1_in;
            rdata2_o        <= rdata2_in;
            imm_o           <= imm_in;
            imm_b_o         <= imm_b_in;
            imm_j_o         <= imm_j_in;
            imm_u_o         <= imm_u_in;
            rd_o            <= rd_in;
            rs1_o           <= rs1_in;
            rs2_o           <= rs2_in;
            funct3_o        <= funct3_in;
            funct7_o        <= funct7_in;
            csr_addr_o      <= csr_addr_in;

            branch_en_o     <= branch_en_in;
            jump_en_o       <= jump_en_in;
            jalr_en_o       <= jalr_en_in;
            mem_read_en_o   <= mem_read_en_in;
            mem_write_en_o  <= mem_write_en_in;
            reg_write_en_o  <= reg_write_en_in;
            ALUSrc_o        <= ALUSrc_in;
            ALUSrcA_o       <= ALUSrcA_in;
            ALUAUIPC_o      <= ALUAUIPC_in;
            ALUOp_o         <= ALUOp_in;
            MemtoReg_o      <= MemtoReg_in;
            is_ecall_o      <= is_ecall_in;
            is_ebreak_o     <= is_ebreak_in;
            is_mret_o       <= is_mret_in;
            is_csr_o        <= is_csr_in;
            csr_imm_o       <= csr_imm_in;
            is_vsetvl_o     <= is_vsetvl_in;
            is_vec_op_o     <= is_vec_op_in;
            predicted_taken_o  <= predicted_taken_in;
            predicted_target_o <= predicted_target_in;
        end
    end
endmodule
