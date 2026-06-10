/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Milosz M. Karolina M.
 *
 * Description:
 * Testbench for common helper primitives used by the project.
 */

module common_primitives_tb;

timeunit 1ns;
timeprecision 1ps;

localparam int CLK_PERIOD = 10;

logic clk;
logic rst_n;
logic reset;
logic async_rst_n;
logic sync_rst_n;

logic deb_sw;
logic deb_level;
logic deb_tick;
int deb_tick_count;

logic mod_tick;
logic [2:0] mod_q;

logic fifo_rd;
logic fifo_wr;
logic [7:0] fifo_w_data;
logic fifo_empty;
logic fifo_full;
logic [7:0] fifo_r_data;

assign reset = !rst_n;

reset_sync #(
    .STAGES (2)
) dut_reset_sync (
    .clk,
    .arst_n (async_rst_n),
    .rst_n  (sync_rst_n)
);

debounce #(
    .N (3)
) dut_debounce (
    .clk      (clk),
    .reset    (reset),
    .sw       (deb_sw),
    .db_level (deb_level),
    .db_tick  (deb_tick)
);

mod_m_counter #(
    .N (3),
    .M (5)
) dut_mod_m_counter (
    .clk      (clk),
    .reset    (reset),
    .max_tick (mod_tick),
    .q        (mod_q)
);

fifo #(
    .B (8),
    .W (2)
) dut_fifo (
    .clk    (clk),
    .reset  (reset),
    .rd     (fifo_rd),
    .wr     (fifo_wr),
    .w_data (fifo_w_data),
    .empty  (fifo_empty),
    .full   (fifo_full),
    .r_data (fifo_r_data)
);

initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD / 2) begin
        clk = ~clk;
    end
end

always @(posedge clk) begin
    if (!reset && deb_tick) begin
        deb_tick_count++;
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
    deb_sw = 1'b0;
    fifo_rd = 1'b0;
    fifo_wr = 1'b0;
    fifo_w_data = '0;
    async_rst_n = 1'b1;
    deb_tick_count = 0;

    repeat (3) begin
        wait_clk;
    end

    assert (deb_level == 1'b0) else $error("debounce reset level failed");
    assert (mod_q == 3'd0 && mod_tick == 1'b0) else $error("mod_m_counter reset failed");
    assert (fifo_empty && !fifo_full) else $error("fifo reset flags failed");

    rst_n = 1'b1;
    wait_clk;
end
endtask

task automatic write_fifo(input logic [7:0] data);
begin
    fifo_w_data = data;
    fifo_wr = 1'b1;
    wait_clk;
    fifo_wr = 1'b0;
    wait_clk;
end
endtask

task automatic read_fifo(input logic [7:0] expected);
begin
    assert (fifo_r_data == expected) else $error("fifo read data mismatch before rd");
    fifo_rd = 1'b1;
    wait_clk;
    fifo_rd = 1'b0;
    wait_clk;
end
endtask

task automatic test_reset_sync;
begin
    async_rst_n = 1'b0;
    #1;
    assert (!sync_rst_n) else $error("reset_sync should assert reset asynchronously");
    wait_clk;
    assert (!sync_rst_n) else $error("reset_sync should stay low while async reset is active");

    async_rst_n = 1'b1;
    #1;
    assert (!sync_rst_n) else $error("reset_sync released too early after async reset deassertion");
    wait_clk;
    assert (!sync_rst_n) else $error("reset_sync should keep reset low for first release stage");
    wait_clk;
    assert (sync_rst_n) else $error("reset_sync did not release after two clock edges");

    async_rst_n = 1'b0;
    #1;
    assert (!sync_rst_n) else $error("reset_sync did not reassert asynchronously");
    async_rst_n = 1'b1;
    repeat (2) begin
        wait_clk;
    end
end
endtask

initial begin
    reset_dut();
    test_reset_sync();
    reset_dut();

    repeat (3) begin
        wait_clk;
    end
    assert (mod_q == 3'd4 && mod_tick) else $error("mod_m_counter did not count to M-1");
    wait_clk;
    assert (mod_q == 3'd0 && !mod_tick) else $error("mod_m_counter did not wrap to zero");

    reset_dut();
    write_fifo(8'ha0);
    write_fifo(8'ha1);
    write_fifo(8'ha2);
    assert (!fifo_empty && !fifo_full) else $error("fifo flags wrong after three writes");
    write_fifo(8'ha3);
    assert (fifo_full && !fifo_empty) else $error("fifo full flag not set");
    read_fifo(8'ha0);
    assert (!fifo_full && !fifo_empty) else $error("fifo flags wrong after one read");
    read_fifo(8'ha1);
    read_fifo(8'ha2);
    read_fifo(8'ha3);
    assert (fifo_empty && !fifo_full) else $error("fifo empty flag not restored");

    deb_sw = 1'b1;
    repeat (2) begin
        wait_clk;
    end
    assert (!deb_level) else $error("debounce accepted a short high pulse too early");
    repeat (8) begin
        wait_clk;
    end
    assert (deb_level) else $error("debounce did not accept a stable high level");
    assert (deb_tick_count == 1) else $error("debounce should create exactly one rising tick");

    deb_sw = 1'b0;
    repeat (2) begin
        wait_clk;
    end
    assert (deb_level) else $error("debounce released too early");
    repeat (8) begin
        wait_clk;
    end
    assert (!deb_level) else $error("debounce did not return to low level");
    assert (deb_tick_count == 1) else $error("debounce should not tick on falling edge");

    $finish;
end

endmodule
