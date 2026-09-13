`timescale 1ns/1ns

module tb_check_matrix;
    logic       clk;
    logic [2:0] layer;       // Sửa kích thước phù hợp MB=6 ($clog2(6)=3)
    logic [3:0] edge_idx;
    logic [3:0] row_weight;
    logic [4:0] col_pos;
    logic [4:0] shift;       // Sửa kích thước phù hợp Z=24 ($clog2(24)=5)
    logic       edge_valid;

    // Sửa tên cổng .layer_idx(...) -> .layer(...)
    check_matrix #(
        .MB(6), .NB(24), .Z(24), .Z0(96), .DR_MAX(15)
    ) dut (
        .clk(clk),
        .layer(layer),
        .edge_idx(edge_idx),
        .row_weight(row_weight),
        .col_pos(col_pos),
        .shift(shift),
        .edge_valid(edge_valid)
    );

    always #5 clk = ~clk;

    task test_matrix(
        input int         tc,
        input logic [2:0] l_idx,
        input logic [3:0] e_idx,
        input logic [3:0] exp_rw,
        input logic [4:0] exp_col,
        input logic [4:0] exp_shift,
        input logic       exp_valid
    );
        @(posedge clk);
        layer    <= l_idx;
        edge_idx <= e_idx;

        @(posedge clk);
        #1;
        $display("[TC %02d] Layer:%0d Edge:%0d => RW:%0d Col:%0d Shift:%0d Val:%b | %s",
                 tc, l_idx, e_idx, row_weight, col_pos, shift, edge_valid,
                 (row_weight == exp_rw && col_pos == exp_col && shift == exp_shift && edge_valid == exp_valid) ? "PASS" : "FAIL");
    endtask

    initial begin
        clk      = 0;
        layer    = 0;
        edge_idx = 0;

        $dumpfile("tb_check_matrix.vcd");
        $dumpvars(0, tb_check_matrix);

        $display("==================== TB CHECK_MATRIX (CORRECTED) ====================");
        // Hàng 0 có 14 phần tử (RW=14)
        test_matrix(1, 3'd0, 4'd0,  4'd14, 5'd0,  5'd1, 1'b1); // Edge 0: hb=0x06 -> Shift=1
        test_matrix(2, 3'd0, 4'd1,  4'd14, 5'd1,  5'd9, 1'b1); // Edge 1: hb=0x26 -> Shift=9
        test_matrix(3, 3'd0, 4'd2,  4'd14, 5'd2,  5'd0, 1'b1); // Edge 2: hb=0x03 -> Shift=0
        test_matrix(4, 3'd0, 4'd14, 4'd14, 5'd0,  5'd0, 1'b0); // Edge 14 out-of-bound -> Valid=0

        // Hàng 1 có 14 phần tử (RW=14)
        test_matrix(5, 3'd1, 4'd0,  4'd14, 5'd0,  5'd15, 1'b1); // Edge 0: hb=0x3E -> Shift=15
        test_matrix(6, 3'd1, 4'd1,  4'd14, 5'd1,  5'd23, 1'b1); // Edge 1: hb=0x5E -> Shift=23

        $finish;
    end
endmodule