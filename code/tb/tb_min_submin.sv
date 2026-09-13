`timescale 1ns/1ns

module tb_min_submin;
    // Tín hiệu điều khiển & clock
    logic       clk;
    logic       rst_n;

    // Tín hiệu ngõ vào (Input VTC)
    logic [7:0] vtc_1, vtc_2, vtc_3, vtc_4, vtc_5, vtc_6, vtc_7;

    // Tín hiệu ngõ ra (Output CTV & Min/Submin)
    logic [7:0] ctv_1, ctv_2, ctv_3, ctv_4, ctv_5, ctv_6, ctv_7;
    logic [7:0] min_o;
    logic [7:0] submin_o;
    logic [3:0] rowWeight;

    // Kết nối với Thiết kế DUT (min_submin)
    min_submin dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .vtc_1     (vtc_1),
        .vtc_2     (vtc_2),
        .vtc_3     (vtc_3),
        .vtc_4     (vtc_4),
        .vtc_5     (vtc_5),
        .vtc_6     (vtc_6),
        .vtc_7     (vtc_7),
        .ctv_1     (ctv_1),
        .ctv_2     (ctv_2),
        .ctv_3     (ctv_3),
        .ctv_4     (ctv_4),
        .ctv_5     (ctv_5),
        .ctv_6     (ctv_6),
        .ctv_7     (ctv_7),
        .min_o     (min_o),
        .submin_o  (submin_o),
        .rowWeight (rowWeight)
    );

    // Tạo Clock (Chu kỳ 10ns = 100MHz)
    always #5 clk = ~clk;

    // Task kiểm thử
    task test_min(
        input int tc,
        input logic signed [7:0] v1, v2, v3, v4, v5, v6, v7,
        input logic signed [7:0] exp_min, exp_submin
    );
        @(posedge clk);
        vtc_1 <= v1; vtc_2 <= v2; vtc_3 <= v3; vtc_4 <= v4;
        vtc_5 <= v5; vtc_6 <= v6; vtc_7 <= v7;

        // Đợi 2 chu kỳ clock cho Pipeline 2 tầng
        @(posedge clk);
        @(posedge clk);
        #1;

        $display("[TC %02d] Inputs: [%4d, %4d, %4d, %4d, %4d, %4d, %4d] | Min: %3d (Exp: %3d) | Submin: %3d (Exp: %3d) | rowWeight: %d | %s",
                 tc, $signed(v1), $signed(v2), $signed(v3), $signed(v4), $signed(v5), $signed(v6), $signed(v7),
                 min_o, exp_min, submin_o, exp_submin, rowWeight,
                 (min_o == exp_min && submin_o == exp_submin) ? "PASS" : "FAIL");
    endtask

    // Luồng kích thích chính (Main Stimulus)
    initial begin
        // Khởi tạo trạng thái ban đầu
        clk   = 0;
        rst_n = 0;
        vtc_1 = 0; vtc_2 = 0; vtc_3 = 0; vtc_4 = 0;
        vtc_5 = 0; vtc_6 = 0; vtc_7 = 0;

        // Xung Reset active-low
        #10 rst_n = 1;

        // Ghi Waveform VCD
        $dumpfile("tb_min_submin.vcd");
        $dumpvars(0, tb_min_submin);

        $display("==========================================================================================");
        $display("                             TESTBENCH FOR MIN_SUBMIN                                    ");
        $display("==========================================================================================");

        // Chạy 10 Test Cases (Tính toán dựa trên Normalized Min-Sum: Y - (Y >> 2))
        test_min(1,   10,  20,  30,  40,  50,  60,  70,   8,  15);
        test_min(2,  -12,  24, -36,  48, -60,  72, -84,   9,  18);
        test_min(3,   40,  40,  40,  40,  40,  40,  40,  30,  30);
        test_min(4,    4,   8,  12,  16,  20,  24,  28,   3,   6);
        test_min(5,  100,  80,  60,  40,  20,  10,   5,   4,   8);
        test_min(6,  -50, -10,  30,  70,  90, 110, 120,   8,  23);
        test_min(7,  124, 100,  80,  60,  44,  28,  16,  12,  21);
        test_min(8,   16,  16,  32,  64,  32,  16,  64,  12,  12);
        test_min(9,    0,  12,  24,  36,  48,  60,  72,   0,   9);
        test_min(10,-128, 127,-100, 100, -50, 50,   0,   0,  38);

        $display("==========================================================================================");
        $finish;
    end

endmodule