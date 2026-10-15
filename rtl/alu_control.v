module alu_control(
    input  [1:0] ALUOp,
    input  [2:0] funct3,
    input  [6:0] funct7,

    output reg [3:0] alu_ctrl
);

//==============================
// ALU Control Encoding
//==============================
// 0000 : ADD
// 0001 : SUB
// 0010 : AND
// 0011 : OR
// 0100 : XOR
// 0101 : SLT
// 0110 : SLL
// 0111 : SRL
// 1000 : SRA
// 1001 : SLTU
//==============================

always @(*) begin

    case(ALUOp)

    //--------------------------------------------------
    // Load / Store
    //--------------------------------------------------
    2'b00: begin
        alu_ctrl = 4'b0000;   // ADD
    end

    //--------------------------------------------------
    // Branch
    //--------------------------------------------------
    2'b01: begin
        alu_ctrl = 4'b0001;   // SUB
    end

    //--------------------------------------------------
    // R-Type
    //--------------------------------------------------
    2'b10: begin

        case(funct3)

        // ADD / SUB
        3'b000: begin
            if(funct7 == 7'b0100000)
                alu_ctrl = 4'b0001;   // SUB
            else
                alu_ctrl = 4'b0000;   // ADD
        end

        // SLL
        3'b001:
            alu_ctrl = 4'b0110;

        // SLT
        3'b010:
            alu_ctrl = 4'b0101;

        // SLTU
        3'b011:
            alu_ctrl = 4'b1001;

        // XOR
        3'b100:
            alu_ctrl = 4'b0100;

        // SRL / SRA
        3'b101: begin
            if(funct7 == 7'b0100000)
                alu_ctrl = 4'b1000;   // SRA
            else
                alu_ctrl = 4'b0111;   // SRL
        end

        // OR
        3'b110:
            alu_ctrl = 4'b0011;

        // AND
        3'b111:
            alu_ctrl = 4'b0010;

        default:
            alu_ctrl = 4'b0000;

        endcase

    end

    //--------------------------------------------------
    // I-Type Arithmetic
    //--------------------------------------------------
    2'b11: begin

        case(funct3)

        // ADDI
        3'b000:
            alu_ctrl = 4'b0000;

        // SLTI
        3'b010:
            alu_ctrl = 4'b0101;

        // SLTIU
        3'b011:
            alu_ctrl = 4'b1001;

        // XORI
        3'b100:
            alu_ctrl = 4'b0100;

        // ORI
        3'b110:
            alu_ctrl = 4'b0011;

        // ANDI
        3'b111:
            alu_ctrl = 4'b0010;

        // SLLI
        3'b001:
            alu_ctrl = 4'b0110;

        // SRLI / SRAI
        3'b101: begin
            if(funct7 == 7'b0100000)
                alu_ctrl = 4'b1000;   // SRAI
            else
                alu_ctrl = 4'b0111;   // SRLI
        end

        default:
            alu_ctrl = 4'b0000;

        endcase

    end

    //--------------------------------------------------
    // Default
    //--------------------------------------------------
    default: begin
        alu_ctrl = 4'b0000;
    end

    endcase

end

endmodule
