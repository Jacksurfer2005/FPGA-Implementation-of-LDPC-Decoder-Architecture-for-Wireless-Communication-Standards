`timescale 1ns/1ns
module fa (
	input logic a,
	input logic b,
	input logic ci,
	output logic s,
	output logic co
);
	assign s = a ^ b ^ ci;
	assign co = a&b | b&ci | ci&a;

	endmodule
