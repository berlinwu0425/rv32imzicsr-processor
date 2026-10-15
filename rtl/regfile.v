module regfile(
    input clk,
    input rst_n,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] wb_data,
    input reg_write_en,
    output [31:0] rdata1,
    output [31:0] rdata2
);
reg [31:0] registry[0:31];
integer i;

// write-first bypass:
// 如果本週期 WB 正在寫入的暫存器，剛好就是這個週期要讀取的 rs1/rs2，
// 要直接把即將寫入的新值(wb_data)繞過去，而不是讀到還沒更新的舊值
// (因為 registry[rd] <= wb_data 要等下一個 posedge 才會真的生效)
assign rdata1 = (rs1 == 0) ? 0 :
                (reg_write_en && rd != 0 && rd == rs1) ? wb_data :
                                                          registry[rs1];
assign rdata2 = (rs2 == 0) ? 0 :
                (reg_write_en && rd != 0 && rd == rs2) ? wb_data :
                                                          registry[rs2];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < 32; i = i + 1)
            registry[i] <= 0;
    end
    else if (reg_write_en && rd != 0) begin
        registry[rd] <= wb_data;
    end
end
endmodule
