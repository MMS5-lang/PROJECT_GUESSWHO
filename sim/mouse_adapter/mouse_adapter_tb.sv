/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Milosz M. Karolina M.
 *
 * Description:
 * Testbench for mouse adaptation and click pulse generation.
 */

module mouse_adapter_tb;

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;

localparam int CLK_PERIOD = 10;

logic clk;
logic rst_n;
logic [11:0] mouse_x_raw;
logic [11:0] mouse_y_raw;
logic mouse_left_raw;
logic mouse_right_raw;
logic [11:0] mouse_x;
logic [11:0] mouse_y;
logic left_click_pulse;
logic right_click_pulse;

mouse_adapter dut (
    .clk,
    .rst_n,
    .mouse_x_raw,
    .mouse_y_raw,
    .mouse_left_raw,
    .mouse_right_raw,
    .mouse_x,
    .mouse_y,
    .left_click_pulse,
    .right_click_pulse
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
    mouse_x_raw = '0;
    mouse_y_raw = '0;
    mouse_left_raw = 1'b0;
    mouse_right_raw = 1'b0;

    repeat (3) begin
        wait_clk;
    end

    assert (mouse_x == 12'd0 && mouse_y == 12'd0) else $error("Mouse coordinates did not reset");
    assert (!left_click_pulse && !right_click_pulse) else $error("Click pulses active during reset");

    rst_n = 1'b1;
    wait_clk;
end
endtask

initial begin
    reset_dut();

    mouse_x_raw = 12'd123;
    mouse_y_raw = 12'd456;
    wait_clk;
    assert (mouse_x == 12'd123 && mouse_y == 12'd456) else $error("Mouse coordinates not captured");

    mouse_x_raw = 12'd1500;
    mouse_y_raw = 12'd900;
    wait_clk;
    assert (mouse_x == HOR_PIXELS - 1) else $error("Mouse X was not clamped to screen width");
    assert (mouse_y == VER_PIXELS - 1) else $error("Mouse Y was not clamped to screen height");

    mouse_left_raw = 1'b1;
    wait_clk;
    assert (left_click_pulse) else $error("Left click rising edge did not create a pulse");
    wait_clk;
    assert (!left_click_pulse) else $error("Held left click created a repeated pulse");

    mouse_left_raw = 1'b0;
    wait_clk;
    assert (!left_click_pulse) else $error("Left release should not create a rising pulse");

    mouse_right_raw = 1'b1;
    wait_clk;
    assert (right_click_pulse) else $error("Right click rising edge did not create a pulse");
    wait_clk;
    assert (!right_click_pulse) else $error("Held right click created a repeated pulse");

    $finish;
end

endmodule
