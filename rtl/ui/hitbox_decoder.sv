/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Mouse hitbox decoder for board cells and game buttons.
 */

module hitbox_decoder (
    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,
    input  logic        left_click,
    input  logic        right_click,
    output logic        start_click,
    output logic        reset_click,
    output logic        char_left_click,
    output logic        char_right_click,
    output logic [guess_who_pkg::CHAR_ID_W-1:0] char_id
);

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;
import guess_who_pkg::*;

logic in_board;
logic in_start_btn;
logic in_reset_btn;
logic [2:0] col;
logic [1:0] row;

always_comb begin
    in_board = (mouse_x >= BOARD_X) && (mouse_x < BOARD_X + BOARD_W) &&
               (mouse_y >= BOARD_Y) && (mouse_y < BOARD_Y + BOARD_H);

    in_start_btn = (mouse_x >= START_X) && (mouse_x < START_X + BUTTON_W) &&
                   (mouse_y >= BUTTON_Y) && (mouse_y < BUTTON_Y + BUTTON_H);

    in_reset_btn = (mouse_x >= RESET_X) && (mouse_x < RESET_X + BUTTON_W) &&
                   (mouse_y >= BUTTON_Y) && (mouse_y < BUTTON_Y + BUTTON_H);

    col = 3'd0;
    row = 2'd0;

    if (in_board) begin
        if (mouse_x < BOARD_X + CELL_W) begin
            col = 3'd0;
        end else if (mouse_x < BOARD_X + 2 * CELL_W) begin
            col = 3'd1;
        end else if (mouse_x < BOARD_X + 3 * CELL_W) begin
            col = 3'd2;
        end else if (mouse_x < BOARD_X + 4 * CELL_W) begin
            col = 3'd3;
        end else if (mouse_x < BOARD_X + 5 * CELL_W) begin
            col = 3'd4;
        end else begin
            col = 3'd5;
        end

        if (mouse_y < BOARD_Y + CELL_H) begin
            row = 2'd0;
        end else if (mouse_y < BOARD_Y + 2 * CELL_H) begin
            row = 2'd1;
        end else begin
            row = 2'd2;
        end
    end

    case (row)
        2'd0: begin
            char_id = {2'b00, col};
        end
        2'd1: begin
            char_id = 5'd6 + {2'b00, col};
        end
        default: begin
            char_id = 5'd12 + {2'b00, col};
        end
    endcase

    start_click = left_click && in_start_btn;
    reset_click = left_click && in_reset_btn;
    char_left_click = left_click && in_board;
    char_right_click = right_click && in_board;
end

endmodule
