`timescale 1ns / 1ps

// =========================================================================
// 動態分支預測器：2-bit飽和計數器 + BTB(分支目標緩衝區) + tag比對
// 用PC低位元索引，64個項目；加上tag比對PC高位元，避免"位址別名碰撞"
// 誤把完全不相干、甚至根本不是分支的指令，誤套用到別的分支的預測結果上。
// =========================================================================
module branch_predictor #(
    parameter TABLE_BITS = 6,   // 64個項目
    parameter TAG_BITS   = 10   // 額外比對的PC高位元數量，降低碰撞誤判機率
)(
    input  wire        clk,
    input  wire         rst_n,

    // ---- IF階段查詢介面：組合邏輯查詢，同一拍就要有結果 ----
    input  wire [31:0] query_pc,
    output wire         predict_taken,     // 這次查詢猜「跳」還是「不跳」
    output wire [31:0] predict_target,     // 猜「跳」的話，目標位址是多少(來自BTB)

    // ---- EX階段更新介面：驗證完實際結果後，回頭修正預測器內容 ----
    input  wire        update_en,          // 這個cycle有一筆真正的分支結果要更新(僅限確認是branch指令)
    input  wire [31:0] update_pc,          // 這條分支指令自己的PC
    input  wire         update_taken,       // 這條分支實際上有沒有跳
    input  wire [31:0] update_target        // 如果跳了，目標位址是多少(用來寫入BTB)
);

    localparam TABLE_SIZE = (1 << TABLE_BITS);

    reg [1:0]         counter_table [0:TABLE_SIZE-1];
    reg [31:0]        btb_table     [0:TABLE_SIZE-1];
    reg                btb_valid     [0:TABLE_SIZE-1];
    reg [TAG_BITS-1:0] btb_tag       [0:TABLE_SIZE-1];   // 額外存PC高位元，查詢時比對確認不是別名碰撞

    wire [TABLE_BITS-1:0] query_idx  = query_pc[TABLE_BITS+1:2];
    wire [TAG_BITS-1:0]   query_tag  = query_pc[TABLE_BITS+TAG_BITS+1:TABLE_BITS+2];
    wire [TABLE_BITS-1:0] update_idx = update_pc[TABLE_BITS+1:2];
    wire [TAG_BITS-1:0]   update_tag = update_pc[TABLE_BITS+TAG_BITS+1:TABLE_BITS+2];

    // ---- 查詢：組合邏輯，同一拍立即回應；tag要對得上才算真的命中，否則視同沒有預測資訊 ----
    wire tag_hit = btb_valid[query_idx] && (btb_tag[query_idx] == query_tag);
    assign predict_taken  = tag_hit && counter_table[query_idx][1];
    // 安全加固：predict_target 現在也用 tag_hit 保護，
    // tag miss 時恆定輸出0，不再原封不動洩漏被別名碰撞覆蓋的項目內容
    // (雖然目前唯一的消費端cpu_top.v已經有用predict_taken做保護，
    // 但這種"依賴使用端自律"的設計不是縱深防禦，源頭直接把關才是正確做法)
    assign predict_target = tag_hit ? btb_table[query_idx] : 32'b0;

    // ---- 更新：同步邏輯，依實際結果調整計數器、寫入BTB+tag ----
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < TABLE_SIZE; i = i + 1) begin
                counter_table[i] <= 2'b01;   // reset預設弱不跳，保守起點
                btb_valid[i]     <= 1'b0;
                btb_tag[i]       <= {TAG_BITS{1'b0}};   // 修正：之前漏掉，導致reset後為不確定值
                btb_table[i]     <= 32'b0;              // 修正：同樣遺漏，一併補齊
            end
        end else if (update_en) begin
            // 只有tag也對得上時，才做飽和計數器的漸進調整；
            // 如果這次更新的是一個全新的PC(tag不合)，直接覆寫成全新項目，計數器歸零重新學習，
            // 避免拿舊的、不相干的計數器歷史去干擾這個新出現的分支
            if (btb_valid[update_idx] && (btb_tag[update_idx] == update_tag)) begin
                if (update_taken) begin
                    if (counter_table[update_idx] != 2'b11)
                        counter_table[update_idx] <= counter_table[update_idx] + 2'b01;
                end else begin
                    if (counter_table[update_idx] != 2'b00)
                        counter_table[update_idx] <= counter_table[update_idx] - 2'b01;
                end
            end else begin
                // 全新項目(或別名碰撞覆寫)：計數器從中性起點開始，依這次結果給第一個推力
                counter_table[update_idx] <= update_taken ? 2'b10 : 2'b01;
                btb_tag[update_idx]       <= update_tag;
            end

            if (update_taken) begin
                btb_table[update_idx] <= update_target;
                btb_valid[update_idx] <= 1'b1;
            end
        end
    end

`ifdef FORMAL
    // ---- 安全性質A：tag miss時，predict_taken必須恆為0，不透露被覆蓋項目的任何資訊 ----
    // 這條性質確認：無論攻擊者訓練了什麼樣的歷史狀態在這個索引上，
    // 只要受害者查詢時tag對不上，predict_taken的結果是確定性的、
    // 不會因為被別名碰撞的那個項目內容不同而有任何差異(等同"無法被觀察出資訊")
    always @(*) begin
        if (!tag_hit) begin
            assert (predict_taken == 1'b0);
        end
    end

    // ---- 安全性質B(預期目前會FAIL，正式記錄這是一個已知的設計缺口)：
    // tag miss時，predict_target也應該要恆為0(或某個跟被覆蓋內容無關的固定值)，
    // 目前的實作並未如此，這條斷言故意寫成「規格上應該要有的樣子」，
    // 用來對照出目前實作跟這個更嚴謹規格之間的落差
    always @(*) begin
        if (!tag_hit) begin
            assert (predict_target == 32'b0);
        end
    end
`endif

endmodule
