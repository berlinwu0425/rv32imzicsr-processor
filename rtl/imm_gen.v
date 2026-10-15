module imm_gen(
    input  [31:0] inst,
    output reg [31:0] imm,
    output reg [31:0] imm_b,
    output reg [31:0] imm_j,
    output reg [31:0] imm_u
);

always @(*) begin
    // Initialize all outputs
    imm = 32'b0;
    imm_b = 32'b0;
    imm_j = 32'b0; 
    imm_u = 32'b0;

    case (inst[6:0])

        // I-type
        7'b0010011, // addi
        7'b0000011, // lw
        7'b1100111: // jalr
            //把 12-bit 的 immediate 做 Sign Extension（符號延伸）成 32-bit。
            imm = {{20{inst[31]}}, inst[31:20]};

        // S-type
        7'b0100011:
            imm = {{20{inst[31]}},
                inst[31:25],
                inst[11:7]};

        // B-type
        7'b1100011:
            imm_b = {{19{inst[31]}},
                inst[31],
                inst[7],
                inst[30:25],
                inst[11:8],
                1'b0};

        // J-type
        7'b1101111:
            imm_j = {{11{inst[31]}},
                inst[31],
                inst[19:12],
                inst[20],
                inst[30:21],
                1'b0};
                

        // U-type
        7'b0110111, // lui
        7'b0010111: // auipc
            imm_u = {inst[31:12], 12'b0};

        default:begin

            imm = 32'b0;
            imm_b = 32'b0;
            imm_j = 32'b0; 
            imm_u = 32'b0;
        end
    endcase
end

endmodule
