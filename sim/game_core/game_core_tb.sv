/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Testbench for the local Guess Who game FSM.
 */

module game_core_tb;

timeunit 1ns;
timeprecision 1ps;

import guess_who_pkg::*;

localparam int CLK_PERIOD = 10;

logic clk;
logic rst_n;
logic player_id;
logic frame_tick;
logic start_click;
logic reset_click;
logic char_left_click;
logic char_right_click;
logic link_ready;
logic [CHAR_ID_W-1:0] char_id;
logic opponent_ready;
logic opponent_turn_end;
logic opponent_guess;
logic [CHAR_ID_W-1:0] opponent_guess_id;
logic opponent_final_check;
logic [CHAR_ID_W-1:0] opponent_final_check_id;
logic opponent_reset_game;
logic guess_result_valid;
logic guess_result_correct;
logic final_result_valid;
logic final_result_correct;
game_state_t game_state;
logic [CHAR_COUNT-1:0] eliminated_mask;
logic [CHAR_ID_W-1:0] selected_id;
logic [CHAR_ID_W-1:0] local_secret_id;
logic [CHAR_ID_W-1:0] last_guess_id;
logic has_secret;
logic local_ready;
logic remote_ready;
logic my_turn;
logic wrong_guess_visible;
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

game_core dut (
    .clk                     (clk),
    .rst_n                   (rst_n),
    .player_id               (player_id),
    .frame_tick              (frame_tick),
    .start_click             (start_click),
    .reset_click             (reset_click),
    .char_left_click         (char_left_click),
    .char_right_click        (char_right_click),
    .link_ready              (link_ready),
    .char_id                 (char_id),
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
    .final_result_correct    (final_result_correct),
    .game_state              (game_state),
    .eliminated_mask         (eliminated_mask),
    .selected_id             (selected_id),
    .local_secret_id         (local_secret_id),
    .last_guess_id           (last_guess_id),
    .has_secret              (has_secret),
    .local_ready             (local_ready),
    .remote_ready            (remote_ready),
    .my_turn                 (my_turn),
    .wrong_guess_visible     (wrong_guess_visible),
    .send_ready              (send_ready),
    .send_turn_end           (send_turn_end),
    .send_guess              (send_guess),
    .send_guess_id           (send_guess_id),
    .send_final_check        (send_final_check),
    .send_final_check_id     (send_final_check_id),
    .send_result             (send_result),
    .send_result_correct     (send_result_correct),
    .send_result_id          (send_result_id),
    .send_reset_game         (send_reset_game)
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

task automatic pulse_start;
begin
    start_click = 1'b1;
    wait_clk;
    start_click = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_reset_button;
begin
    reset_click = 1'b1;
    wait_clk;
    reset_click = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_left_char(input logic [CHAR_ID_W-1:0] id);
begin
    char_id = id;
    char_left_click = 1'b1;
    wait_clk;
    char_left_click = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_right_char(input logic [CHAR_ID_W-1:0] id);
begin
    char_id = id;
    char_right_click = 1'b1;
    wait_clk;
    char_right_click = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_opponent_ready;
begin
    opponent_ready = 1'b1;
    wait_clk;
    opponent_ready = 1'b0;
    wait_clk;
    wait_clk;
end
endtask

task automatic pulse_opponent_turn_end;
begin
    opponent_turn_end = 1'b1;
    wait_clk;
    opponent_turn_end = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_frame;
begin
    frame_tick = 1'b1;
    wait_clk;
    frame_tick = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_guess_result(input logic correct);
begin
    guess_result_correct = correct;
    guess_result_valid = 1'b1;
    wait_clk;
    guess_result_valid = 1'b0;
    guess_result_correct = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_final_result(input logic correct);
begin
    final_result_correct = correct;
    final_result_valid = 1'b1;
    wait_clk;
    final_result_valid = 1'b0;
    final_result_correct = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_opponent_guess(input logic [CHAR_ID_W-1:0] id);
begin
    opponent_guess_id = id;
    opponent_guess = 1'b1;
    #1;
    assert (send_result && (send_result_correct == (id == local_secret_id)))
        else $error("Opponent guess result pulse is wrong");
    assert (send_result_id == id) else $error("Opponent guess result id is wrong");
    wait_clk;
    opponent_guess = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_opponent_final(input logic [CHAR_ID_W-1:0] id);
begin
    opponent_final_check_id = id;
    opponent_final_check = 1'b1;
    #1;
    assert (send_result && (send_result_correct == (id == local_secret_id)))
        else $error("Opponent final-check result pulse is wrong");
    assert (send_result_id == id) else $error("Opponent final-check result id is wrong");
    wait_clk;
    opponent_final_check = 1'b0;
    wait_clk;
end
endtask

task automatic pulse_frames(input int number);
    int i;
begin
    for (i = 0; i < number; i++) begin
        pulse_frame;
    end
end
endtask

initial begin
    int i;

    rst_n = 1'b0;
    player_id = 1'b0;
    frame_tick = 1'b0;
    start_click = 1'b0;
    reset_click = 1'b0;
    char_left_click = 1'b0;
    char_right_click = 1'b0;
    link_ready = 1'b1;
    char_id = '0;
    opponent_ready = 1'b0;
    opponent_turn_end = 1'b0;
    opponent_guess = 1'b0;
    opponent_guess_id = '0;
    opponent_final_check = 1'b0;
    opponent_final_check_id = '0;
    opponent_reset_game = 1'b0;
    guess_result_valid = 1'b0;
    guess_result_correct = 1'b0;
    final_result_valid = 1'b0;
    final_result_correct = 1'b0;

    wait_clk;
    assert (game_state == S_RESET) else $error("Async reset should force S_RESET");
    rst_n = 1'b1;
    wait_clk;

    assert (game_state == S_SELECT_SECRET) else $error("FSM did not enter select state");
    assert (eliminated_mask == '0) else $error("Eliminated mask not clear after reset");

    pulse_left_char(5'd3);
    assert (has_secret) else $error("Secret was not selected");
    assert (selected_id == 5'd3) else $error("Wrong selected id");

    pulse_left_char(5'd8);
    assert (selected_id == 5'd8) else $error("Selection should be changeable before START");

    pulse_start;
    assert (game_state == S_LOCAL_READY) else $error("START should wait for remote READY");
    assert (local_ready) else $error("Local READY should be latched");
    assert (local_secret_id == 5'd8) else $error("Secret was not locked on start");

    pulse_left_char(5'd4);
    assert (local_secret_id == 5'd8) else $error("Secret should not change after START");

    pulse_opponent_ready;
    assert (game_state == S_MY_TURN) else $error("Player 0 should start with own turn");
    assert (remote_ready) else $error("Remote READY should be latched");
    assert (my_turn) else $error("my_turn output should be high");

    pulse_right_char(5'd5);
    assert (eliminated_mask[5]) else $error("Right click should eliminate character");

    pulse_right_char(5'd5);
    assert (!eliminated_mask[5]) else $error("Second right click should undo elimination");

    pulse_left_char(5'd4);
    assert (send_guess_id == 5'd4) else $error("Sent guess id is wrong");
    assert (game_state == S_WAIT_GUESS_RESULT) else $error("Guess should wait for result");

    pulse_guess_result(1'b0);
    assert (game_state == S_WRONG_GUESS_FEEDBACK) else $error("Wrong result should enter feedback");
    assert (wrong_guess_visible) else $error("Wrong guess flag should be visible");
    assert (eliminated_mask[4]) else $error("Wrong guessed character should be eliminated");
    assert (last_guess_id == 5'd4) else $error("Last guess id not stored");

    pulse_frames(180);
    assert (game_state == S_OPPONENT_TURN) else $error("Wrong feedback should end in opponent turn");

    pulse_opponent_turn_end;
    assert (game_state == S_MY_TURN) else $error("TURN_END should return to own turn");

    pulse_left_char(5'd8);
    assert (game_state == S_WAIT_GUESS_RESULT) else $error("Correct guess should also wait");
    pulse_guess_result(1'b1);
    assert (game_state == S_WIN) else $error("Correct guess should win the game");

    pulse_reset_button;
    assert (game_state == S_SELECT_SECRET) else $error("Reset button should return to select");
    assert (!has_secret) else $error("Reset button should clear selected secret");
    assert (eliminated_mask == '0) else $error("Reset button should clear eliminated mask");
    assert (send_reset_game == 1'b0) else $error("Reset pulse should not stay active");

    pulse_left_char(5'd2);
    pulse_start;
    pulse_opponent_ready;
    assert (game_state == S_MY_TURN) else $error("FSM should restart after reset");

    for (i = 0; i < CHAR_COUNT; i++) begin
        if (i != 7) begin
            pulse_right_char(i[CHAR_ID_W-1:0]);
        end
    end
    assert (game_state == S_FINAL_CHECK) else $error("One active character should start final check");
    assert (last_guess_id == 5'd7) else $error("Final check should remember remaining id");
    assert (send_final_check_id == 5'd7) else $error("Final check id should be remaining id");

    pulse_final_result(1'b1);
    assert (game_state == S_WIN) else $error("Correct final check should win");

    pulse_reset_button;
    pulse_left_char(5'd2);
    pulse_start;
    pulse_opponent_ready;
    pulse_start;
    assert (game_state == S_OPPONENT_TURN) else $error("End turn should enter opponent turn");

    pulse_opponent_guess(5'd2);
    assert (game_state == S_LOSE) else $error("Correct opponent guess should lose the game");

    pulse_reset_button;
    pulse_left_char(5'd4);
    pulse_start;
    pulse_opponent_ready;
    pulse_start;
    pulse_opponent_final(5'd1);
    assert (game_state == S_WIN) else $error("Wrong opponent final check should win locally");

    $finish;
end

endmodule
