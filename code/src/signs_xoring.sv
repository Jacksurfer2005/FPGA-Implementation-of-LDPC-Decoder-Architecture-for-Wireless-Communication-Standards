`timescale 1ns/1ns

module signs_xoring (
    input  logic [6:0] sign_i,
    output logic       sign_o
);
    assign sign_o = ^sign_i;
endmodule