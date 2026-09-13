`timescale 1ns/1ns

module iter_counter #(
  parameter bit DONE = 1
)(
  input  logic       clk,
  input  logic       rst_n,
  input  logic       clear,      // bat dau khung moi
  input  logic       iter_done,  // xung: ket thuc 1 vong lap
  input  logic       converged,  // Hx = 0
  input  logic [4:0] max_iter,
  output logic [4:0] iter_cnt,
  output logic       done        // muc cao -> ket thuc giai ma
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      iter_cnt <= '0;
      done     <= 1'b0;
    end else if (clear) begin
      iter_cnt <= '0;
      done     <= 1'b0;
    end else if (iter_done && !done) begin
      logic [4:0] next_cnt;
      next_cnt = iter_cnt + 1'b1;
      
      iter_cnt <= next_cnt;
      if (next_cnt >= max_iter || (DONE && converged)) begin
        done <= 1'b1;
      end
    end
  end

endmodule
