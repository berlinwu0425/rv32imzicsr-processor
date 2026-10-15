`timescale 1ns/1ps
module tb_debounce;
    reg clk = 0;
    reg rst_n = 0;
    reg btn_raw = 0;
    wire btn_pulse;

    always #5 clk = ~clk;   // 100MHz

    button_debounce #(.DEBOUNCE_CYCLES(20)) uut (
        .clk(clk), .rst_n(rst_n), .btn_raw(btn_raw), .btn_pulse(btn_pulse)
    );

    integer pulse_count = 0;
    always @(posedge clk) begin
        if (btn_pulse) begin
            pulse_count = pulse_count + 1;
            $display("[PULSE] Time=%0t 偵測到第 %0d 次乾淨脈衝", $time, pulse_count);
        end
    end

    initial begin
        rst_n = 0;
        #50;
        rst_n = 1;
        #100;

        // ---- 模擬第一次按壓：真實按鍵會有一段劇烈彈跳雜訊，再穩定下來 ----
        $display("===== 模擬第一次按壓(含彈跳雜訊) =====");
        btn_raw = 1; #3;
        btn_raw = 0; #2;
        btn_raw = 1; #4;
        btn_raw = 0; #3;
        btn_raw = 1; #500;   // 之後穩定維持高電位夠久(模擬手指真的按住)

        #300;
        $display("===== 模擬放開(含彈跳雜訊) =====");
        btn_raw = 0; #3;
        btn_raw = 1; #2;
        btn_raw = 0; #500;   // 穩定維持低電位

        #300;
        $display("===== 模擬第二次按壓 =====");
        btn_raw = 1; #2;
        btn_raw = 0; #3;
        btn_raw = 1; #500;

        #300;
        btn_raw = 0;
        #500;

        $display("===== 總共偵測到 %0d 次乾淨脈衝(預期應該是2次) =====", pulse_count);
        $finish;
    end
endmodule
