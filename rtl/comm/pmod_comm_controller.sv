/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Milosz M. Karolina M.
 *
 * UART byte link adapted from the provided UART example project, originally
 * based on examples by prof. Eric Crabilla.
 *
 * Description:
 * Packet controller for board-to-board Guess Who communication over PMOD UART.
 */

module pmod_comm_controller #(
    parameter int CLK_FREQ_HZ = 65_000_000,
    parameter int BAUD_RATE = 115_200,
    parameter int HELLO_INTERVAL_CYCLES = 1_000_000
) (
    input  logic clk,
    input  logic rst_n,
    input  logic player_id,
    input  logic uart_rx,
    input  logic send_ready,
    input  logic send_turn_end,
    input  logic send_guess,
    input  logic [guess_who_pkg::CHAR_ID_W-1:0] send_guess_id,
    input  logic send_final_check,
    input  logic [guess_who_pkg::CHAR_ID_W-1:0] send_final_check_id,
    input  logic send_result,
    input  logic send_result_correct,
    input  logic [guess_who_pkg::CHAR_ID_W-1:0] send_result_id,
    input  logic send_reset_game,
    output logic uart_tx,
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

localparam logic [7:0] START_BYTE = 8'hA5;
localparam int PACKET_BYTES = 6;
localparam logic [2:0] PACKET_LAST_INDEX = PACKET_BYTES - 1;
localparam int HELLO_COUNTER_W = (HELLO_INTERVAL_CYCLES <= 1) ? 1 : $clog2(HELLO_INTERVAL_CYCLES);

typedef enum logic [2:0] {
    RX_WAIT_START,
    RX_TYPE,
    RX_PLAYER,
    RX_PAYLOAD,
    RX_SEQ,
    RX_CHECKSUM
} rx_state_t;

rx_state_t rx_state;

logic uart_tx_ready;
logic uart_tx_valid;
logic [7:0] uart_tx_data;
logic uart_rx_valid;
logic [7:0] uart_rx_data;

logic pending_valid;
logic pending_is_hello;
packet_type_t pending_type;
logic [CHAR_ID_W-1:0] pending_payload;

logic tx_active;
packet_type_t tx_type;
logic [CHAR_ID_W-1:0] tx_payload;
logic [2:0] tx_byte_index;
logic [7:0] tx_seq;

logic [HELLO_COUNTER_W-1:0] hello_counter;
logic hello_due;

logic [7:0] rx_type_byte;
logic [7:0] rx_player_byte;
logic [7:0] rx_payload_byte;
logic [7:0] rx_seq_byte;

logic awaiting_guess_result;
logic awaiting_final_result;
logic [CHAR_ID_W-1:0] awaiting_result_payload;

logic request_valid;
packet_type_t request_type;
logic [CHAR_ID_W-1:0] request_payload;

assign hello_due = hello_counter == HELLO_INTERVAL_CYCLES - 1;
assign uart_tx_valid = tx_active && uart_tx_ready;
assign uart_tx_data = packet_byte(tx_type, tx_payload, tx_seq, tx_byte_index);

function automatic logic [7:0] packet_type_byte(input packet_type_t packet_type);
begin
    packet_type_byte = {4'h0, packet_type};
end
endfunction

function automatic logic [7:0] packet_player_byte(input logic packet_player_id);
begin
    packet_player_byte = {7'd0, packet_player_id};
end
endfunction

function automatic logic [7:0] packet_payload_byte(input logic [CHAR_ID_W-1:0] packet_payload);
begin
    packet_payload_byte = {{8 - CHAR_ID_W{1'b0}}, packet_payload};
end
endfunction

function automatic logic [7:0] packet_checksum(
    input packet_type_t packet_type,
    input logic packet_player_id,
    input logic [CHAR_ID_W-1:0] packet_payload,
    input logic [7:0] packet_seq
);
begin
    packet_checksum = START_BYTE ^
                      packet_type_byte(packet_type) ^
                      packet_player_byte(packet_player_id) ^
                      packet_payload_byte(packet_payload) ^
                      packet_seq;
end
endfunction

function automatic logic [7:0] packet_byte(
    input packet_type_t packet_type,
    input logic [CHAR_ID_W-1:0] packet_payload,
    input logic [7:0] packet_seq,
    input logic [2:0] packet_index
);
begin
    case (packet_index)
        3'd0: begin
            packet_byte = START_BYTE;
        end
        3'd1: begin
            packet_byte = packet_type_byte(packet_type);
        end
        3'd2: begin
            packet_byte = packet_player_byte(player_id);
        end
        3'd3: begin
            packet_byte = packet_payload_byte(packet_payload);
        end
        3'd4: begin
            packet_byte = packet_seq;
        end
        default: begin
            packet_byte = packet_checksum(packet_type, player_id, packet_payload, packet_seq);
        end
    endcase
end
endfunction

function automatic logic packet_type_supported(input logic [3:0] packet_type_nibble);
begin
    case (packet_type_nibble)
        PKT_HELLO,
        PKT_STATUS,
        PKT_READY,
        PKT_TURN_END,
        PKT_GUESS,
        PKT_FINAL_CHECK,
        PKT_RESULT_CORRECT,
        PKT_RESULT_WRONG,
        PKT_RESET_GAME,
        PKT_ACK,
        PKT_ERROR: begin
            packet_type_supported = 1'b1;
        end
        default: begin
            packet_type_supported = 1'b0;
        end
    endcase
end
endfunction

always_comb begin
    request_valid = 1'b0;
    request_type = PKT_READY;
    request_payload = '0;

    if (send_reset_game) begin
        request_valid = 1'b1;
        request_type = PKT_RESET_GAME;
    end else if (send_result) begin
        request_valid = 1'b1;
        request_type = send_result_correct ? PKT_RESULT_CORRECT : PKT_RESULT_WRONG;
        request_payload = send_result_id;
    end else if (send_final_check) begin
        request_valid = 1'b1;
        request_type = PKT_FINAL_CHECK;
        request_payload = send_final_check_id;
    end else if (send_guess) begin
        request_valid = 1'b1;
        request_type = PKT_GUESS;
        request_payload = send_guess_id;
    end else if (send_turn_end) begin
        request_valid = 1'b1;
        request_type = PKT_TURN_END;
    end else if (send_ready) begin
        request_valid = 1'b1;
        request_type = PKT_READY;
    end
end

uart_byte_link #(
    .CLK_FREQ_HZ (CLK_FREQ_HZ),
    .BAUD_RATE   (BAUD_RATE),
    .DATA_BITS   (8),
    .STOP_TICKS  (16)
) u_uart_byte_link (
    .clk      (clk),
    .rst_n    (rst_n),
    .tx       (uart_tx),
    .tx_ready (uart_tx_ready),
    .tx_valid (uart_tx_valid),
    .tx_data  (uart_tx_data),
    .rx_valid (uart_rx_valid),
    .rx_data  (uart_rx_data),
    .rx       (uart_rx)
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pending_valid <= 1'b0;
        pending_is_hello <= 1'b0;
        pending_type <= PKT_HELLO;
        pending_payload <= '0;
        tx_active <= 1'b0;
        tx_type <= PKT_HELLO;
        tx_payload <= '0;
        tx_byte_index <= 3'd0;
        tx_seq <= 8'h00;
        hello_counter <= '0;
        rx_state <= RX_WAIT_START;
        rx_type_byte <= 8'h00;
        rx_player_byte <= 8'h00;
        rx_payload_byte <= 8'h00;
        rx_seq_byte <= 8'h00;
        awaiting_guess_result <= 1'b0;
        awaiting_final_result <= 1'b0;
        awaiting_result_payload <= '0;
        link_ready <= 1'b0;
        opponent_ready <= 1'b0;
        opponent_turn_end <= 1'b0;
        opponent_guess <= 1'b0;
        opponent_guess_id <= '0;
        opponent_final_check <= 1'b0;
        opponent_final_check_id <= '0;
        opponent_reset_game <= 1'b0;
        guess_result_valid <= 1'b0;
        guess_result_correct <= 1'b0;
        final_result_valid <= 1'b0;
        final_result_correct <= 1'b0;
    end else begin
        opponent_ready <= 1'b0;
        opponent_turn_end <= 1'b0;
        opponent_guess <= 1'b0;
        opponent_guess_id <= '0;
        opponent_final_check <= 1'b0;
        opponent_final_check_id <= '0;
        opponent_reset_game <= 1'b0;
        guess_result_valid <= 1'b0;
        guess_result_correct <= 1'b0;
        final_result_valid <= 1'b0;
        final_result_correct <= 1'b0;

        if (hello_due) begin
            hello_counter <= '0;
        end else begin
            hello_counter <= hello_counter + 1'b1;
        end

        if (send_guess) begin
            awaiting_guess_result <= 1'b1;
            awaiting_final_result <= 1'b0;
            awaiting_result_payload <= send_guess_id;
        end

        if (send_final_check) begin
            awaiting_guess_result <= 1'b0;
            awaiting_final_result <= 1'b1;
            awaiting_result_payload <= send_final_check_id;
        end

        if (send_reset_game) begin
            awaiting_guess_result <= 1'b0;
            awaiting_final_result <= 1'b0;
            awaiting_result_payload <= '0;
            pending_valid <= 1'b1;
            pending_is_hello <= 1'b0;
            pending_type <= PKT_RESET_GAME;
            pending_payload <= '0;
        end else if ((!pending_valid || pending_is_hello) && request_valid) begin
            pending_valid <= 1'b1;
            pending_is_hello <= 1'b0;
            pending_type <= request_type;
            pending_payload <= request_payload;
        end else if (!pending_valid && hello_due) begin
            pending_valid <= 1'b1;
            pending_is_hello <= 1'b1;
            pending_type <= PKT_HELLO;
            pending_payload <= '0;
        end

        if (!tx_active && pending_valid && uart_tx_ready &&
            !send_reset_game && !(pending_is_hello && request_valid)) begin
            tx_active <= 1'b1;
            tx_type <= pending_type;
            tx_payload <= pending_payload;
            tx_byte_index <= 3'd0;
            pending_valid <= 1'b0;
            pending_is_hello <= 1'b0;
        end else if (tx_active && uart_tx_ready) begin
            if (tx_byte_index == PACKET_LAST_INDEX) begin
                tx_active <= 1'b0;
                tx_byte_index <= 3'd0;
                tx_seq <= tx_seq + 8'd1;
            end else begin
                tx_byte_index <= tx_byte_index + 3'd1;
            end
        end

        if (uart_rx_valid) begin
            case (rx_state)
                RX_WAIT_START: begin
                    if (uart_rx_data == START_BYTE) begin
                        rx_state <= RX_TYPE;
                    end
                end

                RX_TYPE: begin
                    rx_type_byte <= uart_rx_data;
                    rx_state <= RX_PLAYER;
                end

                RX_PLAYER: begin
                    rx_player_byte <= uart_rx_data;
                    rx_state <= RX_PAYLOAD;
                end

                RX_PAYLOAD: begin
                    rx_payload_byte <= uart_rx_data;
                    rx_state <= RX_SEQ;
                end

                RX_SEQ: begin
                    rx_seq_byte <= uart_rx_data;
                    rx_state <= RX_CHECKSUM;
                end

                RX_CHECKSUM: begin
                    rx_state <= RX_WAIT_START;

                    if ((uart_rx_data == packet_checksum(
                            packet_type_t'(rx_type_byte[3:0]),
                            rx_player_byte[0],
                            rx_payload_byte[CHAR_ID_W-1:0],
                            rx_seq_byte
                        )) &&
                        (rx_type_byte[7:4] == 4'h0) &&
                        (rx_player_byte[7:1] == 7'd0) &&
                        (rx_player_byte[0] != player_id) &&
                        packet_type_supported(rx_type_byte[3:0])) begin
                        link_ready <= 1'b1;

                        case (rx_type_byte[3:0])
                            PKT_READY: begin
                                opponent_ready <= 1'b1;
                            end

                            PKT_TURN_END: begin
                                opponent_turn_end <= 1'b1;
                            end

                            PKT_GUESS: begin
                                opponent_guess <= 1'b1;
                                opponent_guess_id <= rx_payload_byte[CHAR_ID_W-1:0];
                            end

                            PKT_FINAL_CHECK: begin
                                opponent_final_check <= 1'b1;
                                opponent_final_check_id <= rx_payload_byte[CHAR_ID_W-1:0];
                            end

                            PKT_RESULT_CORRECT,
                            PKT_RESULT_WRONG: begin
                                if ((rx_payload_byte[CHAR_ID_W-1:0] == awaiting_result_payload) &&
                                    awaiting_final_result) begin
                                    final_result_valid <= 1'b1;
                                    final_result_correct <= rx_type_byte[3:0] == PKT_RESULT_CORRECT;
                                    awaiting_final_result <= 1'b0;
                                    awaiting_result_payload <= '0;
                                end else if ((rx_payload_byte[CHAR_ID_W-1:0] == awaiting_result_payload) &&
                                             awaiting_guess_result) begin
                                    guess_result_valid <= 1'b1;
                                    guess_result_correct <= rx_type_byte[3:0] == PKT_RESULT_CORRECT;
                                    awaiting_guess_result <= 1'b0;
                                    awaiting_result_payload <= '0;
                                end
                            end

                            PKT_RESET_GAME: begin
                                opponent_reset_game <= 1'b1;
                                awaiting_guess_result <= 1'b0;
                                awaiting_final_result <= 1'b0;
                            end

                            default: begin
                                link_ready <= 1'b1;
                            end
                        endcase
                    end
                end

                default: begin
                    rx_state <= RX_WAIT_START;
                end
            endcase
        end

        if (send_result && !send_result_correct) begin
            opponent_turn_end <= 1'b1;
        end
    end
end

endmodule
