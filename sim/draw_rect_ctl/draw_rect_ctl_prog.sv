/**
 * Test program for draw_rect_ctl.
 */

module draw_rect_ctl_prog #(
        parameter int TICK_DIV = 4
    )(
        input  logic        clk,
        input  logic        rst_n,
        output logic        mouse_left,
        output logic [11:0] mouse_xpos,
        output logic [11:0] mouse_ypos,
        input  logic [11:0] xpos,
        input  logic [11:0] ypos
    );

    timeunit 1ns;
    timeprecision 1ps;

    initial begin : test_prog
        mouse_left = 1'b0;
        mouse_xpos = 12'd100;
        mouse_ypos = 12'd50;

        wait (rst_n == 1'b0);
        wait (rst_n == 1'b1);
        repeat (5) begin
            @(posedge clk);
        end

        if ((xpos !== 12'd100) || (ypos !== 12'd50)) begin
            $error("Rectangle should follow mouse before click.");
        end

        mouse_xpos = 12'd120;
        mouse_ypos = 12'd70;
        repeat (5) begin
            @(posedge clk);
        end

        if ((xpos !== 12'd120) || (ypos !== 12'd70)) begin
            $error("Rectangle should still follow mouse before click.");
        end

        mouse_left = 1'b1;
        repeat (2) begin
            @(posedge clk);
        end
        mouse_left = 1'b0;

        repeat (TICK_DIV * 5) begin
            @(posedge clk);
        end

        if (xpos !== 12'd120) begin
            $error("Rectangle X position should stay latched during fall.");
        end
        if (ypos <= 12'd70) begin
            $error("Rectangle Y position should increase after click.");
        end

        repeat (TICK_DIV * 3000) begin
            @(posedge clk);
        end

        if (ypos > 12'd536) begin
            $error("Rectangle should not fall below the bottom of the screen.");
        end

        mouse_left = 1'b0;
        mouse_xpos = 12'd10;
        mouse_ypos = 12'd20;
        repeat (5) begin
            @(posedge clk);
        end

        if ((xpos !== 12'd10) || (ypos !== 12'd20)) begin
            $error("Rectangle should return to mouse position after release, got xpos=%0d ypos=%0d.", xpos, ypos);
        end

        $display("draw_rect_ctl test finished.");
        $finish;
    end

endmodule
