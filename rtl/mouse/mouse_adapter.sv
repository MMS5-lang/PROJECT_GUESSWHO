/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Adapts mouse signals in the shared 65 MHz clock domain and creates click pulses.
 */

module mouse_adapter
import vga_pkg::*;
(
    input  logic        clk,
    input  logic        rst_n,
    output logic [11:0] mouse_x,
    output logic [11:0] mouse_y,
    output logic        left_click_pulse,
    output logic        right_click_pulse,
    input  logic [11:0] mouse_x_raw,
    input  logic [11:0] mouse_y_raw,
    input  logic        mouse_left_raw,
    input  logic        mouse_right_raw
);

timeunit 1ns;
timeprecision 1ps;

localparam logic [11:0] MOUSE_MAX_X = HOR_PIXELS - 1;
localparam logic [11:0] MOUSE_MAX_Y = VER_PIXELS - 1;

logic mouse_left_prev;
logic mouse_right_prev;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mouse_x <= '0;
        mouse_y <= '0;
        mouse_left_prev <= 1'b0;
        mouse_right_prev <= 1'b0;
        left_click_pulse <= 1'b0;
        right_click_pulse <= 1'b0;
    end else begin
        mouse_x <= (mouse_x_raw > MOUSE_MAX_X) ? MOUSE_MAX_X : mouse_x_raw;
        mouse_y <= (mouse_y_raw > MOUSE_MAX_Y) ? MOUSE_MAX_Y : mouse_y_raw;
        mouse_left_prev <= mouse_left_raw;
        mouse_right_prev <= mouse_right_raw;
        left_click_pulse <= mouse_left_raw && !mouse_left_prev;
        right_click_pulse <= mouse_right_raw && !mouse_right_prev;
    end
end

endmodule
