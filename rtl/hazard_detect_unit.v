// ==========================================================
// Hazard Detection Unit (load-use hazard)
// ==========================================================
module hazard_detect_unit (
    input  wire        mem_read_en_ex,  // ID/EX 那條指令是否為 Load
    input  wire [4:0]  rd_ex,           // ID/EX 那條指令的目的暫存器

    input  wire [4:0]  rs1_id,          // 目前在 ID 階段解碼的指令，其 rs1
    input  wire [4:0]  rs2_id,          // 目前在 ID 階段解碼的指令，其 rs2

    output wire        hazard_stall     // 1 = 偵測到 load-use hazard，需要stall一拍
);

    // 條件：(1)ID/EX是Load (2)目的暫存器不是x0 (3)剛好是下一條指令要讀的來源
    assign hazard_stall = mem_read_en_ex &&
        (rd_ex != 5'b0) &&
        ((rd_ex == rs1_id) || (rd_ex == rs2_id));

endmodule