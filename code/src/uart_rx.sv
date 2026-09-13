`timescale 1ns/1ns

module uart_rx #(
  parameter int CLK_FREQ  = 100_000_000, // Tần số xung clock System (100 MHz)
  parameter int BAUD_RATE = 115_200      // Tốc độ truyền dữ liệu UART
)(
  input  logic       clk,
  input  logic       rst_n,
  input  logic       rx,
  output logic [7:0] rx_data,
  output logic       rx_valid
);

  localparam int CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

  typedef enum logic [1:0] {
    S_IDLE,
    S_START,
    S_DATA,
    S_STOP
  } state_t;

  state_t     state;
  int         clk_cnt;
  int         bit_idx;
  logic [7:0] data_shift;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state      <= S_IDLE;
      clk_cnt    <= 0;
      bit_idx    <= 0;
      rx_valid   <= 1'b0;
      rx_data    <= 8'h00;
      data_shift <= 8'h00;
    end else begin
      rx_valid <= 1'b0;

      case (state)
        S_IDLE: begin
          clk_cnt <= 0;
          bit_idx <= 0;
          if (rx == 1'b0) begin // Phân biệt Start bit (mức LOW)
            state <= S_START;
          end
        end

        S_START: begin
          if (clk_cnt == (CLKS_PER_BIT - 1) / 2) begin
            if (rx == 1'b0) begin
              clk_cnt <= 0;
              state   <= S_DATA;
            end else begin
              state   <= S_IDLE;
            end
          end else begin
            clk_cnt <= clk_cnt + 1;
          end
        end

        S_DATA: begin
          if (clk_cnt < CLKS_PER_BIT - 1) begin
            clk_cnt <= clk_cnt + 1;
          end else begin
            clk_cnt            <= 0;
            data_shift[bit_idx] <= rx;
            if (bit_idx < 7) begin
              bit_idx <= bit_idx + 1;
            end else begin
              bit_idx <= 0;
              state   <= S_STOP;
            end
          end
        end

        S_STOP: begin
          if (clk_cnt < CLKS_PER_BIT - 1) begin
            clk_cnt <= clk_cnt + 1;
          end else begin
            rx_valid <= 1'b1;
            rx_data  <= data_shift;
            state    <= S_IDLE;
          end
        end

        default: state <= S_IDLE;
      endcase
    end
  end

endmodule