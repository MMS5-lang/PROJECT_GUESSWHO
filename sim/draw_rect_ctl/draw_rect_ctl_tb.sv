/**
 * Structural testbench for draw_rect_ctl.
 */

module draw_rect_ctl_tb;

    timeunit 1ns;
    timeprecision 1ps;

    localparam int CLK_PERIOD = 25;
    localparam int TICK_DIV = 4;

    logic clk;
    logic rst_n;
    logic mouse_left;
    logic [11:0] mouse_xpos;
    logic [11:0] mouse_ypos;
    logic [11:0] xpos;
    logic [11:0] ypos;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) begin
            clk = ~clk;
        end
    end

    initial begin
        rst_n = 1'b1;
        #30;
        rst_n = 1'b0;
        #60;
        rst_n = 1'b1;
    end

    draw_rect_ctl #(
        .TICK_DIV   (TICK_DIV),
        .GRAVITY    (24'sd24),
        .STOP_SPEED (24'sd12)
    ) dut (
        .clk,
        .rst_n,
        .mouse_left,
        .mouse_xpos,
        .mouse_ypos,
        .xpos,
        .ypos
    );

    draw_rect_ctl_prog #(
        .TICK_DIV (TICK_DIV)
    ) u_draw_rect_ctl_prog (
        .clk,
        .rst_n,
        .mouse_left,
        .mouse_xpos,
        .mouse_ypos,
        .xpos,
        .ypos
    );

endmodule
