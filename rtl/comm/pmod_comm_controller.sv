/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Simple game packet interface placeholder for the PMOD link.
 */

module pmod_comm_controller (
    input  logic clk,
    input  logic rst_n,
    input  logic [guess_who_pkg::CHAR_ID_W-1:0] local_secret_id,
    input  logic send_ready,
    input  logic send_turn_end,
    input  logic send_guess,
    input  logic [guess_who_pkg::CHAR_ID_W-1:0] send_guess_id,
    input  logic send_final_check,
    input  logic [guess_who_pkg::CHAR_ID_W-1:0] send_final_check_id,
    input  logic send_result,
    input  logic send_result_correct,
    input  logic send_reset_game,
    output logic link_ready,
    output logic opponent_ready,
    output logic opponent_turn_end,
    output logic opponent_guess,
    output logic [guess_who_pkg::CHAR_ID_W-1:0] opponent_guess_id,
    output logic opponent_final_check,
    output logic [guess_who_pkg::CHAR_ID_W-1:0] opponent_final_check_id,
    output logic opponent_reset_game,
    output logic guess_result_valid,
    output logic guess_result_correct,
    output logic final_result_valid,
    output logic final_result_correct
);

timeunit 1ns;
timeprecision 1ps;

import guess_who_pkg::*;

logic send_turn_end_d;
logic send_result_d;
logic send_result_correct_d;

assign opponent_turn_end = send_turn_end_d || (send_result_d && !send_result_correct_d);

/*
 * This module keeps packet handling separated from the FSM. At this stage it
 * behaves as a one-board communication model, so the game can be synthesized
 * and tested before the real PMOD serial protocol is connected.
 */
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        link_ready <= 1'b0;
        opponent_ready <= 1'b0;
        opponent_guess <= 1'b0;
        opponent_guess_id <= '0;
        opponent_final_check <= 1'b0;
        opponent_final_check_id <= '0;
        opponent_reset_game <= 1'b0;
        guess_result_valid <= 1'b0;
        guess_result_correct <= 1'b0;
        final_result_valid <= 1'b0;
        final_result_correct <= 1'b0;
        send_turn_end_d <= 1'b0;
        send_result_d <= 1'b0;
        send_result_correct_d <= 1'b0;
    end else begin
        link_ready <= 1'b1;
        opponent_guess <= 1'b0;
        opponent_guess_id <= '0;
        opponent_final_check <= 1'b0;
        opponent_final_check_id <= '0;
        opponent_reset_game <= send_reset_game;

        if (send_reset_game) begin
            opponent_ready <= 1'b0;
        end else if (send_ready) begin
            opponent_ready <= 1'b1;
        end

        guess_result_valid <= send_guess;
        guess_result_correct <= send_guess_id == local_secret_id;
        final_result_valid <= send_final_check;
        final_result_correct <= send_final_check_id == local_secret_id;
        send_turn_end_d <= send_turn_end;
        send_result_d <= send_result;
        send_result_correct_d <= send_result_correct;
    end
end

endmodule
