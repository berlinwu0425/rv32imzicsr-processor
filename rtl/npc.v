module npc (
    input  wire [31:0] pc_out,       // 當前的 PC
    input  wire [31:0] imm_b,        // 來自 Branch 的立即值
    input  wire [31:0] imm_j,        // 來自 Jump (JAL) 的立即值
    input  wire [31:0] alu_result,   // 來自主 ALU (給 JALR 用的)
    
    // 控制訊號
    input  wire        branch_en,    // 是否為 Branch 指令
    input  wire        branch_taken, // Branch 條件是否成立
    input  wire        jump_en,       // 是否為 JAL 指令
    input  wire        jalr_en,      // 是否為 JALR 指令

    output reg  [31:0] next_pc,      // 算好並選好的下一個 PC
    output wire [31:0] pc_plus4     // 獨立輸出給 Write-back (JAL/JALR 存 return address 用)
);

    // 1. 內部加法器 (Adders)直接在這裡宣告與計算
    assign pc_plus4 = pc_out + 32'd4;
    
    wire [31:0] branch_target = pc_out + imm_b;
    wire [31:0] jump_target = pc_out + imm_j;

    // 2. 決定 next_pc 的大 MUX
    always @(*) begin
        if (jalr_en) begin
            // JALR: 直接吃 ALU 算好的 (rs1 + imm_i) 並把最低位設為 0
            next_pc = {alu_result[31:1], 1'b0}; 
        end
        else if (jump_en) begin
            // JAL: PC + J-Type 立即值
            next_pc = jump_target;
        end
        else if (branch_en && branch_taken) begin
            // Branch 條件成立: PC + B-Type 立即值
            next_pc = branch_target;
        end
        else begin
            // 常態：沒跳躍就繼續執行下一行
            next_pc = pc_plus4;
        end
    end

endmodule