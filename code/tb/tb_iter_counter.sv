`timescale 1ns/1ns

module tb_iter_counter;

  // Tham số mô phỏng
  parameter bit DONE_PARAM = 1;
  parameter int CLK_PERIOD = 10;

  // Tín hiệu kết nối DUT[cite: 20]
  logic       clk;
  logic       rst_n;
  logic       clear;
  logic       iter_done;
  logic       converged;
  logic [4:0] max_iter;
  logic [4:0] iter_cnt;
  logic       done;

  // Kết nối chính xác module iter_counter[cite: 20]
  iter_counter #(
    .DONE(DONE_PARAM)
  ) dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .clear     (clear),
    .iter_done (iter_done),
    .converged (converged),
    .max_iter  (max_iter),
    .iter_cnt  (iter_cnt),
    .done      (done)
  );

  // Khởi tạo xung Clock
  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // Ghi nhận Waveform ra file VCD để xem bằng GTKWave / ModelSim
  initial begin
    $dumpfile("tb_iter_counter.vcd");
    $dumpvars(0, tb_iter_counter);
  end

  // Task tạo 1 xung iter_done đồng bộ theo chu kỳ Clock[cite: 20]
  task automatic pulse_iter_done();
    @(posedge clk);
    iter_done <= 1'b1;
    @(posedge clk);
    iter_done <= 1'b0;
  endtask

  // Tiến trình 10 Kịch bản kiểm thử
  initial begin
    // ------------------------------------------------------------------------
    // CASE 1: Kiểm tra Async Reset ban đầu[cite: 20]
    // ------------------------------------------------------------------------
    $display("\n[TB] === TC1: Reset hệ thống (Async Reset) ===");
    rst_n     = 0;
    clear     = 0;
    iter_done = 0;
    converged = 0;
    max_iter  = 5'd5;
    #(CLK_PERIOD * 2);

    if (iter_cnt === 0 && done === 1'b0)
      $display("[TB] TC1 PASSED: Tín hiệu Reset thành công (iter_cnt=0, done=0)");
    else
      $display("[TB] TC1 FAILED: iter_cnt=%0d, done=%b", iter_cnt, done);

    rst_n = 1;
    @(posedge clk);

    // ------------------------------------------------------------------------
    // CASE 2: Đếm bình thường tới max_iter (max_iter = 4, converged = 0)[cite: 20]
    // ------------------------------------------------------------------------
    $display("\n[TB] === TC2: Đếm đạt max_iter = 4 (converged = 0) ===");
    clear = 1; @(posedge clk); clear = 0;
    
    repeat (4) pulse_iter_done();
    @(posedge clk);

    if (done === 1'b1 && iter_cnt === 4)
      $display("[TB] TC2 PASSED: Đã dừng giải mã chuẩn xác tại iter_cnt = 4");
    else
      $display("[TB] TC2 FAILED: iter_cnt=%0d, done=%b", iter_cnt, done);

    // ------------------------------------------------------------------------
    // CASE 3: Dừng sớm do hội tụ (converged = 1 tại vòng thứ 2)[cite: 20]
    // ------------------------------------------------------------------------
    $display("\n[TB] === TC3: Dừng sớm do hội tụ (converged = 1 tại iter 2) ===");
    max_iter = 5'd10;
    clear = 1; @(posedge clk); clear = 0;

    pulse_iter_done(); // Iter 1
    converged = 1'b1;
    pulse_iter_done(); // Iter 2 (converged active)
    converged = 1'b0;
    @(posedge clk);

    if (done === 1'b1 && iter_cnt === 2)
      $display("[TB] TC3 PASSED: Dừng sớm chính xác tại iter_cnt = 2 khi converged = 1");
    else
      $display("[TB] TC3 FAILED: iter_cnt=%0d, done=%b", iter_cnt, done);

    // ------------------------------------------------------------------------
    // CASE 4: Xóa đếm (clear) giữa chừng khi đang đếm dở[cite: 20]
    // ------------------------------------------------------------------------
    $display("\n[TB] === TC4: Tín hiệu clear giữa chừng ===");
    clear = 1; @(posedge clk); clear = 0;

    repeat (2) pulse_iter_done(); // Đếm lên 2
    clear = 1; @(posedge clk); clear = 0; // Clear ngắt ngang
    @(posedge clk);

    if (iter_cnt === 0 && done === 1'b0)
      $display("[TB] TC4 PASSED: Tín hiệu clear đã xoá bộ đếm về 0");
    else
      $display("[TB] TC4 FAILED: iter_cnt=%0d, done=%b", iter_cnt, done);

    // ------------------------------------------------------------------------
    // CASE 5: Hội tụ ngay ở vòng đầu tiên (iter 1)[cite: 20]
    // ------------------------------------------------------------------------
    $display("\n[TB] === TC5: Hội tụ ngay ở vòng 1 (converged = 1 tại iter 1) ===");
    clear = 1; @(posedge clk); clear = 0;
    converged = 1'b1;
    pulse_iter_done();
    converged = 1'b0;
    @(posedge clk);

    if (done === 1'b1 && iter_cnt === 1)
      $display("[TB] TC5 PASSED: Dừng thành công ngay tại iter_cnt = 1");
    else
      $display("[TB] TC5 FAILED: iter_cnt=%0d, done=%b", iter_cnt, done);

    // ------------------------------------------------------------------------
    // CASE 6: Xung iter_done thừa sau khi đã ở trạng thái done = 1[cite: 20]
    // ------------------------------------------------------------------------
    $display("\n[TB] === TC6: Kiểm tra khóa bộ đếm khi đã done = 1 ===");
    pulse_iter_done(); // Bơm thêm pulse khi done đã = 1
    @(posedge clk);

    if (iter_cnt === 1 && done === 1'b1)
      $display("[TB] TC6 PASSED: Đã khóa đếm thành công, iter_cnt không tăng tràn");
    else
      $display("[TB] TC6 FAILED: iter_cnt=%0d, done=%b", iter_cnt, done);

    // ------------------------------------------------------------------------
    // CASE 7: Khôi phục trạng thái bằng clear sau khi đã done[cite: 20]
    // ------------------------------------------------------------------------
    $display("\n[TB] === TC7: Xóa khung cũ bằng clear khi đang done = 1 ===");
    clear = 1; @(posedge clk); clear = 0;
    @(posedge clk);

    if (iter_cnt === 0 && done === 1'b0)
      $display("[TB] TC7 PASSED: Thoát khỏi trạng thái done=1, sẵn sàng cho khung mới");
    else
      $display("[TB] TC7 FAILED: iter_cnt=%0d, done=%b", iter_cnt, done);

    // ------------------------------------------------------------------------
    // CASE 8: Thay đổi max_iter động trong lúc đang chạy[cite: 20]
    // ------------------------------------------------------------------------
    $display("\n[TB] === TC8: Thay đổi max_iter động (từ 10 xuống 3) ===");
    max_iter = 5'd10;
    clear = 1; @(posedge clk); clear = 0;

    repeat (2) pulse_iter_done(); // iter_cnt = 2
    max_iter = 5'd3;              // Đổi max_iter xuống 3
    pulse_iter_done();            // iter_cnt = 3
    @(posedge clk);

    if (done === 1'b1 && iter_cnt === 3)
      $display("[TB] TC8 PASSED: Cập nhật max_iter động và dừng chính xác");
    else
      $display("[TB] TC8 FAILED: iter_cnt=%0d, done=%b", iter_cnt, done);

    // ------------------------------------------------------------------------
    // CASE 9: Đếm cực đại max_iter = 31 (5-bit MAX)[cite: 20]
    // ------------------------------------------------------------------------
    $display("\n[TB] === TC9: Kiểm tra giới hạn tối đa 5-bit (max_iter = 31) ===");
    max_iter = 5'd31;
    clear = 1; @(posedge clk); clear = 0;

    repeat (31) pulse_iter_done();
    @(posedge clk);

    if (done === 1 meq 1'b1 && iter_cnt === 31)
      $display("[TB] TC9 PASSED: Đếm đủ 31 vòng và báo done chính xác");
    else
      $display("[TB] TC9 FAILED: iter_cnt=%0d, done=%b", iter_cnt, done);

    // ------------------------------------------------------------------------
    // CASE 10: Tín hiệu converged bật lên nhưng không có iter_done[cite: 20]
    // ------------------------------------------------------------------------
    $display("\n[TB] === TC10: Bật converged nhưng không kích iter_done ===");
    clear = 1; @(posedge clk); clear = 0;
    converged = 1'b1;
    #(CLK_PERIOD * 3); // Chờ 3 chu kỳ clock mà không phát xung iter_done

    if (iter_cnt === 0 && done === 1'b0)
      $display("[TB] TC10 PASSED: Giữ nguyên trạng thái khi chưa có pulse iter_done");
    else
      $display("[TB] TC10 FAILED: iter_cnt=%0d, done=%b", iter_cnt, done);

    $display("\n[TB] HOÀN THÀNH TOÀN BỘ 10 KỊCH BẢN KĨỂM THỬ.");
    $finish;
  end

endmodule