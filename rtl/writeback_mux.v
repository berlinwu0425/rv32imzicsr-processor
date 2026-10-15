module writeback_mux(
    input  [31:0] alu_result,
    input  [31:0] mem_rdata,
    input  [31:0] pc_plus4,
    input  [31:0] imm_u,
    input  [31:0] csr_rdata,
    input  [31:0] vl_result,     // vsetvl 的回傳值 (向量單元目前的 vl)
    input  [2:0]  MemtoReg,
    output reg [31:0] wb_data
);
always @(*) begin
    case(MemtoReg)
        // ALU result
        3'b000:
            wb_data = alu_result;
        // Data Memory result
        3'b001:
            wb_data = mem_rdata;
        // PC + 4 (JAL / JALR)
        3'b010:
            wb_data = pc_plus4;
        // Immediate (LUI)
        3'b011:
            wb_data = imm_u;
        // CSR 讀出的舊值 (csrrw/csrrs/csrrc...)
        3'b100:
            wb_data = csr_rdata;
        // vsetvl 回傳值
        3'b101:
            wb_data = vl_result;
        default:
            wb_data = 32'b0;
    endcase
end
endmodule
