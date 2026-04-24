/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Mouse cursor drawing wrapper for the VHDL MouseDisplay module.
 */

module draw_mouse (
        input  logic       clk,
        input  logic       rst_n,
        input  logic [11:0] xpos,
        input  logic [11:0] ypos,
        vga_if.in          in,
        vga_if.out         out
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */
    logic        blank;
    logic [11:0] mouse_rgb;
    logic [10:0] vcount_dly;
    logic        vsync_dly;
    logic        vblnk_dly;
    logic [10:0] hcount_dly;
    logic        hsync_dly;
    logic        hblnk_dly;

    /**
     * Signal assignments
     */
    assign blank = in.hblnk || in.vblnk;

    /**
     * Submodule instances
     */
    MouseDisplay u_mouse_display (
        .pixel_clk                (clk),
        .xpos                     (xpos),
        .ypos                     (ypos),
        .hcount                   (in.hcount),
        .vcount                   (in.vcount),
        .blank                    (blank),
        .rgb_in                   (in.rgb),
        .enable_mouse_display_out (),
        .rgb_out                  (mouse_rgb)
    );

    /**
     * Sequential logic
     */
    always_ff @(posedge clk or negedge rst_n) begin : mouse_ff_blk
        if (!rst_n) begin
            vcount_dly <= '0;
            vsync_dly  <= '0;
            vblnk_dly  <= '0;
            hcount_dly <= '0;
            hsync_dly  <= '0;
            hblnk_dly  <= '0;
            out.vcount <= '0;
            out.vsync  <= '0;
            out.vblnk  <= '0;
            out.hcount <= '0;
            out.hsync  <= '0;
            out.hblnk  <= '0;
            out.rgb    <= '0;
        end else begin
            vcount_dly <= in.vcount;
            vsync_dly  <= in.vsync;
            vblnk_dly  <= in.vblnk;
            hcount_dly <= in.hcount;
            hsync_dly  <= in.hsync;
            hblnk_dly  <= in.hblnk;
            out.vcount <= vcount_dly;
            out.vsync  <= vsync_dly;
            out.vblnk  <= vblnk_dly;
            out.hcount <= hcount_dly;
            out.hsync  <= hsync_dly;
            out.hblnk  <= hblnk_dly;
            out.rgb    <= mouse_rgb;
        end
    end

endmodule
