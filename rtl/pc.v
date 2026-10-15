module pc (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        pc_write_en,  // 新增的 Enable 訊號 (1=更新, 0=凍結)
    input  wire [31:0] next_pc,
    output reg  [31:0] pc_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 系統重置時，通常將 PC 歸零，或設定為 Boot ROM / 初始記憶體位址
            pc_out <= 32'h80000000; 
        end else if (pc_write_en) begin
            // 只有在 Write Enable 為 1 時，才更新 PC
            pc_out <= next_pc;
        end
        // 當 pc_write_en == 0 時，觸發隱含的 pc_out <= pc_out，保持原值
    end

endmodule