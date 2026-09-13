`timescale 1ns/1ns

module tb_vtc_calc;
    localparam Z = 24;

    logic signed [7:0] app_i [0:Z-1];
    logic signed [7:0] ctv_i [0:Z-1];
    logic signed [7:0] vtc_o [0:Z-1];

    vtc_calc #(
        .Z(Z)
    ) dut (
        .app_i(app_i),
        .ctv_i(ctv_i),
        .vtc_o(vtc_o)
    );

    task test_vtc(
        input int                tc,
        input logic signed [7:0] app_val,
        input logic signed [7:0] ctv_val,
        input logic signed [7:0] exp_vtc
    );
        for (int i = 0; i < Z; i++) begin
            app_i[i] = app_val;
            ctv_i[i] = ctv_val;
        end
        #5;
        $display("[TC %02d] APP: %d, CTV: %d => VTC[0]: %d (Exp: %d) | %s",
                 tc, app_val, ctv_val, vtc_o[0], exp_vtc,
                 (vtc_o[0] == exp_vtc) ? "PASS" : "FAIL");
    endtask

    initial begin
        $dumpfile("tb_vtc_calc.vcd");
        $dumpvars(0, tb_vtc_calc);

        $display("==================== TB VTC_CALC (10 CASES) ====================");
        test_vtc(1,   8'sd50,   8'sd20,   8'sd30);   // Standard subtraction
        test_vtc(2,  -8'sd50,   8'sd20,  -8'sd70);   // Negative - Positive
        test_vtc(3,   8'sd100, -8'sd50,   8'sd127);  // Upper Saturation (> 127)
        test_vtc(4,  -8'sd100,  8'sd50,  -8'sd128);  // Lower Saturation (< -128)
        test_vtc(5,   8'sd0,    8'sd0,    8'sd0);    // Zero
        test_vtc(6,   8'sd127,  8'sd0,    8'sd127);  // Max Positive boundary
        test_vtc(7,  -8'sd128,  8'sd0,   -8'sd128);  // Min Negative boundary
        test_vtc(8,  -8'sd60,  -8'sd60,   8'sd0);    // Equal Negative values
        test_vtc(9,   8'sd80,  -8'sd47,   8'sd127);  // Upper Saturation boundary
        test_vtc(10, -8'sd80,   8'sd49,  -8'sd128);  // Lower Saturation boundary

        $finish;
    end
endmodule