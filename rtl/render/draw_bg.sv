/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Rysowanie tla planszy 6x3 dla gry Guess Who.
 */

 module draw_bg
    import vga_pkg::*;
    (
        input  logic clk,
        input  logic rst_n,
        input  logic sw0,
        vga_if.out   out,
        vga_if.in    in
    );
    
    timeunit 1ns;
    timeprecision 1ps;
    
    localparam logic [11:0] COLOR_TRANSPARENT = 12'hf_0_f;
    localparam logic [11:0] COLOR_BLUE        = 12'h2_8_d;
    localparam logic [11:0] COLOR_GREEN        = 12'h5_9_2;
    
    localparam int DECOR_W = 32;
    localparam int DECOR_H = 32;
    localparam int DECOR_PIXELS = DECOR_W * DECOR_H;
    localparam int DECOR_ADDR_W = $clog2(DECOR_PIXELS);
    localparam int DECOR_CNT = 10;
    
    localparam logic [10:0] DECOR_X [0:DECOR_CNT-1] = '{
        11'd48,  11'd220, 11'd420, 11'd640, 11'd920,
        11'd80,  11'd310, 11'd520, 11'd760, 11'd960
    };
    localparam logic [10:0] DECOR_Y [0:DECOR_CNT-1] = '{
        11'd36,  11'd28,  11'd52,  11'd40,  11'd48,
        11'd700, 11'd720, 11'd708, 11'd695, 11'd715
    };
    
    (* rom_style = "distributed" *) logic [11:0] q_mark_rom [0:DECOR_PIXELS-1];
    
    initial begin
        $readmemh("../../rtl/assets/bg/Q_mark.dat", q_mark_rom);
    end
    
    logic [1:0] sw0_sync;
    logic red_bg_q;
    
    logic in_board;
    logic is_board_frame;
    logic is_cell_frame;
    logic is_grid_col;
    logic is_grid_row;
    
    logic in_decor;
    logic [DECOR_ADDR_W-1:0] decor_addr;
    logic [11:0] decor_pixel;
    logic [11:0] sky_rgb;
    logic [11:0] base_rgb;
    logic [11:0] rgb_nxt;
    
    always_ff @(posedge clk or negedge rst_n) begin : sw0_sync_blk
        if (!rst_n) begin
            sw0_sync <= '0;
        end else begin
            sw0_sync <= {sw0_sync[0], sw0};
        end
    end
    
    assign red_bg_q = sw0_sync[1];
    assign sky_rgb = red_bg_q ? COLOR_GREEN : COLOR_BLUE;
    
    logic [10:0] diff_y;
    logic [10:0] diff_x;

    always_comb begin : decor_hit_blk
        in_decor = 1'b0;
        decor_addr = '0;
        diff_y = '0;
        diff_x = '0;
    
        for (int i = 0; i < DECOR_CNT; i++) begin
            if (!in_decor &&
                (in.hcount >= DECOR_X[i]) && (in.hcount < DECOR_X[i] + DECOR_W) &&
                (in.vcount >= DECOR_Y[i]) && (in.vcount < DECOR_Y[i] + DECOR_H)) begin
                in_decor = 1'b1;
            
                diff_y = in.vcount - DECOR_Y[i];
                diff_x = in.hcount - DECOR_X[i];
            
                decor_addr = { diff_y[4:0], diff_x[4:0] };
            end
        end
    end
    assign decor_pixel = q_mark_rom[decor_addr];
    
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
        in_board = (in.hcount >= BOARD_X) && (in.hcount < BOARD_X + BOARD_W) &&
                   (in.vcount >= BOARD_Y) && (in.vcount < BOARD_Y + BOARD_H);
    
        is_board_frame = in_board && (
            (in.hcount < BOARD_X + 3) ||
            (in.hcount >= BOARD_X + BOARD_W - 3) ||
            (in.vcount < BOARD_Y + 3) ||
            (in.vcount >= BOARD_Y + BOARD_H - 3)
        );
    
        is_grid_col =
            ((in.hcount >= BOARD_X + CELL_W)     && (in.hcount < BOARD_X + CELL_W + 2)) ||
            ((in.hcount >= BOARD_X + 2 * CELL_W) && (in.hcount < BOARD_X + 2 * CELL_W + 2)) ||
            ((in.hcount >= BOARD_X + 3 * CELL_W) && (in.hcount < BOARD_X + 3 * CELL_W + 2)) ||
            ((in.hcount >= BOARD_X + 4 * CELL_W) && (in.hcount < BOARD_X + 4 * CELL_W + 2)) ||
            ((in.hcount >= BOARD_X + 5 * CELL_W) && (in.hcount < BOARD_X + 5 * CELL_W + 2));
    
        is_grid_row =
            ((in.vcount >= BOARD_Y + CELL_H)     && (in.vcount < BOARD_Y + CELL_H + 2)) ||
            ((in.vcount >= BOARD_Y + 2 * CELL_H) && (in.vcount < BOARD_Y + 2 * CELL_H + 2));
    
        is_cell_frame = in_board && (!is_board_frame) && (
            is_grid_col ||
            is_grid_row
        );
    
        base_rgb = sky_rgb;
        if (in_decor && (decor_pixel != COLOR_TRANSPARENT)) begin
            base_rgb = decor_pixel;
        end
    
        if (in.vblnk || in.hblnk) begin
            rgb_nxt = 12'h0_0_0;
        end else if (is_board_frame) begin
            rgb_nxt = 12'h0_0_0;
        end else if (is_cell_frame) begin
            rgb_nxt = 12'h5_5_5;
        end else if (in_board) begin
            rgb_nxt = 12'hf_f_f;
        end else begin
            rgb_nxt = base_rgb | in.rgb;
        end
    end
    
    endmodule