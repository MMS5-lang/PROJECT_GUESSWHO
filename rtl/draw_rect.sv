/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Draw background.
 */

 module draw_rect #(
    parameter int X_POS = 100,
    parameter int Y_POS = 100,
    parameter int WIDTH = 200,
    parameter int HEIGHT = 150,
    parameter logic [11:0] COLOUR = 12'hF00
)(
    input  logic clk,
    input  logic rst_n,
    vga_if.in    in,
    vga_if.out   out
);

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;


/**
 * Local variables and signals
 */

logic [11:0] rgb_nxt;


/**
 * Internal logic
 */
// module out (vga_if.out oif);
// module in (vga_if.in iif);
always_ff @(posedge clk or negedge rst_n) begin : bg_ff_blk
    if (!rst_n) begin
        out.vcount <= '0;
        out.vsync  <= '0;
        out.vblnk <= '0;
        out.hcount <= '0;
        out.hsync  <= '0;
        out.hblnk  <= '0;
        out.rgb    <= '0;
    end else begin
        out.vcount <= in.vcount;
        out.vsync <= in.vsync;
        out.vblnk <= in.vblnk;
        out.hcount <= in.hcount;
        out.hsync <= in.hsync;
        out.hblnk <= in.hblnk;
        out.rgb   <= rgb_nxt;
    end
end

always_comb begin : bg_comb_blk
    rgb_nxt = in.rgb; 
         if ((in.hcount >= X_POS) && (in.hcount < X_POS + WIDTH) && (in.vcount >= Y_POS) && (in.vcount < Y_POS + HEIGHT))
            rgb_nxt = COLOUR;
    end


endmodule
