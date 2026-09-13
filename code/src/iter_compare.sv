`timescale 1ns/1ns

module iter_compare (
    input  logic [7:0] iteration_count,
    input  logic [7:0] max_iteration,
    output logic             done
);

    logic [7:0] diff;
    logic co;

    fa_calc u_fa_compare (
        .A   (iteration_count),
        .B   (max_iteration),
        .Sel (1'b1),
        .S   (diff),
        .Co  (co),
        .Ov  ()
    );

    assign done = co;

endmodule
