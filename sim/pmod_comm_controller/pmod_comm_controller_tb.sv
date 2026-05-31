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
localparam int ACK_TIMEOUT_CYCLES = 20_000;
localparam int MAX_RETRIES = 3;
localparam int COMM_TIMEOUT_CYCLES = 80_000;
localparam int TIMEOUT_CYCLES = 120_000;
localparam logic [7:0] TB_START_BYTE = 8'hA5;

logic clk;
logic rst_n;

logic uart_tx_a;
logic uart_tx_b;
logic uart_rx_a;
logic uart_rx_b;
logic connect_a_to_b;
logic connect_b_to_a;
logic [7:0] forced_rx_data;

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
logic comm_error_a;

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
logic comm_error_b;

assign uart_rx_a = connect_b_to_a ? uart_tx_b : 1'b1;
assign uart_rx_b = connect_a_to_b ? uart_tx_a : 1'b1;

pmod_comm_controller #(
    .CLK_FREQ_HZ           (CLK_FREQ_HZ),
    .BAUD_RATE             (BAUD_RATE),
    .HELLO_INTERVAL_CYCLES (HELLO_INTERVAL_CYCLES),
    .ACK_TIMEOUT_CYCLES    (ACK_TIMEOUT_CYCLES),
    .MAX_RETRIES           (MAX_RETRIES),
    .COMM_TIMEOUT_CYCLES   (COMM_TIMEOUT_CYCLES)
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
    .final_result_correct    (final_result_correct_a),
    .comm_error              (comm_error_a)
);

pmod_comm_controller #(
    .CLK_FREQ_HZ           (CLK_FREQ_HZ),
    .BAUD_RATE             (BAUD_RATE),
    .HELLO_INTERVAL_CYCLES (HELLO_INTERVAL_CYCLES),
    .ACK_TIMEOUT_CYCLES    (ACK_TIMEOUT_CYCLES),
    .MAX_RETRIES           (MAX_RETRIES),
    .COMM_TIMEOUT_CYCLES   (COMM_TIMEOUT_CYCLES)
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
    .final_result_correct    (final_result_correct_b),
    .comm_error              (comm_error_b)
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

function automatic logic [7:0] tb_packet_checksum(
    input logic [3:0] packet_type,
    input logic packet_player_id,
    input logic [CHAR_ID_W-1:0] packet_payload,
    input logic [7:0] packet_seq
);
begin
    tb_packet_checksum = TB_START_BYTE ^
                         {4'h0, packet_type} ^
                         {7'd0, packet_player_id} ^
                         {{(8 - CHAR_ID_W){1'b0}}, packet_payload} ^
                         packet_seq;
end
endfunction

task automatic inject_raw_byte_to_a(input logic [7:0] data);
begin
    forced_rx_data = data;
    force dut_a.uart_rx_valid = 1'b1;
    force dut_a.uart_rx_data = forced_rx_data;
    wait_clk;
    force dut_a.uart_rx_valid = 1'b0;
    force dut_a.uart_rx_data = 8'h00;
    wait_clk;
end
endtask

task automatic inject_raw_packet_to_a(
    input logic [3:0] packet_type,
    input logic packet_player_id,
    input logic [CHAR_ID_W-1:0] packet_payload,
    input logic [7:0] packet_seq,
    input logic corrupt_checksum
);
    logic [7:0] checksum;
begin
    checksum = tb_packet_checksum(packet_type, packet_player_id, packet_payload, packet_seq);
    if (corrupt_checksum) begin
        checksum = checksum ^ 8'h5A;
    end

    inject_raw_byte_to_a(TB_START_BYTE);
    inject_raw_byte_to_a({4'h0, packet_type});
    inject_raw_byte_to_a({7'd0, packet_player_id});
    inject_raw_byte_to_a({{(8 - CHAR_ID_W){1'b0}}, packet_payload});
    inject_raw_byte_to_a(packet_seq);
    inject_raw_byte_to_a(checksum);

    release dut_a.uart_rx_valid;
    release dut_a.uart_rx_data;
    wait_clk;
end
endtask

task automatic assert_board_a_no_rx_event(input string label);
begin
    repeat (8) begin
        wait_clk;
        assert (!opponent_ready_a &&
                !opponent_turn_end_a &&
                !opponent_guess_a &&
                !opponent_final_check_a &&
                !opponent_reset_game_a &&
                !guess_result_valid_a &&
                !final_result_valid_a &&
                !dut_a.ack_pending)
            else $error("%s produced an unexpected receive event or ACK", label);
    end
end
endtask

initial begin
    int i;
    int ready_b_count;

    rst_n = 1'b0;
    connect_a_to_b = 1'b1;
    connect_b_to_a = 1'b1;
    clear_inputs();

    repeat (5) begin
        wait_clk;
    end

    rst_n = 1'b1;

    for (i = 0; i < TIMEOUT_CYCLES && !(link_ready_a && link_ready_b); i++) begin
        wait_clk;
    end
    assert (link_ready_a && link_ready_b) else $error("HELLO packets did not establish the link");

    connect_a_to_b = 1'b0;
    connect_b_to_a = 1'b0;

    inject_raw_packet_to_a(PKT_READY, 1'b1, '0, 8'h21, 1'b1);
    assert_board_a_no_rx_event("bad-checksum READY packet");

    inject_raw_packet_to_a(PKT_READY, 1'b0, '0, 8'h22, 1'b0);
    assert_board_a_no_rx_event("same-player READY packet");

    inject_raw_packet_to_a(4'hF, 1'b1, 5'd7, 8'h23, 1'b0);
    assert_board_a_no_rx_event("unsupported packet type");

    inject_raw_packet_to_a(PKT_GUESS, 1'b1, 5'd31, 8'h24, 1'b0);
    assert_board_a_no_rx_event("out-of-range GUESS payload");

    connect_a_to_b = 1'b1;
    connect_b_to_a = 1'b1;
    repeat (16) begin
        wait_clk;
    end

    ready_b_count = 0;
    connect_b_to_a = 1'b0;
    send_ready_a = 1'b1;
    wait_clk;
    send_ready_a = 1'b0;

    for (i = 0; i < ACK_TIMEOUT_CYCLES * 2 + 5000; i++) begin
        wait_clk;
        if (opponent_ready_b) begin
            ready_b_count++;
        end
    end
    assert (ready_b_count == 1) else $error("Board B should accept retried READY exactly once");
    assert (!comm_error_a && !comm_error_b) else $error("ACK retry should not raise communication error yet");

    connect_b_to_a = 1'b1;
    for (i = 0; i < TIMEOUT_CYCLES && dut_a.reliable_valid; i++) begin
        wait_clk;
        if (opponent_ready_b) begin
            ready_b_count++;
        end
    end
    assert (!dut_a.reliable_valid) else $error("Board A did not clear READY after retried ACK");
    assert (ready_b_count == 1) else $error("Board B emitted duplicate READY event during retry");
    assert (!comm_error_a && !comm_error_b) else $error("Successful ACK retry should keep communication healthy");

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
    for (i = 0; i < TIMEOUT_CYCLES && dut_a.reliable_valid; i++) begin
        wait_clk;
    end
    assert (!dut_a.reliable_valid) else $error("Board A did not receive RESET_GAME ACK");

    repeat (4) begin
        wait_clk;
    end
    assert (!opponent_turn_end_a && !opponent_guess_a &&
            !opponent_final_check_a && !opponent_reset_game_a)
        else $error("Board A received an unexpected opponent command");
    assert (!guess_result_valid_b && !final_result_valid_b)
        else $error("Board B received an unexpected result response");
    report_monitor_snapshot();

    connect_a_to_b = 1'b0;
    connect_b_to_a = 1'b0;
    for (i = 0; i < COMM_TIMEOUT_CYCLES + 1000; i++) begin
        wait_clk;
    end
    assert (comm_error_a && comm_error_b) else $error("Broken UART link did not raise communication timeout");

    $finish;
end

endmodule
