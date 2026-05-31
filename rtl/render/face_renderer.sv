/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Pipelined renderer for the procedural Guess Who face layer.
 */

module face_renderer
import vga_pkg::*;
import guess_who_pkg::*;
(
    input  logic clk,
    input  logic rst_n,
    vga_if.out   out,
    input  logic [CHAR_ID_W-1:0] selected_id,
    input  logic has_secret,
    vga_if.in    in
);

timeunit 1ns;
timeprecision 1ps;

localparam logic [11:0] COLOR_BLACK       = 12'h0_0_0;
localparam logic [11:0] COLOR_WHITE       = 12'hf_f_f;
localparam logic [11:0] COLOR_TRANSPARENT = 12'hf_0_f;

localparam int HEAD_W = 140;
localparam int HEAD_H = 130;
localparam int HEAD_X_OFF = 0;
localparam int HEAD_Y_OFF = 70;
localparam int HEAD_PIXELS = HEAD_W * HEAD_H;
localparam int HEAD_ADDR_W = $clog2(HEAD_PIXELS);

localparam int SUNGLASSES_W = 82;
localparam int SUNGLASSES_H = 21;
localparam int SUNGLASSES_X_OFF = 30;
localparam int SUNGLASSES_Y_OFF = 115;
localparam int SUNGLASSES_PIXELS = SUNGLASSES_W * SUNGLASSES_H;
localparam int SUNGLASSES_ADDR_W = $clog2(SUNGLASSES_PIXELS);

localparam int GLASSES_W = 86;
localparam int GLASSES_H = 29;
localparam int GLASSES_X_OFF = 24;
localparam int GLASSES_Y_OFF = 116;
localparam int GLASSES_PIXELS = GLASSES_W * GLASSES_H;
localparam int GLASSES_ADDR_W = $clog2(GLASSES_PIXELS);

localparam int HAIR1_W = 80;
localparam int HAIR1_H = 34;
localparam int HAIR1_X_OFF = 28;
localparam int HAIR1_Y_OFF = 70;
localparam int HAIR1_PIXELS = HAIR1_W * HAIR1_H;
localparam int HAIR1_ADDR_W = $clog2(HAIR1_PIXELS);

localparam int HAIR2_W = 85;
localparam int HAIR2_H = 55;
localparam int HAIR2_X_OFF = 28;
localparam int HAIR2_Y_OFF = 64;
localparam int HAIR2_PIXELS = HAIR2_W * HAIR2_H;
localparam int HAIR2_ADDR_W = $clog2(HAIR2_PIXELS);

localparam int BEARD_W = 70;
localparam int BEARD_H = 54;
localparam int BEARD_X_OFF = 33;
localparam int BEARD_Y_OFF = 134;
localparam int BEARD_PIXELS = BEARD_W * BEARD_H;
localparam int BEARD_ADDR_W = $clog2(BEARD_PIXELS);

localparam int HAT_W = 134;
localparam int HAT_H = 54;
localparam int HAT_X_OFF = 5;
localparam int HAT_Y_OFF = 50;
localparam int HAT_PIXELS = HAT_W * HAT_H;
localparam int HAT_ADDR_W = $clog2(HAT_PIXELS);

localparam int CAP_W = 107;
localparam int CAP_H = 68;
localparam int CAP_X_OFF = 7;
localparam int CAP_Y_OFF = 57;
localparam int CAP_PIXELS = CAP_W * CAP_H;
localparam int CAP_ADDR_W = $clog2(CAP_PIXELS);

localparam int PAYOT_W = 72;
localparam int PAYOT_H = 66;
localparam int PAYOT_X_OFF = 32;
localparam int PAYOT_Y_OFF = 120;
localparam int PAYOT_PIXELS = PAYOT_W * PAYOT_H;
localparam int PAYOT_ADDR_W = $clog2(PAYOT_PIXELS);

(* rom_style = "block" *) logic [11:0] head_rom [0:HEAD_PIXELS-1];
(* rom_style = "block" *) logic [11:0] sunglasses_rom [0:SUNGLASSES_PIXELS-1];
(* rom_style = "block" *) logic [11:0] glasses_rom [0:GLASSES_PIXELS-1];
(* rom_style = "block" *) logic [11:0] hair1_rom [0:HAIR1_PIXELS-1];
(* rom_style = "block" *) logic [11:0] hair2_rom [0:HAIR2_PIXELS-1];
(* rom_style = "block" *) logic [11:0] beard_rom [0:BEARD_PIXELS-1];
(* rom_style = "block" *) logic [11:0] hat_rom [0:HAT_PIXELS-1];
(* rom_style = "block" *) logic [11:0] cap_rom [0:CAP_PIXELS-1];
(* rom_style = "block" *) logic [11:0] payot_rom [0:PAYOT_PIXELS-1];

/**
 * Vivado supports $readmemh in an initial block for FPGA ROM initialization.
 */
initial begin
    $readmemh("../../rtl/assets/faces/head_shape.dat", head_rom);
    $readmemh("../../rtl/assets/faces/sunglasses.dat", sunglasses_rom);
    $readmemh("../../rtl/assets/faces/glasses.dat", glasses_rom);
    $readmemh("../../rtl/assets/faces/hair1.dat", hair1_rom);
    $readmemh("../../rtl/assets/faces/hair2.dat", hair2_rom);
    $readmemh("../../rtl/assets/faces/beard.dat", beard_rom);
    $readmemh("../../rtl/assets/faces/hat.dat", hat_rom);
    $readmemh("../../rtl/assets/faces/cap.dat", cap_rom);
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
logic [11:0] traits_nxt; 
logic in_head_area_nxt;
logic in_sunglasses_area_nxt;
logic in_glasses_area_nxt;
logic in_hair1_area_nxt;
logic in_hair2_area_nxt;
logic in_beard_area_nxt;
logic in_hat_area_nxt;
logic in_cap_area_nxt;
logic in_payot_area_nxt;

logic [HEAD_ADDR_W-1:0]       head_addr_nxt;
logic [SUNGLASSES_ADDR_W-1:0] sunglasses_addr_nxt;
logic [GLASSES_ADDR_W-1:0]    glasses_addr_nxt;
logic [HAIR1_ADDR_W-1:0]      hair1_addr_nxt;
logic [HAIR2_ADDR_W-1:0]      hair2_addr_nxt;
logic [BEARD_ADDR_W-1:0]      beard_addr_nxt;
logic [HAT_ADDR_W-1:0]        hat_addr_nxt;
logic [CAP_ADDR_W-1:0]        cap_addr_nxt;
logic [PAYOT_ADDR_W-1:0]      payot_addr_nxt;

logic [10:0] head_lx, head_ly;
logic [10:0] sunglasses_lx, sunglasses_ly;
logic [10:0] glasses_lx, glasses_ly;
logic [10:0] hair1_lx, hair1_ly;
logic [10:0] hair2_lx, hair2_ly;
logic [10:0] beard_lx, beard_ly;
logic [10:0] hat_lx, hat_ly;
logic [10:0] cap_lx, cap_ly;
logic [10:0] payot_lx, payot_ly;

logic [15:0] head_addr_full;
logic [15:0] sunglasses_addr_full;
logic [15:0] glasses_addr_full;
logic [15:0] hair1_addr_full;
logic [15:0] hair2_addr_full;
logic [15:0] beard_addr_full;
logic [15:0] hat_addr_full;
logic [15:0] cap_addr_full;
logic [15:0] payot_addr_full;


logic [10:0] s0_vcount;
logic        s0_vsync;
logic        s0_vblnk;
logic [10:0] s0_hcount;
logic        s0_hsync;
logic        s0_hblnk;
logic [11:0] s0_rgb;
logic        s0_draw_face;
logic [11:0] s0_traits;

logic        s0_in_head_area;
logic        s0_in_sunglasses_area;
logic        s0_in_glasses_area;
logic        s0_in_hair1_area;
logic        s0_in_hair2_area;
logic        s0_in_beard_area;
logic        s0_in_hat_area;
logic        s0_in_cap_area;
logic        s0_in_payot_area;

logic [HEAD_ADDR_W-1:0]       s0_head_addr;
logic [SUNGLASSES_ADDR_W-1:0] s0_sunglasses_addr;
logic [GLASSES_ADDR_W-1:0]    s0_glasses_addr;
logic [HAIR1_ADDR_W-1:0]      s0_hair1_addr;
logic [HAIR2_ADDR_W-1:0]      s0_hair2_addr;
logic [BEARD_ADDR_W-1:0]      s0_beard_addr;
logic [HAT_ADDR_W-1:0]        s0_hat_addr;
logic [CAP_ADDR_W-1:0]        s0_cap_addr;
logic [PAYOT_ADDR_W-1:0]      s0_payot_addr;

logic [10:0] s1_vcount;
logic        s1_vsync;
logic        s1_vblnk;
logic [10:0] s1_hcount;
logic        s1_hsync;
logic        s1_hblnk;
logic [11:0] s1_rgb;
logic        s1_draw_face;
logic [11:0] s1_traits;

logic        s1_in_head_area;
logic        s1_in_sunglasses_area;
logic        s1_in_glasses_area;
logic        s1_in_hair1_area;
logic        s1_in_hair2_area;
logic        s1_in_beard_area;
logic        s1_in_hat_area;
logic        s1_in_cap_area;
logic        s1_in_payot_area;

logic [11:0] head_pixel;
logic [11:0] sunglasses_pixel;
logic [11:0] glasses_pixel;
logic [11:0] hair1_pixel;
logic [11:0] hair2_pixel;
logic [11:0] beard_pixel;
logic [11:0] hat_pixel;
logic [11:0] cap_pixel;
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
        2'd0: char_idx_nxt = {2'b00, col_nxt};
        2'd1: char_idx_nxt = 5'd6 + {2'b00, col_nxt};
        default: char_idx_nxt = 5'd12 + {2'b00, col_nxt};
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

    in_sunglasses_area_nxt = draw_face_nxt && traits_nxt[2] &&
        (cell_x_nxt >= SUNGLASSES_X_OFF) && (cell_x_nxt < SUNGLASSES_X_OFF + SUNGLASSES_W) &&
        (cell_y_nxt >= SUNGLASSES_Y_OFF) && (cell_y_nxt < SUNGLASSES_Y_OFF + SUNGLASSES_H);

    in_glasses_area_nxt = draw_face_nxt && traits_nxt[8] &&
        (cell_x_nxt >= GLASSES_X_OFF) && (cell_x_nxt < GLASSES_X_OFF + GLASSES_W) &&
        (cell_y_nxt >= GLASSES_Y_OFF) && (cell_y_nxt < GLASSES_Y_OFF + GLASSES_H);

    in_hair1_area_nxt = draw_face_nxt && traits_nxt[6] &&
        (cell_x_nxt >= HAIR1_X_OFF) && (cell_x_nxt < HAIR1_X_OFF + HAIR1_W) &&
        (cell_y_nxt >= HAIR1_Y_OFF) && (cell_y_nxt < HAIR1_Y_OFF + HAIR1_H);

    in_hair2_area_nxt = draw_face_nxt && traits_nxt[7] &&
        (cell_x_nxt >= HAIR2_X_OFF) && (cell_x_nxt < HAIR2_X_OFF + HAIR2_W) &&
        (cell_y_nxt >= HAIR2_Y_OFF) && (cell_y_nxt < HAIR2_Y_OFF + HAIR2_H);

    in_beard_area_nxt = draw_face_nxt && traits_nxt[11] &&
        (cell_x_nxt >= BEARD_X_OFF) && (cell_x_nxt < BEARD_X_OFF + BEARD_W) &&
        (cell_y_nxt >= BEARD_Y_OFF) && (cell_y_nxt < BEARD_Y_OFF + BEARD_H);

    in_hat_area_nxt = draw_face_nxt && traits_nxt[9] &&
        (cell_x_nxt >= HAT_X_OFF) && (cell_x_nxt < HAT_X_OFF + HAT_W) &&
        (cell_y_nxt >= HAT_Y_OFF) && (cell_y_nxt < HAT_Y_OFF + HAT_H);

    in_cap_area_nxt = draw_face_nxt && traits_nxt[10] &&
        (cell_x_nxt >= CAP_X_OFF) && (cell_x_nxt < CAP_X_OFF + CAP_W) &&
        (cell_y_nxt >= CAP_Y_OFF) && (cell_y_nxt < CAP_Y_OFF + CAP_H);

    in_payot_area_nxt = draw_face_nxt && traits_nxt[0] &&
        (cell_x_nxt >= PAYOT_X_OFF) && (cell_x_nxt < PAYOT_X_OFF + PAYOT_W) &&
        (cell_y_nxt >= PAYOT_Y_OFF) && (cell_y_nxt < PAYOT_Y_OFF + PAYOT_H);


    head_addr_nxt = '0;
    sunglasses_addr_nxt = '0;
    glasses_addr_nxt = '0;
    hair1_addr_nxt = '0;
    hair2_addr_nxt = '0;
    beard_addr_nxt = '0;
    hat_addr_nxt = '0;
    cap_addr_nxt = '0;
    payot_addr_nxt = '0;

    head_lx = cell_x_nxt - HEAD_X_OFF;
    head_ly = cell_y_nxt - HEAD_Y_OFF;
    
    sunglasses_lx = cell_x_nxt - SUNGLASSES_X_OFF;
    sunglasses_ly = cell_y_nxt - SUNGLASSES_Y_OFF;

    glasses_lx = cell_x_nxt - GLASSES_X_OFF;
    glasses_ly = cell_y_nxt - GLASSES_Y_OFF;

    hair1_lx = cell_x_nxt - HAIR1_X_OFF;
    hair1_ly = cell_y_nxt - HAIR1_Y_OFF;

    hair2_lx = cell_x_nxt - HAIR2_X_OFF;
    hair2_ly = cell_y_nxt - HAIR2_Y_OFF;

    beard_lx = cell_x_nxt - BEARD_X_OFF;
    beard_ly = cell_y_nxt - BEARD_Y_OFF;

    hat_lx = cell_x_nxt - HAT_X_OFF;
    hat_ly = cell_y_nxt - HAT_Y_OFF;

    cap_lx = cell_x_nxt - CAP_X_OFF;
    cap_ly = cell_y_nxt - CAP_Y_OFF;

    payot_lx = cell_x_nxt - PAYOT_X_OFF;
    payot_ly = cell_y_nxt - PAYOT_Y_OFF;


    head_addr_full       = head_ly * HEAD_W + head_lx;
    sunglasses_addr_full = sunglasses_ly * SUNGLASSES_W + sunglasses_lx;
    glasses_addr_full    = glasses_ly * GLASSES_W + glasses_lx;
    hair1_addr_full      = hair1_ly * HAIR1_W + hair1_lx;
    hair2_addr_full      = hair2_ly * HAIR2_W + hair2_lx;
    beard_addr_full      = beard_ly * BEARD_W + beard_lx;
    hat_addr_full        = hat_ly * HAT_W + hat_lx;
    cap_addr_full        = cap_ly * CAP_W + cap_lx;
    payot_addr_full      = payot_ly * PAYOT_W + payot_lx;

    if (in_head_area_nxt)       head_addr_nxt       = head_addr_full[HEAD_ADDR_W-1:0];
    if (in_sunglasses_area_nxt) sunglasses_addr_nxt = sunglasses_addr_full[SUNGLASSES_ADDR_W-1:0];
    if (in_glasses_area_nxt)    glasses_addr_nxt    = glasses_addr_full[GLASSES_ADDR_W-1:0];
    if (in_hair1_area_nxt)      hair1_addr_nxt      = hair1_addr_full[HAIR1_ADDR_W-1:0];
    if (in_hair2_area_nxt)      hair2_addr_nxt      = hair2_addr_full[HAIR2_ADDR_W-1:0];
    if (in_beard_area_nxt)      beard_addr_nxt      = beard_addr_full[BEARD_ADDR_W-1:0];
    if (in_hat_area_nxt)        hat_addr_nxt        = hat_addr_full[HAT_ADDR_W-1:0];
    if (in_cap_area_nxt)        cap_addr_nxt        = cap_addr_full[CAP_ADDR_W-1:0];
    if (in_payot_area_nxt)      payot_addr_nxt      = payot_addr_full[PAYOT_ADDR_W-1:0];
end

always_comb begin
    rgb_nxt = s1_rgb;

    if (s1_vblnk || s1_hblnk) begin
        rgb_nxt = COLOR_BLACK;
    end else if (s1_draw_face) begin
        
        /* Kapelusz i czapka. */
        if (s1_in_hat_area && hat_pixel != COLOR_TRANSPARENT) begin
            rgb_nxt = hat_pixel;
            
        end else if (s1_in_cap_area && cap_pixel != COLOR_TRANSPARENT) begin
            if (cap_pixel == 12'hc_3_2)
                rgb_nxt = s1_traits[1] ? 12'h2_2_2 : 12'h0_3_2;
            else
                rgb_nxt = cap_pixel;
                
        /* Okulary przeciwsłoneczne i zwykłe. */
        end else if (s1_in_sunglasses_area && sunglasses_pixel != COLOR_TRANSPARENT) begin
            rgb_nxt = sunglasses_pixel;
            
        end else if (s1_in_glasses_area && glasses_pixel != COLOR_TRANSPARENT) begin
            rgb_nxt = glasses_pixel;

        /* Broda. */
        end else if (s1_in_beard_area && beard_pixel != COLOR_TRANSPARENT) begin
            if (beard_pixel == 12'h3_2_2)
                rgb_nxt = s1_traits[5] ? 12'hd_b_7 : 12'h2_1_0;
            else if (beard_pixel == 12'h0_0_0)
                rgb_nxt = s1_traits[5] ? 12'hc_9_7 : 12'h0_0_0;
            else
                rgb_nxt = beard_pixel;
                
        /* Włosy. */
        end else if (s1_in_hair1_area && hair1_pixel != COLOR_TRANSPARENT) begin
            if (hair1_pixel == 12'h3_2_2) begin
                rgb_nxt = s1_traits[5] ? 12'hd_b_7 : 12'h2_1_0;
            end else if (hair1_pixel == 12'h0_0_0) begin
                rgb_nxt = s1_traits[5] ? 12'hc_9_7 : 12'h0_0_0;
            end else begin
                rgb_nxt = hair1_pixel;
            end
        end else if (s1_in_hair2_area && hair2_pixel != COLOR_TRANSPARENT) begin
            if (hair2_pixel == 12'h3_2_2) begin
                rgb_nxt = s1_traits[5] ? 12'hd_b_7 : 12'h2_1_0;
            end else if (hair2_pixel == 12'h0_0_0) begin
                rgb_nxt = s1_traits[5] ? 12'hc_9_7 : 12'h2_1_0;
            end else begin
                rgb_nxt = hair2_pixel;
            end
            
        /* Pejsy. */
        end else if (s1_in_payot_area && payot_pixel != COLOR_TRANSPARENT) begin
            if (payot_pixel == 12'h3_2_2) begin
                rgb_nxt = s1_traits[5] ? 12'hd_b_7 : 12'h3_2_2;
            end else begin
                rgb_nxt = payot_pixel;
            end
            
        /* Skóra i głowa. */
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
        s0_in_sunglasses_area <= '0;
        s0_in_glasses_area <= '0;
        s0_in_hair1_area <= '0;
        s0_in_hair2_area <= '0;
        s0_in_beard_area <= '0;
        s0_in_hat_area <= '0;
        s0_in_cap_area <= '0;
        s0_in_payot_area <= '0;
        
        s0_head_addr <= '0;
        s0_sunglasses_addr <= '0;
        s0_glasses_addr <= '0;
        s0_hair1_addr <= '0;
        s0_hair2_addr <= '0;
        s0_beard_addr <= '0;
        s0_hat_addr <= '0;
        s0_cap_addr <= '0;
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
        s1_in_sunglasses_area <= '0;
        s1_in_glasses_area <= '0;
        s1_in_hair1_area <= '0;
        s1_in_hair2_area <= '0;
        s1_in_beard_area <= '0;
        s1_in_hat_area <= '0;
        s1_in_cap_area <= '0;
        s1_in_payot_area <= '0;
        
        head_pixel <= COLOR_TRANSPARENT;
        sunglasses_pixel <= COLOR_TRANSPARENT;
        glasses_pixel <= COLOR_TRANSPARENT;
        hair1_pixel <= COLOR_TRANSPARENT;
        hair2_pixel <= COLOR_TRANSPARENT;
        beard_pixel <= COLOR_TRANSPARENT;
        hat_pixel <= COLOR_TRANSPARENT;
        cap_pixel <= COLOR_TRANSPARENT;
        payot_pixel <= COLOR_TRANSPARENT;
        
        out.vcount <= '0;
        out.vsync <= '0;
        out.vblnk <= '0;
        out.hcount <= '0;
        out.hsync <= '0;
        out.hblnk <= '0;
        out.rgb <= '0;
    end else begin
        /* Stage 0. */
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
        s0_in_sunglasses_area <= in_sunglasses_area_nxt;
        s0_in_glasses_area <= in_glasses_area_nxt;
        s0_in_hair1_area <= in_hair1_area_nxt;
        s0_in_hair2_area <= in_hair2_area_nxt;
        s0_in_beard_area <= in_beard_area_nxt;
        s0_in_hat_area <= in_hat_area_nxt;
        s0_in_cap_area <= in_cap_area_nxt;
        s0_in_payot_area <= in_payot_area_nxt;
        
        s0_head_addr <= head_addr_nxt;
        s0_sunglasses_addr <= sunglasses_addr_nxt;
        s0_glasses_addr <= glasses_addr_nxt;
        s0_hair1_addr <= hair1_addr_nxt;
        s0_hair2_addr <= hair2_addr_nxt;
        s0_beard_addr <= beard_addr_nxt;
        s0_hat_addr <= hat_addr_nxt;
        s0_cap_addr <= cap_addr_nxt;
        s0_payot_addr <= payot_addr_nxt;

        /* Stage 1. */
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
        s1_in_sunglasses_area <= s0_in_sunglasses_area;
        s1_in_glasses_area <= s0_in_glasses_area;
        s1_in_hair1_area <= s0_in_hair1_area;
        s1_in_hair2_area <= s0_in_hair2_area;
        s1_in_beard_area <= s0_in_beard_area;
        s1_in_hat_area <= s0_in_hat_area;
        s1_in_cap_area <= s0_in_cap_area;
        s1_in_payot_area <= s0_in_payot_area;

        /* ROM read. */
        head_pixel <= head_rom[s0_head_addr];
        sunglasses_pixel <= sunglasses_rom[s0_sunglasses_addr];
        glasses_pixel <= glasses_rom[s0_glasses_addr];
        hair1_pixel <= hair1_rom[s0_hair1_addr];
        hair2_pixel <= hair2_rom[s0_hair2_addr];
        beard_pixel <= beard_rom[s0_beard_addr];
        hat_pixel <= hat_rom[s0_hat_addr];
        cap_pixel <= cap_rom[s0_cap_addr];
        payot_pixel <= payot_rom[s0_payot_addr];

        /* Output stage. */
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
