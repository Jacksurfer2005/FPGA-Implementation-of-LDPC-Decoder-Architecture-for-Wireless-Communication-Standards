`timescale 1ns/1ns

module min_submin (
    input  logic       clk,         // Thêm Clock cho Pipeline
    input  logic       rst_n,       // Thêm Reset

    input  logic [7:0] vtc_1,
    input  logic [7:0] vtc_2,
    input  logic [7:0] vtc_3,
    input  logic [7:0] vtc_4,
    input  logic [7:0] vtc_5,
    input  logic [7:0] vtc_6,
    input  logic [7:0] vtc_7,

    output logic [7:0] ctv_1,
    output logic [7:0] ctv_2,
    output logic [7:0] ctv_3,
    output logic [7:0] ctv_4,
    output logic [7:0] ctv_5,
    output logic [7:0] ctv_6,
    output logic [7:0] ctv_7,

    output logic [7:0] min_o,
    output logic [7:0] submin_o,
    output logic [3:0] rowWeight
);

    // ==================================================
    // STAGE 1: TÍNH ABS VÀ DẤU (Logic Tổ Hợp)
    // ==================================================
    logic [7:0] abs_1, abs_2, abs_3, abs_4, abs_5, abs_6, abs_7;
    logic [6:0] sign_bus;
    logic       sign_total;

    abs_calc dut_abs (
        .x_1(vtc_1), 
        .x_2(vtc_2), 
        .x_3(vtc_3), 
        .x_4(vtc_4),
        .x_5(vtc_5), 
        .x_6(vtc_6), 
        .x_7(vtc_7), 
        .x_8(8'b0),
        .y_1(abs_1), 
        .y_2(abs_2), 
        .y_3(abs_3), 
        .y_4(abs_4),
        .y_5(abs_5), 
        .y_6(abs_6), 
        .y_7(abs_7), 
        .y_8(),
        .sign_o(sign_bus)
    );

    signs_xoring dut_sign (
        .sign_i(sign_bus),
        .sign_o(sign_total)
    );

    // ==================================================
    // PIPELINE STAGE 1 -> 2
    // ==================================================
    logic [7:0] abs_1_reg, abs_2_reg, abs_3_reg, abs_4_reg, abs_5_reg, abs_6_reg, abs_7_reg;
    logic [6:0] sign_bus_reg;
    logic       sign_total_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {abs_1_reg, abs_2_reg, abs_3_reg, abs_4_reg, abs_5_reg, abs_6_reg, abs_7_reg} <= '0;
            sign_bus_reg   <= '0;
            sign_total_reg <= '0;
        end else begin
            abs_1_reg <= abs_1; abs_2_reg <= abs_2; abs_3_reg <= abs_3; abs_4_reg <= abs_4;
            abs_5_reg <= abs_5; abs_6_reg <= abs_6; abs_7_reg <= abs_7;
            sign_bus_reg   <= sign_bus;
            sign_total_reg <= sign_total;
        end
    end

    // ==================================================
    // STAGE 2: COMPARATOR TREE
    // ==================================================
    logic [7:0] y_1, y_2, y_3, y_4, y_5, y_6, y_7;
    logic [7:0] min_val, submin_val;

    comp_tree dut_comp (
        .x_1(abs_1_reg), 
        .x_2(abs_2_reg), 
        .x_3(abs_3_reg), 
        .x_4(abs_4_reg),
        .x_5(abs_5_reg), 
        .x_6(abs_6_reg), 
        .x_7(abs_7_reg),
        .y_1(y_1), 
        .y_2(y_2), 
        .y_3(y_3), 
        .y_4(y_4),
        .y_5(y_5), 
        .y_6(y_6), 
        .y_7(y_7),
        .min_o(min_val), 
        .submin_o(submin_val),
        .vtc_o_1(), 
        .vtc_o_2(), 
        .vtc_o_3(), 
        .vtc_o_4(),
        .vtc_o_5(), 
        .vtc_o_6(), 
        .vtc_o_7(),
        .rowWeight(rowWeight)
    );

    // ==================================================
    // NHÂN HỆ SỐ ALPHA (Normalized Min-Sum, Alpha = 0.75)
    // 0.75 * Y = Y - (Y >> 2)
    // ==================================================
    logic [7:0] y_1_norm, y_2_norm, y_3_norm, y_4_norm, y_5_norm, y_6_norm, y_7_norm;
    logic [7:0] min_norm, submin_norm;
    
    assign y_1_norm = y_1 - (y_1 >> 2);
    assign y_2_norm = y_2 - (y_2 >> 2);
    assign y_3_norm = y_3 - (y_3 >> 2);
    assign y_4_norm = y_4 - (y_4 >> 2);
    assign y_5_norm = y_5 - (y_5 >> 2);
    assign y_6_norm = y_6 - (y_6 >> 2);
    assign y_7_norm = y_7 - (y_7 >> 2);
    
    assign min_norm    = min_val - (min_val >> 2);
    assign submin_norm = submin_val - (submin_val >> 2);

    // ==================================================
    // PIPELINE STAGE 2 -> 3
    // ==================================================
    logic [7:0] y_1_reg, y_2_reg, y_3_reg, y_4_reg, y_5_reg, y_6_reg, y_7_reg;
    logic [6:0] sign_bus_reg2;
    logic       sign_total_reg2;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {y_1_reg, y_2_reg, y_3_reg, y_4_reg, y_5_reg, y_6_reg, y_7_reg} <= '0;
            {min_o, submin_o} <= '0;
            sign_bus_reg2     <= '0;
            sign_total_reg2   <= '0;
        end else begin
            y_1_reg <= y_1_norm; y_2_reg <= y_2_norm; y_3_reg <= y_3_norm; y_4_reg <= y_4_norm;
            y_5_reg <= y_5_norm; y_6_reg <= y_6_norm; y_7_reg <= y_7_norm;
            min_o   <= min_norm;
            submin_o <= submin_norm;
            sign_bus_reg2     <= sign_bus_reg;
            sign_total_reg2   <= sign_total_reg;
        end
    end

    // ==================================================
    // STAGE 3: CHÈN LẠI DẤU
    // ==================================================
    sign_insertion dut_insert (
        .x_1(y_1_reg), 
        .x_2(y_2_reg), 
        .x_3(y_3_reg), 
        .x_4(y_4_reg),
        .x_5(y_5_reg), 
        .x_6(y_6_reg), 
        .x_7(y_7_reg),
        .sign_i(sign_bus_reg2),
        .sign_total(sign_total_reg2),
        .y_1(ctv_1), 
        .y_2(ctv_2), 
        .y_3(ctv_3), 
        .y_4(ctv_4),
        .y_5(ctv_5), 
        .y_6(ctv_6), 
        .y_7(ctv_7)
    );

endmodule