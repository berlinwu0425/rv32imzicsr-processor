module if_id_register (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,        // 1 = 凍結（load-use hazard 用，目前先接死0）
    input  wire        flush,        // 1 = 清空成NOP（branch/jump redirect用）

    input  wire [31:0] pc_out_in,
    input  wire [31:0] inst_in,
    input  wire        predicted_taken_in,     // IF階段查詢分支預測器的結果
    input  wire [31:0] predicted_target_in,    // 猜「跳」的話，目標位址

    output reg  [31:0] pc_out_o,
    output reg  [31:0] inst_o,
    output reg          predicted_taken_o,
    output reg  [31:0] predicted_target_o
);

    localparam [31:0] NOP = 32'h00000013;  // addi x0, x0, 0

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_out_o           <= 32'b0;
            inst_o             <= NOP;
            predicted_taken_o  <= 1'b0;
            predicted_target_o <= 32'b0;
        end
        else if (flush) begin
            pc_out_o           <= 32'b0;
            inst_o             <= NOP;
            predicted_taken_o  <= 1'b0;   // bubble一定不能誤判成"有預測跳"
            predicted_target_o <= 32'b0;
        end
        else if (stall) begin
            pc_out_o           <= pc_out_o;
            inst_o             <= inst_o;
            predicted_taken_o  <= predicted_taken_o;
            predicted_target_o <= predicted_target_o;
        end
        else begin
            pc_out_o           <= pc_out_in;
            inst_o             <= inst_in;
            predicted_taken_o  <= predicted_taken_in;
            predicted_target_o <= predicted_target_in;
        end
    end

`ifdef FORMAL
    // ---- 形式驗證性質：只要rst_n是0，輸出就必須恆為乾淨的bubble ----
    // 因為是非同步reset，這個性質必須是"位準"檢查(只要rst_n=0就要成立)，
    // 不是"邊緣"檢查，這樣才符合非同步reset的真實語意：
    // rst_n只要維持低電位，不管維持多久，輸出都要一直是bubble狀態
    always @(*) begin
        if (!rst_n) begin
            assert (pc_out_o == 32'b0);
            assert (inst_o == NOP);
            assert (predicted_taken_o == 1'b0);
            assert (predicted_target_o == 32'b0);
        end
    end
`endif

endmodule
