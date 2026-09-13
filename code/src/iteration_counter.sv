`timescale 1ns/1ns

module iteration_counter (
    input  logic             clk,
    input  logic             reset_n,
    input  logic             start,
    input  logic             enable,
    output logic [7:0] count
);

    logic [7:0] count_plus_one;
    logic       carry_unused;

    fa_calc u_fa_increment (
        .A   (count),
        .B   (8'd1),
        .Sel (1'b0),       // addition
        .S   (count_plus_one),
        .Co  (carry_unused),
        .Ov  ()
    );

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            count <= '0;
        else if (start)
            count <= '0;
        else if (enable)
            count <= count_plus_one;
    end

endmodule
