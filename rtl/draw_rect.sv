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
    parameter int WIDTH = 530,
    parameter int HEIGHT = 240,
    parameter int THICKNESS = 5,
    parameter logic [11:0] COLOUR = 12'hF00
)(
    input  logic clk,
    input  logic rst_n,
    input logic [11:0] xpos,
    input logic [11:0] ypos,
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

    if ((in.hcount >= xpos) && (in.hcount < xpos + WIDTH) && 
        (in.vcount >= ypos) && (in.vcount < ypos + HEIGHT)) begin
        
        if ((in.hcount < xpos + THICKNESS) || (in.hcount >= xpos + WIDTH - THICKNESS) ||
            (in.vcount < ypos + THICKNESS) || (in.vcount >= ypos + HEIGHT - THICKNESS)) begin
            
            rgb_nxt = COLOUR;
        end
    end
end

endmodule