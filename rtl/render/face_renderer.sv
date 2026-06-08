/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Fully Pipelined renderer for the procedural Guess Who face layer.
 * Strictly pipelined at boundaries to resolve deep combinational dividers logic paths.
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
    localparam int BEARD_Y_OFF = 132;
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

    // --- STAGE 0: Input Isolation Registers ---
    logic [10:0] s0_hcount, s0_vcount;
    logic s0_vsync, s0_vblnk, s0_hsync, s0_hblnk;
    logic [11:0] s0_rgb;
    logic [CHAR_ID_W-1:0] s0_selected_id;
    logic s0_has_secret;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            s0_hcount <= '0; s0_vcount <= '0;
            s0_vsync  <= '0; s0_vblnk  <= '0;
            s0_hsync  <= '0; s0_hblnk  <= '0;
            s0_rgb    <= '0;
            s0_selected_id <= '0;
            s0_has_secret  <= '0;
        end else begin
            s0_hcount <= in.hcount; s0_vcount <= in.vcount;
            s0_vsync  <= in.vsync;  s0_vblnk  <= in.vblnk;
            s0_hsync  <= in.hsync;  s0_hblnk  <= in.hblnk;
            s0_rgb    <= in.rgb;
            s0_selected_id <= selected_id;
            s0_has_secret  <= has_secret;
        end
    end

    // --- STAGE 1: Board grid decode (no division, registered) ---
    logic in_board_g, in_panel_g;
    logic [10:0] off_x_g, off_y_g;
    logic [2:0] col_g;
    logic [1:0] row_g;
    logic [10:0] cell_x_g, cell_y_g;

    logic [10:0] s1_vcount, s1_hcount;
    logic s1_vsync, s1_vblnk, s1_hsync, s1_hblnk;
    logic [11:0] s1_rgb;
    logic [CHAR_ID_W-1:0] s1_selected_id;
    logic s1_has_secret;
    logic s1_in_board, s1_in_panel;
    logic [2:0] s1_col;
    logic [1:0] s1_row;
    logic [10:0] s1_cell_x, s1_cell_y;

    always_comb begin
        in_board_g = (s0_hcount >= BOARD_X) && (s0_hcount < BOARD_X + BOARD_W) &&
                     (s0_vcount >= BOARD_Y) && (s0_vcount < BOARD_Y + BOARD_H);
        in_panel_g = (s0_hcount >= PANEL_X) && (s0_hcount < PANEL_X + CELL_W) &&
                     (s0_vcount >= PANEL_Y) && (s0_vcount < PANEL_Y + CELL_H);

        off_x_g = s0_hcount - BOARD_X;
        off_y_g = s0_vcount - BOARD_Y;
        col_g = 3'd0;
        row_g = 2'd0;
        cell_x_g = 11'h0;
        cell_y_g = 11'h0;

        if (in_board_g) begin
            col_g = board_col(off_x_g);
            row_g = board_row(off_y_g);
            cell_x_g = board_cell_x(off_x_g, col_g);
            cell_y_g = board_cell_y(off_y_g, row_g);
        end else if (in_panel_g) begin
            cell_x_g = s0_hcount - PANEL_X;
            cell_y_g = s0_vcount - PANEL_Y;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            s1_vcount <= '0; s1_hcount <= '0;
            s1_vsync <= '0; s1_vblnk <= '0;
            s1_hsync <= '0; s1_hblnk <= '0;
            s1_rgb <= '0;
            s1_selected_id <= '0;
            s1_has_secret <= '0;
            s1_in_board <= '0;
            s1_in_panel <= '0;
            s1_col <= '0;
            s1_row <= '0;
            s1_cell_x <= '0;
            s1_cell_y <= '0;
        end else begin
            s1_vcount <= s0_vcount;
            s1_hcount <= s0_hcount;
            s1_vsync <= s0_vsync;
            s1_vblnk <= s0_vblnk;
            s1_hsync <= s0_hsync;
            s1_hblnk <= s0_hblnk;
            s1_rgb <= s0_rgb;
            s1_selected_id <= s0_selected_id;
            s1_has_secret <= s0_has_secret;
            s1_in_board <= in_board_g;
            s1_in_panel <= in_panel_g;
            s1_col <= col_g;
            s1_row <= row_g;
            s1_cell_x <= cell_x_g;
            s1_cell_y <= cell_y_g;
        end
    end

    // --- STAGE 2: Character index and draw enable ---
    logic [4:0] char_idx_c;
    logic draw_face_c;

    always_comb begin
        char_idx_c = 5'h0;
        if (s1_in_board) begin
            char_idx_c = board_char_idx(s1_row, s1_col);
        end else if (s1_in_panel && s1_has_secret && (s1_selected_id < CHAR_COUNT)) begin
            char_idx_c = s1_selected_id;
        end

        draw_face_c = (s1_in_board && (s1_rgb == COLOR_WHITE)) || (s1_in_panel && s1_has_secret);
    end

    logic [10:0] s2_vcount, s2_hcount;
    logic s2_vsync, s2_vblnk, s2_hsync, s2_hblnk;
    logic [11:0] s2_rgb;
    logic s2_draw_face;
    logic [10:0] s2_cell_x, s2_cell_y;
    logic [4:0] s2_char_idx;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            s2_vcount <= '0; s2_hcount <= '0;
            s2_vsync <= '0; s2_vblnk <= '0;
            s2_hsync <= '0; s2_hblnk <= '0;
            s2_rgb <= '0;
            s2_draw_face <= '0;
            s2_cell_x <= '0;
            s2_cell_y <= '0;
            s2_char_idx <= '0;
        end else begin
            s2_vcount <= s1_vcount;
            s2_hcount <= s1_hcount;
            s2_vsync <= s1_vsync;
            s2_vblnk <= s1_vblnk;
            s2_hsync <= s1_hsync;
            s2_hblnk <= s1_hblnk;
            s2_rgb <= s1_rgb;
            s2_draw_face <= draw_face_c;
            s2_cell_x <= s1_cell_x;
            s2_cell_y <= s1_cell_y;
            s2_char_idx <= char_idx_c;
        end
    end

    // --- STAGE 3: Area Mapping & Trait Memory Layout ---
    logic [11:0] traits_s2;
    logic in_head_area_s2, in_sunglasses_area_s2, in_glasses_area_s2;
    logic in_hair1_area_s2, in_hair2_area_s2, in_beard_area_s2;
    logic in_hat_area_s2, in_cap_area_s2, in_payot_area_s2;

    logic [HEAD_ADDR_W-1:0]       head_addr_s2;
    logic [SUNGLASSES_ADDR_W-1:0] sunglasses_addr_s2;
    logic [GLASSES_ADDR_W-1:0]    glasses_addr_s2;
    logic [HAIR1_ADDR_W-1:0]      hair1_addr_s2;
    logic [HAIR2_ADDR_W-1:0]      hair2_addr_s2;
    logic [BEARD_ADDR_W-1:0]      beard_addr_s2;
    logic [HAT_ADDR_W-1:0]        hat_addr_s2;
    logic [CAP_ADDR_W-1:0]        cap_addr_s2;
    logic [PAYOT_ADDR_W-1:0]      payot_addr_s2;

    face_traits_rom u_face_traits_rom (
        .char_id (s2_char_idx),
        .traits  (traits_s2)
    );

    always_comb begin
        in_head_area_s2 = s2_draw_face &&
            (s2_cell_x >= HEAD_X_OFF) && (s2_cell_x < HEAD_X_OFF + HEAD_W) &&
            (s2_cell_y >= HEAD_Y_OFF) && (s2_cell_y < HEAD_Y_OFF + HEAD_H);
        in_sunglasses_area_s2 = s2_draw_face && traits_s2[2] &&
            (s2_cell_x >= SUNGLASSES_X_OFF) && (s2_cell_x < SUNGLASSES_X_OFF + SUNGLASSES_W) &&
            (s2_cell_y >= SUNGLASSES_Y_OFF) && (s2_cell_y < SUNGLASSES_Y_OFF + SUNGLASSES_H);
        in_glasses_area_s2 = s2_draw_face && traits_s2[8] &&
            (s2_cell_x >= GLASSES_X_OFF) && (s2_cell_x < GLASSES_X_OFF + GLASSES_W) &&
            (s2_cell_y >= GLASSES_Y_OFF) && (s2_cell_y < GLASSES_Y_OFF + GLASSES_H);
        in_hair1_area_s2 = s2_draw_face && traits_s2[6] &&
            (s2_cell_x >= HAIR1_X_OFF) && (s2_cell_x < HAIR1_X_OFF + HAIR1_W) &&
            (s2_cell_y >= HAIR1_Y_OFF) && (s2_cell_y < HAIR1_Y_OFF + HAIR1_H);
        in_hair2_area_s2 = s2_draw_face && traits_s2[7] &&
            (s2_cell_x >= HAIR2_X_OFF) && (s2_cell_x < HAIR2_X_OFF + HAIR2_W) &&
            (s2_cell_y >= HAIR2_Y_OFF) && (s2_cell_y < HAIR2_Y_OFF + HAIR2_H);
        in_beard_area_s2 = s2_draw_face && traits_s2[11] &&
            (s2_cell_x >= BEARD_X_OFF) && (s2_cell_x < BEARD_X_OFF + BEARD_W) &&
            (s2_cell_y >= BEARD_Y_OFF) && (s2_cell_y < BEARD_Y_OFF + BEARD_H);
        in_hat_area_s2 = s2_draw_face && traits_s2[9] &&
            (s2_cell_x >= HAT_X_OFF) && (s2_cell_x < HAT_X_OFF + HAT_W) &&
            (s2_cell_y >= HAT_Y_OFF) && (s2_cell_y < HAT_Y_OFF + HAT_H);
        in_cap_area_s2 = s2_draw_face && traits_s2[10] &&
            (s2_cell_x >= CAP_X_OFF) && (s2_cell_x < CAP_X_OFF + CAP_W) &&
            (s2_cell_y >= CAP_Y_OFF) && (s2_cell_y < CAP_Y_OFF + CAP_H);
        in_payot_area_s2 = s2_draw_face && traits_s2[0] &&
            (s2_cell_x >= PAYOT_X_OFF) && (s2_cell_x < PAYOT_X_OFF + PAYOT_W) &&
            (s2_cell_y >= PAYOT_Y_OFF) && (s2_cell_y < PAYOT_Y_OFF + PAYOT_H);

        head_addr_s2       = ((s2_cell_y - HEAD_Y_OFF) << 7) + ((s2_cell_y - HEAD_Y_OFF) << 3) + ((s2_cell_y - HEAD_Y_OFF) << 2) + (s2_cell_x - HEAD_X_OFF);
        sunglasses_addr_s2 = ((s2_cell_y - SUNGLASSES_Y_OFF) << 6) + ((s2_cell_y - SUNGLASSES_Y_OFF) << 4) + ((s2_cell_y - SUNGLASSES_Y_OFF) << 1) + (s2_cell_x - SUNGLASSES_X_OFF);
        glasses_addr_s2    = ((s2_cell_y - GLASSES_Y_OFF) << 6) + ((s2_cell_y - GLASSES_Y_OFF) << 4) + ((s2_cell_y - GLASSES_Y_OFF) << 2) + ((s2_cell_y - GLASSES_Y_OFF) << 1) + (s2_cell_x - GLASSES_X_OFF);
        hair1_addr_s2      = ((s2_cell_y - HAIR1_Y_OFF) << 6) + ((s2_cell_y - HAIR1_Y_OFF) << 4) + (s2_cell_x - HAIR1_X_OFF);
        hair2_addr_s2      = ((s2_cell_y - HAIR2_Y_OFF) << 6) + ((s2_cell_y - HAIR2_Y_OFF) << 4) + ((s2_cell_y - HAIR2_Y_OFF) << 2) + (s2_cell_y - HAIR2_Y_OFF) + (s2_cell_x - HAIR2_X_OFF);
        beard_addr_s2      = ((s2_cell_y - BEARD_Y_OFF) << 6) + ((s2_cell_y - BEARD_Y_OFF) << 2) + ((s2_cell_y - BEARD_Y_OFF) << 1) + (s2_cell_x - BEARD_X_OFF);
        hat_addr_s2        = ((s2_cell_y - HAT_Y_OFF) << 7) + ((s2_cell_y - HAT_Y_OFF) << 2) + ((s2_cell_y - HAT_Y_OFF) << 1) + (s2_cell_x - HAT_X_OFF);
        cap_addr_s2        = ((s2_cell_y - CAP_Y_OFF) << 6) + ((s2_cell_y - CAP_Y_OFF) << 5) + ((s2_cell_y - CAP_Y_OFF) << 3) + ((s2_cell_y - CAP_Y_OFF) << 1) + (s2_cell_y - CAP_Y_OFF) + (s2_cell_x - CAP_X_OFF);
        payot_addr_s2      = ((s2_cell_y - PAYOT_Y_OFF) << 6) + ((s2_cell_y - PAYOT_Y_OFF) << 3) + (s2_cell_x - PAYOT_X_OFF);
    end

    logic [10:0] s3_vcount, s3_hcount;
    logic s3_vsync, s3_vblnk, s3_hsync, s3_hblnk;
    logic [11:0] s3_rgb, s3_traits;
    logic s3_draw_face;

    logic s3_in_head_area, s3_in_sunglasses_area, s3_in_glasses_area;
    logic s3_in_hair1_area, s3_in_hair2_area, s3_in_beard_area;
    logic s3_in_hat_area, s3_in_cap_area, s3_in_payot_area;

    logic [HEAD_ADDR_W-1:0]       s3_head_addr;
    logic [SUNGLASSES_ADDR_W-1:0] s3_sunglasses_addr;
    logic [GLASSES_ADDR_W-1:0]    s3_glasses_addr;
    logic [HAIR1_ADDR_W-1:0]      s3_hair1_addr;
    logic [HAIR2_ADDR_W-1:0]      s3_hair2_addr;
    logic [BEARD_ADDR_W-1:0]      s3_beard_addr;
    logic [HAT_ADDR_W-1:0]        s3_hat_addr;
    logic [CAP_ADDR_W-1:0]        s3_cap_addr;
    logic [PAYOT_ADDR_W-1:0]      s3_payot_addr;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            s3_vcount <= '0; s3_hcount <= '0; s3_vsync <= '0; s3_vblnk <= '0;
            s3_hsync <= '0; s3_hblnk <= '0; s3_rgb <= '0; s3_traits <= '0;
            s3_draw_face <= '0; s3_in_head_area <= '0; s3_in_sunglasses_area <= '0;
            s3_in_glasses_area <= '0; s3_in_hair1_area <= '0; s3_in_hair2_area <= '0;
            s3_in_beard_area <= '0; s3_in_hat_area <= '0; s3_in_cap_area <= '0; s3_in_payot_area <= '0;
        end else begin
            s3_vcount <= s2_vcount; s3_hcount <= s2_hcount; s3_vsync <= s2_vsync; s3_vblnk <= s2_vblnk;
            s3_hsync <= s2_hsync; s3_hblnk <= s2_hblnk; s3_rgb <= s2_rgb; s3_traits <= traits_s2;
            s3_draw_face <= s2_draw_face;
            s3_in_head_area <= in_head_area_s2; s3_in_sunglasses_area <= in_sunglasses_area_s2;
            s3_in_glasses_area <= in_glasses_area_s2; s3_in_hair1_area <= in_hair1_area_s2;
            s3_in_hair2_area <= in_hair2_area_s2; s3_in_beard_area <= in_beard_area_s2;
            s3_in_hat_area <= in_hat_area_s2; s3_in_cap_area <= in_cap_area_s2;
            s3_in_payot_area <= in_payot_area_s2;
        end
    end

    // ROM address registers: no reset (avoids BRAM async-control DRC REQP-1839/1840).
    always_ff @(posedge clk) begin
        s3_head_addr       <= head_addr_s2;
        s3_sunglasses_addr <= sunglasses_addr_s2;
        s3_glasses_addr    <= glasses_addr_s2;
        s3_hair1_addr      <= hair1_addr_s2;
        s3_hair2_addr      <= hair2_addr_s2;
        s3_beard_addr      <= beard_addr_s2;
        s3_hat_addr        <= hat_addr_s2;
        s3_cap_addr        <= cap_addr_s2;
        s3_payot_addr      <= payot_addr_s2;
    end

    // --- STAGE 4: Block ROM Fetching ---
    logic [10:0] s4_vcount, s4_hcount;
    logic s4_vsync, s4_vblnk, s4_hsync, s4_hblnk;
    logic [11:0] s4_rgb, s4_traits;
    logic s4_draw_face;

    logic s4_in_head_area, s4_in_sunglasses_area, s4_in_glasses_area;
    logic s4_in_hair1_area, s4_in_hair2_area, s4_in_beard_area;
    logic s4_in_hat_area, s4_in_cap_area, s4_in_payot_area;

    logic [11:0] head_pixel, sunglasses_pixel, glasses_pixel;
    logic [11:0] hair1_pixel, hair2_pixel, beard_pixel;
    logic [11:0] hat_pixel, cap_pixel, payot_pixel;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            s4_vcount <= '0; s4_hcount <= '0; s4_vsync <= '0; s4_vblnk <= '0;
            s4_hsync <= '0; s4_hblnk <= '0; s4_rgb <= '0; s4_traits <= '0;
            s4_draw_face <= '0; s4_in_head_area <= '0; s4_in_sunglasses_area <= '0;
            s4_in_glasses_area <= '0; s4_in_hair1_area <= '0; s4_in_hair2_area <= '0;
            s4_in_beard_area <= '0; s4_in_hat_area <= '0; s4_in_cap_area <= '0; s4_in_payot_area <= '0;
        end else begin
            s4_vcount <= s3_vcount; s4_hcount <= s3_hcount; s4_vsync <= s3_vsync; s4_vblnk <= s3_vblnk;
            s4_hsync <= s3_hsync; s4_hblnk <= s3_hblnk; s4_rgb <= s3_rgb; s4_traits <= s3_traits;
            s4_draw_face <= s3_draw_face;
            s4_in_head_area <= s3_in_head_area; s4_in_sunglasses_area <= s3_in_sunglasses_area;
            s4_in_glasses_area <= s3_in_glasses_area; s4_in_hair1_area <= s3_in_hair1_area;
            s4_in_hair2_area <= s3_in_hair2_area; s4_in_beard_area <= s3_in_beard_area;
            s4_in_hat_area <= s3_in_hat_area; s4_in_cap_area <= s3_in_cap_area;
            s4_in_payot_area <= s3_in_payot_area;
        end
    end

    always_ff @(posedge clk) begin
        head_pixel       <= head_rom[s3_head_addr];
        sunglasses_pixel <= sunglasses_rom[s3_sunglasses_addr];
        glasses_pixel    <= glasses_rom[s3_glasses_addr];
        hair1_pixel      <= hair1_rom[s3_hair1_addr];
        hair2_pixel      <= hair2_rom[s3_hair2_addr];
        beard_pixel      <= beard_rom[s3_beard_addr];
        hat_pixel        <= hat_rom[s3_hat_addr];
        cap_pixel        <= cap_rom[s3_cap_addr];
        payot_pixel      <= payot_rom[s3_payot_addr];
    end

    // --- STAGE 5: Color Multiplexer ---
    logic [11:0] rgb_nxt;

    always_comb begin
        if (s4_vblnk || s4_hblnk) begin
            rgb_nxt = COLOR_BLACK;
        end else begin
            priority case (1'b1)
                (s4_draw_face && s4_in_hat_area && hat_pixel != COLOR_TRANSPARENT): begin
                    rgb_nxt = hat_pixel;
                end

                (s4_draw_face && s4_in_cap_area && cap_pixel != COLOR_TRANSPARENT): begin
                    if (cap_pixel == 12'hc_3_2)
                        rgb_nxt = s4_traits[1] ? 12'h2_2_2 : 12'h0_3_2;
                    else
                        rgb_nxt = cap_pixel;
                end

                (s4_draw_face && s4_in_sunglasses_area && sunglasses_pixel != COLOR_TRANSPARENT): begin
                    rgb_nxt = sunglasses_pixel;
                end

                (s4_draw_face && s4_in_glasses_area && glasses_pixel != COLOR_TRANSPARENT): begin
                    rgb_nxt = glasses_pixel;
                end

                (s4_draw_face && s4_in_beard_area && beard_pixel != COLOR_TRANSPARENT): begin
                    if (beard_pixel == 12'h3_2_2)
                        rgb_nxt = s4_traits[5] ? 12'hd_b_7 : 12'h2_1_0;
                    else if (beard_pixel == 12'h0_0_0)
                        rgb_nxt = s4_traits[5] ? 12'hc_9_7 : 12'h0_0_0;
                    else
                        rgb_nxt = beard_pixel;
                end

                (s4_draw_face && s4_in_hair1_area && hair1_pixel != COLOR_TRANSPARENT): begin
                    if (hair1_pixel == 12'h3_2_2) begin
                        rgb_nxt = s4_traits[5] ? 12'hd_b_7 : 12'h2_1_0;
                    end else if (hair1_pixel == 12'h0_0_0) begin
                        rgb_nxt = s4_traits[5] ? 12'hc_9_7 : 12'h0_0_0;
                    end else begin
                        rgb_nxt = hair1_pixel;
                    end
                end

                (s4_draw_face && s4_in_hair2_area && hair2_pixel != COLOR_TRANSPARENT): begin
                    if (hair2_pixel == 12'h3_2_2) begin
                        rgb_nxt = s4_traits[5] ? 12'hd_b_7 : 12'h2_1_0;
                    end else if (hair2_pixel == 12'h0_0_0) begin
                        rgb_nxt = s4_traits[5] ? 12'hc_9_7 : 12'h2_1_0;
                    end else begin
                        rgb_nxt = hair2_pixel;
                    end
                end

                (s4_draw_face && s4_in_payot_area && payot_pixel != COLOR_TRANSPARENT): begin
                    if (payot_pixel == 12'h3_2_2) begin
                        rgb_nxt = s4_traits[5] ? 12'hd_b_7 : 12'h3_2_2;
                    end else begin
                        rgb_nxt = payot_pixel;
                    end
                end

                (s4_draw_face && s4_in_head_area && head_pixel != COLOR_TRANSPARENT): begin
                    if (head_pixel == COLOR_WHITE) begin
                        rgb_nxt = s4_traits[3] ? 12'h8_5_2 : 12'hf_d_b;
                    end else if (head_pixel == 12'h9_5_3) begin
                        rgb_nxt = s4_traits[4] ? 12'h4_a_f : 12'h3_4_1;
                    end else begin
                        rgb_nxt = head_pixel;
                    end
                end

                default: rgb_nxt = s4_rgb;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            out.vcount <= '0; out.vsync <= '0; out.vblnk <= '0;
            out.hcount <= '0; out.hsync <= '0; out.hblnk <= '0; out.rgb <= '0;
        end else begin
            out.vcount <= s4_vcount;
            out.vsync  <= s4_vsync;
            out.vblnk  <= s4_vblnk;
            out.hcount <= s4_hcount;
            out.hsync  <= s4_hsync;
            out.hblnk  <= s4_hblnk;
            out.rgb    <= rgb_nxt;
        end
    end

endmodule
