`timescale 1ns/1ns

module ldpc_top #(
    parameter int Z  = 24,
    parameter int DW = 8,
    parameter int MB = 6,
    parameter int NB = 24
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,             // Xung khởi tạo giải mã khung dữ liệu mới[cite: 21, 27]
    input  logic        count_en,          // Xung báo kết thúc 1 vòng lặp (iter_done)[cite: 21, 27]
    input  logic        converged,         // Tín hiệu báo hội tụ Hx = 0[cite: 21, 27]
    input  logic [7:0]  max_iteration,     // Cấu hình số vòng lặp tối đa[cite: 21, 27]

    // Giao tiếp nạp dữ liệu LLR ban đầu vào BRAM APP[cite: 23]
    input  logic                     ext_app_we,
    input  logic [4:0]               ext_app_addr,
    input  logic [Z*DW-1:0]          ext_app_din,

    // Giao tiếp địa chỉ quét ma trận kiểm tra (FSM điều khiển bên ngoài)[cite: 23, 24, 25]
    input  logic [4:0]               app_rd_addr,
    input  logic [4:0]               app_wr_addr,
    input  logic [6:0]               ctv_rd_addr,
    input  logic [6:0]               ctv_wr_addr,
    input  logic [$clog2(MB)-1:0]    matrix_layer,
    input  logic [3:0]               matrix_edge_idx,

    // Tín hiệu ngõ ra điều khiển và dữ liệu giải mã
    output logic        ready,             // Tín hiệu sẵn sàng xuất dữ liệu[cite: 21]
    output logic        done,              // Tín hiệu hoàn thành giải mã[cite: 21, 27]
    output logic        mode,              // 0: DECODING, 1: RESULT OUTPUT[cite: 21]
    output logic [7:0]  iteration_count,   // Số vòng lặp hiện tại[cite: 21]
    output logic [7:0]  output_data        // Dữ liệu ngõ ra[cite: 21]
);

    // =========================================================================
    // TÍN HIỆU KẾT NỐI NỘI BỘ (INTERNAL WIRES)
    // =========================================================================

    // 1. Dữ liệu BRAM APP[cite: 23]
    logic [Z*DW-1:0]           bram_app_dout;
    logic [Z*DW-1:0]           bram_app_din;
    logic [4:0]                bram_app_wr_addr;
    logic                      bram_app_we;

    // 2. Dữ liệu BRAM CTV[cite: 24]
    logic [Z*DW-1:0]           bram_ctv_dout;
    logic [Z*DW-1:0]           bram_ctv_din;

    // 3. Tín hiệu Memory Check Matrix
    logic [$clog2(16)-1:0]     row_weight;
    logic [$clog2(NB)-1:0]     col_pos;
    logic [$clog2(Z)-1:0]      shift_val;
    logic                      edge_valid;

    // 4. Tín hiệu VTC (Chuyển đổi kiểu dữ liệu Packed <-> Unpacked)[cite: 22]
    logic signed [Z-1:0][DW-1:0] vtc_app_in;
    logic signed [Z-1:0][DW-1:0] vtc_ctv_in;
    logic signed [Z-1:0][DW-1:0] vtc_out;

    // 5. Tín hiệu Min/Submin Calculation[cite: 28]
    logic [DW-1:0]             min_val;
    logic [DW-1:0]             submin_val;
    logic [3:0]                min_row_weight;
    logic [DW-1:0]             ctv_stage1 [1:7];

    // 6. Tín hiệu CTV & APP mới (Sau tính toán)[cite: 26]
    logic [DW-1:0]             ctv_new [1:7];
    logic [DW-1:0]             app_new [1:7];

    // 7. Tín hiệu đếm vòng lặp độc lập[cite: 27]
    logic [4:0]                standalone_iter_cnt;
    logic                      standalone_done;

    // =========================================================================
    // GHÉP VÀ BIẾN ĐỔI DỮ LIỆU (DATA PACKING & BUS MATCHING)
    // =========================================================================
    
    // Tách 192-bit BRAM dout thành mảng 24 phần tử 8-bit cho vtc_calc[cite: 22, 23, 24]
    always_comb begin
        for (int i = 0; i < Z; i++) begin
            vtc_app_in[i] = bram_app_dout[i*DW +: DW];
            vtc_ctv_in[i] = bram_ctv_dout[i*DW +: DW];
        end
    end

    // Đóng gói các phần tử APP_new và CTV_new mới thành Bus 192-bit để ghi vào BRAM
    always_comb begin
        bram_app_din = '0;
        bram_ctv_din = '0;
        for (int i = 0; i < 7; i++) begin
            bram_app_din[i*DW +: DW] = app_new[i+1];
            bram_ctv_din[i*DW +: DW] = ctv_new[i+1];
        end
    end

    // Lựa chọn cổng ghi BRAM APP (Nạp từ ngoài vs Cập nhật APP_new khi giải mã)[cite: 21, 23]
    assign bram_app_we      = ext_app_we ? 1'b1 : (mode ? 1'b0 : 1'b1);
    assign bram_app_wr_addr = ext_app_we ? ext_app_addr : app_wr_addr;

    // =========================================================================
    // NỐI 8 MODULE CON (SUB-MODULE INSTANTIATION)
    // =========================================================================

    // MODULE 1: BRAM APP (Lưu trữ Log-Likelihood Ratios)[cite: 23]
    bram_app #(
        .DEPTH(Z),
        .WIDTH(Z*DW)
    ) u_bram_app (
        .clk    (clk),
        .a_en   (1'b1),
        .a_addr (app_rd_addr),
        .a_dout (bram_app_dout),
        .b_we   (bram_app_we),
        .b_addr (bram_app_wr_addr),
        .b_din  (ext_app_we ? ext_app_din : bram_app_din)
    );

    // MODULE 2: Operating Mode Selection (Quản lý trạng thái giải mã / xuất kết quả)[cite: 21]
    mode_select_top u_mode_select_top (
        .clk             (clk),
        .reset_n         (rst_n),
        .start           (start),
        .count_en        (count_en),
        .converged       (converged),
        .max_iteration   (max_iteration),
        .decoding_data   (bram_app_dout[7:0]),
        .result_data     (app_new[1]),
        .iteration_count (iteration_count),
        .done            (done),
        .mode            (mode),
        .ready           (ready),
        .output_data     (output_data)
    );

    // MODULE 3: Iterations Counter (Bộ đếm số vòng lặp độc lập)[cite: 27]
    iter_counter #(
        .DONE(1)
    ) u_iter_counter (
        .clk       (clk),
        .rst_n     (rst_n),
        .clear     (start),
        .iter_done (count_en),
        .converged (converged),
        .max_iter  (max_iteration[4:0]),
        .iter_cnt  (standalone_iter_cnt),
        .done      (standalone_done)
    );

    // MODULE 4: Memory for Check Matrix (Lưu cấu trúc ma trận H_b nén)[cite: 25]
    check_matrix #(
        .MB(MB),
        .NB(NB),
        .Z(Z)
    ) u_check_matrix (
        .clk        (clk),
        .layer      (matrix_layer),
        .edge_idx   (matrix_edge_idx),
        .row_weight (row_weight),
        .col_pos    (col_pos),
        .shift      (shift_val),
        .edge_valid (edge_valid)
    );

    // MODULE 5: VTC Calculation (Tính VTC = APP - CTV)[cite: 22]
    vtc_calc #(
        .DW(DW),
        .Z(Z)
    ) u_vtc_calc (
        .app_i (vtc_app_in),
        .ctv_i (vtc_ctv_in),
        .vtc_o (vtc_out)
    );

    // MODULE 6: Min/Submin Calculation (Tính Min1, Min2 và nhân hệ số Alpha = 0.75)[cite: 28]
    min_submin u_min_submin (
        .clk       (clk),
        .rst_n     (rst_n),
        .vtc_1     (vtc_out[0]),
        .vtc_2     (vtc_out[1]),
        .vtc_3     (vtc_out[2]),
        .vtc_4     (vtc_out[3]),
        .vtc_5     (vtc_out[4]),
        .vtc_6     (vtc_out[5]),
        .vtc_7     (vtc_out[6]),
        .ctv_1     (ctv_stage1[1]),
        .ctv_2     (ctv_stage1[2]),
        .ctv_3     (ctv_stage1[3]),
        .ctv_4     (ctv_stage1[4]),
        .ctv_5     (ctv_stage1[5]),
        .ctv_6     (ctv_stage1[6]),
        .ctv_7     (ctv_stage1[7]),
        .min_o     (min_val),
        .submin_o  (submin_val),
        .rowWeight (min_row_weight)
    );

    // MODULE 7: CTV and APP Calculation (Cập nhật CTV_new và APP_new)[cite: 26]
    ctv_app_calc u_ctv_app_calc (
        .min_i     (min_val),
        .submin_i  (submin_val),
        .vtc_1     (vtc_out[0]),
        .vtc_2     (vtc_out[1]),
        .vtc_3     (vtc_out[2]),
        .vtc_4     (vtc_out[3]),
        .vtc_5     (vtc_out[4]),
        .vtc_6     (vtc_out[5]),
        .vtc_7     (vtc_out[6]),
        .rowWeight (min_row_weight),
        .ctv_new_1 (ctv_new[1]),
        .ctv_new_2 (ctv_new[2]),
        .ctv_new_3 (ctv_new[3]),
        .ctv_new_4 (ctv_new[4]),
        .ctv_new_5 (ctv_new[5]),
        .ctv_new_6 (ctv_new[6]),
        .ctv_new_7 (ctv_new[7]),
        .app_new_1 (app_new[1]),
        .app_new_2 (app_new[2]),
        .app_new_3 (app_new[3]),
        .app_new_4 (app_new[4]),
        .app_new_5 (app_new[5]),
        .app_new_6 (app_new[6]),
        .app_new_7 (app_new[7])
    );

    // MODULE 8: BRAM CTV (Lưu trữ tin nhắn Check-to-Variable)[cite: 24]
    bram_ctv #(
        .DEPTH(Z),
        .WIDTH(Z*DW)
    ) u_bram_ctv (
        .clk     (clk),
        .rd_en   (1'b1),
        .rd_addr (ctv_rd_addr),
        .rd_data (bram_ctv_dout),
        .wr_en   (!mode), // Khóa ghi khi đã ở RESULT mode
        .wr_addr (ctv_wr_addr),
        .wr_data (bram_ctv_din)
    );

endmodule