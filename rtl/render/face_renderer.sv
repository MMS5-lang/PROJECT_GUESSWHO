/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Pipelined renderer for the procedural Guess Who face layer.
 */

module face_renderer (
    input  logic clk,
    input  logic rst_n,
    input  logic [guess_who_pkg::CHAR_ID_W-1:0] selected_id,
    input  logic has_secret,
    vga_if.in    in,
    vga_if.out   out
);

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;
import guess_who_pkg::*;

localparam logic [11:0] COLOR_BLACK       = 12'h0_0_0;
localparam logic [11:0] COLOR_WHITE       = 12'hf_f_f;
localparam logic [11:0] COLOR_TRANSPARENT = 12'hf_0_f;

localparam int HEAD_W = 140;
localparam int HEAD_H = 130;
localparam int HEAD_X_OFF = 0;
localparam int HEAD_Y_OFF = 70;
localparam int HEAD_PIXELS = HEAD_W * HEAD_H;
localparam int HEAD_ADDR_W = $clog2(HEAD_PIXELS);

localparam int GLASSES_W = 82;
localparam int GLASSES_H = 21;
localparam int GLASSES_X_OFF = 30;
localparam int GLASSES_Y_OFF = 115;
localparam int GLASSES_PIXELS = GLASSES_W * GLASSES_H;
localparam int GLASSES_ADDR_W = $clog2(GLASSES_PIXELS);

localparam int HAIR_1_W = 80;
localparam int HAIR_1_H = 34;
localparam int HAIR_1_X_OFF = 28;
localparam int HAIR_1_Y_OFF = 70;
localparam int HAIR_1_PIXELS = HAIR_1_W * HAIR_1_H;
localparam int HAIR_1_ADDR_W = $clog2(HAIR_1_PIXELS);

localparam int HAIR_LONG_W = 85;
localparam int HAIR_LONG_H = 55;
localparam int HAIR_LONG_X_OFF = 28;
localparam int HAIR_LONG_Y_OFF = 64;
localparam int HAIR_LONG_PIXELS = HAIR_LONG_W * HAIR_LONG_H;
localparam int HAIR_LONG_ADDR_W = $clog2(HAIR_LONG_PIXELS);

localparam int PAYOT_W = 72;
localparam int PAYOT_H = 66;
localparam int PAYOT_X_OFF = 32;
localparam int PAYOT_Y_OFF = 120;
localparam int PAYOT_PIXELS = PAYOT_W * PAYOT_H;
localparam int PAYOT_ADDR_W = $clog2(PAYOT_PIXELS);

(* rom_style = "block" *) logic [11:0] head_rom [0:HEAD_PIXELS-1];
(* rom_style = "block" *) logic [11:0] glasses_rom [0:GLASSES_PIXELS-1];
(* rom_style = "block" *) logic [11:0] hair_1_rom [0:HAIR_1_PIXELS-1];
(* rom_style = "block" *) logic [11:0] hair_long_rom [0:HAIR_LONG_PIXELS-1];
(* rom_style = "block" *) logic [11:0] payot_rom [0:PAYOT_PIXELS-1];

/**
 * Vivado supports $readmemh in an initial block for FPGA ROM initialization.
 * The data is fixed at configuration time and is used only to preload face
 * asset memories, so no run-time register behavior depends on this block.
 */
initial begin
    $readmemh("../../rtl/assets/faces/head_shape.dat", head_rom);
    $readmemh("../../rtl/assets/faces/glasses_2.dat", glasses_rom);
    $readmemh("../../rtl/assets/faces/hair_1_1.dat", hair_1_rom);
    $readmemh("../../rtl/assets/faces/hair_long_1.dat", hair_long_rom);
    $readmemh("../../rtl/assets/faces/payot.dat", payot_rom);
end

logic [11:0] rgb_nxt;

logic in_board_nxt;
logic in_panel_nxt;
logic draw_face_nxt;
logic [10:0] cell_x_nxt;
logic [10:0] cell_y_nxt;
logic [2:0] col_nxt;
logic [1:0] row_nxt;
logic [4:0] char_idx_nxt;
logic [7:0] traits_nxt;

logic in_head_area_nxt;
logic in_glasses_area_nxt;
logic in_hair_1_area_nxt;
logic in_hair_long_area_nxt;
logic in_payot_area_nxt;

logic [HEAD_ADDR_W-1:0] head_addr_nxt;
logic [GLASSES_ADDR_W-1:0] glasses_addr_nxt;
logic [HAIR_1_ADDR_W-1:0] hair_1_addr_nxt;
logic [HAIR_LONG_ADDR_W-1:0] hair_long_addr_nxt;
logic [PAYOT_ADDR_W-1:0] payot_addr_nxt;

logic [10:0] head_lx;
logic [10:0] head_ly;
logic [10:0] glasses_lx;
logic [10:0] glasses_ly;
logic [10:0] hair_1_lx;
logic [10:0] hair_1_ly;
logic [10:0] hair_long_lx;
logic [10:0] hair_long_ly;
logic [10:0] payot_lx;
logic [10:0] payot_ly;

logic [15:0] head_addr_full;
logic [15:0] glasses_addr_full;
logic [15:0] hair_1_addr_full;
logic [15:0] hair_long_addr_full;
logic [15:0] payot_addr_full;

logic [10:0] s0_vcount;
logic        s0_vsync;
logic        s0_vblnk;
logic [10:0] s0_hcount;
logic        s0_hsync;
logic        s0_hblnk;
logic [11:0] s0_rgb;
logic        s0_draw_face;
logic [7:0]  s0_traits;
logic        s0_in_head_area;
logic        s0_in_glasses_area;
logic        s0_in_hair_1_area;
logic        s0_in_hair_long_area;
logic        s0_in_payot_area;
logic [HEAD_ADDR_W-1:0] s0_head_addr;
logic [GLASSES_ADDR_W-1:0] s0_glasses_addr;
logic [HAIR_1_ADDR_W-1:0] s0_hair_1_addr;
logic [HAIR_LONG_ADDR_W-1:0] s0_hair_long_addr;
logic [PAYOT_ADDR_W-1:0] s0_payot_addr;

logic [10:0] s1_vcount;
logic        s1_vsync;
logic        s1_vblnk;
logic [10:0] s1_hcount;
logic        s1_hsync;
logic        s1_hblnk;
logic [11:0] s1_rgb;
logic        s1_draw_face;
logic [7:0]  s1_traits;
logic        s1_in_head_area;
logic        s1_in_glasses_area;
logic        s1_in_hair_1_area;
logic        s1_in_hair_long_area;
logic        s1_in_payot_area;

logic [11:0] head_pixel;
logic [11:0] glasses_pixel;
logic [11:0] hair_1_pixel;
logic [11:0] hair_long_pixel;
logic [11:0] payot_pixel;

face_traits_rom u_face_traits_rom (
    .char_id (char_idx_nxt),
    .traits  (traits_nxt)
);

always_comb begin
    in_board_nxt = (in.hcount >= BOARD_X) && (in.hcount < BOARD_X + BOARD_W) &&
                   (in.vcount >= BOARD_Y) && (in.vcount < BOARD_Y + BOARD_H);
    in_panel_nxt = (in.hcount >= PANEL_X) && (in.hcount < PANEL_X + CELL_W) &&
                   (in.vcount >= PANEL_Y) && (in.vcount < PANEL_Y + CELL_H);

    cell_x_nxt = 11'h0;
    cell_y_nxt = 11'h0;
    col_nxt = 3'h0;
    row_nxt = 2'h0;

    if (in_board_nxt) begin
        if (in.hcount < BOARD_X + CELL_W) begin
            col_nxt = 3'd0;
            cell_x_nxt = in.hcount - BOARD_X;
        end else if (in.hcount < BOARD_X + 2 * CELL_W) begin
            col_nxt = 3'd1;
            cell_x_nxt = in.hcount - (BOARD_X + CELL_W);
        end else if (in.hcount < BOARD_X + 3 * CELL_W) begin
            col_nxt = 3'd2;
            cell_x_nxt = in.hcount - (BOARD_X + 2 * CELL_W);
        end else if (in.hcount < BOARD_X + 4 * CELL_W) begin
            col_nxt = 3'd3;
            cell_x_nxt = in.hcount - (BOARD_X + 3 * CELL_W);
        end else if (in.hcount < BOARD_X + 5 * CELL_W) begin
            col_nxt = 3'd4;
            cell_x_nxt = in.hcount - (BOARD_X + 4 * CELL_W);
        end else begin
            col_nxt = 3'd5;
            cell_x_nxt = in.hcount - (BOARD_X + 5 * CELL_W);
        end

        if (in.vcount < BOARD_Y + CELL_H) begin
            row_nxt = 2'd0;
            cell_y_nxt = in.vcount - BOARD_Y;
        end else if (in.vcount < BOARD_Y + 2 * CELL_H) begin
            row_nxt = 2'd1;
            cell_y_nxt = in.vcount - (BOARD_Y + CELL_H);
        end else begin
            row_nxt = 2'd2;
            cell_y_nxt = in.vcount - (BOARD_Y + 2 * CELL_H);
        end
    end

    case (row_nxt)
        2'd0: begin
            char_idx_nxt = {2'b00, col_nxt};
        end
        2'd1: begin
            char_idx_nxt = 5'd6 + {2'b00, col_nxt};
        end
        default: begin
            char_idx_nxt = 5'd12 + {2'b00, col_nxt};
        end
    endcase

    if (in_panel_nxt && has_secret && (selected_id < CHAR_COUNT)) begin
        cell_x_nxt = in.hcount - PANEL_X;
        cell_y_nxt = in.vcount - PANEL_Y;
        char_idx_nxt = selected_id;
    end

    draw_face_nxt = (in_board_nxt && (in.rgb == COLOR_WHITE)) ||
                    (in_panel_nxt && has_secret);

    in_head_area_nxt = draw_face_nxt &&
        (cell_x_nxt >= HEAD_X_OFF) && (cell_x_nxt < HEAD_X_OFF + HEAD_W) &&
        (cell_y_nxt >= HEAD_Y_OFF) && (cell_y_nxt < HEAD_Y_OFF + HEAD_H);
    in_glasses_area_nxt = draw_face_nxt && traits_nxt[2] &&
        (cell_x_nxt >= GLASSES_X_OFF) && (cell_x_nxt < GLASSES_X_OFF + GLASSES_W) &&
        (cell_y_nxt >= GLASSES_Y_OFF) && (cell_y_nxt < GLASSES_Y_OFF + GLASSES_H);
    in_hair_1_area_nxt = draw_face_nxt && traits_nxt[6] &&
        (cell_x_nxt >= HAIR_1_X_OFF) && (cell_x_nxt < HAIR_1_X_OFF + HAIR_1_W) &&
        (cell_y_nxt >= HAIR_1_Y_OFF) && (cell_y_nxt < HAIR_1_Y_OFF + HAIR_1_H);
    in_hair_long_area_nxt = draw_face_nxt && traits_nxt[7] &&
        (cell_x_nxt >= HAIR_LONG_X_OFF) && (cell_x_nxt < HAIR_LONG_X_OFF + HAIR_LONG_W) &&
        (cell_y_nxt >= HAIR_LONG_Y_OFF) && (cell_y_nxt < HAIR_LONG_Y_OFF + HAIR_LONG_H);
    in_payot_area_nxt = draw_face_nxt && traits_nxt[0] &&
        (cell_x_nxt >= PAYOT_X_OFF) && (cell_x_nxt < PAYOT_X_OFF + PAYOT_W) &&
        (cell_y_nxt >= PAYOT_Y_OFF) && (cell_y_nxt < PAYOT_Y_OFF + PAYOT_H);

    head_addr_nxt = '0;
    glasses_addr_nxt = '0;
    hair_1_addr_nxt = '0;
    hair_long_addr_nxt = '0;
    payot_addr_nxt = '0;

    head_lx = cell_x_nxt - HEAD_X_OFF;
    head_ly = cell_y_nxt - HEAD_Y_OFF;
    glasses_lx = cell_x_nxt - GLASSES_X_OFF;
    glasses_ly = cell_y_nxt - GLASSES_Y_OFF;
    hair_1_lx = cell_x_nxt - HAIR_1_X_OFF;
    hair_1_ly = cell_y_nxt - HAIR_1_Y_OFF;
    hair_long_lx = cell_x_nxt - HAIR_LONG_X_OFF;
    hair_long_ly = cell_y_nxt - HAIR_LONG_Y_OFF;
    payot_lx = cell_x_nxt - PAYOT_X_OFF;
    payot_ly = cell_y_nxt - PAYOT_Y_OFF;

    /* ROM images are stored row by row, so address = y * width + x. */
    head_addr_full = head_ly * HEAD_W + head_lx;
    glasses_addr_full = glasses_ly * GLASSES_W + glasses_lx;
    hair_1_addr_full = hair_1_ly * HAIR_1_W + hair_1_lx;
    hair_long_addr_full = hair_long_ly * HAIR_LONG_W + hair_long_lx;
    payot_addr_full = payot_ly * PAYOT_W + payot_lx;

    if (in_head_area_nxt) begin
        head_addr_nxt = head_addr_full[HEAD_ADDR_W-1:0];
    end
    if (in_glasses_area_nxt) begin
        glasses_addr_nxt = glasses_addr_full[GLASSES_ADDR_W-1:0];
    end
    if (in_hair_1_area_nxt) begin
        hair_1_addr_nxt = hair_1_addr_full[HAIR_1_ADDR_W-1:0];
    end
    if (in_hair_long_area_nxt) begin
        hair_long_addr_nxt = hair_long_addr_full[HAIR_LONG_ADDR_W-1:0];
    end
    if (in_payot_area_nxt) begin
        payot_addr_nxt = payot_addr_full[PAYOT_ADDR_W-1:0];
    end
end

always_comb begin
    rgb_nxt = s1_rgb;

    if (s1_vblnk || s1_hblnk) begin
        rgb_nxt = COLOR_BLACK;
    end else if (s1_draw_face) begin
        if (s1_in_glasses_area && glasses_pixel != COLOR_TRANSPARENT) begin
            rgb_nxt = glasses_pixel;
        end else if (s1_in_hair_1_area && hair_1_pixel != COLOR_TRANSPARENT) begin
            if (hair_1_pixel == 12'h3_2_2) begin
                rgb_nxt = s1_traits[5] ? 12'hd_b_7 : 12'h2_1_0;
            end else if (hair_1_pixel == 12'h0_0_0) begin
                rgb_nxt = s1_traits[5] ? 12'hc_9_7 : 12'h0_0_0;
            end else begin
                rgb_nxt = hair_1_pixel;
            end
        end else if (s1_in_hair_long_area && hair_long_pixel != COLOR_TRANSPARENT) begin
            if (hair_long_pixel == 12'h3_2_2) begin
                rgb_nxt = s1_traits[5] ? 12'hd_b_7 : 12'h2_1_0;
            end else if (hair_long_pixel == 12'h0_0_0) begin
                rgb_nxt = s1_traits[5] ? 12'hc_9_7 : 12'h2_1_0;
            end else begin
                rgb_nxt = hair_long_pixel;
            end
        end else if (s1_in_payot_area && payot_pixel != COLOR_TRANSPARENT) begin
            if (payot_pixel == 12'h3_2_2) begin
                rgb_nxt = s1_traits[5] ? 12'hd_b_7 : 12'h3_2_2;
            end else begin
                rgb_nxt = payot_pixel;
            end
        end else if (s1_in_head_area && head_pixel != COLOR_TRANSPARENT) begin
            if (head_pixel == COLOR_WHITE) begin
                rgb_nxt = s1_traits[3] ? 12'h8_5_2 : 12'hf_d_b;
            end else if (head_pixel == 12'h9_5_3) begin
                rgb_nxt = s1_traits[4] ? 12'h4_a_f : 12'h3_4_1;
            end else begin
                rgb_nxt = head_pixel;
            end
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s0_vcount <= '0;
        s0_vsync <= '0;
        s0_vblnk <= '0;
        s0_hcount <= '0;
        s0_hsync <= '0;
        s0_hblnk <= '0;
        s0_rgb <= '0;
        s0_draw_face <= '0;
        s0_traits <= '0;
        s0_in_head_area <= '0;
        s0_in_glasses_area <= '0;
        s0_in_hair_1_area <= '0;
        s0_in_hair_long_area <= '0;
        s0_in_payot_area <= '0;
        s0_head_addr <= '0;
        s0_glasses_addr <= '0;
        s0_hair_1_addr <= '0;
        s0_hair_long_addr <= '0;
        s0_payot_addr <= '0;
        s1_vcount <= '0;
        s1_vsync <= '0;
        s1_vblnk <= '0;
        s1_hcount <= '0;
        s1_hsync <= '0;
        s1_hblnk <= '0;
        s1_rgb <= '0;
        s1_draw_face <= '0;
        s1_traits <= '0;
        s1_in_head_area <= '0;
        s1_in_glasses_area <= '0;
        s1_in_hair_1_area <= '0;
        s1_in_hair_long_area <= '0;
        s1_in_payot_area <= '0;
        head_pixel <= COLOR_TRANSPARENT;
        glasses_pixel <= COLOR_TRANSPARENT;
        hair_1_pixel <= COLOR_TRANSPARENT;
        hair_long_pixel <= COLOR_TRANSPARENT;
        payot_pixel <= COLOR_TRANSPARENT;
        out.vcount <= '0;
        out.vsync <= '0;
        out.vblnk <= '0;
        out.hcount <= '0;
        out.hsync <= '0;
        out.hblnk <= '0;
        out.rgb <= '0;
    end else begin
        s0_vcount <= in.vcount;
        s0_vsync <= in.vsync;
        s0_vblnk <= in.vblnk;
        s0_hcount <= in.hcount;
        s0_hsync <= in.hsync;
        s0_hblnk <= in.hblnk;
        s0_rgb <= in.rgb;
        s0_draw_face <= draw_face_nxt;
        s0_traits <= traits_nxt;
        s0_in_head_area <= in_head_area_nxt;
        s0_in_glasses_area <= in_glasses_area_nxt;
        s0_in_hair_1_area <= in_hair_1_area_nxt;
        s0_in_hair_long_area <= in_hair_long_area_nxt;
        s0_in_payot_area <= in_payot_area_nxt;
        s0_head_addr <= head_addr_nxt;
        s0_glasses_addr <= glasses_addr_nxt;
        s0_hair_1_addr <= hair_1_addr_nxt;
        s0_hair_long_addr <= hair_long_addr_nxt;
        s0_payot_addr <= payot_addr_nxt;

        s1_vcount <= s0_vcount;
        s1_vsync <= s0_vsync;
        s1_vblnk <= s0_vblnk;
        s1_hcount <= s0_hcount;
        s1_hsync <= s0_hsync;
        s1_hblnk <= s0_hblnk;
        s1_rgb <= s0_rgb;
        s1_draw_face <= s0_draw_face;
        s1_traits <= s0_traits;
        s1_in_head_area <= s0_in_head_area;
        s1_in_glasses_area <= s0_in_glasses_area;
        s1_in_hair_1_area <= s0_in_hair_1_area;
        s1_in_hair_long_area <= s0_in_hair_long_area;
        s1_in_payot_area <= s0_in_payot_area;

        head_pixel <= head_rom[s0_head_addr];
        glasses_pixel <= glasses_rom[s0_glasses_addr];
        hair_1_pixel <= hair_1_rom[s0_hair_1_addr];
        hair_long_pixel <= hair_long_rom[s0_hair_long_addr];
        payot_pixel <= payot_rom[s0_payot_addr];

        out.vcount <= s1_vcount;
        out.vsync <= s1_vsync;
        out.vblnk <= s1_vblnk;
        out.hcount <= s1_hcount;
        out.hsync <= s1_hsync;
        out.hblnk <= s1_hblnk;
        out.rgb <= rgb_nxt;
    end
end

endmodule
