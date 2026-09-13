`timescale 1ns/1ns

module check_matrix_mem #(
    parameter int MB          = 6,
    parameter int NB          = 24,
    parameter int Z           = 24,
    parameter int Z0          = 96,
    parameter int DR_MAX      = 7,
    parameter int INIT_WIDTH  = 8,
    parameter string INIT_FILE = "0_src/h_base.mem"
)(
    input  logic clk,

    input  logic [$clog2(MB)-1:0] layer,
    input  logic [$clog2(DR_MAX)-1:0] edge_idx,

    output logic [$clog2(DR_MAX+1)-1:0] row_weight,
    output logic [$clog2(NB)-1:0] col_pos,
    output logic [$clog2(Z)-1:0] shift,
    output logic edge_valid
);

    localparam int COL_W = (NB <= 1) ? 1 : $clog2(NB);
    localparam int EDGE_W = (DR_MAX <= 1) ? 1 : $clog2(DR_MAX);
    localparam int RW_W = $clog2(DR_MAX+1);
    localparam int Z_W = (Z <= 1) ? 1 : $clog2(Z);

    // Raw Hb. FF represents -1.
    logic [INIT_WIDTH-1:0] hb [0:MB*NB-1];

    // Paper's compressed representation.
    logic [COL_W-1:0] pos_mem [0:MB*DR_MAX-1];
    logic [Z_W-1:0]   vals_mem[0:MB*DR_MAX-1];
    logic [RW_W-1:0] elementSize_mem[0:MB-1];

    integer r, c, k;
    integer p_scaled;

    initial begin
        // Safe initialization before reading the file.
        for (int i = 0; i < MB*NB; i = i + 1)
            hb[i] = 8'hFF;

        for (int i = 0; i < MB*DR_MAX; i = i + 1) begin
            pos_mem[i]  = '0;
            vals_mem[i] = '0;
        end

        for (int i = 0; i < MB; i = i + 1)
            elementSize_mem[i] = '0;

        $readmemh("0_src/h_base.mem", hb);

        for (r = 0; r < MB; r = r + 1) begin
            k = 0;

            for (c = 0; c < NB; c = c + 1) begin

                if (hb[r*NB+c] != 8'hFF) begin

                    if (k >= DR_MAX) begin
                        $error(
                            "check_matrix_mem: row %0d has more than DR_MAX=%0d edges",
                            r, DR_MAX
                        );
                        $finish;
                    end

                    // Scale the standard reference shift Z0 -> selected Z.
                    p_scaled = (hb[r*NB+c] * Z) / Z0;

                    pos_mem[r*DR_MAX+k]  = c;
                    vals_mem[r*DR_MAX+k] = p_scaled[Z_W-1:0];

                    k = k + 1;
                end
            end

            elementSize_mem[r] = k;
        end
    end

    // Synchronous read, suitable for the memory-oriented architecture.
    always_ff @(posedge clk) begin
        row_weight <= elementSize_mem[layer];

        if (edge_idx < elementSize_mem[layer]) begin
            col_pos    <= pos_mem[layer*DR_MAX + edge_idx];
            shift      <= vals_mem[layer*DR_MAX + edge_idx];
            edge_valid <= 1'b1;
        end
        else begin
            col_pos    <= '0;
            shift      <= '0;
            edge_valid <= 1'b0;
        end
    end

endmodule
