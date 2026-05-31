/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Rysowanie tla i planszy 6x3 dla gry Guess Who.
 */

module draw_bg (
    input  logic clk,
    input  logic rst_n,
    vga_if.in    in,
    vga_if.out   out
);

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;

logic [11:0] rgb_nxt;

logic in_board;
logic is_board_frame;
logic is_cell_frame;
logic is_grid_col;
logic is_grid_row;

always_ff @(posedge clk or negedge rst_n) begin : bg_ff_blk
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

always_comb begin : bg_comb_blk
    in_board = (in.hcount >= BOARD_X) && (in.hcount < BOARD_X + BOARD_W) &&
               (in.vcount >= BOARD_Y) && (in.vcount < BOARD_Y + BOARD_H);

    is_board_frame = in_board && (
        (in.hcount < BOARD_X + 3) ||
        (in.hcount >= BOARD_X + BOARD_W - 3) ||
        (in.vcount < BOARD_Y + 3) ||
        (in.vcount >= BOARD_Y + BOARD_H - 3)
    );

    is_grid_col =
        ((in.hcount >= BOARD_X + CELL_W)     && (in.hcount < BOARD_X + CELL_W + 2)) ||
        ((in.hcount >= BOARD_X + 2 * CELL_W) && (in.hcount < BOARD_X + 2 * CELL_W + 2)) ||
        ((in.hcount >= BOARD_X + 3 * CELL_W) && (in.hcount < BOARD_X + 3 * CELL_W + 2)) ||
        ((in.hcount >= BOARD_X + 4 * CELL_W) && (in.hcount < BOARD_X + 4 * CELL_W + 2)) ||
        ((in.hcount >= BOARD_X + 5 * CELL_W) && (in.hcount < BOARD_X + 5 * CELL_W + 2));

    is_grid_row =
        ((in.vcount >= BOARD_Y + CELL_H)     && (in.vcount < BOARD_Y + CELL_H + 2)) ||
        ((in.vcount >= BOARD_Y + 2 * CELL_H) && (in.vcount < BOARD_Y + 2 * CELL_H + 2));

    is_cell_frame = in_board && (!is_board_frame) && (
        is_grid_col ||
        is_grid_row
    );

    if (in.vblnk || in.hblnk) begin
        rgb_nxt = 12'h0_0_0;
    end else if (is_board_frame) begin
        rgb_nxt = 12'h0_0_0;
    end else if (is_cell_frame) begin
        rgb_nxt = 12'h5_5_5;
    end else if (in_board) begin
        rgb_nxt = 12'hf_f_f;
    end else begin
        rgb_nxt = in.rgb;
    end
end

endmodule
