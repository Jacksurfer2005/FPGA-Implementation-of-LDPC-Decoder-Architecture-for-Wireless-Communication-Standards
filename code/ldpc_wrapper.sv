`timescale 1ns/1ns

/**
 * Wrapper Module cho Bo mạch Terasic DE10-Standard (Altera Cyclone V)
 * Kết nối LDPC Decoder với Nút bấm (KEY), Switch (SW), LED (LEDR),
 * LED 7 đoạn (HEX) và Cổng nối tiếp UART RX.
 */
module ldpc_wrapper (
    input  logic        CLOCK_50,   // Xung Clock 50MHz
    input  logic [3:0]  KEY,        // KEY[0]: Reset active-low, KEY[1]: Start
    input  logic [9:0]  SW,         // SW[7:0]: Max iterations / Input Data
    output logic [9:0]  LEDR,       // LEDR[0]: Ready, LEDR[1]: Mode, LEDR[9:2]: Status
    output logic [6:0]  HEX0,       // LED 7 đoạn hiển thị Hex Byte ngõ ra (LSB)
    output logic [6:0]  HEX1,       // LED 7 đoạn hiển thị Hex Byte ngõ ra (MSB)
    output logic [6:0]  HEX2,       // Tắt / Dự phòng
    output logic [6:0]  HEX3,       // Tắt / Dự phòng
    output logic [6:0]  HEX4,       // Hiển thị số vòng lặp (LSB)
    output logic [6:0]  HEX5,       // Hiển thị số vòng lặp (MSB)
    input  logic        UART_RX     // Chân thu UART từ PC/Chip UART
);

    // Đồng bộ hóa tín hiệu Reset và Start từ KEY
    logic rst_n;
    logic start_btn;
    assign rst_n     = KEY[0];
    assign start_btn = ~KEY[1]; // Active-high pulse khi nhấn nút KEY1

    // -------------------------------------------------------------------------
    // 1. MODULE UART RX (THU DỮ LIỆU NẠP TỪ BÊN NGOÀI)
    // -------------------------------------------------------------------------
    logic [7:0] rx_data;
    logic       rx_valid;

    uart_rx #(
        .CLK_FREQ(100_000_000),   // Tần số Clock 50MHz trên Kit DE10-Standard
        .BAUD_RATE(115_200)      // Baudrate chuẩn 115200 bps
    ) u_uart_rx (
        .clk      (CLOCK_50),
        .rst_n    (rst_n),
        .rx       (UART_RX),
        .rx_data  (rx_data),
        .rx_valid (rx_valid)
    );

    // Tự động tăng địa chỉ RAM khi thu thành công 1 Byte UART
    logic [4:0] auto_load_addr;
    always_ff @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n)
            auto_load_addr <= '0;
        else if (rx_valid)
            auto_load_addr <= auto_load_addr + 1'b1;
    end

    // -------------------------------------------------------------------------
    // 2. TÍCH HỢP BỘ GIẢI MÃ LDPC TOP
    // -------------------------------------------------------------------------
    logic       ready;
    logic       mode;
    logic [7:0] iter_cnt;
    logic [7:0] decoded_data;
    logic [7:0] max_iter_val;

    // Chọn số vòng lặp tối đa từ công tắc SW[7:0], mặc định = 10 nếu công tắc = 0
    assign max_iter_val = (SW[7:0] == 8'h00) ? 8'd10 : SW[7:0];

    ldpc_top #(
        .DW(8),
        .Z(24),
        .MB(6),
        .NB(24),
        .DR_MAX(15)
    ) u_ldpc_dut (
        .clk             (CLOCK_50),
        .rst_n           (rst_n),
        .start           (start_btn),
        .max_iteration   (max_iter_val),
        
        .data_in_valid   (rx_valid),
        .data_in_addr    (auto_load_addr),
        .data_in_val     (rx_data),
        
        .ready           (ready),
        .mode            (mode),
        .iteration_count (iter_cnt),
        .data_out        (decoded_data)
    );

    // -------------------------------------------------------------------------
    // 3. HIỂN THỊ ĐÈN LEDR TÍNH TRẠNG
    // -------------------------------------------------------------------------
    assign LEDR[0]   = ready;         // Sáng khi hoàn tất giải mã
    assign LEDR[1]   = mode;          // 0: Decoding, 1: Result
    assign LEDR[2]   = rx_valid;      // Chớp khi thu dữ liệu UART thành công
    assign LEDR[9:3] = decoded_data[6:0]; // Hiển thị các bit kết quả trực tiếp

    // -------------------------------------------------------------------------
    // 4. BỘ GIẢI MÃ LED 7 ĐOẠN (SEVEN-SEGMENT DECODERS)
    // -------------------------------------------------------------------------
	// Chuyển hiển thị số vòng lặp (iter_cnt) sang HEX2 và HEX3
	hex_decoder u_hex0 (.hex_digit(decoded_data[3:0]), .seg(HEX0));
	hex_decoder u_hex1 (.hex_digit(decoded_data[7:4]), .seg(HEX1));
	hex_decoder u_hex2 (.hex_digit(iter_cnt[3:0]),     .seg(HEX2)); // Hiển thị LSB số vòng lặp
	hex_decoder u_hex3 (.hex_digit(iter_cnt[7:4]),     .seg(HEX3)); // Hiển thị MSB số vòng lặp
	assign HEX4 = 7'b111_1111; // Tắt HEX4
	assign HEX5 = 7'b111_1111; // Tắt HEX5

endmodule

// Module hỗ trợ giải mã 4-bit Hex ra màn hình LED 7 đoạn (Active-Low)
module hex_decoder (
    input  logic [3:0] hex_digit,
    output logic [6:0] seg
);
    always_comb begin
        case (hex_digit)
            4'h0: seg = 7'b100_0000;
            4'h1: seg = 7'b111_1001;
            4'h2: seg = 7'b010_0100;
            4'h3: seg = 7'b011_0000;
            4'h4: seg = 7'b001_1001;
            4'h5: seg = 7'b001_0010;
            4'h6: seg = 7'b000_0010;
            4'h7: seg = 7'b111_1000;
            4'h8: seg = 7'b000_0000;
            4'h9: seg = 7'b001_0000;
            4'hA: seg = 7'b000_1000;
            4'hB: seg = 7'b000_0011;
            4'hC: seg = 7'b100_0110;
            4'hD: seg = 7'b010_0001;
            4'hE: seg = 7'b000_0110;
            4'hF: seg = 7'b000_1110;
            default: seg = 7'b111_1111;
        endcase
    end
endmodule