module dmem #(
    parameter MEM_BYTES = 4194304   // 預設維持模擬用大小(4MB)，不影響既有RISCOF驗證流程
)(
    input  wire        clk,
    input  wire [31:0] daddr,       // 來自 ALU 的記憶體位址
    input  wire [31:0] wdata,      // 來自暫存器 rdata2 的寫入資料
    input  wire        mem_read_en,   // 讀取啟用
    input  wire        mem_write_en,  // 寫入啟用
    input  wire [2:0]  funct3,     // 存取寬度控制

    output reg  [31:0] mem_rdata,      // 讀出的資料

    // ---- 第二個唯讀埠，給獨立的硬體驗證檢查器用，不影響CPU本身的讀寫路徑 ----
    input  wire [31:0] chk_addr,
    output wire [31:0] chk_rdata
);

    localparam WORDS = (MEM_BYTES + 3) / 4;      // 以32-bit word為單位的記憶體大小
    localparam WORD_ADDR_BITS = $clog2(WORDS);

    // ==========================================
    // 0. 宣告記憶體本體：改成以 word(32-bit) 為單位，方便Vivado推斷成Block RAM
    // ==========================================
    reg [31:0] memory [0:WORDS-1];

    // byte offset -> word index + word內的byte offset
    wire [WORD_ADDR_BITS-1:0] word_addr = daddr[WORD_ADDR_BITS+1:2];
    wire [1:0] byte_off = daddr[1:0];

    // ==========================================
    // 1. 寫入邏輯 (Write) - Synchronous，先讀出整個word、蓋掉需要的byte(s)、寫回整個word
    // ==========================================
    reg [31:0] word_rd;
    always @(*) begin
        word_rd = memory[word_addr];
    end

    reg [31:0] word_wr;
    always @(*) begin
        word_wr = word_rd;
        case (funct3)
            // SB (Store Byte) - 只蓋掉對應的那1個byte
            3'b000: begin
                case (byte_off)
                    2'b00: word_wr[7:0]   = wdata[7:0];
                    2'b01: word_wr[15:8]  = wdata[7:0];
                    2'b10: word_wr[23:16] = wdata[7:0];
                    2'b11: word_wr[31:24] = wdata[7:0];
                endcase
            end
            // SH (Store Halfword) - 蓋掉對應的2個byte (假設對齊到偶數byte，一般編譯器會保證)
            3'b001: begin
                if (byte_off[1] == 1'b0)
                    word_wr[15:0]  = wdata[15:0];
                else
                    word_wr[31:16] = wdata[15:0];
            end
            // SW (Store Word) - 整個word直接覆蓋
            3'b010: begin
                word_wr = wdata;
            end
            default: word_wr = word_rd;
        endcase
    end

    always @(posedge clk) begin
        if (mem_write_en) begin
            memory[word_addr] <= word_wr;
        end
    end

    // ==========================================
    // 2. 讀取邏輯 (Read) - Combinational，從整個word裡取出需要的byte(s)並做符號延伸
    // ==========================================
    always @(*) begin
        mem_rdata = 32'b0;

        if (mem_read_en) begin
            case (funct3)
                // LB (Load Byte) - 符號延伸
                3'b000: begin
                    case (byte_off)
                        2'b00: mem_rdata = { {24{word_rd[7]}},  word_rd[7:0]   };
                        2'b01: mem_rdata = { {24{word_rd[15]}}, word_rd[15:8]  };
                        2'b10: mem_rdata = { {24{word_rd[23]}}, word_rd[23:16] };
                        2'b11: mem_rdata = { {24{word_rd[31]}}, word_rd[31:24] };
                    endcase
                end
                // LH (Load Halfword) - 符號延伸
                3'b001: begin
                    if (byte_off[1] == 1'b0)
                        mem_rdata = { {16{word_rd[15]}}, word_rd[15:0]  };
                    else
                        mem_rdata = { {16{word_rd[31]}}, word_rd[31:16] };
                end
                // LW (Load Word)
                3'b010: begin
                    mem_rdata = word_rd;
                end
                // LBU (Load Byte Unsigned)
                3'b100: begin
                    case (byte_off)
                        2'b00: mem_rdata = { 24'b0, word_rd[7:0]   };
                        2'b01: mem_rdata = { 24'b0, word_rd[15:8]  };
                        2'b10: mem_rdata = { 24'b0, word_rd[23:16] };
                        2'b11: mem_rdata = { 24'b0, word_rd[31:24] };
                    endcase
                end
                // LHU (Load Halfword Unsigned)
                3'b101: begin
                    if (byte_off[1] == 1'b0)
                        mem_rdata = { 16'b0, word_rd[15:0]  };
                    else
                        mem_rdata = { 16'b0, word_rd[31:16] };
                end
                default: mem_rdata = 32'b0;
            endcase
        end
    end

    // ---- 檢查器用的第二讀取埠：組合邏輯直接讀 memory 陣列，跟CPU的讀寫互不干擾 ----
    wire [WORD_ADDR_BITS-1:0] chk_word_addr = chk_addr[WORD_ADDR_BITS+1:2];
    assign chk_rdata = memory[chk_word_addr];

`ifdef FORMAL
    // ---- 形式驗證性質：word對齊的word寫入，下一拍同位址讀取，必須讀回剛寫入的值 ----
    // 限定word對齊(byte_off==0)且funct3=SW(3'b010)，避免處理byte/halfword部分寫入的複雜情況，
    // 先驗證最基本、最常見的情境：完整word寫入的讀寫一致性
    reg [31:0] f_wdata_reg;
    reg [31:0] f_waddr_reg;
    reg        f_wrote_last_cycle;

    initial f_wrote_last_cycle = 1'b0;

    always @(posedge clk) begin
        // 記錄"上一拍"是否做了一次乾淨的word寫入，以及寫了什麼、寫到哪
        f_wrote_last_cycle <= (mem_write_en && funct3 == 3'b010 && daddr[1:0] == 2'b00);
        f_wdata_reg         <= wdata;
        f_waddr_reg         <= daddr;

        // 核心性質：如果上一拍做了乾淨word寫入，這一拍對同一位址讀取(word/SW)，
        // 讀回的值必須恰好等於上一拍寫入的值
        if (f_wrote_last_cycle && mem_read_en && funct3 == 3'b010 && daddr == f_waddr_reg) begin
            assert (mem_rdata == f_wdata_reg);
        end
    end
`endif

endmodule
