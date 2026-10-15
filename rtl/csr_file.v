module csr_file(
    input  wire        clk,
    input  wire        rst_n,

    // ---- 一般 CSR 讀寫（來自 csrrw/csrrs/csrrc 等指令，在 EX 階段發生）----
    input  wire [11:0] csr_addr,
    input  wire [31:0] csr_wdata,
    input  wire         csr_write_en,
    output reg  [31:0] csr_rdata,

    // ---- Trap 進入：硬體自動寫入 mepc/mcause/mtval/mstatus，優先權最高 ----
    input  wire         trap_taken,
    input  wire [31:0] trap_pc,
    input  wire [31:0] trap_cause,
    input  wire [31:0] trap_value,

    // ---- mret：讀出 mepc 給 npc 用，並觸發 mstatus 的 MIE/MPIE 還原 ----
    input  wire         mret_taken,
    output wire [31:0] mepc_out,
    output wire [31:0] mtvec_out,

    // ---- 即時狀態輸出，給中斷判斷邏輯隨時查看 ----
    output wire [31:0] mstatus_out,
    output wire [31:0] mie_out,

    // ---- 軟體中斷 pending 訊號 (由外部記憶體映射暫存器驅動，直接反映到 mip.MSIP) ----
    input  wire         msip_ext,
    input  wire         mtip_ext    // 計時器中斷pending訊號，來自mtime>=mtimecmp的硬體比較器
);
    reg [31:0] mstatus;
    reg [31:0] mie;
    reg [31:0] mtvec;
    reg [31:0] mscratch;
    reg [31:0] mepc;
    reg [31:0] mcause;
    reg [31:0] mtval;

    localparam ADDR_MSTATUS  = 12'h300;
    localparam ADDR_MIE      = 12'h304;
    localparam ADDR_MTVEC    = 12'h305;
    localparam ADDR_MSCRATCH = 12'h340;
    localparam ADDR_MEPC     = 12'h341;
    localparam ADDR_MCAUSE   = 12'h342;
    localparam ADDR_MTVAL    = 12'h343;
    localparam ADDR_MIP      = 12'h344;

    assign mepc_out    = mepc;
    assign mtvec_out   = mtvec;
    assign mstatus_out = mstatus;
    assign mie_out     = mie;

    // mip 完全由外部訊號驅動 (bit3=MSIP)，不走內部暫存/CSR寫入路徑，
    // 因為軟體中斷只該由記憶體映射暫存器(0x2000000)觸發，符合CLINT慣例
    // bit7=MTIP(計時器中斷)，bit3=MSIP(軟體中斷)，其餘保留(目前沒有外部中斷)
    wire [31:0] mip_value = {24'b0, mtip_ext, 3'b0, msip_ext, 3'b0};

    // 讀取：組合邏輯，依位址選出對應暫存器
    always @(*) begin
        case (csr_addr)
            ADDR_MSTATUS:  csr_rdata = mstatus;
            ADDR_MIE:      csr_rdata = mie;
            ADDR_MTVEC:    csr_rdata = mtvec;
            ADDR_MSCRATCH: csr_rdata = mscratch;
            ADDR_MEPC:     csr_rdata = mepc;
            ADDR_MCAUSE:   csr_rdata = mcause;
            ADDR_MTVAL:    csr_rdata = mtval;
            ADDR_MIP:      csr_rdata = mip_value;
            default:       csr_rdata = 32'b0;
        endcase
    end

    // 寫入：優先權 trap進入(最高) > mret(mstatus的MIE/MPIE還原) > 一般CSR指令寫入(最低)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mstatus  <= 32'b0;
            mie      <= 32'b0;
            mtvec    <= 32'b0;
            mscratch <= 32'b0;
            mepc     <= 32'b0;
            mcause   <= 32'b0;
            mtval    <= 32'b0;
        end else if (trap_taken) begin
            mepc   <= trap_pc;
            mcause <= trap_cause;
            mtval  <= trap_value;
            // 進 trap 時: MPIE(bit7) <= MIE(bit3)，然後 MIE(bit3) <= 0 (先關中斷避免巢狀失控)
            mstatus[7] <= mstatus[3];
            mstatus[3] <= 1'b0;
        end else if (mret_taken) begin
            // mret 返回時: MIE(bit3) <= MPIE(bit7)，MPIE(bit7) <= 1 (規格建議還原成預設開啟)
            mstatus[3] <= mstatus[7];
            mstatus[7] <= 1'b1;
        end else if (csr_write_en) begin
            case (csr_addr)
                ADDR_MSTATUS:  mstatus  <= csr_wdata;
                ADDR_MIE:      mie      <= csr_wdata;
                ADDR_MTVEC:    mtvec    <= csr_wdata;
                ADDR_MSCRATCH: mscratch <= csr_wdata;
                ADDR_MEPC:     mepc     <= csr_wdata;
                ADDR_MCAUSE:   mcause   <= csr_wdata;
                ADDR_MTVAL:    mtval    <= csr_wdata;
                // ADDR_MIP: 不接受一般CSR寫入，完全由外部訊號驅動
                default: ;
            endcase
        end
    end
endmodule
