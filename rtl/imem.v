module imem #(
    parameter MEM_WORDS = 1048576,   // 預設維持模擬用大小，不影響既有RISCOF驗證流程
    parameter INIT_FILE = ""          // 空字串=不做內部初始化(模擬時仍靠testbench外部$readmemh載入)
                                       // FPGA合成時指定實際.hex檔路徑，讓Vivado把內容當BRAM初始值
)(
    input  [31:0] iaddr,
    output [31:0] inst
);
    localparam ADDR_BITS = $clog2(MEM_WORDS);
    reg [31:0] inst_mem [0:MEM_WORDS-1];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, inst_mem);
        end
    end

    // RISC-V 的 PC 是 Byte Address，inst_mem 陣列以 Word(32-bit) 為單位索引
    wire [ADDR_BITS-1:0] word_addr = iaddr[ADDR_BITS+1:2];
    assign inst = inst_mem[word_addr];
endmodule
