/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Main structural top for the Guess Who game.
 */

module top_vga (
    input  logic clk,
    input  logic clk_100mhz,
    input  logic rst_n,
    input  logic rst_100mhz_n,
    input  logic player_id,
    input  logic pmod_uart_rx,
    inout  wire  ps2_clk,
    inout  wire  ps2_data,
    output logic pmod_uart_tx,
    output logic vs,
    output logic hs,
    output logic [3:0] r,
    output logic [3:0] g,
    output logic [3:0] b
);

timeunit 1ns;
timeprecision 1ps;

import guess_who_pkg::*;

logic [11:0] mouse_xpos_raw;
logic [11:0] mouse_ypos_raw;
logic mouse_left_raw;
logic mouse_right_raw;
logic [11:0] mouse_xpos;
logic [11:0] mouse_ypos;
logic left_click_pulse;
logic right_click_pulse;

logic start_click;
logic reset_click;
logic char_left_click;
logic char_right_click;
logic [CHAR_ID_W-1:0] clicked_char_id;

game_state_t game_state;
logic [CHAR_COUNT-1:0] eliminated_mask;
logic [CHAR_ID_W-1:0] selected_id;
logic [CHAR_ID_W-1:0] last_guess_id;
logic has_secret;
logic local_ready;
logic remote_ready;
logic frame_tick;

logic link_ready;
logic opponent_ready;
logic opponent_turn_end;
logic opponent_guess;
logic [CHAR_ID_W-1:0] opponent_guess_id;
logic opponent_final_check;
logic [CHAR_ID_W-1:0] opponent_final_check_id;
logic opponent_reset_game;
logic send_ready;
logic send_turn_end;
logic send_guess;
logic [CHAR_ID_W-1:0] send_guess_id;
logic send_final_check;
logic [CHAR_ID_W-1:0] send_final_check_id;
logic send_result;
logic send_result_correct;
logic [CHAR_ID_W-1:0] send_result_id;
logic send_reset_game;
logic guess_result_valid;
logic guess_result_correct;
logic final_result_valid;
logic final_result_correct;

vga_if if_tim ();
vga_if if_bg ();
vga_if if_ui ();
vga_if if_face ();
vga_if if_board ();
vga_if if_text ();
vga_if if_mouse ();

assign if_tim.rgb = 12'h9_a_b;
assign vs = if_mouse.vsync;
assign hs = if_mouse.hsync;
assign {r, g, b} = if_mouse.rgb;
assign frame_tick = (if_tim.hcount == 11'd0) && (if_tim.vcount == 11'd0);

vga_timing u_vga_timing (
    .clk,
    .rst_n,
    .vcount (if_tim.vcount),
    .vsync  (if_tim.vsync),
    .vblnk  (if_tim.vblnk),
    .hcount (if_tim.hcount),
    .hsync  (if_tim.hsync),
    .hblnk  (if_tim.hblnk)
);

MouseCtl u_mouse_ctl (
    .clk       (clk_100mhz),
    .rst       (!rst_100mhz_n),
    .xpos      (mouse_xpos_raw),
    .ypos      (mouse_ypos_raw),
    .zpos      (),
    .left      (mouse_left_raw),
    .middle    (),
    .right     (mouse_right_raw),
    .new_event (),
    .value     ('0),
    .setx      (1'b0),
    .sety      (1'b0),
    .setmax_x  (1'b0),
    .setmax_y  (1'b0),
    .ps2_clk   (ps2_clk),
    .ps2_data  (ps2_data)
);

mouse_adapter u_mouse_adapter (
    .clk               (clk),
    .rst_n             (rst_n),
    .mouse_x_raw       (mouse_xpos_raw),
    .mouse_y_raw       (mouse_ypos_raw),
    .mouse_left_raw    (mouse_left_raw),
    .mouse_right_raw   (mouse_right_raw),
    .mouse_x           (mouse_xpos),
    .mouse_y           (mouse_ypos),
    .left_click_pulse  (left_click_pulse),
    .right_click_pulse (right_click_pulse)
);

draw_bg u_draw_bg (
    .clk,
    .rst_n,
    .in  (if_tim.in),
    .out (if_bg.out)
);

hitbox_decoder u_hitbox_decoder (
    .mouse_x          (mouse_xpos),
    .mouse_y          (mouse_ypos),
    .left_click       (left_click_pulse),
    .right_click      (right_click_pulse),
    .start_click      (start_click),
    .reset_click      (reset_click),
    .char_left_click  (char_left_click),
    .char_right_click (char_right_click),
    .char_id          (clicked_char_id)
);

pmod_comm_controller u_pmod_comm_controller (
    .clk                     (clk),
    .rst_n                   (rst_n),
    .player_id               (player_id),
    .uart_rx                 (pmod_uart_rx),
    .send_ready              (send_ready),
    .send_turn_end           (send_turn_end),
    .send_guess              (send_guess),
    .send_guess_id           (send_guess_id),
    .send_final_check        (send_final_check),
    .send_final_check_id     (send_final_check_id),
    .send_result             (send_result),
    .send_result_correct     (send_result_correct),
    .send_result_id          (send_result_id),
    .send_reset_game         (send_reset_game),
    .uart_tx                 (pmod_uart_tx),
    .link_ready              (link_ready),
    .opponent_ready          (opponent_ready),
    .opponent_turn_end       (opponent_turn_end),
    .opponent_guess          (opponent_guess),
    .opponent_guess_id       (opponent_guess_id),
    .opponent_final_check    (opponent_final_check),
    .opponent_final_check_id (opponent_final_check_id),
    .opponent_reset_game     (opponent_reset_game),
    .guess_result_valid      (guess_result_valid),
    .guess_result_correct    (guess_result_correct),
    .final_result_valid      (final_result_valid),
    .final_result_correct    (final_result_correct)
);

game_core u_game_core (
    .clk                 (clk),
    .rst_n               (rst_n),
    .player_id           (player_id),
    .frame_tick          (frame_tick),
    .start_click         (start_click),
    .reset_click         (reset_click),
    .char_left_click     (char_left_click),
    .char_right_click    (char_right_click),
    .link_ready          (link_ready),
    .char_id             (clicked_char_id),
    .opponent_ready      (opponent_ready),
    .opponent_turn_end   (opponent_turn_end),
    .opponent_guess      (opponent_guess),
    .opponent_guess_id   (opponent_guess_id),
    .opponent_final_check (opponent_final_check),
    .opponent_final_check_id (opponent_final_check_id),
    .opponent_reset_game (opponent_reset_game),
    .guess_result_valid  (guess_result_valid),
    .guess_result_correct (guess_result_correct),
    .final_result_valid  (final_result_valid),
    .final_result_correct (final_result_correct),
    .game_state          (game_state),
    .eliminated_mask     (eliminated_mask),
    .selected_id         (selected_id),
    .local_secret_id     (),
    .last_guess_id       (last_guess_id),
    .has_secret          (has_secret),
    .local_ready         (local_ready),
    .remote_ready        (remote_ready),
    .my_turn             (),
    .wrong_guess_visible (),
    .send_ready          (send_ready),
    .send_turn_end       (send_turn_end),
    .send_guess          (send_guess),
    .send_guess_id       (send_guess_id),
    .send_final_check    (send_final_check),
    .send_final_check_id (send_final_check_id),
    .send_result         (send_result),
    .send_result_correct (send_result_correct),
    .send_result_id      (send_result_id),
    .send_reset_game     (send_reset_game)
);

ui_renderer u_ui_renderer (
    .clk          (clk),
    .rst_n        (rst_n),
    .game_state   (game_state),
    .has_secret   (has_secret),
    .local_ready  (local_ready),
    .remote_ready (remote_ready),
    .in           (if_bg.in),
    .out          (if_ui.out)
);

face_renderer u_face_renderer (
    .clk        (clk),
    .rst_n      (rst_n),
    .selected_id (selected_id),
    .has_secret (has_secret),
    .in         (if_ui.in),
    .out        (if_face.out)
);

board_renderer u_board_renderer (
    .clk             (clk),
    .rst_n           (rst_n),
    .game_state      (game_state),
    .eliminated_mask (eliminated_mask),
    .selected_id     (selected_id),
    .last_guess_id   (last_guess_id),
    .has_secret      (has_secret),
    .in              (if_face.in),
    .out             (if_board.out)
);

text_renderer u_text_renderer (
    .clk        (clk),
    .rst_n      (rst_n),
    .game_state (game_state),
    .in         (if_board.in),
    .out        (if_text.out)
);

draw_mouse u_draw_mouse (
    .clk   (clk),
    .rst_n (rst_n),
    .xpos  (mouse_xpos),
    .ypos  (mouse_ypos),
    .in    (if_text.in),
    .out   (if_mouse.out)
);

endmodule
