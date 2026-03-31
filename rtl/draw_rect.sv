/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Draw hollow rectangle (frame).
 */

 module draw_rect #(
    // Parametry obejmujące obszar inicjałów (X: 100-590, Y: 200-400) z marginesem
    parameter int X_POS = 80,
    parameter int Y_POS = 180,
    parameter int WIDTH = 530,
    parameter int HEIGHT = 240,
    parameter int THICKNESS = 5,
    parameter logic [11:0] COLOUR = 12'hF00
)(
    input  logic clk,
    input  logic rst_n,
    vga_if.in    in,
    vga_if.out   out
);

timeunit 1ns;
timeprecision 1ps;

logic [11:0] rgb_nxt;

always_ff @(posedge clk or negedge rst_n) begin : rect_ff_blk
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

always_comb begin : rect_comb_blk
    rgb_nxt = in.rgb;

    if ((in.hcount >= X_POS) && (in.hcount < X_POS + WIDTH) && 
        (in.vcount >= Y_POS) && (in.vcount < Y_POS + HEIGHT)) begin
        
        if ((in.hcount < X_POS + THICKNESS) || (in.hcount >= X_POS + WIDTH - THICKNESS) ||
            (in.vcount < Y_POS + THICKNESS) || (in.vcount >= Y_POS + HEIGHT - THICKNESS)) begin
            
            rgb_nxt = COLOUR;
        end
    end
end

endmodule