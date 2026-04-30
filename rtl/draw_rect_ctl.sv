/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 *
 * Description:
 * Simple rectangle position controller.
 */

module draw_rect_ctl #(
        parameter int SCREEN_HEIGHT = 600,
        parameter int RECT_HEIGHT = 64,
        parameter int TICK_DIV = 666666,
        parameter logic signed [23:0] GRAVITY = 24'sd87,
        parameter logic signed [23:0] STOP_SPEED = 24'sd16
    )(
        input  logic        clk,
        input  logic        rst_n,
        input  logic        mouse_left,
        input  logic [11:0] mouse_xpos,
        input  logic [11:0] mouse_ypos,
        output logic [11:0] xpos,
        output logic [11:0] ypos
    );

    timeunit 1ns;
    timeprecision 1ps;

    localparam int FRAC_BITS = 4;
    localparam logic [11:0] Y_MAX = SCREEN_HEIGHT - RECT_HEIGHT;
    localparam logic signed [23:0] Y_MAX_FP = $signed({8'd0, Y_MAX, 4'd0});
    localparam logic signed [23:0] GRAVITY_FP = GRAVITY;
    localparam logic signed [23:0] STOP_SPEED_FP = STOP_SPEED;
    localparam logic signed [23:0] IMPACT_STOP_SPEED_FP = (GRAVITY_FP * 24'sd8) + STOP_SPEED_FP;

    logic [31:0] tick_ctr;
    logic [31:0] tick_ctr_nxt;
    logic        tick;

    logic        falling;
    logic        falling_nxt;
    logic        mouse_left_dly;
    logic        mouse_left_dly_nxt;
    logic        mouse_left_rise;
    logic [11:0] xpos_nxt;
    logic [11:0] ypos_nxt;
    logic [11:0] y_start;

    logic signed [23:0] y_pos_fp;
    logic signed [23:0] y_pos_fp_nxt;
    logic signed [23:0] y_speed;
    logic signed [23:0] y_speed_nxt;
    logic signed [23:0] y_pos_tmp;
    logic signed [23:0] y_speed_tmp;
    logic signed [23:0] y_speed_bounce;

    always_comb begin
        tick = 1'b0;
        tick_ctr_nxt = tick_ctr + 32'd1;
        if (tick_ctr >= TICK_DIV - 1) begin
            tick = 1'b1;
            tick_ctr_nxt = '0;
        end

        falling_nxt = falling;
        mouse_left_dly_nxt = mouse_left;
        mouse_left_rise = mouse_left && !mouse_left_dly;
        xpos_nxt = xpos;
        ypos_nxt = ypos;
        y_pos_fp_nxt = y_pos_fp;
        y_speed_nxt = y_speed;
        y_pos_tmp = y_pos_fp;
        y_speed_tmp = y_speed;
        y_speed_bounce = '0;
        y_start = mouse_ypos;

        if (falling) begin
            if (tick) begin
                y_pos_tmp = y_pos_fp + y_speed;
                y_speed_tmp = y_speed + GRAVITY_FP;
                y_pos_fp_nxt = y_pos_tmp;
                y_speed_nxt = y_speed_tmp;
                ypos_nxt = y_pos_tmp[FRAC_BITS +: 12];

                if (y_pos_tmp >= Y_MAX_FP) begin
                    y_pos_fp_nxt = Y_MAX_FP;
                    ypos_nxt = Y_MAX;
                    if (y_speed_tmp < IMPACT_STOP_SPEED_FP) begin
                        y_speed_nxt = '0;
                        falling_nxt = 1'b0;
                    end else begin
                        // Bounce: keep about 75% of the speed and change direction.
                        y_speed_bounce = y_speed_tmp - (y_speed_tmp >>> 2);
                        y_speed_nxt = -y_speed_bounce;
                    end
                end else if (y_pos_tmp < 24'sd0) begin
                    y_pos_fp_nxt = '0;
                    y_speed_nxt = '0;
                    ypos_nxt = '0;
                end
            end
        end else if (mouse_left_rise) begin
            falling_nxt = 1'b1;
            xpos_nxt = mouse_xpos;
            if (mouse_ypos > Y_MAX) begin
                y_start = Y_MAX;
            end
            ypos_nxt = y_start;
            y_pos_fp_nxt = $signed({8'd0, y_start, 4'd0});
            y_speed_nxt = '0;
        end else begin
            xpos_nxt = mouse_xpos;
            ypos_nxt = mouse_ypos;
            y_pos_fp_nxt = $signed({8'd0, mouse_ypos, 4'd0});
            y_speed_nxt = '0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_ctr <= '0;
            falling <= 1'b0;
            mouse_left_dly <= '0;
            xpos <= '0;
            ypos <= '0;
            y_pos_fp <= '0;
            y_speed <= '0;
        end else begin
            tick_ctr <= tick_ctr_nxt;
            falling <= falling_nxt;
            mouse_left_dly <= mouse_left_dly_nxt;
            xpos <= xpos_nxt;
            ypos <= ypos_nxt;
            y_pos_fp <= y_pos_fp_nxt;
            y_speed <= y_speed_nxt;
        end
    end

endmodule
