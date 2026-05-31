/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Milosz M. Karolina M.
 *
 * Description:
 * Testbench for two PMOD UART communication controllers connected together.
 */

module pmod_comm_controller_tb;

timeunit 1ns;
timeprecision 1ps;

import guess_who_pkg::*;

localparam int CLK_PERIOD = 10;
localparam int CLK_FREQ_HZ = 100_000_000;
localparam int BAUD_RATE = 1_000_000;
localparam int HELLO_INTERVAL_CYCLES = 128;
localparam int TIMEOUT_CYCLES = 120_000;

logic clk;
logic rst_n;

logic uart_tx_a;
logic uart_tx_b;
logic uart_rx_a;
logic uart_rx_b;

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
logic link_ready_a;
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
logic link_ready_b;
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

assign uart_rx_a = uart_tx_b;
assign uart_rx_b = uart_tx_a;

pmod_comm_controller #(
    .CLK_FREQ_HZ           (CLK_FREQ_HZ),
    .BAUD_RATE             (BAUD_RATE),
    .HELLO_INTERVAL_CYCLES (HELLO_INTERVAL_CYCLES)
) dut_a (
    .clk                     (clk),
    .rst_n                   (rst_n),
    .player_id               (1'b0),
    .uart_rx                 (uart_rx_a),
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
) dut_b (
    .clk                     (clk),
    .rst_n                   (rst_n),
    .player_id               (1'b1),
    .uart_rx                 (uart_rx_b),
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
    send_ready_a = 1'b0;
    send_turn_end_a = 1'b0;
    send_guess_a = 1'b0;
    send_guess_id_a = '0;
    send_final_check_a = 1'b0;
    send_final_check_id_a = '0;
    send_result_a = 1'b0;
    send_result_correct_a = 1'b0;
    send_result_id_a = '0;
    send_reset_game_a = 1'b0;

    send_ready_b = 1'b0;
    send_turn_end_b = 1'b0;
    send_guess_b = 1'b0;
    send_guess_id_b = '0;
    send_final_check_b = 1'b0;
    send_final_check_id_b = '0;
    send_result_b = 1'b0;
    send_result_correct_b = 1'b0;
    send_result_id_b = '0;
    send_reset_game_b = 1'b0;
end
endtask

task automatic report_monitor_snapshot;
begin
    $display("Board A opponent monitor snapshot: turn_end=%0b guess=%0b guess_id=%0d final_check=%0b final_check_id=%0d reset=%0b",
             opponent_turn_end_a,
             opponent_guess_a,
             opponent_guess_id_a,
             opponent_final_check_a,
             opponent_final_check_id_a,
             opponent_reset_game_a);
    $display("Board B result monitor snapshot: guess_valid=%0b guess_correct=%0b final_valid=%0b final_correct=%0b",
             guess_result_valid_b,
             guess_result_correct_b,
             final_result_valid_b,
             final_result_correct_b);
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

    for (i = 0; i < TIMEOUT_CYCLES && !(link_ready_a && link_ready_b); i++) begin
        wait_clk;
    end
    assert (link_ready_a && link_ready_b) else $error("HELLO packets did not establish the link");

    send_ready_a = 1'b1;
    wait_clk;
    send_ready_a = 1'b0;

    for (i = 0; i < TIMEOUT_CYCLES && !opponent_ready_b; i++) begin
        wait_clk;
    end
    assert (opponent_ready_b) else $error("Board B did not receive READY from board A");

    send_ready_b = 1'b1;
    wait_clk;
    send_ready_b = 1'b0;

    for (i = 0; i < TIMEOUT_CYCLES && !opponent_ready_a; i++) begin
        wait_clk;
    end
    assert (opponent_ready_a) else $error("Board A did not receive READY from board B");

    send_turn_end_a = 1'b1;
    wait_clk;
    send_turn_end_a = 1'b0;

    for (i = 0; i < TIMEOUT_CYCLES && !opponent_turn_end_b; i++) begin
        wait_clk;
    end
    assert (opponent_turn_end_b) else $error("Board B did not receive TURN_END from board A");

    send_guess_id_a = 5'd7;
    send_guess_a = 1'b1;
    wait_clk;
    send_guess_a = 1'b0;

    for (i = 0; i < TIMEOUT_CYCLES && !opponent_guess_b; i++) begin
        wait_clk;
    end
    assert (opponent_guess_b && opponent_guess_id_b == 5'd7) else $error("Board B received a wrong GUESS");

    send_result_correct_b = 1'b0;
    send_result_id_b = 5'd8;
    send_result_b = 1'b1;
    wait_clk;
    send_result_b = 1'b0;
    send_result_correct_b = 1'b0;
    send_result_id_b = '0;

    for (i = 0; i < TIMEOUT_CYCLES / 2 && !guess_result_valid_a; i++) begin
        wait_clk;
    end
    assert (!guess_result_valid_a) else $error("Board A accepted a result with a wrong payload id");

    send_result_correct_b = 1'b0;
    send_result_id_b = 5'd7;
    send_result_b = 1'b1;
    wait_clk;
    assert (opponent_turn_end_b) else $error("Wrong local result should end opponent turn locally");
    send_result_b = 1'b0;
    send_result_correct_b = 1'b0;
    send_result_id_b = '0;

    for (i = 0; i < TIMEOUT_CYCLES && !guess_result_valid_a; i++) begin
        wait_clk;
    end
    assert (guess_result_valid_a && !guess_result_correct_a) else $error("Board A did not receive WRONG result");

    send_final_check_id_a = 5'd11;
    send_final_check_a = 1'b1;
    wait_clk;
    send_final_check_a = 1'b0;

    for (i = 0; i < TIMEOUT_CYCLES && !opponent_final_check_b; i++) begin
        wait_clk;
    end
    assert (opponent_final_check_b && opponent_final_check_id_b == 5'd11)
        else $error("Board B received a wrong FINAL_CHECK");

    send_result_correct_b = 1'b1;
    send_result_id_b = 5'd11;
    send_result_b = 1'b1;
    wait_clk;
    send_result_b = 1'b0;
    send_result_correct_b = 1'b0;
    send_result_id_b = '0;

    for (i = 0; i < TIMEOUT_CYCLES && !final_result_valid_a; i++) begin
        wait_clk;
    end
    assert (final_result_valid_a && final_result_correct_a) else $error("Board A did not receive final CORRECT result");

    send_reset_game_a = 1'b1;
    wait_clk;
    send_reset_game_a = 1'b0;

    for (i = 0; i < TIMEOUT_CYCLES && !opponent_reset_game_b; i++) begin
        wait_clk;
    end
    assert (opponent_reset_game_b) else $error("Board B did not receive RESET_GAME from board A");

    repeat (4) begin
        wait_clk;
    end
    assert (!opponent_turn_end_a && !opponent_guess_a &&
            !opponent_final_check_a && !opponent_reset_game_a)
        else $error("Board A received an unexpected opponent command");
    assert (!guess_result_valid_b && !final_result_valid_b)
        else $error("Board B received an unexpected result response");
    report_monitor_snapshot();

    $finish;
end

endmodule
