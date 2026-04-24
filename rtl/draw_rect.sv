/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Draw a 48 x 64 rectangle filled with image ROM data.
 */

module draw_rect #(
        parameter int WIDTH = 48,
        parameter int HEIGHT = 64
    )(
        input  logic        clk,
        input  logic        rst_n,
        input  logic [11:0] xpos,
        input  logic [11:0] ypos,
        input  logic [11:0] rgb_pixel,
        output logic [11:0] pixel_addr,
        vga_if.in           in,
        vga_if.out          out
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */
    logic [11:0] pixel_addr_nxt;

    logic        rect_area_nxt;
    logic        top_edge_nxt;
    logic        bottom_edge_nxt;
    logic        left_edge_nxt;
    logic        right_edge_nxt;

    logic        rect_area_dly;
    logic        top_edge_dly;
    logic        bottom_edge_dly;
    logic        left_edge_dly;
    logic        right_edge_dly;
    logic [10:0] vcount_dly;
    logic        vsync_dly;
    logic        vblnk_dly;
    logic [10:0] hcount_dly;
    logic        hsync_dly;
    logic        hblnk_dly;
    logic [11:0] rgb_dly;

    logic        rect_area;
    logic        top_edge;
    logic        bottom_edge;
    logic        left_edge;
    logic        right_edge;
    logic [10:0] vcount;
    logic        vsync;
    logic        vblnk;
    logic [10:0] hcount;
    logic        hsync;
    logic        hblnk;
    logic [11:0] rgb;

    /**
     * Internal logic
     */
    always_comb begin : rect_comb_blk
        pixel_addr_nxt = '0;
        rect_area_nxt  = 1'b0;
        top_edge_nxt   = 1'b0;
        bottom_edge_nxt = 1'b0;
        left_edge_nxt  = 1'b0;
        right_edge_nxt = 1'b0;

        if ((in.hcount >= xpos) && (in.hcount < xpos + WIDTH) &&
            (in.vcount >= ypos) && (in.vcount < ypos + HEIGHT)) begin
            rect_area_nxt = 1'b1;
            pixel_addr_nxt = {6'(in.vcount - ypos), 6'(in.hcount - xpos)};

            if (in.vcount == ypos) begin
                top_edge_nxt = 1'b1;
            end
            if (in.vcount == ypos + HEIGHT - 1) begin
                bottom_edge_nxt = 1'b1;
            end
            if (in.hcount == xpos) begin
                left_edge_nxt = 1'b1;
            end
            if (in.hcount == xpos + WIDTH - 1) begin
                right_edge_nxt = 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin : pixel_addr_ff_blk
        pixel_addr <= pixel_addr_nxt;
    end

    always_ff @(posedge clk or negedge rst_n) begin : rect_ff_blk
        if (!rst_n) begin
            rect_area_dly   <= '0;
            top_edge_dly    <= '0;
            bottom_edge_dly <= '0;
            left_edge_dly   <= '0;
            right_edge_dly  <= '0;
            vcount_dly      <= '0;
            vsync_dly       <= '0;
            vblnk_dly       <= '0;
            hcount_dly      <= '0;
            hsync_dly       <= '0;
            hblnk_dly       <= '0;
            rgb_dly         <= '0;
            rect_area       <= '0;
            top_edge        <= '0;
            bottom_edge     <= '0;
            left_edge       <= '0;
            right_edge      <= '0;
            vcount          <= '0;
            vsync           <= '0;
            vblnk           <= '0;
            hcount          <= '0;
            hsync           <= '0;
            hblnk           <= '0;
            rgb             <= '0;
            out.vcount      <= '0;
            out.vsync       <= '0;
            out.vblnk       <= '0;
            out.hcount      <= '0;
            out.hsync       <= '0;
            out.hblnk       <= '0;
            out.rgb         <= '0;
        end else begin
            rect_area_dly   <= rect_area_nxt;
            top_edge_dly    <= top_edge_nxt;
            bottom_edge_dly <= bottom_edge_nxt;
            left_edge_dly   <= left_edge_nxt;
            right_edge_dly  <= right_edge_nxt;
            vcount_dly      <= in.vcount;
            vsync_dly       <= in.vsync;
            vblnk_dly       <= in.vblnk;
            hcount_dly      <= in.hcount;
            hsync_dly       <= in.hsync;
            hblnk_dly       <= in.hblnk;
            rgb_dly         <= in.rgb;
            rect_area       <= rect_area_dly;
            top_edge        <= top_edge_dly;
            bottom_edge     <= bottom_edge_dly;
            left_edge       <= left_edge_dly;
            right_edge      <= right_edge_dly;
            vcount          <= vcount_dly;
            vsync           <= vsync_dly;
            vblnk           <= vblnk_dly;
            hcount          <= hcount_dly;
            hsync           <= hsync_dly;
            hblnk           <= hblnk_dly;
            rgb             <= rgb_dly;
            out.vcount      <= vcount;
            out.vsync       <= vsync;
            out.vblnk       <= vblnk;
            out.hcount      <= hcount;
            out.hsync       <= hsync;
            out.hblnk       <= hblnk;

            if (rect_area) begin
                if (top_edge) begin
                    out.rgb <= 12'h0_F_0;
                end else if (bottom_edge) begin
                    out.rgb <= 12'hF_F_0;
                end else if (left_edge) begin
                    out.rgb <= 12'h0_0_F;
                end else if (right_edge) begin
                    out.rgb <= 12'hF_0_0;
                end else begin
                    out.rgb <= rgb_pixel;
                end
            end else begin
                out.rgb <= rgb;
            end
        end
    end

endmodule
