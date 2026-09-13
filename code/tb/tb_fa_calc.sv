`timescale 1ns/1ns

module tb_fa_calc;
    logic [7:0] A, B;
    logic       Sel;
    logic [7:0] S;
    logic       Co, Ov;

    fa_calc dut (
        .A(A), .B(B), .Sel(Sel), .S(S), .Co(Co), .Ov(Ov)
    );

    task check_case(input int tc_num, input [7:0] a_in, input [7:0] b_in, input sel_in, input [7:0] exp_s, input exp_co);
        A = a_in; B = b_in; Sel = sel_in; #10;
        $display("[TC %0d] Op: %s | A=%d, B=%d => S=%d (Exp:%d), Co=%b (Exp:%b) | %s",
                 tc_num, sel_in ? "SUB" : "ADD", A, B, S, exp_s, Co, exp_co,
                 (S == exp_s && Co == exp_co) ? "PASS" : "FAIL");
    endtask

    initial begin
        $dumpfile("tb_fa_calc.vcd");
        $dumpvars(0, tb_fa_calc);

        $display("=================== TB FA_CALC (10 CASES) ===================");
        check_case(1,  8'd0,   8'd0,   1'b0, 8'd0,   1'b0); // 0 + 0
        check_case(2,  8'd15,  8'd20,  1'b0, 8'd35,  1'b0); // 15 + 20
        check_case(3,  8'd100, 8'd50,  1'b0, 8'd150, 1'b0); // 100 + 50
        check_case(4,  8'd200, 8'd100, 1'b0, 8'd44,  1'b1); // Overflow Add
        check_case(5,  8'd50,  8'd20,  1'b1, 8'd30,  1'b1); // 50 - 20
        check_case(6,  8'd20,  8'd50,  1'b1, 8'd226, 1'b0); // 20 - 50 (-30)
        check_case(7,  8'd0,   8'd5,   1'b1, 8'd251, 1'b0); // 0 - 5 (-5)
        check_case(8,  8'd127, 8'd1,   1'b0, 8'd128, 1'b0); // 127 + 1
        check_case(9,  8'd10,  8'd10,  1'b1, 8'd0,   1'b1); // 10 - 10
        check_case(10, 8'd255, 8'd1,   1'b0, 8'd0,   1'b1); // 255 + 1
        $display("=============================================================");
        $finish;
    end
endmodule