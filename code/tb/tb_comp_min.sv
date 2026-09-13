`timescale 1ns/1ns

module tb_comp_min;
    logic [7:0] A, B;
    logic [7:0] min_o;

    comp_min dut (.A(A), .B(B), .min_o(min_o));

    task test_cmin(input int tc, input [7:0] a_in, b_in, exp_min);
        A = a_in; B = b_in; #10;
        $display("[TC %02d] A=%d, B=%d => Min=%d (Exp:%d) | %s",
                 tc, A, B, min_o, exp_min, (min_o == exp_min) ? "PASS" : "FAIL");
    endtask

    initial begin
        $dumpfile("tb_comp_min.vcd");
        $dumpvars(0, tb_comp_min);
        
        $display("=================== TB COMP_MIN (10 CASES) ===================");
        test_cmin(1,  8'd10,  8'd20,  8'd10);
        test_cmin(2,  8'd30,  8'd15,  8'd15);
        test_cmin(3,  8'd0,   8'd0,   8'd0);
        test_cmin(4,  8'd255, 8'd100, 8'd100);
        test_cmin(5,  8'd5,   8'd5,   8'd5);
        test_cmin(6,  8'd1,   8'd2,   8'd1);
        test_cmin(7,  8'd200, 8'd201, 8'd200);
        test_cmin(8,  8'd128, 8'd127, 8'd127);
        test_cmin(9,  8'd80,  8'd90,  8'd80);
        test_cmin(10, 8'd254, 8'd255, 8'd254);
        $display("==============================================================");
        $finish;
    end
endmodule