/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Warstwa UI: przyciski START, RESET oraz panel wybranej postaci.
 */

module ui_renderer (
    input  logic clk,
    input  logic rst_n,
    input  guess_who_pkg::game_state_t game_state,
    input  logic has_secret,
    input  logic local_ready,
    input  logic remote_ready,
    vga_if.in    in,
    vga_if.out   out
);

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;
import guess_who_pkg::*;

logic [11:0] rgb_nxt;
logic [11:0] start_btn_color;
logic [11:0] panel_color;
logic is_start_btn;
logic is_reset_btn;
logic is_panel;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out.vcount <= '0;
        out.vsync  <= '0;
        out.vblnk  <= '0;
        out.hcount <= '0;
        out.hsync  <= '0;
        out.hblnk  <= '0;
        out.rgb    <= '0;
    end else begin
        out.vcount <= in.vcount;
        out.vsync  <= in.vsync;
        out.vblnk  <= in.vblnk;
        out.hcount <= in.hcount;
        out.hsync  <= in.hsync;
        out.hblnk  <= in.hblnk;
        out.rgb    <= rgb_nxt;
    end
end

always_comb begin
    start_btn_color = 12'h5_5_5;
    panel_color = 12'hf_f_f;

    case (game_state)
        S_WAIT_LINK: begin
            start_btn_color = 12'h5_5_5;
            panel_color = 12'hf_f_f;
        end
        S_SELECT_SECRET: begin
            start_btn_color = has_secret ? 12'h0_b_0 : 12'h6_6_6;
            panel_color = has_secret ? 12'hc_d_f : 12'hf_f_f;
        end
        S_LOCAL_READY: begin
            start_btn_color = (local_ready && remote_ready) ? 12'h0_b_0 : 12'hf_9_0;
            panel_color = 12'hf_e_b;
        end
        S_GAME_START: begin
            start_btn_color = 12'h0_8_e;
            panel_color = 12'hd_f_d;
        end
        S_MY_TURN: begin
            start_btn_color = 12'h0_8_e;
            panel_color = 12'hd_f_d;
        end
        S_OPPONENT_TURN: begin
            start_btn_color = 12'h5_5_5;
            panel_color = 12'hf_e_c;
        end
        S_WAIT_GUESS_RESULT, S_FINAL_CHECK, S_WRONG_GUESS_FEEDBACK: begin
            start_btn_color = 12'hf_9_0;
            panel_color = 12'hf_e_c;
        end
        S_WIN: begin
            start_btn_color = 12'h0_b_0;
            panel_color = 12'hd_f_d;
        end
        S_LOSE: begin
            start_btn_color = 12'hd_0_0;
            panel_color = 12'hf_d_d;
        end
        default: begin
            start_btn_color = 12'h5_5_5;
            panel_color = 12'hf_f_f;
        end
    endcase

    is_start_btn = (in.hcount >= START_X) &&
                   (in.hcount < START_X + BUTTON_W) &&
                   (in.vcount >= BUTTON_Y) &&
                   (in.vcount < BUTTON_Y + BUTTON_H);

    is_reset_btn = (in.hcount >= RESET_X) &&
                   (in.hcount < RESET_X + BUTTON_W) &&
                   (in.vcount >= BUTTON_Y) &&
                   (in.vcount < BUTTON_Y + BUTTON_H);

    is_panel = (in.hcount >= PANEL_X) &&
               (in.hcount < PANEL_X + CELL_W) &&
               (in.vcount >= PANEL_Y) &&
               (in.vcount < PANEL_Y + CELL_H);

    if (in.vblnk || in.hblnk) begin
        rgb_nxt = 12'h0_0_0;
    end else if (is_start_btn) begin
        rgb_nxt = start_btn_color;
    end else if (is_reset_btn) begin
        rgb_nxt = 12'hd_0_0;
    end else if (is_panel) begin
        rgb_nxt = panel_color;
    end else begin
        rgb_nxt = in.rgb;
    end
end

endmodule
