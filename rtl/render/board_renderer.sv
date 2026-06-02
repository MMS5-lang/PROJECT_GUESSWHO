/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Pipelined Overlay renderer for selection, elimination, guess feedback,
 * and dynamic mouth expressions.
 * Heavily pipelined to completely isolate constant dividers from inter-module paths.
 */

 module board_renderer
    import vga_pkg::*;
    import guess_who_pkg::*;
    (
        input  logic clk,
        input  logic rst_n,
        vga_if.out   out,
        input  game_state_t game_state,
        input  logic [CHAR_COUNT-1:0] eliminated_mask,
        input  logic [CHAR_ID_W-1:0] selected_id,
        input  logic [CHAR_ID_W-1:0] last_guess_id,
        input  logic has_secret,
        vga_if.in    in
    );
    timeunit 1ns;
    timeprecision 1ps;

    localparam logic [11:0] COLOR_BLACK  = 12'h0_0_0;
    localparam logic [11:0] COLOR_BLUE   = 12'h1_4_f;
    localparam logic [11:0] COLOR_GREEN  = 12'h0_b_0;
    localparam logic [11:0] COLOR_ORANGE = 12'hf_9_0;
    localparam logic [11:0] COLOR_RED    = 12'hf_0_0;
    localparam logic [11:0] COLOR_TRANSPARENT = 12'hf_0_f;
    localparam int MOUTH_W = 26;
    localparam int MOUTH_H = 10;
    localparam int MOUTH_X = 54;
    localparam int MOUTH_Y = 154;


    localparam logic [0:15] Q_MARK [0:23] = '{
        16'b0000011111100000, 16'b0000111111110000, 16'b0001110000111000, 16'b0011100000011100,
        16'b0011100000011100, 16'b0011100000011100, 16'b0011100000111000, 16'b0000000001110000,
        16'b0000000011100000, 16'b0000000111000000, 16'b0000001110000000, 16'b0000011100000000,
        16'b0000011100000000, 16'b0000011100000000, 16'b0000011100000000, 16'b0000000000000000,
        16'b0000000000000000, 16'b0000000000000000, 16'b0000011110000000, 16'b0000111111000000,
        16'b0000111111000000, 16'b0000111111000000, 16'b0000011110000000, 16'b0000000000000000
    };

    // --- STAGE 0: Input Isolation Registers (Guarantees zero inter-module wire delay setup) ---
    logic [10:0] s0_hcount, s0_vcount;
    logic s0_vsync, s0_vblnk, s0_hsync, s0_hblnk;
    logic [11:0] s0_rgb;
    game_state_t s0_game_state;
    logic [CHAR_COUNT-1:0] s0_eliminated_mask;
    logic [CHAR_ID_W-1:0] s0_selected_id;
    logic [CHAR_ID_W-1:0] s0_last_guess_id;
    logic s0_has_secret;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            s0_hcount <= '0; s0_vcount <= '0;
            s0_vsync <= '0; s0_vblnk <= '0;
            s0_hsync <= '0; s0_hblnk <= '0; s0_rgb <= '0;
            s0_game_state <= S_SELECT_SECRET;
            s0_eliminated_mask <= '0;
            s0_selected_id <= '0;
            s0_last_guess_id <= '0;
            s0_has_secret <= '0;
        end else begin
            s0_hcount <= in.hcount; s0_vcount <= in.vcount;
            s0_vsync <= in.vsync; s0_vblnk <= in.vblnk;
            s0_hsync <= in.hsync; s0_hblnk <= in.hblnk;
            s0_rgb <= in.rgb;
            s0_game_state <= game_state;
            s0_eliminated_mask <= eliminated_mask;
            s0_selected_id <= selected_id;
            s0_last_guess_id <= last_guess_id;
            s0_has_secret <= has_secret;
        end
    end

    // --- STAGE 1: Isolated Math Operations (Grid Coordinates Extraction) ---
    logic [10:0] off_x_s0, off_y_s0;
    logic [10:0] cell_x_s0, cell_y_s0;
    logic [2:0] col_s0;
    logic [1:0] row_s0;
    logic [CHAR_ID_W-1:0] char_idx_s0;
    logic valid_char_s0;
    logic in_mouth_area_s0;
    logic [8:0] mouth_addr_s0;

    always_comb begin
        off_x_s0 = s0_hcount - BOARD_X;
        off_y_s0 = s0_vcount - BOARD_Y;
        cell_x_s0 = 11'h0;
        cell_y_s0 = 11'h0;
        col_s0 = 3'd0;
        row_s0 = 2'd0;
        char_idx_s0 = '0;

        if ((s0_hcount >= BOARD_X) && (s0_hcount < BOARD_X + BOARD_W) &&
            (s0_vcount >= BOARD_Y) && (s0_vcount < BOARD_Y + BOARD_H)) begin
            col_s0 = board_col(off_x_s0);
            row_s0 = board_row(off_y_s0);
            cell_x_s0 = board_cell_x(off_x_s0, col_s0);
            cell_y_s0 = board_cell_y(off_y_s0, row_s0);
            char_idx_s0 = board_char_idx(row_s0, col_s0);
        end

        valid_char_s0 = ((s0_hcount >= BOARD_X) && (s0_hcount < BOARD_X + BOARD_W) &&
                         (s0_vcount >= BOARD_Y) && (s0_vcount < BOARD_Y + BOARD_H)) && (char_idx_s0 < CHAR_COUNT);

        in_mouth_area_s0 = valid_char_s0 && (cell_x_s0 >= MOUTH_X) && (cell_x_s0 < MOUTH_X + MOUTH_W) &&
                                             (cell_y_s0 >= MOUTH_Y) && (cell_y_s0 < MOUTH_Y + MOUTH_H);

        mouth_addr_s0 = ((cell_y_s0 - MOUTH_Y) << 4) + ((cell_y_s0 - MOUTH_Y) << 3) + ((cell_y_s0 - MOUTH_Y) << 1) + (cell_x_s0 - MOUTH_X);
    end

    // Stage 1 Pipeline Registers
    logic [10:0] s1_hcount, s1_vcount;
    logic s1_vsync, s1_vblnk, s1_hsync, s1_hblnk;
    logic [11:0] s1_rgb;
    game_state_t s1_game_state;
    logic [CHAR_COUNT-1:0] s1_eliminated_mask;
    logic [CHAR_ID_W-1:0] s1_selected_id;
    logic [CHAR_ID_W-1:0] s1_last_guess_id;
    logic s1_has_secret;
    logic [10:0] s1_cell_x, s1_cell_y;
    logic [CHAR_ID_W-1:0] s1_char_idx;
    logic s1_valid_char;
    logic s1_in_mouth_area;
    logic [8:0] s1_mouth_addr;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            s1_hcount <= '0; s1_vcount <= '0; s1_vsync <= '0; s1_vblnk <= '0;
            s1_hsync <= '0; s1_hblnk <= '0; s1_rgb <= '0; s1_game_state <= S_SELECT_SECRET;
            s1_eliminated_mask <= '0; s1_selected_id <= '0; s1_last_guess_id <= '0; s1_has_secret <= '0;
            s1_cell_x <= '0; s1_cell_y <= '0; s1_char_idx <= '0; s1_valid_char <= '0;
            s1_in_mouth_area <= '0; s1_mouth_addr <= '0;
        end else begin
            s1_hcount <= s0_hcount; s1_vcount <= s0_vcount; s1_vsync <= s0_vsync; s1_vblnk <= s0_vblnk;
            s1_hsync <= s0_hsync; s1_hblnk <= s0_hblnk; s1_rgb <= s0_rgb; s1_game_state <= s0_game_state;
            s1_eliminated_mask <= s0_eliminated_mask; s1_selected_id <= s0_selected_id;
            s1_last_guess_id <= s0_last_guess_id; s1_has_secret <= s0_has_secret;
            s1_cell_x <= cell_x_s0; s1_cell_y <= cell_y_s0; s1_char_idx <= char_idx_s0;
            s1_valid_char <= valid_char_s0; s1_in_mouth_area <= in_mouth_area_s0;
            s1_mouth_addr <= mouth_addr_s0;
        end
    end

    // --- STAGE 2: Area Flags, Logic Checks & Synchronous Block ROM Call ---
    logic is_cell_border_s1, is_panel_border_s1, is_elimination_mark_s1;
    logic is_selected_mark_s1, is_last_guess_mark_s1, is_wrong_guess_bg_s1;
    logic in_q_mark_area_s1, q_pixel_on_s1, char_is_sad_s1;
    logic [3:0] q_x_s1;
    logic [4:0] q_y_s1;
    logic in_panel_s1;
    logic [11:0] mouth_rgb_happy, mouth_rgb_sad;

    // mouth_rom receives s1_mouth_addr, output will be ready in Stage 2 (Cycle 2)
    mouth_rom u_mouth_rom (
        .clk(clk),
        .addr(s1_mouth_addr),
        .rgb_happy(mouth_rgb_happy),
        .rgb_sad(mouth_rgb_sad)
    );

    always_comb begin
        in_panel_s1 = (s1_hcount >= PANEL_X) && (s1_hcount < PANEL_X + CELL_W) &&
                      (s1_vcount >= PANEL_Y) && (s1_vcount < PANEL_Y + CELL_H);

        is_cell_border_s1 = s1_valid_char && ((s1_cell_x < 5) || (s1_cell_x >= CELL_W - 5) || (s1_cell_y < 5) || (s1_cell_y >= CELL_H - 5));
        is_panel_border_s1 = in_panel_s1 && ((s1_hcount < PANEL_X + 5) || (s1_hcount >= PANEL_X + CELL_W - 5) ||
                                             (s1_vcount < PANEL_Y + 5) || (s1_vcount >= PANEL_Y + CELL_H - 5));

        is_elimination_mark_s1 = s1_valid_char && s1_eliminated_mask[s1_char_idx] &&
            !(s1_game_state == S_WRONG_GUESS_FEEDBACK && s1_char_idx == s1_last_guess_id) &&
            (s1_cell_x >= 1) && (s1_cell_x < CELL_W) && (s1_cell_y >= 3) && (s1_cell_y < CELL_H);

        is_selected_mark_s1 = s1_valid_char && s1_has_secret && (s1_game_state == S_SELECT_SECRET) && (s1_char_idx == s1_selected_id) && is_cell_border_s1;
        is_last_guess_mark_s1 = s1_valid_char && (s1_char_idx == s1_last_guess_id) && (s1_game_state == S_WRONG_GUESS_FEEDBACK) && is_cell_border_s1;
        is_wrong_guess_bg_s1 = s1_valid_char && (s1_char_idx == s1_last_guess_id) && (s1_game_state == S_WRONG_GUESS_FEEDBACK) && !is_cell_border_s1;

        in_q_mark_area_s1 = is_elimination_mark_s1 && (s1_cell_x >= 40) && (s1_cell_x < 104) && (s1_cell_y >= 52) && (s1_cell_y < 148);

        if (in_q_mark_area_s1) begin
            q_x_s1 = (s1_cell_x - 11'd40) >> 2;
            q_y_s1 = (s1_cell_y - 11'd52) >> 2;
            q_pixel_on_s1 = (q_y_s1 < 24 && q_x_s1 < 16) ? Q_MARK[q_y_s1][q_x_s1] : 1'b0;
        end else begin
            q_x_s1 = '0; q_y_s1 = '0; q_pixel_on_s1 = 1'b0;
        end

        char_is_sad_s1 = s1_valid_char && (s1_eliminated_mask[s1_char_idx] || (s1_game_state == S_WRONG_GUESS_FEEDBACK && s1_char_idx == s1_last_guess_id));
    end

    // Stage 2 Pipeline Registers
    logic [10:0] s2_hcount, s2_vcount;
    logic s2_vsync, s2_vblnk, s2_hsync, s2_hblnk;
    logic [11:0] s2_rgb;
    game_state_t s2_game_state;
    logic s2_is_panel_border, s2_is_elimination_mark;
    logic s2_is_selected_mark, s2_is_last_guess_mark, s2_is_wrong_guess_bg;
    logic s2_q_pixel_on, s2_has_secret, s2_in_mouth_area, s2_char_is_sad;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            s2_hcount <= '0; s2_vcount <= '0;
            s2_vsync <= '0; s2_vblnk <= '0; s2_hsync <= '0; s2_hblnk <= '0; s2_rgb <= '0;
            s2_game_state <= S_SELECT_SECRET; s2_is_panel_border <= '0;
            s2_is_elimination_mark <= '0; s2_is_selected_mark <= '0; s2_is_last_guess_mark <= '0;
            s2_is_wrong_guess_bg <= '0; s2_q_pixel_on <= '0; s2_has_secret <= '0;
            s2_in_mouth_area <= '0; s2_char_is_sad <= '0;
        end else begin
            s2_hcount <= s1_hcount; s2_vcount <= s1_vcount;
            s2_vsync <= s1_vsync; s2_vblnk <= s1_vblnk; s2_hsync <= s1_hsync; s2_hblnk <= s1_hblnk; s2_rgb <= s1_rgb;
            s2_game_state <= s1_game_state;
            s2_is_panel_border <= is_panel_border_s1;
            s2_is_elimination_mark <= is_elimination_mark_s1;
            s2_is_selected_mark <= is_selected_mark_s1;
            s2_is_last_guess_mark <= is_last_guess_mark_s1;
            s2_is_wrong_guess_bg <= is_wrong_guess_bg_s1;
            s2_q_pixel_on <= q_pixel_on_s1;
            s2_has_secret <= s1_has_secret;
            s2_in_mouth_area <= s1_in_mouth_area;
            s2_char_is_sad <= char_is_sad_s1;
        end
    end

    // --- STAGE 3: Color Mixing Multiplexer & Final Latch ---
    logic [11:0] rgb_nxt;
    logic [11:0] base_rgb;
    logic [11:0] active_mouth_color;

    always_comb begin
        base_rgb = s2_rgb;
        active_mouth_color = s2_char_is_sad ? mouth_rgb_sad : mouth_rgb_happy;

        if (s2_in_mouth_area && active_mouth_color != COLOR_TRANSPARENT) begin
            base_rgb = active_mouth_color;
        end
        if (s2_vblnk || s2_hblnk) begin
            rgb_nxt = COLOR_BLACK;
        end else if (s2_is_last_guess_mark) begin
            rgb_nxt = COLOR_RED;
        end else if (s2_is_wrong_guess_bg) begin
            rgb_nxt = {1'b1, base_rgb[11:9], 1'b0, base_rgb[7:5], 1'b0, base_rgb[3:1]};
        end else if (s2_is_elimination_mark) begin
            if (s2_q_pixel_on) begin
                rgb_nxt = COLOR_BLUE;
            end else begin
                rgb_nxt = {1'b0, base_rgb[11:9], 1'b0, base_rgb[7:5], 1'b1, base_rgb[3:1]};
            end
        end else if (s2_is_selected_mark) begin
            rgb_nxt = COLOR_BLUE;
        end else if (s2_is_panel_border && s2_game_state == S_WIN) begin
            rgb_nxt = COLOR_GREEN;
        end else if (s2_is_panel_border && s2_game_state == S_LOSE) begin
            rgb_nxt = COLOR_RED;
        end else if (s2_is_panel_border && s2_game_state == S_OPPONENT_TURN) begin
            rgb_nxt = COLOR_ORANGE;
        end else if (s2_is_panel_border && s2_game_state == S_MY_TURN) begin
            rgb_nxt = COLOR_GREEN;
        end else if (s2_is_panel_border && s2_has_secret) begin
            rgb_nxt = COLOR_BLUE;
        end else begin
            rgb_nxt = base_rgb;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            out.vcount <= '0; out.vsync <= '0; out.vblnk <= '0;
            out.hcount <= '0; out.hsync <= '0; out.hblnk <= '0; out.rgb <= '0;
        end else begin
            out.vcount <= s2_vcount;
            out.vsync  <= s2_vsync;
            out.vblnk  <= s2_vblnk;
            out.hcount <= s2_hcount;
            out.hsync  <= s2_hsync;
            out.hblnk  <= s2_hblnk;
            out.rgb    <= rgb_nxt;
        end
    end
 endmodule