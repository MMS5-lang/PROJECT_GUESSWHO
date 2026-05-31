/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Milosz M. Karolina M.
 *
 * Description:
 * Pixel-level tests for renderers, text, face traits and cursor overlay.
 */

module render_modules_tb;

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;
import guess_who_pkg::*;

localparam int CLK_PERIOD = 10;
localparam logic [11:0] COLOR_BLACK = 12'h0_0_0;
localparam logic [11:0] COLOR_WHITE = 12'hf_f_f;
localparam logic [11:0] COLOR_GRAY = 12'h5_5_5;
localparam logic [11:0] COLOR_ELIM = 12'h7_7_7;
localparam logic [11:0] COLOR_BLUE = 12'h1_4_f;
localparam logic [11:0] COLOR_GREEN = 12'h0_b_0;
localparam logic [11:0] COLOR_ORANGE = 12'hf_9_0;
localparam logic [11:0] COLOR_RED = 12'hf_0_0;
localparam logic [11:0] COLOR_DARK_SKIN = 12'h8_5_2;

logic clk;
logic rst_n;

logic [7:0] font_char_code;
logic [2:0] font_row;
logic [4:0] font_pixels;
logic [CHAR_ID_W-1:0] traits_char_id;
logic [11:0] traits;

game_state_t ui_state;
logic ui_local_ready;
logic ui_remote_ready;

game_state_t board_state;
logic [CHAR_COUNT-1:0] board_eliminated_mask;
logic [CHAR_ID_W-1:0] board_selected_id;
logic [CHAR_ID_W-1:0] board_last_guess_id;
logic board_has_secret;

game_state_t text_state;

logic [CHAR_ID_W-1:0] face_selected_id;
logic face_has_secret;

logic [11:0] mouse_xpos;
logic [11:0] mouse_ypos;
cursor_mode_t mouse_cursor_mode;

vga_if bg_in ();
vga_if bg_out ();
vga_if ui_in ();
vga_if ui_out ();
vga_if board_in ();
vga_if board_out ();
vga_if text_in ();
vga_if text_out ();
vga_if face_in ();
vga_if face_out ();
vga_if mouse_in ();
vga_if mouse_out ();

font_rom dut_font_rom (
    .char_code (font_char_code),
    .row       (font_row),
    .pixels    (font_pixels)
);

face_traits_rom dut_face_traits_rom (
    .char_id (traits_char_id),
    .traits  (traits)
);

draw_bg dut_draw_bg (
    .clk,
    .rst_n,
    .in  (bg_in.in),
    .out (bg_out.out)
);

ui_renderer dut_ui_renderer (
    .clk,
    .rst_n,
    .game_state   (ui_state),
    .local_ready  (ui_local_ready),
    .remote_ready (ui_remote_ready),
    .in           (ui_in.in),
    .out          (ui_out.out)
);

board_renderer dut_board_renderer (
    .clk,
    .rst_n,
    .game_state      (board_state),
    .eliminated_mask (board_eliminated_mask),
    .selected_id     (board_selected_id),
    .last_guess_id   (board_last_guess_id),
    .has_secret      (board_has_secret),
    .in              (board_in.in),
    .out             (board_out.out)
);

text_renderer dut_text_renderer (
    .clk,
    .rst_n,
    .game_state (text_state),
    .in         (text_in.in),
    .out        (text_out.out)
);

face_renderer dut_face_renderer (
    .clk,
    .rst_n,
    .selected_id (face_selected_id),
    .has_secret  (face_has_secret),
    .in          (face_in.in),
    .out         (face_out.out)
);

draw_mouse dut_draw_mouse (
    .clk,
    .rst_n,
    .xpos        (mouse_xpos),
    .ypos        (mouse_ypos),
    .cursor_mode (mouse_cursor_mode),
    .in          (mouse_in.in),
    .out         (mouse_out.out)
);

initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD / 2) begin
        clk = ~clk;
    end
end

task automatic wait_clk;
begin
    @(posedge clk);
    #1;
end
endtask

task automatic drive_bg(input int h, input int v, input logic [11:0] rgb, input logic hblnk, input logic vblnk);
begin
    bg_in.hcount = h[10:0];
    bg_in.vcount = v[10:0];
    bg_in.hsync = 1'b1;
    bg_in.vsync = 1'b1;
    bg_in.hblnk = hblnk;
    bg_in.vblnk = vblnk;
    bg_in.rgb = rgb;
    wait_clk;
end
endtask

task automatic drive_ui(input int h, input int v, input logic [11:0] rgb, input logic hblnk, input logic vblnk);
begin
    ui_in.hcount = h[10:0];
    ui_in.vcount = v[10:0];
    ui_in.hsync = 1'b1;
    ui_in.vsync = 1'b1;
    ui_in.hblnk = hblnk;
    ui_in.vblnk = vblnk;
    ui_in.rgb = rgb;
    wait_clk;
end
endtask

task automatic drive_board(input int h, input int v, input logic [11:0] rgb, input logic hblnk, input logic vblnk);
begin
    board_in.hcount = h[10:0];
    board_in.vcount = v[10:0];
    board_in.hsync = 1'b1;
    board_in.vsync = 1'b1;
    board_in.hblnk = hblnk;
    board_in.vblnk = vblnk;
    board_in.rgb = rgb;
    wait_clk;
end
endtask

task automatic drive_text(input int h, input int v, input logic [11:0] rgb, input logic hblnk, input logic vblnk);
begin
    text_in.hcount = h[10:0];
    text_in.vcount = v[10:0];
    text_in.hsync = 1'b1;
    text_in.vsync = 1'b1;
    text_in.hblnk = hblnk;
    text_in.vblnk = vblnk;
    text_in.rgb = rgb;
    repeat (4) begin
        wait_clk;
    end
end
endtask

task automatic drive_face(input int h, input int v, input logic [11:0] rgb, input logic hblnk, input logic vblnk);
begin
    face_in.hcount = h[10:0];
    face_in.vcount = v[10:0];
    face_in.hsync = 1'b1;
    face_in.vsync = 1'b1;
    face_in.hblnk = hblnk;
    face_in.vblnk = vblnk;
    face_in.rgb = rgb;
    repeat (3) begin
        wait_clk;
    end
end
endtask

task automatic drive_mouse(input int h, input int v, input logic [11:0] rgb, input logic hblnk, input logic vblnk);
begin
    mouse_in.hcount = h[10:0];
    mouse_in.vcount = v[10:0];
    mouse_in.hsync = 1'b1;
    mouse_in.vsync = 1'b1;
    mouse_in.hblnk = hblnk;
    mouse_in.vblnk = vblnk;
    mouse_in.rgb = rgb;
    repeat (3) begin
        wait_clk;
    end
end
endtask

task automatic expect_text_pixels(
    input game_state_t state,
    input int x0,
    input int y0,
    input int len,
    input logic [11:0] color,
    input string label
);
    int x;
    int y;
    bit found;
begin
    text_state = state;
    found = 1'b0;

    for (y = 0; y < 14; y += 2) begin
        for (x = 0; x < len * 12; x += 2) begin
            drive_text(x0 + x, y0 + y, 12'h1_2_3, 1'b0, 1'b0);
            if (text_out.rgb == color) begin
                found = 1'b1;
            end
        end
    end

    assert (found) else $error("%s text did not draw the expected color", label);
end
endtask

task automatic clear_inputs;
begin
    bg_in.hcount = '0;
    bg_in.vcount = '0;
    bg_in.hsync = 1'b0;
    bg_in.vsync = 1'b0;
    bg_in.hblnk = 1'b0;
    bg_in.vblnk = 1'b0;
    bg_in.rgb = '0;

    ui_in.hcount = '0;
    ui_in.vcount = '0;
    ui_in.hsync = 1'b0;
    ui_in.vsync = 1'b0;
    ui_in.hblnk = 1'b0;
    ui_in.vblnk = 1'b0;
    ui_in.rgb = '0;

    board_in.hcount = '0;
    board_in.vcount = '0;
    board_in.hsync = 1'b0;
    board_in.vsync = 1'b0;
    board_in.hblnk = 1'b0;
    board_in.vblnk = 1'b0;
    board_in.rgb = '0;

    text_in.hcount = '0;
    text_in.vcount = '0;
    text_in.hsync = 1'b0;
    text_in.vsync = 1'b0;
    text_in.hblnk = 1'b0;
    text_in.vblnk = 1'b0;
    text_in.rgb = '0;

    face_in.hcount = '0;
    face_in.vcount = '0;
    face_in.hsync = 1'b0;
    face_in.vsync = 1'b0;
    face_in.hblnk = 1'b0;
    face_in.vblnk = 1'b0;
    face_in.rgb = '0;

    mouse_in.hcount = '0;
    mouse_in.vcount = '0;
    mouse_in.hsync = 1'b0;
    mouse_in.vsync = 1'b0;
    mouse_in.hblnk = 1'b0;
    mouse_in.vblnk = 1'b0;
    mouse_in.rgb = '0;
end
endtask

initial begin
    rst_n = 1'b0;
    ui_state = S_SELECT_SECRET;
    ui_local_ready = 1'b0;
    ui_remote_ready = 1'b0;
    board_state = S_SELECT_SECRET;
    board_eliminated_mask = '0;
    board_selected_id = '0;
    board_last_guess_id = '0;
    board_has_secret = 1'b0;
    text_state = S_SELECT_SECRET;
    face_selected_id = '0;
    face_has_secret = 1'b0;
    mouse_xpos = 12'd10;
    mouse_ypos = 12'd10;
    mouse_cursor_mode = CURSOR_POINTER;
    font_char_code = "A";
    font_row = 3'd0;
    traits_char_id = '0;
    clear_inputs();

    repeat (3) begin
        wait_clk;
    end

    assert (bg_out.rgb == 12'h000) else $error("draw_bg reset failed");
    assert (ui_out.rgb == 12'h000) else $error("ui_renderer reset failed");
    assert (board_out.rgb == 12'h000) else $error("board_renderer reset failed");
    assert (text_out.rgb == 12'h000) else $error("text_renderer reset failed");
    assert (face_out.rgb == 12'h000) else $error("face_renderer reset failed");
    assert (mouse_out.rgb == 12'h000) else $error("draw_mouse reset failed");

    rst_n = 1'b1;
    wait_clk;

    font_char_code = "A";
    font_row = 3'd0;
    #1;
    assert (font_pixels == 5'b01110) else $error("font_rom A row 0 mismatch");
    font_char_code = "B";
    font_row = 3'd0;
    #1;
    assert (font_pixels == 5'b11110) else $error("font_rom B row 0 mismatch");
    font_char_code = "S";
    font_row = 3'd3;
    #1;
    assert (font_pixels == 5'b01110) else $error("font_rom S row 3 mismatch");
    font_char_code = "x";
    font_row = 3'd0;
    #1;
    assert (font_pixels == 5'b00000) else $error("font_rom unsupported char should be blank");

    traits_char_id = 5'd0;
    #1;
    assert (traits == 12'b0000_0110_1000) else $error("face_traits_rom char 0 mismatch");
    traits_char_id = 5'd17;
    #1;
    assert (traits == 12'b1001_0001_0000) else $error("face_traits_rom char 17 mismatch");
    traits_char_id = 5'd31;
    #1;
    assert (traits == 12'b0000_0000_0000) else $error("face_traits_rom invalid id should be blank");

    drive_bg(0, 0, 12'h1_2_3, 1'b0, 1'b0);
    assert (bg_out.rgb == 12'h1_2_3) else $error("draw_bg should pass outside-board pixels");
    drive_bg(BOARD_X, BOARD_Y, 12'h1_2_3, 1'b0, 1'b0);
    assert (bg_out.rgb == COLOR_BLACK) else $error("draw_bg board frame should be black");
    drive_bg(BOARD_X + 10, BOARD_Y + 10, 12'h1_2_3, 1'b0, 1'b0);
    assert (bg_out.rgb == COLOR_WHITE) else $error("draw_bg board interior should be white");
    drive_bg(BOARD_X + CELL_W, BOARD_Y + 10, 12'h1_2_3, 1'b0, 1'b0);
    assert (bg_out.rgb == COLOR_GRAY) else $error("draw_bg grid line should be gray");
    drive_bg(BOARD_X + 10, BOARD_Y + 10, 12'h1_2_3, 1'b1, 1'b0);
    assert (bg_out.rgb == COLOR_BLACK) else $error("draw_bg blanking should be black");

    ui_state = S_SELECT_SECRET;
    drive_ui(START_X + 2, START_Y + 2, 12'h1_2_3, 1'b0, 1'b0);
    assert (ui_out.rgb == 12'h1_b_5) else $error("START button should be green during selection");
    drive_ui(RESET_X + 2, RESET_Y + 2, 12'h1_2_3, 1'b0, 1'b0);
    assert (ui_out.rgb == 12'hd_0_0) else $error("RESET button should be red");
    ui_state = S_LOCAL_READY;
    drive_ui(PANEL_X + 10, PANEL_Y + 10, 12'h1_2_3, 1'b0, 1'b0);
    assert (ui_out.rgb == COLOR_WHITE) else $error("Panel should stay white");
    ui_state = S_MY_TURN;
    drive_ui(START_X + 2, START_Y + 2, 12'h1_2_3, 1'b0, 1'b0);
    assert (ui_out.rgb == COLOR_BLUE) else $error("End-turn button should be blue");

    board_state = S_SELECT_SECRET;
    board_has_secret = 1'b1;
    board_selected_id = 5'd0;
    drive_board(BOARD_X + 1, BOARD_Y + 1, 12'h1_2_3, 1'b0, 1'b0);
    assert (board_out.rgb == COLOR_BLUE) else $error("Selected character border should be blue");
    board_state = S_MY_TURN;
    board_eliminated_mask = '0;
    board_eliminated_mask[5] = 1'b1;
    drive_board(BOARD_X + 5 * CELL_W + CELL_W / 2, BOARD_Y + CELL_H / 2, 12'h1_2_3, 1'b0, 1'b0);
    assert (board_out.rgb == COLOR_ELIM) else $error("Eliminated character overlay should be gray");
    board_eliminated_mask = '0;
    board_state = S_WRONG_GUESS_FEEDBACK;
    board_last_guess_id = 5'd7;
    drive_board(BOARD_X + CELL_W + 1, BOARD_Y + CELL_H + 1, 12'h1_2_3, 1'b0, 1'b0);
    assert (board_out.rgb == COLOR_RED) else $error("Wrong guess border should be red");
    board_state = S_WIN;
    drive_board(PANEL_X + 1, PANEL_Y + 1, 12'h1_2_3, 1'b0, 1'b0);
    assert (board_out.rgb == COLOR_GREEN) else $error("Win panel border should be green");
    board_state = S_OPPONENT_TURN;
    drive_board(PANEL_X + 1, PANEL_Y + 1, 12'h1_2_3, 1'b0, 1'b0);
    assert (board_out.rgb == COLOR_ORANGE) else $error("Opponent turn panel border should be orange");

    expect_text_pixels(S_SELECT_SECRET, START_X + 20, START_Y + 18, 5, COLOR_WHITE, "START");
    expect_text_pixels(S_MY_TURN, START_X + 14, START_Y + 8, 6, COLOR_WHITE, "KONIEC");
    expect_text_pixels(S_MY_TURN, START_X + 26, START_Y + 28, 4, COLOR_WHITE, "TURY");
    expect_text_pixels(S_WAIT_LINK, PANEL_X + ((CELL_W - 6 * 12) / 2),
                       PANEL_Y + CELL_H + 8, 6, COLOR_BLACK, "CZEKAM");
    expect_text_pixels(S_SELECT_SECRET, PANEL_X + ((CELL_W - 7 * 12) / 2),
                       PANEL_Y + CELL_H + 8, 7, COLOR_BLACK, "WYBIERZ");
    expect_text_pixels(S_SELECT_SECRET, PANEL_X + ((CELL_W - 5 * 12) / 2),
                       PANEL_Y + CELL_H + 28, 5, COLOR_BLACK, "SWOJA");
    expect_text_pixels(S_LOCAL_READY, PANEL_X + ((CELL_W - 8 * 12) / 2),
                       PANEL_Y + CELL_H + 8, 8, COLOR_BLACK, "POCZEKAJ");
    expect_text_pixels(S_WAIT_GUESS_RESULT, PANEL_X + ((CELL_W - 8 * 12) / 2),
                       PANEL_Y + CELL_H + 28, 8, COLOR_BLACK, "NA WYNIK");
    expect_text_pixels(S_WRONG_GUESS_FEEDBACK, PANEL_X + ((CELL_W - 11 * 12) / 2),
                       PANEL_Y + CELL_H + 8, 11, COLOR_RED, "NIEPOPRAWNA");
    expect_text_pixels(S_COMM_ERROR, PANEL_X + ((CELL_W - 5 * 12) / 2),
                       PANEL_Y + CELL_H + 8, 5, COLOR_RED, "ERROR");
    expect_text_pixels(S_WIN, PANEL_X + ((CELL_W - 8 * 12) / 2),
                       PANEL_Y + CELL_H + 28, 8, COLOR_GREEN, "WYGRALES");
    expect_text_pixels(S_LOSE, PANEL_X + ((CELL_W - 10 * 12) / 2),
                       PANEL_Y + CELL_H + 28, 10, COLOR_RED, "PRZEGRALES");
    drive_text(0, 0, 12'h1_2_3, 1'b0, 1'b0);
    assert (text_out.rgb == 12'h1_2_3) else $error("text_renderer should pass unrelated pixels");

    face_selected_id = 5'd0;
    face_has_secret = 1'b1;
    drive_face(BOARD_X + 70, BOARD_Y + 100, COLOR_WHITE, 1'b0, 1'b0);
    assert (face_out.rgb == COLOR_DARK_SKIN) else $error("face_renderer should color head skin pixels");
    drive_face(0, 0, 12'h1_2_3, 1'b0, 1'b0);
    assert (face_out.rgb == 12'h1_2_3) else $error("face_renderer should pass unrelated pixels");

    mouse_xpos = 12'd10;
    mouse_ypos = 12'd10;
    mouse_cursor_mode = CURSOR_POINTER;
    drive_mouse(100, 100, 12'h1_2_3, 1'b0, 1'b0);
    assert (mouse_out.rgb == 12'h1_2_3) else $error("draw_mouse should pass pixels outside cursor");

    drive_mouse(16, 16, 12'h7_7_7, 1'b0, 1'b0);
    assert (mouse_out.rgb == COLOR_WHITE) else $error("draw_mouse normal cursor pixel mismatch");

    mouse_cursor_mode = CURSOR_POINTER_HOVER;
    drive_mouse(32, 31, 12'h7_7_7, 1'b0, 1'b0);
    assert (mouse_out.rgb == COLOR_WHITE) else $error("draw_mouse hover cursor pixel mismatch");

    mouse_cursor_mode = CURSOR_BUSY;
    drive_mouse(35, 44, 12'h7_7_7, 1'b0, 1'b0);
    assert (mouse_out.rgb == COLOR_WHITE) else $error("draw_mouse busy cursor pixel mismatch");

    mouse_cursor_mode = CURSOR_POINTER;
    drive_mouse(60, 60, 12'h7_7_7, 1'b0, 1'b0);
    assert (mouse_out.rgb == 12'h7_7_7) else $error("draw_mouse transparent cursor pixel should pass input");

    drive_mouse(100, 100, 12'h7_7_7, 1'b1, 1'b0);
    assert (mouse_out.rgb == COLOR_BLACK) else $error("draw_mouse blanking should be black");

    $finish;
end

endmodule
