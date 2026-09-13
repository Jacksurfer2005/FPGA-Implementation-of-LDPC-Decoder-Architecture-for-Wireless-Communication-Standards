`timescale 1ns/1ns

module tb_bram_app;
    logic        clk;
    logic        a_en;
    logic [4:0]  a_addr;
    logic [7:0]  a_dout;
    logic        b_we;
    logic [4:0]  b_addr;
    logic [7:0]  b_din;

    bram_app #(
        .DATA_WIDTH(8),
        .ADDR_WIDTH(5),
        .DEPTH(24)
    ) dut (
        .clk(clk),
        .a_en(a_en),
        .a_addr(a_addr),
        .a_dout(a_dout),
        .b_we(b_we),
        .b_addr(b_addr),
        .b_din(b_din)
    );

    always #5 clk = ~clk;

    task test_bram(
        input int         tc,
        input logic [4:0] waddr,
        input logic [7:0] wdata,
        input logic [4:0] raddr,
        input logic [7:0] exp_out
    );
        // Write operation
        @(posedge clk);
        b_we   <= 1'b1;
        b_addr <= waddr;
        b_din  <= wdata;
        a_en   <= 1'b0;

        // Read operation
        @(posedge clk);
        b_we   <= 1'b0;
        a_en   <= 1'b1;
        a_addr <= raddr;

        @(posedge clk);
        #1;
        $display("[TC %02d] Addr: %0d, Din: %d => Dout: %d (Exp: %d) | %s",
                 tc, raddr, wdata, $signed(a_dout), $signed(exp_out), 
                 (a_dout == exp_out) ? "PASS" : "FAIL");
    endtask

    initial begin
        clk    = 0;
        a_en   = 0;
        b_we   = 0;
        a_addr = 0;
        b_addr = 0;
        b_din  = 0;

        $dumpfile("tb_bram_app.vcd");
        $dumpvars(0, tb_bram_app);

        $display("==================== TB BRAM_APP (10 CASES) ====================");
        test_bram(1,  5'd0,  8'sd50,   5'd0,  8'sd50);
        test_bram(2,  5'd1, -8'sd100,  5'd1, -8'sd100);
        test_bram(3,  5'd2,  8'sd127,  5'd2,  8'sd127);
        test_bram(4,  5'd3, -8'sd128,  5'd3, -8'sd128);
        test_bram(5,  5'd5,  8'sd0,    5'd5,  8'sd0);
        test_bram(6,  5'd10, 8'sd15,   5'd10, 8'sd15);
        test_bram(7,  5'd15,-8'sd45,   5'd15,-8'sd45);
        test_bram(8,  5'd20, 8'sd88,   5'd20, 8'sd88);
        test_bram(9,  5'd22,-8'sd12,   5'd22,-8'sd12);
        test_bram(10, 5'd23, 8'sd99,   5'd23, 8'sd99);
        
        $finish;
    end
endmodule