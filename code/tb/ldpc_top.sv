`timescale 1ns/1ns

/**
 * Module Top-Level LDPC Decoder
 * Kiến trúc dựa trên hình 1 (Figure 1) trong bài báo MOCAST 2021:
 * "FPGA Implementation of LDPC Decoder Architecture for Wireless Communication Standards"
 */
module ldpc_top #(
    parameter int DW       = 8,            // Độ rộng dữ liệu LLR/APP/VTC/CTV
    parameter int Z        = 24,           // Kích thước circulant matrix (z = 24)
    parameter int MB       = 6,            // Số hàng ma trận cơ sở Hb
    parameter int NB       = 24,           // Số cột ma trận cơ sở Hb
    parameter int DR_MAX   = 15            // Trọng số hàng tối đa
)(
    input  logic          clk,
    input  logic          rst_n,
    input  logic          start,           // Xung bắt đầu giải mã khung dữ liệu mới
    input  logic [7:0]    max_iteration,   // Số vòng lặp tối đa
    
    // Giao tiếp nạp dữ liệu mềm (Soft-decision channel LLRs)
    input  logic          data_in_valid,
    input  logic [4:0]    data_in_addr,
    input  logic [7:0]    data_in_val,
    
    // Ngõ ra kết quả
    output logic          ready,           // Sẵn sàng / Giải mã hoàn tất
    output logic          mode,            // 0: DECODING, 1: RESULT
    output logic [7:0]    iteration_count, // Số vòng lặp thực tế đã thực hiện
    output logic [7:0]    data_out         // Dữ liệu giải mã ngõ ra
);

    localparam int APP_WIDTH = Z * DW;     // 24 * 8 = 192 bits (hoặc 144 bits theo cấu hình 18-bit block)
    localparam int CTV_WIDTH = 7 * DW;     // 7 * 8 = 56 bits (chứa 7 tin nhắn CTV)

    // =========================================================================
    // 1. QUẢN LÝ TRẠNG THÁI (CONTROL FSM)
    // =========================================================================
    typedef enum logic [2:0] {
        ST_IDLE,
        ST_LOAD_APP,
        ST_READ_LAYER,
        ST_CALC_VTC_MIN,
        ST_WRITE_BACK,
        ST_NEXT_LAYER,
        ST_DONE
    } state_t;

    state_t state, next_state;

    logic [$clog2(MB)-1:0] layer_cnt;
    logic                  count_en;
    logic                  done_signal;

    // Control layer counting
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= ST_IDLE;
            layer_cnt <= '0;
        end else begin
            state <= next_state;
            if (state == ST_NEXT_LAYER) begin
                if (layer_cnt == MB - 1)
                    layer_cnt <= '0;
                else
                    layer_cnt <= layer_cnt + 1'b1;
            end else if (state == ST_IDLE) begin
                layer_cnt <= '0;
            end
        end
    end

    // FSM chuyển trạng thái
    always_comb begin
        next_state = state;
        count_en   = 1'b0;

        case (state)
            ST_IDLE: begin
                if (start)
                    next_state = ST_READ_LAYER;
                else if (data_in_valid)
                    next_state = ST_LOAD_APP;
            end

            ST_LOAD_APP: begin
                next_state = ST_IDLE;
            end

            ST_READ_LAYER: begin
                next_state = ST_CALC_VTC_MIN;
            end

            ST_CALC_VTC_MIN: begin
                next_state = ST_WRITE_BACK;
            end

            ST_WRITE_BACK: begin
                next_state = ST_NEXT_LAYER;
            end

            ST_NEXT_LAYER: begin
                if (layer_cnt == MB - 1) begin
                    count_en = 1'b1; // Tăng đếm vòng lặp khi duyệt hết các layer
                    if (done_signal)
                        next_state = ST_DONE;
                    else
                        next_state = ST_READ_LAYER;
                end else begin
                    next_state = ST_READ_LAYER;
                end
            end

            ST_DONE: begin
                if (start)
                    next_state = ST_READ_LAYER;
            end

            default: next_state = ST_IDLE;
        endcase
    end

    // =========================================================================
    // 2. CHECK MATRIX MEMORY (BỘ NHỚ MA TRẬN KIỂM TRA Hb)
    // =========================================================================
    logic [$clog2(DR_MAX+1)-1:0] row_weight;
    logic [$clog2(NB)-1:0]       col_pos;
    logic [$clog2(Z)-1:0]        shift_val;
    logic                        edge_valid;

    check_matrix_mem #(
        .MB(MB), .NB(NB), .Z(Z), .Z0(96), .DR_MAX(DR_MAX),
        .INIT_WIDTH(8), .INIT_FILE("h_base.mem")
    ) u_check_matrix (
        .clk        (clk),
        .layer      (layer_cnt),
        .edge_idx   (4'd0),
        .row_weight (row_weight),
        .col_pos    (col_pos),
        .shift      (shift_val),
        .edge_valid (edge_valid)
    );

    // =========================================================================
    // 3. BRAM APP (BỘ NHỚ CHỨA XÁC SUẤT HẬU NGHIỆM APP)
    // =========================================================================
    logic                  app_a_en;
    logic [4:0]            app_a_addr;
    logic [143:0]          app_a_dout;
    logic                  app_b_we;
    logic [4:0]            app_b_addr;
    logic [143:0]          app_b_din;

    assign app_a_en   = (state == ST_READ_LAYER) || (state == ST_DONE);
    assign app_a_addr = (state == ST_DONE) ? 5'd0 : col_pos[4:0];

    assign app_b_we   = (state == ST_LOAD_APP) || (state == ST_WRITE_BACK);
    assign app_b_addr = (state == ST_LOAD_APP) ? data_in_addr : col_pos[4:0];

    // Tạo vector APP dữ liệu nạp hoặc ghi lại
    logic [143:0] app_updated_bus;
    assign app_b_din  = (state == ST_LOAD_APP) ? {136'b0, data_in_val} : app_updated_bus;

    bram_app #(
        .DEPTH(24),
        .WIDTH(144)
    ) u_bram_app (
        .clk    (clk),
        .a_en   (app_a_en),
        .a_addr (app_a_addr),
        .a_dout (app_a_dout),
        .b_we   (app_b_we),
        .b_addr (app_b_addr),
        .b_din  (app_b_din)
    );

    // =========================================================================
    // 4. BRAM CTV (BỘ NHỚ CHỨA TIN NHẮN CHECK-TO-VARIABLE)
    // =========================================================================
    logic         ctv_rd_en;
    logic [6:0]   ctv_rd_addr;
    logic [143:0] ctv_rd_data;
    logic         ctv_wr_en;
    logic [6:0]   ctv_wr_addr;
    logic [143:0] ctv_wr_data;

    assign ctv_rd_en   = (state == ST_READ_LAYER);
    assign ctv_rd_addr = {4'b0, layer_cnt};

    assign ctv_wr_en   = (state == ST_WRITE_BACK);
    assign ctv_wr_addr = {4'b0, layer_cnt};

    bram_ctv #(
        .DEPTH(24),
        .WIDTH(144)
    ) u_bram_ctv (
        .clk     (clk),
        .rd_en   (ctv_rd_en),
        .rd_addr (ctv_rd_addr),
        .rd_data (ctv_rd_data),
        .wr_en   (ctv_wr_en),
        .wr_addr (ctv_wr_addr),
        .wr_data (ctv_wr_data)
    );

    // =========================================================================
    // 5. OPERATING MODE SELECTION & ITERATION COUNTER
    // =========================================================================
    logic [7:0] raw_app_byte;
    assign raw_app_byte = app_a_dout[7:0];

    // Quyết định cứng: Bit giải mã cứng x_n = (APP > 0) ? 0 : 1
    logic [7:0] hard_decision_byte;
    assign hard_decision_byte = raw_app_byte[7] ? 8'h01 : 8'h00;

    mode_select_top u_mode_select (
        .clk             (clk),
        .reset_n         (rst_n),
        .start           (start),
        .count_en        (count_en),
        .max_iteration   (max_iteration),
        .decoding_data   (raw_app_byte),
        .result_data     (hard_decision_byte),
        .iteration_count (iteration_count),
        .done            (done_signal),
        .mode            (mode),
        .ready           (ready),
        .output_data     (data_out)
    );

    // =========================================================================
    // 6. VTC CALCULATION (APP - CTV)
    // =========================================================================
    logic signed [Z-1:0][DW-1:0] app_vec, ctv_vec, vtc_vec;

		genvar i;
		generate
			 for (i = 0; i < Z; i++) begin : gen_vec
				  assign app_vec[i] = (i < 18) ? app_a_dout[i*8 +: 8] : 8'd0;
				  assign ctv_vec[i] = (i < 18) ? ctv_rd_data[i*8 +: 8] : 8'd0;
			 end
		endgenerate

    vtc_calc #(
        .DW(DW),
        .Z(Z)
    ) u_vtc_calc (
        .app_i (app_vec),
        .ctv_i (ctv_vec),
        .vtc_o (vtc_vec)
    );

    // =========================================================================
    // 7. MIN / SUBMIN CALCULATION (NORM-MIN-SUM CNU PIPELINE)
    // =========================================================================
    logic [7:0] ctv_new_1, ctv_new_2, ctv_new_3, ctv_new_4, ctv_new_5, ctv_new_6, ctv_new_7;
    logic [7:0] min_val, submin_val;
    logic [3:0] row_weight_out;

    min_submin u_min_submin (
        .clk        (clk),
        .rst_n      (rst_n),
        .vtc_1      (vtc_vec[0]),
        .vtc_2      (vtc_vec[1]),
        .vtc_3      (vtc_vec[2]),
        .vtc_4      (vtc_vec[3]),
        .vtc_5      (vtc_vec[4]),
        .vtc_6      (vtc_vec[5]),
        .vtc_7      (vtc_vec[6]),
        .ctv_1      (ctv_new_1),
        .ctv_2      (ctv_new_2),
        .ctv_3      (ctv_new_3),
        .ctv_4      (ctv_new_4),
        .ctv_5      (ctv_new_5),
        .ctv_6      (ctv_new_6),
        .ctv_7      (ctv_new_7),
        .min_o      (min_val),
        .submin_o   (submin_val),
        .rowWeight  (row_weight_out)
    );

    assign ctv_wr_data = {88'b0, ctv_new_7, ctv_new_6, ctv_new_5, ctv_new_4, ctv_new_3, ctv_new_2, ctv_new_1};

    // =========================================================================
    // 8. CTV AND APP CALCULATION (APP_NEW = VTC + CTV_NEW)
    // =========================================================================
    logic [7:0] app_new_1, app_new_2, app_new_3, app_new_4, app_new_5, app_new_6, app_new_7;

    ctv_app_calc u_ctv_app_calc (
        .vtc_1 (vtc_vec[0]), .vtc_2 (vtc_vec[1]), .vtc_3 (vtc_vec[2]), .vtc_4 (vtc_vec[3]),
        .vtc_5 (vtc_vec[4]), .vtc_6 (vtc_vec[5]), .vtc_7 (vtc_vec[6]),
        .ctv_1 (ctv_new_1),  .ctv_2 (ctv_new_2),  .ctv_3 (ctv_new_3),  .ctv_4 (ctv_new_4),
        .ctv_5 (ctv_new_5),  .ctv_6 (ctv_new_6),  .ctv_7 (ctv_new_7),
        .app_1 (app_new_1),  .app_2 (app_new_2),  .app_3 (app_new_3),  .app_4 (app_new_4),
        .app_5 (app_new_5),  .app_6 (app_new_6),  .app_7 (app_new_7)
    );

    assign app_updated_bus = {88'b0, app_new_7, app_new_6, app_new_5, app_new_4, app_new_3, app_new_2, app_new_1};

endmodule