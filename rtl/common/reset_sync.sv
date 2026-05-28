/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 *
 * Description:
 * Active-low asynchronous reset assertion with synchronous release.
 */

module reset_sync #(
    parameter int STAGES = 2
) (
    input  logic clk,
    input  logic arst_n,
    output logic rst_n
);

timeunit 1ns;
timeprecision 1ps;

localparam int SYNC_STAGES = (STAGES < 1) ? 1 : STAGES;

(* ASYNC_REG = "TRUE" *) logic [SYNC_STAGES-1:0] rst_pipe;

assign rst_n = rst_pipe[SYNC_STAGES-1];

generate
    if (SYNC_STAGES == 1) begin : gen_one_stage
        always_ff @(posedge clk or negedge arst_n) begin
            if (!arst_n) begin
                rst_pipe <= '0;
            end else begin
                rst_pipe <= 1'b1;
            end
        end
    end else begin : gen_multi_stage
        always_ff @(posedge clk or negedge arst_n) begin
            if (!arst_n) begin
                rst_pipe <= '0;
            end else begin
                rst_pipe <= {rst_pipe[SYNC_STAGES-2:0], 1'b1};
            end
        end
    end
endgenerate

endmodule
