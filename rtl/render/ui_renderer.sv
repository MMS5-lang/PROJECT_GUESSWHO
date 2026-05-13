/**
 * Description:
 * Warstwa UI: przyciski START, RESET oraz panel wybranej postaci.
 */

 module ui_renderer (
    input  logic clk,
    input  logic rst_n,
    vga_if.in    in,
    vga_if.out   out
);

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;

logic [11:0] rgb_nxt;
logic is_start_btn, is_reset_btn, is_panel;

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

always_comb begin
    is_start_btn = (in.hcount >= START_X) && (in.hcount < START_X + BUTTON_W) && (in.vcount >= BUTTON_Y)   && (in.vcount < BUTTON_Y + BUTTON_H);
                   
    is_reset_btn = (in.hcount >= RESET_X) && (in.hcount < RESET_X + BUTTON_W) && (in.vcount >= BUTTON_Y)   && (in.vcount < BUTTON_Y + BUTTON_H);
                   
    is_panel = (in.hcount >= PANEL_X) && (in.hcount < PANEL_X + CELL_W) && (in.vcount >= PANEL_Y) && (in.vcount < PANEL_Y + CELL_H);

    if (in.vblnk || in.hblnk) begin
        rgb_nxt = 12'h0_0_0;
    end else if (is_start_btn) begin
        rgb_nxt = 12'h0_b_0; 
    end else if (is_reset_btn) begin
        rgb_nxt = 12'hd_0_0; 
    end else if (is_panel) begin
        rgb_nxt = 12'hf_f_f; 
    end else begin
        rgb_nxt = in.rgb;    
    end
end

endmodule

