`timescale 1ns/1ns

module tb_ctv_app_calc;
    logic signed [7:0] min_i;
    logic signed [7:0] submin_i;
    logic signed [7:0] vtc_i;
    logic signed [7:0] app_old;
    logic signed [7:0] ctv_o;
    logic signed [7:0] app_new;

    ctv_app_calc dut (
        .min_i(min_i),
        .submin_i(submin_i),
        .vtc_i(vtc_i),
        .app_old(app_old),
        .ctv_o(ctv_o),
        .app_new(app_new)
    );

    task test_ctv_app(
        input int                tc,
        input logic signed [7:0] min_v,
        input logic signed [7:0] submin_v,
        input logic signed [7:0] vtc_v,
        input logic signed [7:0] app_v,
        input logic signed [7:0] exp_ctv,
        input logic signed [7:0] exp_app
    );
        min_i    = min_v;
        submin_i = submin_v;
        vtc_i    = vtc_v;
        app_old  = app_v;
        #5;
        $display("[TC %02d] Min:%d Sub:%d VTC:%d APP_old:%d => CTV:%d APP_new:%d (Exp CTV:%d, APP:%d) | %s",
                 tc, min_v, submin_v, vtc_v, app_v, ctv_o, app_new, exp_ctv, exp_app,
                 (ctv_o == exp_ctv && app_new == exp_app) ? "PASS" : "FAIL");
    endtask

    initial begin
        $dumpfile("tb_ctv_app_calc.vcd");
        $dumpvars(0, tb_ctv_app_calc);

        $display("==================== TB CTV_APP_CALC (10 CASES) ====================");
        test_ctv_app(1,  8'sd10, 8'sd15,  8'sd20,  8'sd50,  8'sd10,  8'sd60);
        test_ctv_app(2,  8'sd10, 8'sd15,  8'sd10,  8'sd50,  8'sd15,  8'sd65);
        test_ctv_app(3,  8'sd10, 8'sd15, -8'sd20,  8'sd50, -8'sd10,  8'sd40);
        test_ctv_app(4,  8'sd10, 8'sd15, -8'sd10,  8'sd50, -8'sd15,  8'sd35);
        test_ctv_app(5,  8'sd0,  8'sd5,   8'sd10,  8'sd20,  8'sd0,   8'sd20);
        test_ctv_app(6,  8'sd20, 8'sd30,  8'sd25,  8'sd100, 8'sd20,  8'sd120);
        test_ctv_app(7,  8'sd50, 8'sd60,  8'sd50,  8'sd100, 8'sd60,  8'sd127); // Saturation
        test_ctv_app(8,  8'sd50, 8'sd60, -8'sd80, -8'sd100,-8'sd50, -8'sd128); // Saturation
        test_ctv_app(9,  8'sd5,  8'sd12, -8'sd5,   8'sd0,  -8'sd12, -8'sd12);
        test_ctv_app(10, 8'sd30, 8'sd40,  8'sd30, -8'sd10,  8'sd40,  8'sd30);

        $finish;
    end
endmodule