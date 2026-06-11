/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Simple FSM for local Guess Who game flow.
 */

module game_core
import guess_who_pkg::*;
(
    input  logic       clk,
    input  logic       rst_n,
    output game_state_t game_state,
    output logic [CHAR_COUNT-1:0] eliminated_mask,
    output logic [CHAR_ID_W-1:0] selected_id,
    output logic [CHAR_ID_W-1:0] last_guess_id,
    output logic       has_secret,
    output logic       local_ready,
    output logic       remote_ready,
    output logic       send_ready,
    output logic       send_turn_end,
    output logic       send_guess,
    output logic [CHAR_ID_W-1:0] send_guess_id,
    output logic       send_final_check,
    output logic [CHAR_ID_W-1:0] send_final_check_id,
    output logic       send_result,
    output logic       send_result_correct,
    output logic [CHAR_ID_W-1:0] send_result_id,
    output logic       send_reset_game,
    input  logic       player_id,
    input  logic       frame_tick,
    input  logic       start_click,
    input  logic       reset_click,
    input  logic       char_left_click,
    input  logic       char_right_click,
    input  logic       link_ready,
    input  logic [CHAR_ID_W-1:0] char_id,
    input  logic       opponent_ready,
    input  logic       opponent_turn_end,
    input  logic       opponent_guess,
    input  logic [CHAR_ID_W-1:0] opponent_guess_id,
    input  logic       opponent_final_check,
    input  logic [CHAR_ID_W-1:0] opponent_final_check_id,
    input  logic       opponent_reset_game,
    input  logic       guess_result_valid,
    input  logic       guess_result_correct,
    input  logic       final_result_valid,
    input  logic       final_result_correct,
    input  logic       comm_error
);

timeunit 1ns;
timeprecision 1ps;

localparam int FEEDBACK_FRAMES = 180;
localparam int RESULT_TIMEOUT_FRAMES = 600;
localparam int RESULT_TIMEOUT_CNT_W = $clog2(RESULT_TIMEOUT_FRAMES + 1);
game_state_t state;
game_state_t state_nxt;

logic [CHAR_COUNT-1:0] eliminated_mask_nxt;
logic [CHAR_ID_W-1:0] selected_id_nxt;
logic [CHAR_ID_W-1:0] local_secret_id;
logic [CHAR_ID_W-1:0] local_secret_id_nxt;
logic [CHAR_ID_W-1:0] last_guess_id_nxt;
logic has_secret_nxt;
logic local_ready_nxt;
logic remote_ready_nxt;

logic [7:0] feedback_cnt;
logic [7:0] feedback_cnt_nxt;
logic [RESULT_TIMEOUT_CNT_W-1:0] result_wait_cnt;
logic [RESULT_TIMEOUT_CNT_W-1:0] result_wait_cnt_nxt;
logic [CHAR_COUNT-1:0] char_mask;
logic [CHAR_COUNT-1:0] last_guess_mask;
logic [CHAR_COUNT-1:0] elim_after_click;
logic [4:0] active_after_click;
logic valid_char;
logic valid_opponent_char;
logic valid_opponent_final_char;

assign game_state = state;

function automatic logic [4:0] count_active(input logic [CHAR_COUNT-1:0] mask);
    logic [4:0] count;
    int i;
begin
    count = '0;
    for (i = 0; i < CHAR_COUNT; i++) begin
        if (!mask[i]) begin
            count = count + 5'd1;
        end
    end
    count_active = count;
end
endfunction

always_comb begin
    valid_char = char_id < CHAR_COUNT;
    valid_opponent_char = opponent_guess_id < CHAR_COUNT;
    valid_opponent_final_char = opponent_final_check_id < CHAR_COUNT;
    char_mask = '0;
    last_guess_mask = '0;

    if (valid_char) begin
        char_mask = 18'h1 << char_id;
    end

    if (last_guess_id < CHAR_COUNT) begin
        last_guess_mask = 18'h1 << last_guess_id;
    end
end

always_comb begin
    elim_after_click = eliminated_mask ^ char_mask;
    active_after_click = count_active(elim_after_click);
end

always_comb begin
    state_nxt = state;
    eliminated_mask_nxt = eliminated_mask;
    selected_id_nxt = selected_id;
    local_secret_id_nxt = local_secret_id;
    last_guess_id_nxt = last_guess_id;
    has_secret_nxt = has_secret;
    local_ready_nxt = local_ready;
    remote_ready_nxt = remote_ready;
    feedback_cnt_nxt = feedback_cnt;
    result_wait_cnt_nxt = result_wait_cnt;
    send_ready = 1'b0;
    send_turn_end = 1'b0;
    send_guess = 1'b0;
    send_guess_id = last_guess_id;
    send_final_check = 1'b0;
    send_final_check_id = last_guess_id;
    send_result = 1'b0;
    send_result_correct = 1'b0;
    send_result_id = '0;
    send_reset_game = 1'b0;

    if (reset_click || opponent_reset_game) begin
        state_nxt = S_WAIT_LINK;
        eliminated_mask_nxt = '0;
        selected_id_nxt = '0;
        local_secret_id_nxt = '0;
        last_guess_id_nxt = '0;
        has_secret_nxt = 1'b0;
        local_ready_nxt = 1'b0;
        remote_ready_nxt = 1'b0;
        feedback_cnt_nxt = '0;
        result_wait_cnt_nxt = '0;
        send_reset_game = reset_click;
    end else if (comm_error) begin
        state_nxt = S_COMM_ERROR;
        feedback_cnt_nxt = '0;
        result_wait_cnt_nxt = '0;
    end else begin
        if (opponent_ready) begin
            remote_ready_nxt = 1'b1;
        end

        case (state)
            S_RESET: begin
                if (link_ready) begin
                    state_nxt = S_SELECT_SECRET;
                end else begin
                    state_nxt = S_WAIT_LINK;
                end
            end

            S_WAIT_LINK: begin
                if (link_ready) begin
                    state_nxt = S_SELECT_SECRET;
                end
            end

            S_SELECT_SECRET: begin
                if (char_left_click && valid_char) begin
                    selected_id_nxt = char_id;
                    has_secret_nxt = 1'b1;
                end

                if (start_click && has_secret) begin
                    local_secret_id_nxt = selected_id;
                    local_ready_nxt = 1'b1;
                    send_ready = 1'b1;
                    result_wait_cnt_nxt = '0;
                    state_nxt = S_LOCAL_READY;
                end
            end

            S_LOCAL_READY: begin
                if (local_ready && remote_ready) begin
                    state_nxt = S_GAME_START;
                end
                feedback_cnt_nxt = '0;
                result_wait_cnt_nxt = '0;
            end

            S_GAME_START: begin
                if (player_id) begin
                    state_nxt = S_OPPONENT_TURN;
                end else begin
                    state_nxt = S_MY_TURN;
                end
            end

            S_MY_TURN: begin
                if (char_left_click && valid_char) begin
                    last_guess_id_nxt = char_id;
                    send_guess = 1'b1;
                    send_guess_id = char_id;
                    result_wait_cnt_nxt = '0;
                    state_nxt = S_WAIT_GUESS_RESULT;
                end else if (char_right_click && valid_char) begin
                    if (active_after_click != 5'd0) begin
                        eliminated_mask_nxt = elim_after_click;
                    end
                end else if (start_click) begin
                    send_turn_end = 1'b1;
                    state_nxt = S_OPPONENT_TURN;
                end
            end

            S_WAIT_GUESS_RESULT: begin
                if (guess_result_valid) begin
                    if (guess_result_correct) begin
                        state_nxt = S_WIN;
                    end else begin
                        eliminated_mask_nxt = eliminated_mask | last_guess_mask;
                        feedback_cnt_nxt = '0;
                        result_wait_cnt_nxt = '0;
                        state_nxt = S_WRONG_GUESS_FEEDBACK;
                    end
                end else if (frame_tick) begin
                    if (result_wait_cnt == RESULT_TIMEOUT_FRAMES - 1) begin
                        result_wait_cnt_nxt = '0;
                        state_nxt = S_COMM_ERROR;
                    end else begin
                        result_wait_cnt_nxt = result_wait_cnt + {{(RESULT_TIMEOUT_CNT_W-1){1'b0}}, 1'b1};
                    end
                end
            end

            S_WRONG_GUESS_FEEDBACK: begin
                if (frame_tick) begin
                    if (feedback_cnt == FEEDBACK_FRAMES - 1) begin
                        feedback_cnt_nxt = '0;
                        send_turn_end = 1'b1;
                        state_nxt = S_OPPONENT_TURN;
                    end else begin
                        feedback_cnt_nxt = feedback_cnt + 8'd1;
                    end
                end
            end

            S_FINAL_CHECK: begin
                if (final_result_valid) begin
                    if (final_result_correct) begin
                        state_nxt = S_WIN;
                    end else begin
                        state_nxt = S_LOSE;
                    end
                    result_wait_cnt_nxt = '0;
                end else if (frame_tick) begin
                    if (result_wait_cnt == RESULT_TIMEOUT_FRAMES - 1) begin
                        result_wait_cnt_nxt = '0;
                        state_nxt = S_COMM_ERROR;
                    end else begin
                        result_wait_cnt_nxt = result_wait_cnt + {{(RESULT_TIMEOUT_CNT_W-1){1'b0}}, 1'b1};
                    end
                end
            end

            S_OPPONENT_TURN: begin
                if (opponent_guess && valid_opponent_char) begin
                    send_result = 1'b1;
                    send_result_correct = (opponent_guess_id == local_secret_id);
                    send_result_id = opponent_guess_id;

                    if (opponent_guess_id == local_secret_id) begin
                        state_nxt = S_LOSE;
                    end
                end else if (opponent_final_check && valid_opponent_final_char) begin
                    send_result = 1'b1;
                    send_result_correct = (opponent_final_check_id == local_secret_id);
                    send_result_id = opponent_final_check_id;

                    if (opponent_final_check_id == local_secret_id) begin
                        state_nxt = S_LOSE;
                    end else begin
                        state_nxt = S_WIN;
                    end
                end else if (opponent_turn_end) begin
                    state_nxt = S_MY_TURN;
                end
            end

            S_WIN: begin
                state_nxt = S_WIN;
            end

            S_LOSE: begin
                state_nxt = S_LOSE;
            end

            S_COMM_ERROR: begin
                state_nxt = S_COMM_ERROR;
            end

            default: begin
                state_nxt = S_WAIT_LINK;
            end
        endcase
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= S_RESET;
        eliminated_mask <= '0;
        selected_id <= '0;
        local_secret_id <= '0;
        last_guess_id <= '0;
        has_secret <= 1'b0;
        local_ready <= 1'b0;
        remote_ready <= 1'b0;
        feedback_cnt <= '0;
        result_wait_cnt <= '0;
    end else begin
        state <= state_nxt;
        eliminated_mask <= eliminated_mask_nxt;
        selected_id <= selected_id_nxt;
        local_secret_id <= local_secret_id_nxt;
        last_guess_id <= last_guess_id_nxt;
        has_secret <= has_secret_nxt;
        local_ready <= local_ready_nxt;
        remote_ready <= remote_ready_nxt;
        feedback_cnt <= feedback_cnt_nxt;
        result_wait_cnt <= result_wait_cnt_nxt;
    end
end

endmodule
