`timescale 1ns/1ns

module ctv_app_calc (
    // Tín hiệu từ khối Min/submin calculation
    input  logic [7:0] min_i,
    input  logic [7:0] submin_i,
    input  logic [7:0] vtc_1, vtc_2, vtc_3, vtc_4, vtc_5, vtc_6, vtc_7,
    input  logic [3:0] rowWeight,

    // Ngõ ra CTV new (xuất lưu vào BRAM CTV)
    output logic [7:0] ctv_new_1, ctv_new_2, ctv_new_3, ctv_new_4,
    output logic [7:0] ctv_new_5, ctv_new_6, ctv_new_7,

    // Ngõ ra APP new (xuất lưu vào BRAM APP)
    output logic [7:0] app_new_1, app_new_2, app_new_3, app_new_4,
    output logic [7:0] app_new_5, app_new_6, app_new_7
);

    localparam int MAX_INT = 127;
    localparam int MIN_INT = -128;

    // ========================================================
    // 1. BỘ TÍNH CTV_NEW (Tính dấu và chọn Magnitude min/submin)
    // ========================================================
    logic [6:0] vtc_signs;
    logic       sign_total;
    logic [7:0] vtc_abs [1:7];
    logic [7:0] ctv_mag [1:7];
    logic       ctv_sign[1:7];
    logic signed [7:0] ctv_calc [1:7];

    assign vtc_signs  = {vtc_7[7], vtc_6[7], vtc_5[7], vtc_4[7], vtc_3[7], vtc_2[7], vtc_1[7]};
    assign sign_total = ^vtc_signs; // Dấu tổng thể của toàn bộ hàng

    // Lấy giá trị tuyệt đối |VTC|
    assign vtc_abs[1] = vtc_1[7] ? (-vtc_1) : vtc_1;
    assign vtc_abs[2] = vtc_2[7] ? (-vtc_2) : vtc_2;
    assign vtc_abs[3] = vtc_3[7] ? (-vtc_3) : vtc_3;
    assign vtc_abs[4] = vtc_4[7] ? (-vtc_4) : vtc_4;
    assign vtc_abs[5] = vtc_5[7] ? (-vtc_5) : vtc_5;
    assign vtc_abs[6] = vtc_6[7] ? (-vtc_6) : vtc_6;
    assign vtc_abs[7] = vtc_7[7] ? (-vtc_7) : vtc_7;

    always_comb begin
        for (int i = 1; i <= 7; i++) begin
            // Nếu |VTC_i| là giá trị nhỏ nhất (<= min_i), chọn submin_i; ngược lại chọn min_i
            if (vtc_abs[i] <= min_i)
                ctv_mag[i] = submin_i;
            else
                ctv_mag[i] = min_i;

            // Dấu CTV_new = sign_total XOR sign(VTC_i)
            ctv_sign[i] = sign_total ^ vtc_signs[i-1];

            // Đổi Magnitude sang số 8-bit Signed (Bù 2)
            ctv_calc[i] = ctv_sign[i] ? (-$signed({1'b0, ctv_mag[i]})) : $signed({1'b0, ctv_mag[i]});
        end
    end

    assign ctv_new_1 = ctv_calc[1];
    assign ctv_new_2 = ctv_calc[2];
    assign ctv_new_3 = ctv_calc[3];
    assign ctv_new_4 = ctv_calc[4];
    assign ctv_new_5 = ctv_calc[5];
    assign ctv_new_6 = ctv_calc[6];
    assign ctv_new_7 = ctv_calc[7];

    // ========================================================
    // 2. BỘ TÍNH APP_NEW = VTC + CTV_NEW (Có Saturation Logic)
    // ========================================================
    logic signed [7:0] vtc_arr [1:7];
    assign vtc_arr[1] = vtc_1; assign vtc_arr[2] = vtc_2; assign vtc_arr[3] = vtc_3;
    assign vtc_arr[4] = vtc_4; assign vtc_arr[5] = vtc_5; assign vtc_arr[6] = vtc_6;
    assign vtc_arr[7] = vtc_7;

    logic signed [7:0] app_calc [1:7];

    always_comb begin
        for (int i = 1; i <= 7; i++) begin
            int sum;
            sum = $signed(vtc_arr[i]) + $signed(ctv_calc[i]);

            // Giới hạn chống tràn số $[-128, +127]$
            if (sum > MAX_INT)
                app_calc[i] = MAX_INT;
            else if (sum < MIN_INT)
                app_calc[i] = MIN_INT;
            else
                app_calc[i] = sum[7:0];
        end
    end

    assign app_new_1 = app_calc[1];
    assign app_new_2 = app_calc[2];
    assign app_new_3 = app_calc[3];
    assign app_new_4 = app_calc[4];
    assign app_new_5 = app_calc[5];
    assign app_new_6 = app_calc[6];
    assign app_new_7 = app_calc[7];

endmodule