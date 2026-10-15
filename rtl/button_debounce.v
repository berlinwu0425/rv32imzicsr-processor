`timescale 1ns / 1ps

// =========================================================================
// 按鍵防彈跳 + 單脈衝偵測
// 機械按鍵按下/放開的瞬間，訊號會在極短時間內劇烈抖動好幾次，
// 如果直接拿原始訊號當觸發條件，一次按壓可能被誤判成好幾次觸發。
// 這裡用「訊號要連續穩定N拍才承認狀態改變」的方式過濾抖動，
// 再用edge detection只在狀態真正從低翻高的那一拍，輸出一個乾淨的單cycle脈衝。
// =========================================================================
module button_debounce #(
    parameter DEBOUNCE_CYCLES = 20  // 訊號要連續穩定幾拍才承認(sysclk下約需對應實際彈跳時間)
)(
    input  wire clk,
    input  wire rst_n,
    input  wire btn_raw,      // 直接來自實體接腳的原始訊號
    output reg  btn_pulse     // 偵測到一次乾淨按壓時，脈衝1個cycle
);

    // ---- 兩級同步器：先把外部非同步訊號同步進這個時脈域，避免metastability ----
    reg btn_sync0, btn_sync1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_sync0 <= 1'b0;
            btn_sync1 <= 1'b0;
        end else begin
            btn_sync0 <= btn_raw;
            btn_sync1 <= btn_sync0;
        end
    end

    // ---- 穩定度計數器：只有訊號連續維持同一個值夠久，才承認這是真的狀態 ----
    reg [$clog2(DEBOUNCE_CYCLES+1)-1:0] stable_counter;
    reg btn_debounced;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stable_counter <= 0;
            btn_debounced  <= 1'b0;
        end else begin
            if (btn_sync1 == btn_debounced) begin
                // 訊號跟目前承認的狀態一樣，重置計數器(沒有變化在累積)
                stable_counter <= 0;
            end else begin
                // 訊號跟目前承認的狀態不同，開始累計穩定時間
                if (stable_counter >= DEBOUNCE_CYCLES) begin
                    btn_debounced  <= btn_sync1;   // 累計夠久了，正式承認狀態改變
                    stable_counter <= 0;
                end else begin
                    stable_counter <= stable_counter + 1'b1;
                end
            end
        end
    end

    // ---- Edge detection：只在防彈跳後的訊號從0變1的那一拍，輸出單cycle脈衝 ----
    reg btn_debounced_prev;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_debounced_prev <= 1'b0;
            btn_pulse          <= 1'b0;
        end else begin
            btn_debounced_prev <= btn_debounced;
            btn_pulse <= btn_debounced && !btn_debounced_prev;
        end
    end

endmodule
