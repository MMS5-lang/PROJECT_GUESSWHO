/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Milosz M. Karolina M.
 *
 * Description:
 * Cursor mode selection for board/button hitboxes and opponent-turn waiting.
 */

module cursor_mode_controller
import guess_who_pkg::*;
(
    output cursor_mode_t cursor_mode,
    output logic mouse_over_hitbox,
    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,
    input  game_state_t game_state
);

timeunit 1ns;
timeprecision 1ps;

logic mouse_over_board;
logic mouse_over_start_btn;
logic mouse_over_reset_btn;

assign mouse_over_board = (mouse_x >= vga_pkg::BOARD_X) &&
                          (mouse_x < vga_pkg::BOARD_X + vga_pkg::BOARD_W) &&
                          (mouse_y >= vga_pkg::BOARD_Y) &&
                          (mouse_y < vga_pkg::BOARD_Y + vga_pkg::BOARD_H);

assign mouse_over_start_btn = (mouse_x >= vga_pkg::START_X) &&
                              (mouse_x < vga_pkg::START_X + vga_pkg::BUTTON_W) &&
                              (mouse_y >= vga_pkg::START_Y) &&
                              (mouse_y < vga_pkg::START_Y + vga_pkg::BUTTON_H);

assign mouse_over_reset_btn = (mouse_x >= vga_pkg::RESET_X) &&
                              (mouse_x < vga_pkg::RESET_X + vga_pkg::BUTTON_W) &&
                              (mouse_y >= vga_pkg::RESET_Y) &&
                              (mouse_y < vga_pkg::RESET_Y + vga_pkg::BUTTON_H);

assign mouse_over_hitbox = mouse_over_board || mouse_over_start_btn || mouse_over_reset_btn;

always_comb begin
    cursor_mode = CURSOR_POINTER;

    if (game_state == S_OPPONENT_TURN) begin
        cursor_mode = CURSOR_BUSY;
    end else if (mouse_over_hitbox) begin
        cursor_mode = CURSOR_POINTER_HOVER;
    end
end

endmodule
