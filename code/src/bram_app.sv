`timescale 1ns/1ns

module bram_app #(
  parameter int DEPTH = 24,
  parameter int WIDTH = 192
)(
  input  logic                     clk,
  // cong A - doc
  input  logic                     a_en,
  input  logic [4:0]               a_addr,
  output logic [WIDTH-1:0]         a_dout,
  // cong B - ghi
  input  logic                     b_we,
  input  logic [4:0]               b_addr,
  input  logic [WIDTH-1:0]         b_din
);

  logic [WIDTH-1:0] mem [0:DEPTH-1];

  always_ff @(posedge clk) begin
    if (b_we) mem[b_addr] <= b_din;
  end

  always_ff @(posedge clk) begin
    if (a_en) a_dout <= mem[a_addr];
  end

endmodule
