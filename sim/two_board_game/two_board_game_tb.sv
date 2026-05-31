/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Milosz M. Karolina M.
 *
 * Description:
 * End-to-end test for two game_core instances connected through PMOD UART.
 */

module two_board_game_tb;

timeunit 1ns;
timeprecision 1ps;

import guess_who_pkg::*;

localparam int CLK_PERIOD = 10;
localparam int CLK_FREQ_HZ = 100_000_000;
localparam int BAUD_RATE = 1_000_000;
localparam int HELLO_INTERVAL_CYCLES = 128;
localparam int TIMEOUT_CYCLES = 300_000;

logic clk;
logic rst_n;

logic uart_tx_a;
logic uart_tx_b;
logic link_ready_a;
logic link_ready_b;

logic frame_tick_a;
logic start_click_a;
logic reset_click_a;
logic char_left_click_a;
logic char_right_click_a;
logic [CHAR_ID_W-1:0] char_id_a;
game_state_t game_state_a;
logic [CHAR_COUNT-1:0] eliminated_mask_a;
logic [CHAR_ID_W-1:0] selected_id_a;
logic [CHAR_ID_W-1:0] local_secret_id_a;
logic [CHAR_ID_W-1:0] last_guess_id_a;
logic has_secret_a;
logic local_ready_a;
logic remote_ready_a;
logic wrong_guess_visible_a;
logic send_ready_a;
logic send_turn_end_a;
logic send_guess_a;
logic [CHAR_ID_W-1:0] send_guess_id_a;
logic send_final_check_a;
logic [CHAR_ID_W-1:0] send_final_check_id_a;
logic send_result_a;
logic send_result_correct_a;
logic [CHAR_ID_W-1:0] send_result_id_a;
logic send_reset_game_a;
logic opponent_ready_a;
logic opponent_turn_end_a;
logic opponent_guess_a;
logic [CHAR_ID_W-1:0] opponent_guess_id_a;
logic opponent_final_check_a;
logic [CHAR_ID_W-1:0] opponent_final_check_id_a;
logic opponent_reset_game_a;
logic guess_result_valid_a;
logic guess_result_correct_a;
logic final_result_valid_a;
logic final_result_correct_a;

logic frame_tick_b;
logic start_click_b;
logic reset_click_b;
logic char_left_click_b;
logic char_right_click_b;
logic [CHAR_ID_W-1:0] char_id_b;
game_state_t game_state_b;
logic [CHAR_COUNT-1:0] eliminated_mask_b;
logic [CHAR_ID_W-1:0] selected_id_b;
logic [CHAR_ID_W-1:0] local_secret_id_b;
logic [CHAR_ID_W-1:0] last_guess_id_b;
logic has_secret_b;
logic local_ready_b;
logic remote_ready_b;
logic wrong_guess_visible_b;
logic send_ready_b;
logic send_turn_end_b;
logic send_guess_b;
logic [CHAR_ID_W-1:0] send_guess_id_b;
logic send_final_check_b;
logic [CHAR_ID_W-1:0] send_final_check_id_b;
logic send_result_b;
logic send_result_correct_b;
logic [CHAR_ID_W-1:0] send_result_id_b;
logic send_reset_game_b;
logic opponent_ready_b;
logic opponent_turn_end_b;
logic opponent_guess_b;
logic [CHAR_ID_W-1:0] opponent_guess_id_b;
logic opponent_final_check_b;
logic [CHAR_ID_W-1:0] opponent_final_check_id_b;
logic opponent_reset_game_b;
logic guess_result_valid_b;
logic guess_result_correct_b;
logic final_result_valid_b;
logic final_result_correct_b;

pmod_comm_controller #(
    .CLK_FREQ_HZ           (CLK_FREQ_HZ),
    .BAUD_RATE             (BAUD_RATE),
    .HELLO_INTERVAL_CYCLES (HELLO_INTERVAL_CYCLES)
) comm_a (
    .clk                     (clk),
    .rst_n                   (rst_n),
    .player_id               (1'b0),
    .uart_rx                 (uart_tx_b),
    .send_ready              (send_ready_a),
    .send_turn_end           (send_turn_end_a),
    .send_guess              (send_guess_a),
    .send_guess_id           (send_guess_id_a),
    .send_final_check        (send_final_check_a),
    .send_final_check_id     (send_final_check_id_a),
    .send_result             (send_result_a),
    .send_result_correct     (send_result_correct_a),
    .send_result_id          (send_result_id_a),
    .send_reset_game         (send_reset_game_a),
    .uart_tx                 (uart_tx_a),
    .link_ready              (link_ready_a),
    .opponent_ready          (opponent_ready_a),
    .opponent_turn_end       (opponent_turn_end_a),
    .opponent_guess          (opponent_guess_a),
    .opponent_guess_id       (opponent_guess_id_a),
    .opponent_final_check    (opponent_final_check_a),
    .opponent_final_check_id (opponent_final_check_id_a),
    .opponent_reset_game     (opponent_reset_game_a),
    .guess_result_valid      (guess_result_valid_a),
    .guess_result_correct    (guess_result_correct_a),
    .final_result_valid      (final_result_valid_a),
    .final_result_correct    (final_result_correct_a)
);

pmod_comm_controller #(
    .CLK_FREQ_HZ           (CLK_FREQ_HZ),
    .BAUD_RATE             (BAUD_RATE),
    .HELLO_INTERVAL_CYCLES (HELLO_INTERVAL_CYCLES)
) comm_b (
    .clk                     (clk),
    .rst_n                   (rst_n),
    .player_id               (1'b1),
    .uart_rx                 (uart_tx_a),
    .send_ready              (send_ready_b),
    .send_turn_end           (send_turn_end_b),
    .send_guess              (send_guess_b),
    .send_guess_id           (send_guess_id_b),
    .send_final_check        (send_final_check_b),
    .send_final_check_id     (send_final_check_id_b),
    .send_result             (send_result_b),
    .send_result_correct     (send_result_correct_b),
    .send_result_id          (send_result_id_b),
    .send_reset_game         (send_reset_game_b),
    .uart_tx                 (uart_tx_b),
    .link_ready              (link_ready_b),
    .opponent_ready          (opponent_ready_b),
    .opponent_turn_end       (opponent_turn_end_b),
    .opponent_guess          (opponent_guess_b),
    .opponent_guess_id       (opponent_guess_id_b),
    .opponent_final_check    (opponent_final_check_b),
    .opponent_final_check_id (opponent_final_check_id_b),
    .opponent_reset_game     (opponent_reset_game_b),
    .guess_result_valid      (guess_result_valid_b),
    .guess_result_correct    (guess_result_correct_b),
    .final_result_valid      (final_result_valid_b),
    .final_result_correct    (final_result_correct_b)
);

game_core game_a (
    .clk                     (clk),
    .rst_n                   (rst_n),
    .player_id               (1'b0),
    .frame_tick              (frame_tick_a),
    .start_click             (start_click_a),
    .reset_click             (reset_click_a),
    .char_left_click         (char_left_click_a),
    .char_right_click        (char_right_click_a),
    .link_ready              (link_ready_a),
    .char_id                 (char_id_a),
    .opponent_ready          (opponent_ready_a),
    .opponent_turn_end       (opponent_turn_end_a),
    .opponent_guess          (opponent_guess_a),
    .opponent_guess_id       (opponent_guess_id_a),
    .opponent_final_check    (opponent_final_check_a),
    .opponent_final_check_id (opponent_final_check_id_a),
    .opponent_reset_game     (opponent_reset_game_a),
    .guess_result_valid      (guess_result_valid_a),
    .guess_result_correct    (guess_result_correct_a),
    .final_result_valid      (final_result_valid_a),
    .final_result_correct    (final_result_correct_a),
    .game_state              (game_state_a),
    .eliminated_mask         (eliminated_mask_a),
    .selected_id             (selected_id_a),
    .local_secret_id         (local_secret_id_a),
    .last_guess_id           (last_guess_id_a),
    .has_secret              (has_secret_a),
    .local_ready             (local_ready_a),
    .remote_ready            (remote_ready_a),
    .my_turn                 (),
    .wrong_guess_visible     (wrong_guess_visible_a),
    .send_ready              (send_ready_a),
    .send_turn_end           (send_turn_end_a),
    .send_guess              (send_guess_a),
    .send_guess_id           (send_guess_id_a),
    .send_final_check        (send_final_check_a),
    .send_final_check_id     (send_final_check_id_a),
    .send_result             (send_result_a),
    .send_result_correct     (send_result_correct_a),
    .send_result_id          (send_result_id_a),
    .send_reset_game         (send_reset_game_a)
);

game_core game_b (
    .clk                     (clk),
    .rst_n                   (rst_n),
    .player_id               (1'b1),
    .frame_tick              (frame_tick_b),
    .start_click             (start_click_b),
    .reset_click             (reset_click_b),
    .char_left_click         (char_left_click_b),
    .char_right_click        (char_right_click_b),
    .link_ready              (link_ready_b),
    .char_id                 (char_id_b),
    .opponent_ready          (opponent_ready_b),
    .opponent_turn_end       (opponent_turn_end_b),
    .opponent_guess          (opponent_guess_b),
    .opponent_guess_id       (opponent_guess_id_b),
    .opponent_final_check    (opponent_final_check_b),
    .opponent_final_check_id (opponent_final_check_id_b),
    .opponent_reset_game     (opponent_reset_game_b),
    .guess_result_valid      (guess_result_valid_b),
    .guess_result_correct    (guess_result_correct_b),
    .final_result_valid      (final_result_valid_b),
    .final_result_correct    (final_result_correct_b),
    .game_state              (game_state_b),
    .eliminated_mask         (eliminated_mask_b),
    .selected_id             (selected_id_b),
    .local_secret_id         (local_secret_id_b),
    .last_guess_id           (last_guess_id_b),
    .has_secret              (has_secret_b),
    .local_ready             (local_ready_b),
    .remote_ready            (remote_ready_b),
    .my_turn                 (),
    .wrong_guess_visible     (wrong_guess_visible_b),
    .send_ready              (send_ready_b),
    .send_turn_end           (send_turn_end_b),
    .send_guess              (send_guess_b),
    .send_guess_id           (send_guess_id_b),
    .send_final_check        (send_final_check_b),
    .send_final_check_id     (send_final_check_id_b),
    .send_result             (send_result_b),
    .send_result_correct     (send_result_correct_b),
    .send_result_id          (send_result_id_b),
    .send_reset_game         (send_reset_game_b)
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

task automatic clear_inputs;
begin
    frame_tick_a = 1'b0;
    start_click_a = 1'b0;
    reset_click_a = 1'b0;
    char_left_click_a = 1'b0;
    char_right_click_a = 1'b0;
    char_id_a = '0;

    frame_tick_b = 1'b0;
    start_click_b = 1'b0;
    reset_click_b = 1'b0;
    char_left_click_b = 1'b0;
    char_right_click_b = 1'b0;
    char_id_b = '0;
end
endtask

task automatic wait_state_a(input game_state_t expected);
    int i;
begin
    for (i = 0; i < TIMEOUT_CYCLES && game_state_a != expected; i++) begin
        wait_clk;
    end
    assert (game_state_a == expected) else $error("Board A did not reach expected state");
end
endtask

task automatic wait_state_b(input game_state_t expected);
    int i;
begin
    for (i = 0; i < TIMEOUT_CYCLES && game_state_b != expected; i++) begin
        wait_clk;
    end
    assert (game_state_b == expected) else $error("Board B did not reach expected state");
end
endtask

task automatic pulse_left_a(input logic [CHAR_ID_W-1:0] id);
begin
    char_id_a = id;
    char_left_click_a = 1'b1;
    wait_clk;
    char_left_click_a = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_left_b(input logic [CHAR_ID_W-1:0] id);
begin
    char_id_b = id;
    char_left_click_b = 1'b1;
    wait_clk;
    char_left_click_b = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_start_a;
begin
    start_click_a = 1'b1;
    wait_clk;
    start_click_a = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_start_b;
begin
    start_click_b = 1'b1;
    wait_clk;
    start_click_b = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_reset_b;
begin
    reset_click_b = 1'b1;
    wait_clk;
    reset_click_b = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_frame_both;
begin
    frame_tick_a = 1'b1;
    frame_tick_b = 1'b1;
    wait_clk;
    frame_tick_a = 1'b0;
    frame_tick_b = 1'b0;
    wait_clk;
end
endtask

initial begin
    int i;

    rst_n = 1'b0;
    clear_inputs();

    repeat (5) begin
        wait_clk;
    end

    rst_n = 1'b1;

    wait_state_a(S_SELECT_SECRET);
    wait_state_b(S_SELECT_SECRET);

    pulse_left_a(5'd3);
    pulse_left_b(5'd8);
    assert (selected_id_a == 5'd3 && selected_id_b == 5'd8)
        else $error("Secret selection did not latch locally");

    pulse_start_a;
    pulse_start_b;

    wait_state_a(S_MY_TURN);
    wait_state_b(S_OPPONENT_TURN);
    assert (local_secret_id_a == 5'd3 && local_secret_id_b == 5'd8)
        else $error("Local secrets were not locked");
    assert (local_ready_a && remote_ready_a && local_ready_b && remote_ready_b)
        else $error("READY handshakes did not settle on both boards");

    pulse_left_a(5'd4);
    wait_state_a(S_WRONG_GUESS_FEEDBACK);
    wait_state_b(S_MY_TURN);
    assert (last_guess_id_a == 5'd4 && eliminated_mask_a[4])
        else $error("Wrong guess did not mark local elimination on board A");
    assert (wrong_guess_visible_a) else $error("Wrong guess feedback is not visible");
    assert (!wrong_guess_visible_b) else $error("Wrong guess feedback should be local to board A");

    for (i = 0; i < 180; i++) begin
        pulse_frame_both;
    end
    wait_state_a(S_OPPONENT_TURN);

    pulse_left_b(5'd3);
    wait_state_b(S_WIN);
    wait_state_a(S_LOSE);
    assert (last_guess_id_b == 5'd3) else $error("Winning guess id was not stored on board B");

    pulse_reset_b;
    wait_state_a(S_SELECT_SECRET);
    wait_state_b(S_SELECT_SECRET);
    assert (!has_secret_a && !has_secret_b) else $error("RESET_GAME did not clear secrets");
    assert (eliminated_mask_a == '0 && eliminated_mask_b == '0)
        else $error("RESET_GAME did not clear eliminated masks");
    assert (!wrong_guess_visible_a && !wrong_guess_visible_b)
        else $error("RESET_GAME did not clear wrong-guess feedback");

    $finish;
end

endmodule
