`timescale 1ns / 1ps

// =========================================================================
// mtime/mtimecmp 計時器單元 (RISC-V 官方規格要求兩者皆為64-bit，即使在32-bit CPU上)
// mtime 每個clk自動+1，硬體持續比較 mtime >= mtimecmp，成立時輸出mtip_pending，
// 這個訊號直接反映到 csr_file 的 mip.MTIP，軟體不能直接寫入，只能透過改mtimecmp間接控制。
// =========================================================================
module mtime_unit (
    input  wire        clk,
    input  wire         rst_n,

    // ---- 記憶體映射讀寫介面 ----
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire         write_en,
    output reg  [31:0] rdata,

    output wire         mtip_pending    // mtime >= mtimecmp 時拉高
);

    reg [63:0] mtime;
    reg [63:0] mtimecmp;

    localparam ADDR_MTIME_LO    = 32'h09000000;
    localparam ADDR_MTIME_HI    = 32'h09000004;
    localparam ADDR_MTIMECMP_LO = 32'h09000008;
    localparam ADDR_MTIMECMP_HI = 32'h0900000C;

    // ---- mtime 自由執行，每拍自動+1 ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mtime <= 64'b0;
        end else begin
            mtime <= mtime + 64'b1;
        end
    end

    // ---- mtimecmp 由軟體寫入設定，reset後預設全為1，避免開機瞬間mtime(=0)就误判成pending ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mtimecmp <= 64'hFFFFFFFF_FFFFFFFF;
        end else if (write_en && addr == ADDR_MTIMECMP_LO) begin
            mtimecmp[31:0] <= wdata;
        end else if (write_en && addr == ADDR_MTIMECMP_HI) begin
            mtimecmp[63:32] <= wdata;
        end
    end

    // ---- 硬體比較器：mtime >= mtimecmp 時持續拉高，直到軟體改mtimecmp才會歸零 ----
    assign mtip_pending = (mtime >= mtimecmp);

`ifdef FORMAL
    // ---- 形式驗證性質：mtip_pending 任何時候都必須恰好等於 mtime>=mtimecmp ----
    // 這個性質乍看跟上面那行assign一模一樣，但意義完全不同：
    // 上面是"實作"，這裡是"獨立於實作、用數學方式重新描述規格要求"，
    // 用來防範未來如果有人改壞了上面那行的邏輯(例如打錯成 > 而不是 >=)，
    // 形式驗證引擎會窮舉證明這個性質是否恆成立，而不是只跑幾個測試案例碰運氣。
    always @(*) begin
        assert (mtip_pending == (mtime >= mtimecmp));
    end
`endif


    // ---- 讀取 mux ----
    always @(*) begin
        case (addr)
            ADDR_MTIME_LO:    rdata = mtime[31:0];
            ADDR_MTIME_HI:    rdata = mtime[63:32];
            ADDR_MTIMECMP_LO: rdata = mtimecmp[31:0];
            ADDR_MTIMECMP_HI: rdata = mtimecmp[63:32];
            default:          rdata = 32'b0;
        endcase
    end

endmodule
