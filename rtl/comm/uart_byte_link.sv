/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Milosz M. Karolina M.
 *
 * Description:
 * Project-facing byte adapter around the UART core copied from UART.rar.
 */

module uart_byte_link #(
    parameter int CLK_FREQ_HZ = 65_000_000,
    parameter int BAUD_RATE = 115_200,
    parameter int DATA_BITS = 8,
    parameter int STOP_TICKS = 16,
    parameter int FIFO_W = 4
) (
    input  logic clk,
    input  logic rst_n,
    output logic tx,
    output logic tx_ready,
    output logic rx_valid,
    output logic [DATA_BITS-1:0] rx_data,
    input  logic tx_valid,
    input  logic [DATA_BITS-1:0] tx_data,
    input  logic rx
);

timeunit 1ns;
timeprecision 1ps;

localparam int OVERSAMPLE = 16;
localparam int RAW_UART_DIVISOR = CLK_FREQ_HZ / (BAUD_RATE * OVERSAMPLE);
localparam int UART_DIVISOR = (RAW_UART_DIVISOR < 2) ? 2 : RAW_UART_DIVISOR;
localparam int UART_DIVISOR_W = (UART_DIVISOR <= 2) ? 2 : $clog2(UART_DIVISOR);

logic reset;
logic rd_uart;
logic wr_uart;
logic tx_full;
logic rx_empty;
logic [7:0] uart_r_data;

assign reset = !rst_n;
assign tx_ready = !tx_full;
assign wr_uart = tx_valid && !tx_full;

uart #(
    .DBIT     (DATA_BITS),
    .SB_TICK  (STOP_TICKS),
    .DVSR     (UART_DIVISOR),
    .DVSR_BIT (UART_DIVISOR_W),
    .FIFO_W   (FIFO_W)
) u_uart (
    .clk      (clk),
    .reset    (reset),
    .rd_uart  (rd_uart),
    .wr_uart  (wr_uart),
    .rx       (rx),
    .w_data   (tx_data),
    .tx_full  (tx_full),
    .rx_empty (rx_empty),
    .tx       (tx),
    .r_data   (uart_r_data)
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rd_uart <= 1'b0;
        rx_valid <= 1'b0;
        rx_data <= '0;
    end else begin
        rd_uart <= !rx_empty && !rd_uart;
        rx_valid <= rd_uart;

        if (rd_uart) begin
            rx_data <= uart_r_data[DATA_BITS-1:0];
        end
    end
end

endmodule
