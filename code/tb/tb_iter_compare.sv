`timescale 1ns/1ns

module tb_iter_compare;
    logic [7:0] iteration_count;
    logic [7:0] max_iteration;
    logic       done;

    iter_compare dut (
        .iteration_count(iteration_count),
        .max_iteration(max_iteration),
        .done(done)
    );

    task test_cmp(input int tc, input [7:0] cur_it, max_it, input exp_done);
        iteration_count = cur_it; max_iteration = max_it; #10;
        $display("[TC %02d] Iter_count=%d, Max_iter=%d => Done=%b (Exp:%b) | %s",
                 tc, cur_it, max_it, done, exp_done, (done == exp_done) ? "PASS" : "FAIL");
    endtask

    initial begin
        $dumpfile("tb_iter_compare.vcd");
        $dumpvars(0, tb_iter_compare);

        $display("=================== TB ITER_COMPARE (10 CASES) ===================");
        test_cmp(1,  8'd0,   8'd10,  1'b0); // Vòng lặp 0 < 10
        test_cmp(2,  8'd5,   8'd10,  1'b0); // Vòng lặp 5 < 10
        test_cmp(3,  8'd9,   8'd10,  1'b0); // Vòng lặp 9 < 10
        test_cmp(4,  8'd10,  8'd10,  1'b1); // Vòng lặp 10 == 10 (Chạm ngưỡng Max)
        test_cmp(5,  8'd11,  8'd10,  1'b1); // Vòng lặp 11 > 10
        test_cmp(6,  8'd0,   8'd0,   1'b1); // Max = 0
        test_cmp(7,  8'd1,   8'd15,  1'b0); // Vòng lặp 1 < 15
        test_cmp(8,  8'd15,  8'd15,  1'b1); // Vòng lặp 15 == 15
        test_cmp(9,  8'd50,  8'd20,  1'b1); // Đã vượt quá xa
        test_cmp(10, 8'd255, 8'd255, 1'b1); // Max 8-bit
        $display("=================================================================");
        $finish;
    end
endmodule