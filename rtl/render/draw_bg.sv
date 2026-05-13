/**
 * Description:
 * Rysowanie tła i planszy 6x3 dla gry Guess Who
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
logic [10:0] relative_x;
logic [10:0] relative_y;


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
    relative_x = in.hcount - BOARD_X;
    relative_y = in.vcount - BOARD_Y;

    in_board = (in.hcount >= BOARD_X) && (in.hcount <= BOARD_X + BOARD_W) &&
               (in.vcount >= BOARD_Y) && (in.vcount <= BOARD_Y + BOARD_H);

    is_board_frame = in_board && (
        (in.hcount < BOARD_X + 3) || 
        (in.hcount > BOARD_X + BOARD_W - 3) ||
        (in.vcount < BOARD_Y + 3) || 
        (in.vcount > BOARD_Y + BOARD_H - 3)
    );


    is_cell_frame = in_board && (!is_board_frame) && (
        (relative_x % CELL_W < 2) || 
        (relative_y % CELL_H < 2)
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
        rgb_nxt = 12'h9_a_b;               
    end
end

 endmodule