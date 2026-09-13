`timescale 1ns/1ns

module tb_signs_xoring;
    logic [6:0] sign_i;
    logic       sign_o;

    signs_xoring dut (.sign_i(sign_i), .sign_o(sign_o));

    task test_sign(input int tc, input [6:0] s_in, input exp_out);
        sign_i = s_in; #10;
        $display("[TC %02d] Sign_in: %b => Sign_out: %b (Exp: %b) | %s",
                 tc, sign_i, sign_o, exp_out, (sign_o == exp_out) ? "PASS" : "FAIL");
    endtask

    initial begin
        $dumpfile("tb_signs_xoring.vcd");
        $dumpvars(0, tb_signs_xoring);

        $display("=================== TB SIGNS_XORING (10 CASES) ===================");
        test_sign(1,  7'b0000000, 1'b0);
        test_sign(2,  7'b0000001, 1'b1);
        test_sign(3,  7'b0000011, 1'b0);
        test_sign(4,  7'b0000111, 1'b1);
        test_sign(5,  7'b1111111, 1'b1);
        test_sign(6,  7'b1010101, 1'b0);
        test_sign(7,  7'b1100110, 1'b0);
        test_sign(8,  7'b1000000, 1'b1);
        test_sign(9,  7'b0111110, 1'b1);
        test_sign(10, 7'b1111000, 1'b0);
        $display("=================================================================");
        $finish;
    end
endmodule