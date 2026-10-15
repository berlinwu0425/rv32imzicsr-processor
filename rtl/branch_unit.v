module branch_unit(
    input  [31:0] rdata1,
    input  [31:0] rdata2,
    input  [2:0]  funct3,

    output reg    branch_taken
);

always @(*) begin

    case (funct3)

        //=========================
        // BEQ
        //=========================
        3'b000: begin
            branch_taken = (rdata1 == rdata2);
        end

        //=========================
        // BNE
        //=========================
        3'b001: begin
            branch_taken = (rdata1 != rdata2);
        end

        //=========================
        // BLT (Signed)
        //=========================
        3'b100: begin
            branch_taken = ($signed(rdata1) < $signed(rdata2));
        end

        //=========================
        // BGE (Signed)
        //=========================
        3'b101: begin
            branch_taken = ($signed(rdata1) >= $signed(rdata2));
        end

        //=========================
        // BLTU (Unsigned)
        //=========================
        3'b110: begin
        branch_taken = $unsigned(rdata1) < $unsigned(rdata2);
        end

        //=========================
        // BGEU (Unsigned)
        //=========================
        // BGEU
        3'b111: begin
        branch_taken = $unsigned(rdata1) >= $unsigned(rdata2);
        end

        //=========================
        // Default
        //=========================
        default: begin
            branch_taken = 1'b0;
        end

    endcase

end

endmodule
