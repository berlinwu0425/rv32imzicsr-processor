module mul_div_unit(
    input  [31:0] a,
    input  [31:0] b,
    input  [2:0]  funct3,
    output reg [31:0] result
);
    // 64-bit 有號/無號的 a, b，供乘法使用
    wire signed [63:0] a_s64 = {{32{a[31]}}, a};
    wire signed [63:0] b_s64 = {{32{b[31]}}, b};
    wire        [63:0] a_u64 = {32'b0, a};
    wire        [63:0] b_u64 = {32'b0, b};

    wire signed [63:0] mul_ss = a_s64 * b_s64;               // signed x signed
    wire        [63:0] mul_uu = a_u64 * b_u64;                // unsigned x unsigned
    wire signed [63:0] mul_su = a_s64 * $signed(b_u64);       // signed x unsigned (b補0視為非負)

    // 有號除法/餘數改用 always block + reg signed 明確計算，
    // 避免三元運算子(?:)混合 signed/unsigned 運算元時型別推斷出錯的陷阱
    reg signed [31:0] div_s_r;
    reg signed [31:0] rem_s_r;
    wire signed [31:0] a_signed = $signed(a);
    wire signed [31:0] b_signed = $signed(b);

    always @(*) begin
        // DIV：除以0回傳全1；溢位(最小負數 / -1)回傳最小負數 (RISC-V規格特例)
        if (b == 32'b0) begin
            div_s_r = -32'sd1;
        end else if ((a == 32'h80000000) && (b == 32'hFFFFFFFF)) begin
            div_s_r = 32'sh80000000;
        end else begin
            div_s_r = a_signed / b_signed;
        end

        // REM：除以0回傳被除數本身；溢位回傳0 (RISC-V規格特例)
        if (b == 32'b0) begin
            rem_s_r = a_signed;
        end else if ((a == 32'h80000000) && (b == 32'hFFFFFFFF)) begin
            rem_s_r = 32'sd0;
        end else begin
            rem_s_r = a_signed % b_signed;
        end
    end

    wire [31:0] div_u = (b == 32'b0) ? 32'hFFFFFFFF : (a / b);
    wire [31:0] rem_u = (b == 32'b0) ? a : (a % b);

    always @(*) begin
        case (funct3)
            3'b000: result = mul_ss[31:0];    // MUL
            3'b001: result = mul_ss[63:32];   // MULH
            3'b010: result = mul_su[63:32];   // MULHSU
            3'b011: result = mul_uu[63:32];   // MULHU
            3'b100: result = div_s_r;         // DIV
            3'b101: result = div_u;           // DIVU
            3'b110: result = rem_s_r;         // REM
            3'b111: result = rem_u;           // REMU
            default: result = 32'b0;
        endcase
    end
endmodule
