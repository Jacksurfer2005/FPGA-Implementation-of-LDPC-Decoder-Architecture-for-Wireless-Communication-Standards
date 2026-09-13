`timescale 1ns/1ns

module tb_mode_select_top;
    logic       clk;
    logic       reset_n;
    logic       start;
    logic       count_en;
    logic       converged;
    logic [7:0] max_iteration;
    logic [7:0] decoding_data;
    logic [7:0] result_data;

    logic [7:0] iteration_count;
    logic       done;
    logic       mode;
    logic       ready;
    logic [7:0] output_data;

    mode_select_top dut (
        .clk(clk),
        .reset_n(reset_n),
        .start(start),
        .count_en(count_en),
        .converged(converged),
        .max_iteration(max_iteration),
        .decoding_data(decoding_data),
        .result_data(result_data),
        .iteration_count(iteration_count),
        .done(done),
        .mode(mode),
        .ready(ready),
        .output_data(output_data)
    );

    always #5 clk = ~clk;

    task test_mode(
        input int         tc,
        input logic       start_i,
        input logic       en_i,
        input logic       conv_i,
        input logic       exp_done,
        input logic [7:0] exp_out
    );
        start     <= start_i;
        count_en  <= en_i;
        converged <= conv_i;
        @(posedge clk);
        #1;
        $display("[TC %02d] Start:%b En:%b Conv:%b => Done:%b OutData:%d (Exp Done:%b Out:%d) | %s",
                 tc, start_i, en_i, conv_i, done, output_data, exp_done, exp_out,
                 (done == exp_done && output_data == exp_out) ? "PASS" : "FAIL");
    endtask

    initial begin
        clk           = 0;
        reset_n       = 0;
        start         = 0;
        count_en      = 0;
        converged     = 0;
        max_iteration = 8'd5;
        decoding_data = 8'd11;
        result_data   = 8'd99;

        #10 reset_n = 1;

        $dumpfile("tb_mode_select_top.vcd");
        $dumpvars(0, tb_mode_select_top);

        $display("==================== TB MODE_SELECT_TOP (10 CASES) ====================");
        test_mode(1,  1'b1, 1'b0, 1'b0, 1'b0, 8'd11); // Frame start
        test_mode(2,  1'b0, 1'b1, 1'b0, 1'b0, 8'd11); // Iter 1
        test_mode(3,  1'b0, 1'b1, 1'b0, 1'b0, 8'd11); // Iter 2
        test_mode(4,  1'b0, 1'b0, 1'b1, 1'b1, 8'd99); // Early termination (converged=1)
        test_mode(5,  1'b0, 1'b0, 1'b0, 1'b1, 8'd99); // Hold done
        test_mode(6,  1'b1, 1'b0, 1 me_conv, 1'b0, 8'd11); // New frame reset
        test_mode(7,  1'b0, 1'b1, 1'b0, 1'b0, 8'd11); // Iter 1
        test_mode(8,  1'b0, 1'b1, 1'b0, 1'b0, 8'd11); // Iter 2
        test_mode(9,  1'b0, 1'b1, 1'b0, 1'b0, 8'd11); // Iter 3
        test_mode(10, 1'b0, 1'b1, 1'b0, 1'b1, 8'd99); // Max iteration reached (count=5)

        $finish;
    end
endmodule