`timescale 1ns/1ns

module mode_select_top (
    input  logic        clk,
    input  logic        reset_n,
    input  logic        start,            // Xung kích hoạt bắt đầu giải mã khung dữ liệu mới
    input  logic        count_en,         // Xung báo hoàn thành 1 vòng lặp (iter_done)
    input  logic        converged,        // Tín hiệu báo ma trận chẵn lẻ hội tụ Hx = 0 (Early termination)

    input  logic [7:0]  max_iteration,    // Số vòng lặp tối đa được cấu hình

    input  logic [7:0]  decoding_data,    // Dữ liệu tạm thời trong quá trình giải mã
    input  logic [7:0]  result_data,      // Dữ liệu từ mã giải mã thành công (Hard decision)

    output logic [7:0]  iteration_count,
    output logic        done,             // Tín hiệu hoàn thành giải mã
    output logic        mode,             // 0: DECODING mode, 1: RESULT OUTPUT mode
    output logic        ready,            // Tín hiệu báo sẵn sàng xuất dữ liệu ra ngoài
    output logic [7:0]  output_data       // Dữ liệu xuất ra ngoài
);

    // Tín hiệu báo đạt số vòng lặp tối đa từ bộ so sánh iter_compare
    logic max_iter_done;
    
    // Điều kiện xong tức thời (kết hợp cả 2 điều kiện dừng của bài báo)
    logic done_comb;
    
    // Thanh ghi lưu giữ trạng thái done cho đến khi nhận khung mới (start)
    logic done_reg;

    // ========================================================
    // 1. ITERATION COUNTER (Bộ đếm số vòng lặp)
    // ========================================================
    iteration_counter u_iteration_counter (
        .clk     (clk),
        .reset_n (reset_n),
        .start   (start),
        .enable  (count_en && !done_reg && !done_comb), // Chặn không cho đếm tiếp khi đã giải mã xong
        .count   (iteration_count)
    );

    // ========================================================
    // 2. ITERATION COMPARATOR (So sánh với max_iteration)
    // ========================================================
    iter_compare u_iter_compare (
        .iteration_count (iteration_count),
        .max_iteration   (max_iteration),
        .done            (max_iter_done)
    );

    // ========================================================
    // 3. DONE LOGIC & LATCH REGISTRY (Theo đúng bài báo)
    // ========================================================
    // Điều kiện dừng giải mã trong bài báo:
    // (1) Đạt số vòng lặp tối đa (max_iter_done) HOẶC
    // (2) Toàn bộ từ mã thỏa mãn phương trình Hx = 0 (converged)
    assign done_comb = max_iter_done | converged;

    // Chốt (Latch) trạng thái done lên 1 cho đến khi nhận xung start của khung dữ liệu tiếp theo
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            done_reg <= 1'b0;
        end else if (start) begin
            done_reg <= 1'b0;          // Reset về 0 để chuẩn bị cho khung giải mã mới
        end else if (done_comb) begin
            done_reg <= 1'b1;          // Giữ mức cao 1 khi bất kỳ điều kiện dừng nào xảy ra
        end
    end

    assign done = done_reg;

    // ========================================================
    // 4. MODE & READY CONTROL (Mục III-A trong bài báo)
    // ========================================================
    // done = 0: MODE = 0 (DECODING), READY = 0
    // done = 1: MODE = 1 (RESULT OUTPUT), READY = 1
    assign mode  = done;
    assign ready = done;

    // Multiplexer chuyển đổi ngõ ra:
    // - Khi đang giải mã (mode = 0): Xuất decoding_data (hoặc dữ liệu nội bộ)
    // - Khi hoàn thành (mode = 1)  : Xuất result_data (từ mã đã giải mã xong)
    assign output_data = mode ? result_data : decoding_data;

endmodule