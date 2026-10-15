module alu(
    input  [31:0] alu_a,
    input  [31:0] alu_b,
    input  [3:0]  alu_ctrl,

    output reg [31:0] alu_result
);

always @(*) begin

    case (alu_ctrl)

        //====================
        // ADD
        //====================
        4'b0000: alu_result = alu_a + alu_b;

        //====================
        // SUB
        //====================
        4'b0001: alu_result = alu_a - alu_b;

        //====================
        // AND
        //====================
        4'b0010: alu_result = alu_a & alu_b;

        //====================
        // OR
        //====================
        4'b0011: alu_result = alu_a | alu_b;

        //====================
        // XOR
        //====================
        4'b0100: alu_result = alu_a ^ alu_b;

        //====================
        // SLT (signed)
        //====================
        4'b0101: alu_result = ($signed(alu_a) < $signed(alu_b)) ? 1 : 0;

        //====================
        // SLTU (unsigned)
        //====================
        4'b1001: alu_result = ($unsigned(alu_a) < $unsigned(alu_b))? 32'd1 : 32'd0;

        //====================
        // SLL
        //====================
        4'b0110: alu_result = alu_a << alu_b[4:0];

        //====================
        // SRL
        //====================
        4'b0111: alu_result = alu_a >> alu_b[4:0];

        //====================
        // SRA
        //====================
        4'b1000: alu_result = $signed(alu_a) >>> alu_b[4:0];

        //====================
        // default
        //====================
        default: alu_result = 32'b0;

    endcase

end

endmodule
