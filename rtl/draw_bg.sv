/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Draw background.
 */

module draw_bg (
        input  logic clk,
        input  logic rst_n,

        input  logic [10:0] vcount_in,
        input  logic        vsync_in,
        input  logic        vblnk_in,
        input  logic [10:0] hcount_in,
        input  logic        hsync_in,
        input  logic        hblnk_in,

        output logic [10:0] vcount_out,
        output logic        vsync_out,
        output logic        vblnk_out,
        output logic [10:0] hcount_out,
        output logic        hsync_out,
        output logic        hblnk_out,

        output logic [11:0] rgb_out
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

    always_ff @(posedge clk or negedge rst_n) begin : bg_ff_blk
        if (!rst_n) begin
            vcount_out <= '0;
            vsync_out  <= '0;
            vblnk_out  <= '0;
            hcount_out <= '0;
            hsync_out  <= '0;
            hblnk_out  <= '0;
            rgb_out    <= '0;
        end else begin
            vcount_out <= vcount_in;
            vsync_out  <= vsync_in;
            vblnk_out  <= vblnk_in;
            hcount_out <= hcount_in;
            hsync_out  <= hsync_in;
            hblnk_out  <= hblnk_in;
            rgb_out    <= rgb_nxt;
        end
    end

    always_comb begin : bg_comb_blk
        if (vblnk_in || hblnk_in) begin             // Blanking region:
            rgb_nxt = 12'h0_0_0;                    // - make it it black.
        end else begin                              // Active region:
            if (vcount_in == 0)                     // - top edge:
                rgb_nxt = 12'hf_f_0;                // - - make a yellow line.
            else if (vcount_in == VER_PIXELS - 1)   // - bottom edge:
                rgb_nxt = 12'hf_0_0;                // - - make a red line.
            else if (hcount_in == 0)                // - left edge:
                rgb_nxt = 12'h0_f_0;                // - - make a green line.
            else if (hcount_in == HOR_PIXELS - 1)   // - right edge:
                rgb_nxt = 12'h0_0_f;                // - - make a blue line.
            //litera K
            else if (( hcount_in >=100 && hcount_in<110) && (vcount_in>= 200 && vcount_in<400))
                rgb_nxt = 12'hf_0_f;
            else if ((hcount_in >= 110 && hcount_in < 200) && (vcount_in >= 405 - hcount_in) && (vcount_in <= 415 - hcount_in))
                rgb_nxt = 12'hf_0_f;
            else if ((hcount_in >= 110 && hcount_in < 200) && (vcount_in >= hcount_in + 185) && (vcount_in <= hcount_in + 195))
                rgb_nxt = 12'hf_0_f;
            //koniec litery K

            // Litera M
            else if ((hcount_in >= 220 && hcount_in < 230 && vcount_in >= 200 && vcount_in < 400) ||
                     (hcount_in >= 310 && hcount_in < 320 && vcount_in >= 200 && vcount_in < 400) ||
                     (hcount_in >= 230 && hcount_in < 270 && vcount_in + 260 >= 2 * hcount_in && vcount_in + 250 <= 2 * hcount_in) ||
                     (hcount_in >= 270 && hcount_in < 310 && vcount_in + 2 * hcount_in >= 820 && vcount_in + 2 * hcount_in <= 830))
                rgb_nxt = 12'hf_0_f;


            // Litera M
            else if ((hcount_in >= 370 && hcount_in < 380 && vcount_in >= 200 && vcount_in < 400) ||
                     (hcount_in >= 460 && hcount_in < 470 && vcount_in >= 200 && vcount_in < 400) ||
                     (hcount_in >= 380 && hcount_in < 420 && vcount_in + 560 >= 2 * hcount_in && vcount_in + 550 <= 2 * hcount_in) ||
                     (hcount_in >= 420 && hcount_in < 460 && vcount_in + 2 * hcount_in >= 1120 && vcount_in + 2 * hcount_in <= 1130))
                rgb_nxt = 12'hf_0_f;

            // Litera M
            else if ((hcount_in >= 490 && hcount_in < 500 && vcount_in >= 200 && vcount_in < 400) ||
                     (hcount_in >= 580 && hcount_in < 590 && vcount_in >= 200 && vcount_in < 400) ||
                     (hcount_in >= 500 && hcount_in < 540 && vcount_in + 800 >= 2 * hcount_in && vcount_in + 790 <= 2 * hcount_in) ||
                     (hcount_in >= 540 && hcount_in < 580 && vcount_in + 2 * hcount_in >= 1360 && vcount_in + 2 * hcount_in <= 1370))
                rgb_nxt = 12'hf_0_f;
            else                                    // The rest of active display pixels:
                rgb_nxt = 12'h8_8_8;                // - fill with gray.
        end
    end

endmodule
