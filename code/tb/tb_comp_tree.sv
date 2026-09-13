`timescale 1ns/1ns

module tb_comp_tree;
    logic [7:0] x_1, x_2, x_3, x_4, x_5, x_6, x_7;
    logic [7:0] y_1, y_2, y_3, y_4, y_5, y_6, y_7;
    logic [7:0] min_o, submin_o;
    logic [7:0] vtc_o_1, vtc_o_2, vtc_o_3, vtc_o_4, vtc_o_5, vtc_o_6, vtc_o_7;
    logic [3:0] rowWeight;

    comp_tree dut (
        .x_1(x_1), .x_2(x_2), .x_3(x_3), .x_4(x_4), .x_5(x_5), .x_6(x_6), .x_7(x_7),
        .y_1(y_1), .y_2(y_2), .y_3(y_3), .y_4(y_4), .y_5(y_5), .y_6(y_6), .y_7(y_7),
        .min_o(min_o), .submin_o(submin_o),
        .vtc_o_1(vtc_o_1), .vtc_o_2(vtc_o_2), .vtc_o_3(vtc_o_3), .vtc_o_4(vtc_o_4),
        .vtc_o_5(vtc_o_5), .vtc_o_6(vtc_o_6), .vtc_o_7(vtc_o_7),
        .rowWeight(rowWeight)
    );

    task test_tree(input int tc, input [7:0] i1,i2,i3,i4,i5,i6,i7, exp_m1, exp_m2);
        x_1=i1; x_2=i2; x_3=i3; x_4=i4; x_5=i5; x_6=i6; x_7=i7; #10;
        $display("[TC %02d] Inputs:[%d,%d,%d,%d,%d,%d,%d] => Min1=%d (Exp:%d), Min2=%d (Exp:%d) | %s",
                 tc, i1,i2,i3,i4,i5,i6,i7, min_o, exp_m1, submin_o, exp_m2,
                 (min_o == exp_m1 && submin_o == exp_m2) ? "PASS" : "FAIL");
    endtask

    initial begin
        $dumpfile("tb_comp_tree.vcd");
        $dumpvars(0, tb_comp_tree);

        $display("=================== TB COMP_TREE (10 CASES) ===================");
        test_tree(1,  10, 20, 30, 40, 50, 60, 70, 10, 20); // Tăng dần
        test_tree(2,  70, 60, 50, 40, 30, 20, 10, 10, 20); // Giảm dần
        test_tree(3,  25, 40,  5, 12, 50, 30,  8,  5,  8); // Min ở giữa
        test_tree(4,   5, 10,  5, 20, 30, 40, 50,  5,  5); // Hai Min trùng nhau
        test_tree(5,  15, 15, 15, 15, 15, 15, 15, 15, 15); // Tất cả bằng nhau
        test_tree(6,   1,  2,  3,  4,  5,  6,  7,  1,  2); // Giá trị nhỏ
        test_tree(7, 250,200,150,100, 50,220,180, 50,100); // Giá trị lớn
        test_tree(8,  40, 30, 20, 50, 60, 70, 10, 10, 20); // Min ở x_7
        test_tree(9,   3, 80, 50, 40, 90,100, 10,  3, 10); // Min ở x_1
        test_tree(10, 18, 42, 99,  7, 23, 11, 85,  7, 11); // Bất kỳ
        $display("===============================================================");
        $finish;
    end
endmodule