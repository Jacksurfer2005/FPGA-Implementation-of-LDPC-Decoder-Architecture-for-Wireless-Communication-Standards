`timescale 1ns/1ns

module tb_abs_calc;
    logic [7:0] x_1, x_2, x_3, x_4, x_5, x_6, x_7;
    logic [7:0] y_1, y_2, y_3, y_4, y_5, y_6, y_7;
    logic [6:0] sign_o;

    abs_calc dut (
        .x_1(x_1), .x_2(x_2), .x_3(x_3), .x_4(x_4), .x_5(x_5), .x_6(x_6), .x_7(x_7),
        .y_1(y_1), .y_2(y_2), .y_3(y_3), .y_4(y_4), .y_5(y_5), .y_6(y_6), .y_7(y_7),
        .sign_o(sign_o)
    );

    task test_abs(input int tc, input signed [7:0] in1, in2, in3, in4, in5, in6, in7);
        x_1 = in1; x_2 = in2; x_3 = in3; x_4 = in4; x_5 = in5; x_6 = in6; x_7 = in7; #10;
        $display("[TC %0d] Inputs: [%d,%d,%d,%d,%d,%d,%d]", tc, in1,in2,in3,in4,in5,in6,in7);
        $display("       => Abs:   [%d,%d,%d,%d,%d,%d,%d], Signs: %b", y_1,y_2,y_3,y_4,y_5,y_6,y_7, sign_o);
    endtask

    initial begin
        $dumpfile("tb_abs_calc.vcd");
        $dumpvars(0, tb_abs_calc);

        $display("=================== TB ABS_CALC (10 CASES) ===================");
        test_abs(1,  10,  20,  30,  40,  50,  60,  70);  // Tất cả dương
        test_abs(2, -10, -20, -30, -40, -50, -60, -70);  // Tất cả âm
        test_abs(3, -10,  20, -30,  40, -50,  60, -70);  // Xen kẽ
        test_abs(4,   0,   0,   0,   0,   0,   0,   0);  // Bằng 0
        test_abs(5, -128, 127, -1,   1, -50,  50,   0);  // Biên
        test_abs(6,  -5,  -5,  -5,  -5,  -5,  -5,  -5);  // Âm giống nhau
        test_abs(7,  15, -15,  25, -25,  35, -35,  45);  // Cặp đối
        test_abs(8, -99,   8, -12,  44, -33,  22, -11);  // Ngẫu nhiên 1
        test_abs(9,  64, -64,  32, -32,  16, -16,   8);  // Luỹ thừa 2
        test_abs(10,-88, -77,  66,  55, -44, -33,  22);  // Ngẫu nhiên 2
        $display("=============================================================");
        $finish;
    end
endmodule