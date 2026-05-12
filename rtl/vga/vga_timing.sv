/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Vga timing controller.
 */

module vga_timing (
        input  logic clk,
        input  logic rst_n,
        output logic [10:0] vcount,
        output logic vsync,
        output logic vblnk,
        output logic [10:0] hcount,
        output logic hsync,
        output logic hblnk
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;


    /**
     * Local variables and signals
     */

    logic [10:0] vcount_nxt;
    logic [10:0] hcount_nxt;
    logic        vsync_nxt;
    logic        vblnk_nxt;
    logic        hsync_nxt;
    logic        hblnk_nxt;

    /**
     * Sequential logic
     */
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vcount <= '0;
            hcount <= '0;
            vsync  <= '0;
            vblnk  <= '0;
            hsync  <= '0;
            hblnk  <= '0;
        end else begin
            vcount <= vcount_nxt;
            hcount <= hcount_nxt;
            vsync  <= vsync_nxt;
            vblnk  <= vblnk_nxt;
            hsync  <= hsync_nxt;
            hblnk  <= hblnk_nxt;
        end
    end

    /**
     * Combinational logic
     */
    always_comb begin
        vcount_nxt = vcount;
        hcount_nxt = hcount;

        if (hcount == HOR_TOTAL_TIME - 1) begin
            hcount_nxt = '0;

            if (vcount == VER_TOTAL_TIME - 1) begin
                vcount_nxt = '0;
            end else begin
                vcount_nxt = vcount + 11'd1;
            end
        end else begin
            hcount_nxt = hcount + 11'd1;
        end

        hblnk_nxt = (hcount_nxt >= HOR_BLANK_START);
        vblnk_nxt = (vcount_nxt >= VER_BLANK_START);
        hsync_nxt = ((hcount_nxt >= HOR_SYNC_START) &&
                     (hcount_nxt < HOR_SYNC_START + HOR_SYNC_TIME)) ?
                    HOR_SYNC_POLARITY : !HOR_SYNC_POLARITY;
        vsync_nxt = ((vcount_nxt >= VER_SYNC_START) &&
                     (vcount_nxt < VER_SYNC_START + VER_SYNC_TIME)) ?
                    VER_SYNC_POLARITY : !VER_SYNC_POLARITY;
    end

endmodule
