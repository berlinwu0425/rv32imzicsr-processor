module forwarding_unit (
    input  wire        ex_mem_reg_write,  // EX/MEM 那條指令是否要寫回暫存器
    input  wire [4:0]  ex_mem_rd,         // EX/MEM 那條指令的目的暫存器

    input  wire        mem_wb_reg_write,  // MEM/WB 那條指令是否要寫回暫存器
    input  wire [4:0]  mem_wb_rd,         // MEM/WB 那條指令的目的暫存器

    input  wire [4:0]  id_ex_rs1,         // 目前在EX階段的指令，其rs1
    input  wire [4:0]  id_ex_rs2,         // 目前在EX階段的指令，其rs2

    output reg [1:0]  forward_a,         // 00=不轉發 01=從EX/MEM轉發 10=從MEM/WB轉發
    output reg [1:0]  forward_b
);

    // EX/MEM 的優先權比 MEM/WB 高，因為EX/MEM是比較新的結果
    // (如果兩者rd剛好都跟id_ex_rs1相同，代表有連續兩條指令都寫同一個暫存器，
    //  這時候應該採用比較新的EX/MEM那個值)
        always @(*) begin
        if (ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs1)) begin
            forward_a = 2'b01;
        end else if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs1)) begin
            forward_a = 2'b10;
        end else begin
            forward_a = 2'b00;
        end
    end
        always @(*) begin
        if (ex_mem_reg_write && (ex_mem_rd != 5'b0) && (ex_mem_rd == id_ex_rs2)) begin
            forward_b = 2'b01;
        end else if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex_rs2)) begin
            forward_b = 2'b10;
        end else begin
            forward_b = 2'b00;
        end
    end

endmodule