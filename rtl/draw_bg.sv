/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Draw background and initials using VGA interface.
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
    rgb_nxt = in.rgb;

    if (in.vblnk || in.hblnk) begin
        rgb_nxt = 12'h0_0_0;
    end else begin
        if (in.vcount == 0) begin
            rgb_nxt = 12'hf_f_0;
        end else if (in.vcount == VER_PIXELS - 1) begin
            rgb_nxt = 12'hf_0_0;
        end else if (in.hcount == 0) begin
            rgb_nxt = 12'h0_f_0;
        end else if (in.hcount == HOR_PIXELS - 1) begin
            rgb_nxt = 12'h0_0_f;
        end else if ((in.hcount >= 100) && (in.hcount < 110) &&
                     (in.vcount >= 200) && (in.vcount < 400)) begin
            rgb_nxt = 12'hf_0_f;
        end else if ((in.hcount >= 110) && (in.hcount < 200) &&
                     (in.vcount >= 405 - in.hcount) &&
                     (in.vcount <= 415 - in.hcount)) begin
            rgb_nxt = 12'hf_0_f;
        end else if ((in.hcount >= 110) && (in.hcount < 200) &&
                     (in.vcount >= in.hcount + 185) &&
                     (in.vcount <= in.hcount + 195)) begin
            rgb_nxt = 12'hf_0_f;
        end else if ((in.hcount >= 220) && (in.hcount < 230) &&
                     (in.vcount >= 200) && (in.vcount < 400)) begin
            rgb_nxt = 12'hf_0_f;
        end else if ((in.hcount >= 310) && (in.hcount < 320) &&
                     (in.vcount >= 200) && (in.vcount < 400)) begin
            rgb_nxt = 12'hf_0_f;
        end else if ((in.hcount >= 230) && (in.hcount < 270) &&
                     (in.vcount + 260 >= 2 * in.hcount) &&
                     (in.vcount + 250 <= 2 * in.hcount)) begin
            rgb_nxt = 12'hf_0_f;
        end else if ((in.hcount >= 270) && (in.hcount < 310) &&
                     (in.vcount + 2 * in.hcount >= 820) &&
                     (in.vcount + 2 * in.hcount <= 830)) begin
            rgb_nxt = 12'hf_0_f;
        end else if ((in.hcount >= 370) && (in.hcount < 380) &&
                     (in.vcount >= 200) && (in.vcount < 400)) begin
            rgb_nxt = 12'hf_0_f;
        end else if ((in.hcount >= 460) && (in.hcount < 470) &&
                     (in.vcount >= 200) && (in.vcount < 400)) begin
            rgb_nxt = 12'hf_0_f;
        end else if ((in.hcount >= 380) && (in.hcount < 420) &&
                     (in.vcount + 560 >= 2 * in.hcount) &&
                     (in.vcount + 550 <= 2 * in.hcount)) begin
            rgb_nxt = 12'hf_0_f;
        end else if ((in.hcount >= 420) && (in.hcount < 460) &&
                     (in.vcount + 2 * in.hcount >= 1120) &&
                     (in.vcount + 2 * in.hcount <= 1130)) begin
            rgb_nxt = 12'hf_0_f;
        end else if ((in.hcount >= 490) && (in.hcount < 500) &&
                     (in.vcount >= 200) && (in.vcount < 400)) begin
            rgb_nxt = 12'hf_0_f;
        end else if ((in.hcount >= 580) && (in.hcount < 590) &&
                     (in.vcount >= 200) && (in.vcount < 400)) begin
            rgb_nxt = 12'hf_0_f;
        end else if ((in.hcount >= 500) && (in.hcount < 540) &&
                     (in.vcount + 800 >= 2 * in.hcount) &&
                     (in.vcount + 790 <= 2 * in.hcount)) begin
            rgb_nxt = 12'hf_0_f;
        end else if ((in.hcount >= 540) && (in.hcount < 580) &&
                     (in.vcount + 2 * in.hcount >= 1360) &&
                     (in.vcount + 2 * in.hcount <= 1370)) begin
            rgb_nxt = 12'hf_0_f;
        end
    end
end

endmodule
