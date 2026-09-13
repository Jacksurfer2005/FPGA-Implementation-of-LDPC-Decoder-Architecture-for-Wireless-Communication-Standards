`timescale 1ns/1ns

module tb_bram_ctv;
    logic        clk;
    logic        wr_en;
    logic [4:0]  wr_addr;
    logic [7:0]  wr_data;
    logic        rd_en;
    logic [4:0]  rd_addr;
    logic [7:0]  rd_data;

    bram_ctv #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(5),
        .DEPTH(24)
    ) dut (
        .clk(clk),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(rd_data)
    );

    always #5 clk = ~clk;

    task test_ctv(
        input int         tc,
        input logic [4:0] waddr,
        input logic [7:0] wdata,
        input logic [4:0] raddr,
        input logic [7:0] exp_out
    );
        @(posedge clk);
        wr_en   <= 1'b1;
        wr_addr <= waddr;
        wr_data <= wdata;
        rd_en   <= 1'b0;

        @(posedge clk);
        wr_en   <= 1'b0;
        rd_en   <= 1'b1;
        rd_addr <= raddr;

        @(posedge clk);
        #1;
        $display("[TC %02d] WR_Addr: %0d, WData: %d => RData: %d (Exp: %d) | %s",
                 tc, raddr, $signed(wdata), $signed(rd_data), $signed(exp_out), 
                 (rd_data == exp_out) ? "PASS" : "FAIL");
    endtask

    initial begin
        clk     = 0;
        wr_en   = 0;
        rd_en   = 0;
        wr_addr = 0;
        rd_addr = 0;
        wr_data = 0;

        $dumpfile("tb_bram_ctv.vcd");
        $dumpvars(0, tb_bram_ctv);

        $display("==================== TB BRAM_CTV (10 CASES) ====================");
        test_ctv(1,  5'd0,  8'sd12,  5'd0,  8'sd12);
        test_ctv(2,  5'd1, -8'sd34,  5'd1, -8'sd34);
        test_ctv(3,  5'd4,  8'sd77,  5'd4,  8'sd77);
        test_ctv(4,  5'd7, -8'sd120, 5'd7, -8'sd120);
        test_ctv(5,  5'd9,  8'sd0,   5'd9,  8'sd0);
        test_ctv(6,  5'd12, 8'sd64,  5'd12, 8'sd64);
        test_ctv(7,  5'd16,-8'sd88,  5'd16,-8'sd88);
        test_ctv(8,  5'd18, 8'sd127, 5'd18, 8'sd127);
        test_ctv(9,  5'd21,-8'sd128, 5'd21,-8'sd128);
        test_ctv(10, 5'd23, 8'sd42,  5'd23, 8'sd42);

        $finish;
    end
endmodule