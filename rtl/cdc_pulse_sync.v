`timescale 1ns / 1ps

// =========================================================================
// 跨時脈域脈衝同步器 (toggle-based)
// 把來源時脈域(較快)的窄脈衝，可靠地轉換成目的時脈域(較慢)能偵測到的脈衝。
// 標準CDC手法：來源端用脈衝觸發電位反轉(toggle)，目的端用兩級同步器
// 降低metastability風險，再偵測電位變化還原成脈衝。
// =========================================================================
module cdc_pulse_sync (
    input  wire src_clk,
    input  wire src_rst_n,
    input  wire src_pulse,      // 來源時脈域的窄脈衝(可能只有1個src_clk cycle寬)

    input  wire dst_clk,
    input  wire dst_rst_n,
    output wire dst_pulse       // 目的時脈域裡，保證能被偵測到的1cycle脈衝
);
    reg src_toggle;
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) src_toggle <= 1'b0;
        else if (src_pulse) src_toggle <= ~src_toggle;
    end

    reg dst_sync0, dst_sync1, dst_sync2;
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_sync0 <= 1'b0;
            dst_sync1 <= 1'b0;
            dst_sync2 <= 1'b0;
        end else begin
            dst_sync0 <= src_toggle;
            dst_sync1 <= dst_sync0;
            dst_sync2 <= dst_sync1;
        end
    end

    assign dst_pulse = dst_sync1 ^ dst_sync2;
endmodule
