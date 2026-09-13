`timescale 1ns/1ns

module tb_sign_insertion;
    logic [7:0] x_1, x_2, x_3, x_4, x_5, x_6, x_7;
    logic [6:0] sign_i;
    logic       sign_total;
    logic [7:0] y_1, y_2, y_3, y_4, y_5, y_6, y_7;

    sign_insertion dut (
        .x_1(x_1), .x_2(x_2), .x_3(x_3), .x_4(x_4), .x_5(x_5), .x_6(x_6), .x_7(x_7),
        .sign_i(sign_i), .sign_total(sign_total),
        .y_1(y_1), .y_2(y_2), .y_3(y_3), .y_4(y_4), .y_5(y_5), .y_6(y_6), .y_7(y_7)
    );

    task test_insert(input int tc, input [7:0] mag, input [6:0] s_in, input st);
        x_1=mag; x_2=mag; x_3=mag; x_4=mag; x_5=mag; x_6=mag; x_7=mag;
        sign_i = s_in; sign_total = st; #10;
        $display("[TC %02d] Mag=%d, Sign_i=%b, Sign_total=%b => Output y1(Signed): %d (Hex: 0x%h)",
                 tc, mag, s_in, st, $signed(y_1), y_1);
    endtask

    initial begin
        $dumpfile("tb_sign_insertion.vcd");
        $dumpvars(0, tb_sign_insertion);

        $display("=================== TB SIGN_INSERTION (10 CASES) ===================");
        test_insert(1,  8'd10, 7'b0000000, 1'b0); // Dương + Parity 0 -> Dương
        test_insert(2,  8'd10, 7'b0000000, 1'b1); // Dương + Parity 1 -> Âm (-10)
        test_insert(3,  8'd25, 7'b0000001, 1'b0); // x1 Âm + Parity 0 -> Âm (-25)
        test_insert(4,  8'd25, 7'b0000001, 1'b1); // x1 Âm + Parity 1 -> Dương (+25)
        test_insert(5,  8'd0,  7'b1111111, 1'b0); // Giá trị 0
        test_insert(6,  8'd50, 7'b1010101, 1'b0); // Xen kẽ dấu
        test_insert(7,  8'd50, 7'b1010101, 1'b1); // Xen kẽ dấu + Parity 1
        test_insert(8,  8'd127,7'b0000000, 1'b1); // Max positive magnitude
        test_insert(9,  8'd1,  7'b1111111, 1'b1); // Sign total invert all
        test_insert(10, 8'd64, 7'b0110011, 1'b0); // Random signs
        $display("===================================================================");
        $finish;
    end
endmodule