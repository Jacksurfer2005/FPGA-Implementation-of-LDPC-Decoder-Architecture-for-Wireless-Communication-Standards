`timescale 1ns/1ns

module comp_min (
	input logic [7:0] A,
	input logic [7:0] B,
	output logic [7:0] min_o
);
	logic [7:0] temp;
	logic co;
	
	fa_calc dut (.A(A), .B(B), .Sel(1'b1), .S(temp), .Co(co), .Ov());
	
	assign min_o = co ? B : A;

endmodule
