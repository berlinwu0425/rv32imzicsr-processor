module decoder(
    input  [31:0] inst,
    output reg [6:0] opcode,
    output reg [4:0] rd,
    output reg [2:0] funct3,
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [6:0] funct7,
    output reg [11:0] csr_addr   // CSR 位址，SYSTEM 指令(opcode=1110011)專用，即 inst[31:20]
);
always @(*) begin
    opcode   = inst[6:0];
    rd       = inst[11:7];
    funct3   = inst[14:12];
    rs1      = inst[19:15];
    rs2      = inst[24:20];
    funct7   = inst[31:25];
    csr_addr = inst[31:20];
end
endmodule
