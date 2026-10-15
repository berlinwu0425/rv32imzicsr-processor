module control(
    input  [6:0] opcode,
    input  [2:0] funct3,
    input  [11:0] csr_addr,
    output reg reg_write_en,
    output reg mem_read_en,
    output reg mem_write_en,
    output reg branch_en,
    output reg jump_en,
    output reg jalr_en,
    output reg ALUSrc,
    output reg ALUSrcA,          // 0: rs1, 1: PC (AUIPC)
    output reg ALUAUIPC,         // 0: rs1, 1: PC (AUIPC)
    output reg [2:0] MemtoReg,   // 000=ALU 001=MEM 010=PC+4 011=imm_u 100=CSR舊值 101=向量單元(vsetvl)
    output reg [1:0] ALUOp,

    // ---- Zicsr / trap 相關 ----
    output reg is_ecall,
    output reg is_ebreak,
    output reg is_mret,
    output reg is_csr,           // csrrw/csrrs/csrrc/csrrwi/csrrsi/csrrci
    output reg csr_imm,          // 1=立即值版本(csrrwi/csrrsi/csrrci)，rs1欄位當5-bit立即值用

    // ---- 自訂向量擴充 (custom-0 opcode, 0001011) ----
    output reg is_vsetvl,        // vsetvl：走一般管線，單週期完成，結果來自向量單元的vl輸出
    output reg is_vec_op         // vld/vst/vadd.vv/vmul.vv：交給vector_unit接管，主管線視為無害空指令
);
always @(*) begin
    // Default Values
    reg_write_en = 0;
    mem_read_en  = 0;
    mem_write_en = 0;
    branch_en   = 0;
    jump_en     = 0;
    jalr_en     = 0;
    ALUSrc   = 0;
    ALUSrcA  = 0;
    ALUAUIPC = 0;
    MemtoReg = 3'b000;
    ALUOp     = 2'b00;

    is_ecall  = 0;
    is_ebreak = 0;
    is_mret   = 0;
    is_csr    = 0;
    csr_imm   = 0;

    is_vsetvl = 0;
    is_vec_op = 0;

    case(opcode)
        // R-Type
        7'b0110011: begin
            reg_write_en = 1;
            ALUSrc   = 0;
            ALUOp     = 2'b10;
            MemtoReg = 3'b000;
        end
        // I-Type (addi, andi, ori...)
        7'b0010011: begin
            reg_write_en = 1;
            ALUSrc   = 1;
            ALUOp     = 2'b11;
            MemtoReg = 3'b000;
        end
        // Load (lw)
        7'b0000011: begin
            reg_write_en = 1;
            mem_read_en  = 1;
            ALUSrc   = 1;
            ALUOp     = 2'b00;
            MemtoReg = 3'b001;
        end
        // Store (sw)
        7'b0100011: begin
            mem_write_en = 1;
            ALUSrc   = 1;
            ALUOp     = 2'b00;
        end
        // Branch (beq, bne...)
        7'b1100011: begin
            branch_en = 1;
            ALUSrc = 0;
            ALUOp  = 2'b01;
        end
        // Jump
        7'b1101111: begin
            reg_write_en = 1;
            jump_en      = 1;
            MemtoReg = 3'b010;   // PC+4
        end
        // JALR
        7'b1100111: begin
            reg_write_en = 1;
            jalr_en      = 1;
            ALUSrc    = 1;
            MemtoReg = 3'b010;
            ALUOp      = 2'b00;  // rs1 + imm
        end
        // LUI
        7'b0110111: begin
            reg_write_en = 1;
            ALUSrc   = 1;
            ALUOp     = 2'b00;
            MemtoReg = 3'b011;   // imm_u
        end
        // AUIPC
        7'b0010111: begin
            reg_write_en = 1;
            ALUSrcA  = 1;         // ALU A = PC
            ALUSrc   = 1;
            ALUAUIPC = 1;      // ALU B = imm_u
            ALUOp     = 2'b00;
            MemtoReg = 3'b000;
        end
        // SYSTEM (ecall/ebreak/mret/csr指令)
        7'b1110011: begin
            if (funct3 == 3'b000) begin
                // ecall / ebreak / mret，靠 csr_addr 這12 bits區分
                case (csr_addr)
                    12'h000: is_ecall = 1;
                    12'h001: is_ebreak = 1;
                    12'h302: is_mret = 1;
                    default: ; // 其他保留給未來 sret/wfi等，先當nop
                endcase
            end else begin
                // csrrw(001)/csrrs(010)/csrrc(011)/csrrwi(101)/csrrsi(110)/csrrci(111)
                is_csr       = 1;
                reg_write_en = 1;
                MemtoReg     = 3'b100;   // CSR 舊值
                csr_imm      = funct3[2]; // funct3 = 1xx 代表立即值版本
            end
        end
        // custom-0：自訂向量擴充
        7'b0001011: begin
            case (funct3)
                3'b000: begin
                    // vsetvl：走一般管線，單週期完成，rd = 向量單元回傳的實際vl值
                    is_vsetvl    = 1;
                    reg_write_en = 1;
                    MemtoReg     = 3'b101;
                end
                3'b001, 3'b010, 3'b011, 3'b100, 3'b101, 3'b110: begin
                    // vld / vst / vadd.vv / vmul.vv：完全交給vector_unit處理，
                    // 主管線視為無害空指令(不寫GPR、不動dmem的正常路徑)
                    is_vec_op = 1;
                end
                default: ; // 保留給未來擴充
            endcase
        end
        default: begin
        end
    endcase
end
endmodule
