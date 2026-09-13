`timescale 1ns/1ns

module tb_iteration_counter;
    logic       clk;
    logic       reset_n;
    logic       start;
    logic       enable;
    logic [7:0] count;

    iteration_counter dut (
        .clk(clk), .reset_n(reset_n), .start(start), .enable(enable), .count(count)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_iteration_counter.vcd");
        $dumpvars(0, tb_iteration_counter);

        $display("=================== TB ITERATION_COUNTER (10 STEPS) ===================");
        clk = 0; reset_n = 0; start = 0; enable = 0; #12;
        reset_n = 1; $display("[Step 01] Reset released => Count = %d", count);

        enable = 1; #10; $display("[Step 02] Enable=1 => Count = %d", count); // 1
        #10; $display("[Step 03] Enable=1 => Count = %d", count); // 2
        #10; $display("[Step 04] Enable=1 => Count = %d", count); // 3
        
        enable = 0; #10; $display("[Step 05] Enable=0 (Pause) => Count = %d", count); // 3
        
        enable = 1; #10; $display("[Step 06] Enable=1 => Count = %d", count); // 4
        #10; $display("[Step 07] Enable=1 => Count = %d", count); // 5
        
        start = 1; #10; $display("[Step 08] Start pulse => Count = %d", count); // 0
        start = 0; #10; $display("[Step 09] Enable after start => Count = %d", count); // 1
        
        reset_n = 0; #10; $display("[Step 10] Hard Reset => Count = %d", count); // 0
        $display("=======================================================================");
        $finish;
    end
endmodule