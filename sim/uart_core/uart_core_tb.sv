/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Milosz M. Karolina M.
 *
 * Description:
 * Testbench for the copied UART TX/RX blocks. The FIFO-backed core is
 * exercised through the PMOD communication integration tests.
 */

module uart_core_tb;

timeunit 1ns;
timeprecision 1ps;

localparam int CLK_PERIOD = 10;
localparam int TIMEOUT_CYCLES = 20_000;

logic clk;
logic rst_n;
logic reset;

logic tx_start;
logic tx_done_tick;
logic [7:0] tx_din;
logic tx_line;
logic rx_done_tick;
logic [7:0] rx_dout;

assign reset = !rst_n;

uart_tx dut_uart_tx (
    .clk          (clk),
    .reset        (reset),
    .tx_start     (tx_start),
    .s_tick       (1'b1),
    .din          (tx_din),
    .tx_done_tick (tx_done_tick),
    .tx           (tx_line)
);

uart_rx dut_uart_rx (
    .clk          (clk),
    .reset        (reset),
    .rx           (tx_line),
    .s_tick       (1'b1),
    .rx_done_tick (rx_done_tick),
    .dout         (rx_dout)
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

task automatic reset_dut;
begin
    rst_n = 1'b0;
    tx_start = 1'b0;
    tx_din = '0;

    repeat (5) begin
        wait_clk;
    end

    assert (tx_line == 1'b1) else $error("uart_tx should idle high after reset");

    rst_n = 1'b1;
    wait_clk;
end
endtask

task automatic send_serial_byte(input logic [7:0] data);
    int i;
begin
    tx_din = data;
    tx_start = 1'b1;
    wait_clk;
    tx_start = 1'b0;

    for (i = 0; i < TIMEOUT_CYCLES && !rx_done_tick; i++) begin
        wait_clk;
    end

    assert (rx_done_tick) else $error("uart_rx did not complete");
    assert (rx_dout == data) else $error("uart_rx decoded a wrong byte");

    for (i = 0; i < TIMEOUT_CYCLES && !tx_done_tick; i++) begin
        wait_clk;
    end

    assert (tx_done_tick) else $error("uart_tx did not complete");
    wait_clk;
end
endtask

initial begin
    reset_dut();

    send_serial_byte(8'h55);
    send_serial_byte(8'ha6);

    $finish;
end

endmodule
