`timescale 1ns/1ns

module bram_ctv #(
  parameter int DEPTH = 24,
  parameter int WIDTH = 192
)(
  input  logic                     clk,
  input  logic                     rd_en,
  input  logic [6:0]               rd_addr,
  output logic [WIDTH-1:0]         rd_data,
  input  logic                     wr_en,
  input  logic [6:0]               wr_addr,
  input  logic [WIDTH-1:0]         wr_data
);

  logic [WIDTH-1:0] mem [0:DEPTH-1];

  always_ff @(posedge clk) begin
    if (wr_en) mem[wr_addr] <= wr_data;
    if (rd_en) rd_data      <= mem[rd_addr];
  end

endmodule
