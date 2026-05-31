/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Overlay renderer for selection, elimination and guess feedback.
 */

module board_renderer
import vga_pkg::*;
import guess_who_pkg::*;
(
    input  logic clk,
    input  logic rst_n,
    vga_if.out   out,
    input  game_state_t game_state,
    input  logic [CHAR_COUNT-1:0] eliminated_mask,
    input  logic [CHAR_ID_W-1:0] selected_id,
    input  logic [CHAR_ID_W-1:0] last_guess_id,
    input  logic has_secret,
    vga_if.in    in
);

timeunit 1ns;
timeprecision 1ps;

localparam logic [11:0] COLOR_BLACK  = 12'h0_0_0;
localparam logic [11:0] COLOR_BLUE   = 12'h1_4_f;
localparam logic [11:0] COLOR_GREEN  = 12'h0_b_0;
localparam logic [11:0] COLOR_ORANGE = 12'hf_9_0;
localparam logic [11:0] COLOR_RED    = 12'hf_0_0;

logic [11:0] rgb_nxt;

logic in_board;
logic in_panel;
logic is_cell_border;
logic is_panel_border;
logic is_elimination_mark;
logic is_selected_mark;
logic is_last_guess_mark;
logic [10:0] cell_x;
logic [10:0] cell_y;
logic [2:0] col;
logic [1:0] row;
logic [CHAR_ID_W-1:0] char_idx;
logic valid_char;

always_comb begin
    in_board = (in.hcount >= BOARD_X) && (in.hcount < BOARD_X + BOARD_W) &&
               (in.vcount >= BOARD_Y) && (in.vcount < BOARD_Y + BOARD_H);

    in_panel = (in.hcount >= PANEL_X) && (in.hcount < PANEL_X + CELL_W) &&
               (in.vcount >= PANEL_Y) && (in.vcount < PANEL_Y + CELL_H);

    cell_x = 11'h0;
    cell_y = 11'h0;
    col = 3'd0;
    row = 2'd0;

    if (in_board) begin
        if (in.hcount < BOARD_X + CELL_W) begin
            col = 3'd0;
            cell_x = in.hcount - BOARD_X;
        end else if (in.hcount < BOARD_X + 2 * CELL_W) begin
            col = 3'd1;
            cell_x = in.hcount - (BOARD_X + CELL_W);
        end else if (in.hcount < BOARD_X + 3 * CELL_W) begin
            col = 3'd2;
            cell_x = in.hcount - (BOARD_X + 2 * CELL_W);
        end else if (in.hcount < BOARD_X + 4 * CELL_W) begin
            col = 3'd3;
            cell_x = in.hcount - (BOARD_X + 3 * CELL_W);
        end else if (in.hcount < BOARD_X + 5 * CELL_W) begin
            col = 3'd4;
            cell_x = in.hcount - (BOARD_X + 4 * CELL_W);
        end else begin
            col = 3'd5;
            cell_x = in.hcount - (BOARD_X + 5 * CELL_W);
        end

        if (in.vcount < BOARD_Y + CELL_H) begin
            row = 2'd0;
            cell_y = in.vcount - BOARD_Y;
        end else if (in.vcount < BOARD_Y + 2 * CELL_H) begin
            row = 2'd1;
            cell_y = in.vcount - (BOARD_Y + CELL_H);
        end else begin
            row = 2'd2;
            cell_y = in.vcount - (BOARD_Y + 2 * CELL_H);
        end
    end

    case (row)
        2'd0: begin
            char_idx = {2'b00, col};
        end
        2'd1: begin
            char_idx = 5'd6 + {2'b00, col};
        end
        default: begin
            char_idx = 5'd12 + {2'b00, col};
        end
    endcase

    valid_char = in_board && (char_idx < CHAR_COUNT);

    is_cell_border = valid_char && (
        (cell_x < 5) || (cell_x >= CELL_W - 5) ||
        (cell_y < 5) || (cell_y >= CELL_H - 5)
    );

    is_panel_border = in_panel && (
        (in.hcount < PANEL_X + 5) || (in.hcount >= PANEL_X + CELL_W - 5) ||
        (in.vcount < PANEL_Y + 5) || (in.vcount >= PANEL_Y + CELL_H - 5)
    );

    is_elimination_mark = valid_char && eliminated_mask[char_idx] &&
        (cell_x >= 30) && (cell_x < CELL_W - 30) &&
        (cell_y >= 65) && (cell_y < CELL_H - 35);

    is_selected_mark = valid_char && has_secret && (game_state == S_SELECT_SECRET) &&
        (char_idx == selected_id) && is_cell_border;
    is_last_guess_mark = valid_char && (char_idx == last_guess_id) &&
        (game_state == S_WRONG_GUESS_FEEDBACK) && is_cell_border;

    if (in.vblnk || in.hblnk) begin
        rgb_nxt = COLOR_BLACK;
    end else if (is_last_guess_mark) begin
        rgb_nxt = COLOR_RED;
    end else if (is_elimination_mark) begin
        rgb_nxt = 12'h7_7_7;
    end else if (is_selected_mark) begin
        rgb_nxt = COLOR_BLUE;
    end else if (is_panel_border && game_state == S_WIN) begin
        rgb_nxt = COLOR_GREEN;
    end else if (is_panel_border && game_state == S_LOSE) begin
        rgb_nxt = COLOR_RED;
    end else if (is_panel_border && game_state == S_OPPONENT_TURN) begin
        rgb_nxt = COLOR_ORANGE;
    end else if (is_panel_border && game_state == S_MY_TURN) begin
        rgb_nxt = COLOR_GREEN;
    end else if (is_panel_border && has_secret) begin
        rgb_nxt = COLOR_BLUE;
    end else begin
        rgb_nxt = in.rgb;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out.vcount <= '0;
        out.vsync  <= '0;
        out.vblnk  <= '0;
        out.hcount <= '0;
        out.hsync  <= '0;
        out.hblnk  <= '0;
        out.rgb    <= '0;
    end else begin
        out.vcount <= in.vcount;
        out.vsync  <= in.vsync;
        out.vblnk  <= in.vblnk;
        out.hcount <= in.hcount;
        out.hsync  <= in.hsync;
        out.hblnk  <= in.hblnk;
        out.rgb    <= rgb_nxt;
    end
end

endmodule
