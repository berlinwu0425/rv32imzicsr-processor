module ex_mem_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        flush,        // 保留給例外處理等擴充情境使用
    input  wire [31:0] alu_result_in,
    input  wire [31:0] rdata2_in,      // 給 SW/SB/SH 存記憶體用
    input  wire [31:0] imm_u_in,       // 給 LUI 直接寫回用
    input  wire [31:0] pc_plus4_in,    // 給 JAL/JALR 的 link value
    input  wire [31:0] csr_rdata_in,   // 給 CSR 指令的舊值寫回用
    input  wire [31:0] vl_result_in,   // 給 vsetvl 的回傳值寫回用
    input  wire [4:0]  rd_in,
    input  wire [2:0]  funct3_in,      // 給 MEM 判斷 LB/LH/LW/SB/SH/SW
    input  wire        mem_read_en_in,
    input  wire        mem_write_en_in,
    input  wire        reg_write_en_in,
    input  wire [2:0]  MemtoReg_in,
    output reg  [31:0] alu_result_o,
    output reg  [31:0] rdata2_o,
    output reg  [31:0] imm_u_o,
    output reg  [31:0] pc_plus4_o,
    output reg  [31:0] csr_rdata_o,
    output reg  [31:0] vl_result_o,
    output reg  [4:0]  rd_o,
    output reg  [2:0]  funct3_o,
    output reg          mem_read_en_o,
    output reg          mem_write_en_o,
    output reg          reg_write_en_o,
    output reg  [2:0]   MemtoReg_o
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            alu_result_o    <= 32'b0;
            rdata2_o        <= 32'b0;
            imm_u_o         <= 32'b0;
            pc_plus4_o      <= 32'b0;
            csr_rdata_o     <= 32'b0;
            vl_result_o     <= 32'b0;
            rd_o            <= 5'b0;
            funct3_o        <= 3'b0;
            mem_read_en_o   <= 1'b0;   // 確保bubble不會讀DMEM
            mem_write_en_o  <= 1'b0;   // 確保bubble不會寫DMEM
            reg_write_en_o  <= 1'b0;   // 確保bubble不會寫回暫存器
            MemtoReg_o      <= 3'b0;
        end
        else begin
            alu_result_o    <= alu_result_in;
            rdata2_o        <= rdata2_in;
            imm_u_o         <= imm_u_in;
            pc_plus4_o      <= pc_plus4_in;
            csr_rdata_o     <= csr_rdata_in;
            vl_result_o     <= vl_result_in;
            rd_o            <= rd_in;
            funct3_o        <= funct3_in;
            mem_read_en_o   <= mem_read_en_in;
            mem_write_en_o  <= mem_write_en_in;
            reg_write_en_o  <= reg_write_en_in;
            MemtoReg_o      <= MemtoReg_in;
        end
    end
endmodule
