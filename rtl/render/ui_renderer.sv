/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Warstwa UI: przycisk akcji, RESET oraz panel wybranej postaci.
 */

module ui_renderer
import vga_pkg::*;
import guess_who_pkg::*;
(
    input  logic clk,
    input  logic rst_n,
    vga_if.out   out,
    input  game_state_t game_state,
    vga_if.in    in
);

timeunit 1ns;
timeprecision 1ps;

localparam logic [11:0] COLOR_WHITE       = 12'hf_f_f;
localparam logic [11:0] COLOR_GREEN       = 12'h1_b_5;
localparam logic [11:0] COLOR_BLUE        = 12'h1_4_f;
localparam logic [11:0] COLOR_RED         = 12'hd_0_0;
localparam logic [11:0] COLOR_DISABLED    = 12'h6_6_6;

logic [11:0] rgb_nxt;
logic [11:0] action_btn_color;
logic show_action_btn;
logic is_action_btn;
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
    action_btn_color = COLOR_DISABLED;
    show_action_btn = 1'b0;

    case (game_state)
        S_SELECT_SECRET: begin
            action_btn_color = COLOR_GREEN;
            show_action_btn = 1'b1;
        end
        S_MY_TURN: begin
            action_btn_color = COLOR_BLUE;
            show_action_btn = 1'b1;
        end
        default: begin
            action_btn_color = COLOR_DISABLED;
            show_action_btn = 1'b0;
        end
    endcase

    is_action_btn = (in.hcount >= START_X) &&
                   (in.hcount < START_X + BUTTON_W) &&
                   (in.vcount >= START_Y) &&
                   (in.vcount < START_Y + BUTTON_H);

    is_reset_btn = (in.hcount >= RESET_X) &&
                   (in.hcount < RESET_X + BUTTON_W) &&
                   (in.vcount >= RESET_Y) &&
                   (in.vcount < RESET_Y + BUTTON_H);

    is_panel = (in.hcount >= PANEL_X) &&
               (in.hcount < PANEL_X + CELL_W) &&
               (in.vcount >= PANEL_Y) &&
               (in.vcount < PANEL_Y + CELL_H);

    if (in.vblnk || in.hblnk) begin
        rgb_nxt = 12'h0_0_0;
    end else if (show_action_btn && is_action_btn) begin
        rgb_nxt = action_btn_color;
    end else if (is_reset_btn) begin
        rgb_nxt = COLOR_RED;
    end else if (is_panel) begin
        rgb_nxt = COLOR_WHITE;
    end else begin
        rgb_nxt = in.rgb;
    end
end

endmodule
