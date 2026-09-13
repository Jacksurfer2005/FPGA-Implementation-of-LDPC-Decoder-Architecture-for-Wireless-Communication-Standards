`timescale 1ns/1ns

module comp_tree (
    input  logic [7:0] x_1,
    input  logic [7:0] x_2,
    input  logic [7:0] x_3,
    input  logic [7:0] x_4,
    input  logic [7:0] x_5,
    input  logic [7:0] x_6,
    input  logic [7:0] x_7,

    output logic [7:0] y_1,
    output logic [7:0] y_2,
    output logic [7:0] y_3,
    output logic [7:0] y_4,
    output logic [7:0] y_5,
    output logic [7:0] y_6,
    output logic [7:0] y_7,

    output logic [7:0] min_o,
    output logic [7:0] submin_o,

    output logic [7:0] vtc_o_1,
    output logic [7:0] vtc_o_2,
    output logic [7:0] vtc_o_3,
    output logic [7:0] vtc_o_4,
    output logic [7:0] vtc_o_5,
    output logic [7:0] vtc_o_6,
    output logic [7:0] vtc_o_7,

    output logic [3:0] rowWeight
);
    logic [7:0] MAX;
    assign MAX = 8'hFF;

    logic [7:0] m12;
    logic [7:0] m34;
    logic [7:0] m56;
    logic [7:0] m7M;

    logic [7:0] m1234;
    logic [7:0] m567M;

    logic [7:0] e12;
    logic [7:0] e34;
    logic [7:0] e56;
    logic [7:0] e7;

    logic [7:0] min_12;
    logic [7:0] min_34;
    logic [7:0] min_56;
    logic [7:0] min_7M;

    logic [7:0] min_1234;
    logic [7:0] min_567M;

    logic [7:0] min_all;

    logic [7:0] sub_12;
    logic [7:0] sub_34;
    logic [7:0] sub_56;
    logic [7:0] sub_7M;

    logic [7:0] sub_1234;
    logic [7:0] sub_567M;

    logic [7:0] sub_left;
    logic [7:0] sub_right;

    comp_min c1(.A(x_1), .B(x_2), .min_o(m12));
    comp_min c2(.A(x_3), .B(x_4), .min_o(m34));
    comp_min c3(.A(x_5), .B(x_6), .min_o(m56));
    comp_min c4(.A(x_7), .B(MAX), .min_o(m7M));

    comp_min c5(.A(m12), .B(m34), .min_o(m1234));
    comp_min c6(.A(m56), .B(m7M), .min_o(m567M));

    comp_min c7(.A(m34),  .B(m567M), .min_o(e12));
    comp_min c8(.A(m12),  .B(m567M), .min_o(e34));
    comp_min c9(.A(m1234),.B(m7M),   .min_o(e56));
    comp_min c10(.A(m1234),.B(m56),  .min_o(e7));

    comp_min c11(.A(e12), .B(x_2), .min_o(y_1));
    comp_min c12(.A(e12), .B(x_1), .min_o(y_2));
    comp_min c13(.A(e34), .B(x_4), .min_o(y_3));
    comp_min c14(.A(e34), .B(x_3), .min_o(y_4));
    comp_min c15(.A(e56), .B(x_6), .min_o(y_5));
    comp_min c16(.A(e56), .B(x_5), .min_o(y_6));
    //comp_min c17(.A(e7),  .B(x_7), .min_o(y_7));

    assign y_7 = e7;

    // Tín hiệu Min tổng thể
    comp_min c18(.A(m1234), .B(m567M), .min_o(min_o));

    // ĐÃ SỬA LỖI 2: Mạch tính submin_o (Tìm giá trị Max trong tập y_1 .. y_7)
    logic [7:0] max_y12, max_y34, max_y56, max_y1234, max_y567;
    assign max_y12   = (y_1 > y_2) ? y_1 : y_2;
    assign max_y34   = (y_3 > y_4) ? y_3 : y_4;
    assign max_y56   = (y_5 > y_6) ? y_5 : y_6;
    assign max_y1234 = (max_y12 > max_y34) ? max_y12 : max_y34;
    assign max_y567  = (max_y56 > y_7)     ? max_y56 : y_7;
    
    assign submin_o  = (max_y1234 > max_y567) ? max_y1234 : max_y567;

    // Các ngõ ra phụ trợ
    assign vtc_o_1 = y_1;
    assign vtc_o_2 = y_2;
    assign vtc_o_3 = y_3;
    assign vtc_o_4 = y_4;
    assign vtc_o_5 = y_5;
    assign vtc_o_6 = y_6;
    assign vtc_o_7 = y_7;

    assign rowWeight = 4'd7;
endmodule

