/*
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Milosz M. Karolina M.
 *
 * Description:
 * Parametric delay line for aligning data paths in clocked pipelines.
 */

module delay #(
    parameter WIDTH = 8,
    parameter CLK_DEL = 1
) (
    input logic clk,
    input logic rst_n,
    output logic [WIDTH-1:0] dout,
    input logic [WIDTH-1:0] din
);

logic [WIDTH-1:0] del_mem [CLK_DEL-1:0];

assign dout = del_mem[CLK_DEL-1];

/* -----------------------------------------------------------------------------
 * The first delay stage
 * -------------------------------------------------------------------------- */
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        del_mem[0] <= '0;
    end else begin
        del_mem[0] <= din;
    end
end

/* -----------------------------------------------------------------------------
 * All the other delay stages
 * -------------------------------------------------------------------------- */
genvar i;
generate
    for (i = 1; i < CLK_DEL; i = i + 1) begin
        always_ff @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                del_mem[i] <= '0;
            end else begin
                del_mem[i] <= del_mem[i-1];
            end
        end
    end
endgenerate

endmodule
