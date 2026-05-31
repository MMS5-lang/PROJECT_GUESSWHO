/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Draws simple labels and game messages on top of the VGA image.
 */

module text_renderer (
    input  logic clk,
    input  logic rst_n,
    input  guess_who_pkg::game_state_t game_state,
    vga_if.in    in,
    vga_if.out   out
);

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;
import guess_who_pkg::*;

localparam logic [11:0] COLOR_BLACK = 12'h0_0_0;
localparam logic [11:0] COLOR_WHITE = 12'hf_f_f;
localparam logic [11:0] COLOR_GREEN = 12'h0_b_0;
localparam logic [11:0] COLOR_RED   = 12'hf_0_0;

function automatic logic [10:0] pos11(input int value);
begin
    pos11 = value[10:0];
end
endfunction

localparam int FONT_H = 7;
localparam int TEXT_SCALE = 2;
localparam int TEXT_PITCH = 12;
localparam int TEXT_H = FONT_H * TEXT_SCALE;

localparam logic [10:0] START_TEXT_X = pos11(START_X + ((BUTTON_W - 5 * TEXT_PITCH) / 2));
localparam logic [10:0] START_TEXT_Y = pos11(START_Y + ((BUTTON_H - TEXT_H) / 2));
localparam logic [10:0] END_TEXT_X = pos11(START_X + ((BUTTON_W - 6 * TEXT_PITCH) / 2));
localparam logic [10:0] END_TURY_TEXT_X = pos11(START_X + ((BUTTON_W - 4 * TEXT_PITCH) / 2));
localparam logic [10:0] END_TEXT_Y1 = pos11(START_Y + 8);
localparam logic [10:0] END_TEXT_Y2 = pos11(START_Y + 28);
localparam logic [10:0] RESET_TEXT_X = pos11(RESET_X + ((BUTTON_W - 5 * TEXT_PITCH) / 2));
localparam logic [10:0] RESET_GRY_TEXT_X = pos11(RESET_X + ((BUTTON_W - 3 * TEXT_PITCH) / 2));
localparam logic [10:0] RESET_TEXT_Y1 = pos11(RESET_Y + 8);
localparam logic [10:0] RESET_TEXT_Y2 = pos11(RESET_Y + 28);
localparam logic [10:0] PANEL_TEXT_X = pos11(PANEL_X + ((CELL_W - 5 * TEXT_PITCH) / 2));
localparam logic [10:0] PANEL_POSTAC_TEXT_X = pos11(PANEL_X + ((CELL_W - 6 * TEXT_PITCH) / 2));
localparam logic [10:0] PANEL_TEXT_Y1 = pos11(PANEL_Y - 42);
localparam logic [10:0] PANEL_TEXT_Y2 = pos11(PANEL_Y - 22);
localparam logic [10:0] STATUS_LEN5_X = pos11(PANEL_X + ((CELL_W - 5 * TEXT_PITCH) / 2));
localparam logic [10:0] STATUS_LEN6_X = pos11(PANEL_X + ((CELL_W - 6 * TEXT_PITCH) / 2));
localparam logic [10:0] STATUS_LEN7_X = pos11(PANEL_X + ((CELL_W - 7 * TEXT_PITCH) / 2));
localparam logic [10:0] STATUS_LEN8_X = pos11(PANEL_X + ((CELL_W - 8 * TEXT_PITCH) / 2));
localparam logic [10:0] STATUS_LEN9_X = pos11(PANEL_X + ((CELL_W - 9 * TEXT_PITCH) / 2));
localparam logic [10:0] STATUS_LEN10_X = pos11(PANEL_X + ((CELL_W - 10 * TEXT_PITCH) / 2));
localparam logic [10:0] STATUS_LEN11_X = pos11(PANEL_X + ((CELL_W - 11 * TEXT_PITCH) / 2));
localparam logic [10:0] STATUS_TEXT_Y1 = pos11(PANEL_Y + CELL_H + 8);
localparam logic [10:0] STATUS_TEXT_Y2 = pos11(PANEL_Y + CELL_H + 28);
localparam logic [10:0] STATUS_TEXT_Y3 = pos11(PANEL_Y + CELL_H + 48);

typedef enum logic [4:0] {
    TEXT_NONE,
    TEXT_START,
    TEXT_KONIEC,
    TEXT_TURY,
    TEXT_RESET,
    TEXT_GRY,
    TEXT_TWOJA,
    TEXT_POSTAC,
    TEXT_WYGRALES,
    TEXT_PRZEGRALES,
    TEXT_WYBIERZ,
    TEXT_SWOJA,
    TEXT_POCZEKAJ,
    TEXT_NA_RYWALA,
    TEXT_CZEKAM,
    TEXT_NA_LINK,
    TEXT_NA_WYNIK,
    TEXT_OSTATNIA,
    TEXT_NIEPOPRAWNA,
    TEXT_ERROR
} text_id_t;

logic [11:0] rgb_nxt;
logic        show_end_turn;

logic [10:0] s0_vcount;
logic        s0_vsync;
logic        s0_vblnk;
logic [10:0] s0_hcount;
logic        s0_hsync;
logic        s0_hblnk;
logic [11:0] s0_rgb;
game_state_t s0_game_state;

logic        text_active_nxt;
text_id_t    text_id_nxt;
logic [10:0] text_x_nxt;
logic [10:0] text_y_nxt;
logic [3:0]  text_len_nxt;
logic [11:0] text_color_nxt;

logic [10:0] s1_vcount;
logic        s1_vsync;
logic        s1_vblnk;
logic [10:0] s1_hcount;
logic        s1_hsync;
logic        s1_hblnk;
logic [11:0] s1_rgb;
logic        s1_text_active;
text_id_t    s1_text_id;
logic [10:0] s1_text_x;
logic [10:0] s1_text_y;
logic [3:0]  s1_text_len;
logic [11:0] s1_text_color;

logic [3:0] char_index_nxt;
logic [7:0] char_code_nxt;
logic [7:0] local_x_nxt;
logic [7:0] char_start_nxt;
logic [4:0] char_cell_x_nxt;
logic [2:0] font_col_nxt;
logic [2:0] font_row_nxt;
logic [4:0] font_pixels_nxt;

logic [10:0] s2_vcount;
logic        s2_vsync;
logic        s2_vblnk;
logic [10:0] s2_hcount;
logic        s2_hsync;
logic        s2_hblnk;
logic [11:0] s2_rgb;
logic        s2_text_active;
logic [3:0]  s2_text_len;
logic [11:0] s2_text_color;
logic [3:0]  s2_char_index;
logic [2:0]  s2_font_col;
logic [2:0]  s2_font_row;
logic [4:0]  s2_font_pixels;

function automatic logic select_font_bit(input logic [4:0] pixels, input logic [2:0] col);
begin
    case (col)
        3'd0: begin
            select_font_bit = pixels[4];
        end
        3'd1: begin
            select_font_bit = pixels[3];
        end
        3'd2: begin
            select_font_bit = pixels[2];
        end
        3'd3: begin
            select_font_bit = pixels[1];
        end
        3'd4: begin
            select_font_bit = pixels[0];
        end
        default: begin
            select_font_bit = 1'b0;
        end
    endcase
end
endfunction

function automatic logic inside_text(
    input logic [10:0] h,
    input logic [10:0] v,
    input logic [10:0] x0,
    input logic [10:0] y0,
    input int len
);
begin
    inside_text = (h >= x0) && (h < x0 + len * TEXT_PITCH) &&
                  (v >= y0) && (v < y0 + TEXT_H);
end
endfunction

function automatic logic [7:0] get_char(input text_id_t id, input logic [3:0] idx);
begin
    get_char = " ";

    case (id)
        TEXT_START: begin
            case (idx)
                4'd0: get_char = "S";
                4'd1: get_char = "T";
                4'd2: get_char = "A";
                4'd3: get_char = "R";
                4'd4: get_char = "T";
                default: get_char = " ";
            endcase
        end
        TEXT_KONIEC: begin
            case (idx)
                4'd0: get_char = "K";
                4'd1: get_char = "O";
                4'd2: get_char = "N";
                4'd3: get_char = "I";
                4'd4: get_char = "E";
                4'd5: get_char = "C";
                default: get_char = " ";
            endcase
        end
        TEXT_TURY: begin
            case (idx)
                4'd0: get_char = "T";
                4'd1: get_char = "U";
                4'd2: get_char = "R";
                4'd3: get_char = "Y";
                default: get_char = " ";
            endcase
        end
        TEXT_RESET: begin
            case (idx)
                4'd0: get_char = "R";
                4'd1: get_char = "E";
                4'd2: get_char = "S";
                4'd3: get_char = "E";
                4'd4: get_char = "T";
                default: get_char = " ";
            endcase
        end
        TEXT_GRY: begin
            case (idx)
                4'd0: get_char = "G";
                4'd1: get_char = "R";
                4'd2: get_char = "Y";
                default: get_char = " ";
            endcase
        end
        TEXT_TWOJA: begin
            case (idx)
                4'd0: get_char = "T";
                4'd1: get_char = "W";
                4'd2: get_char = "O";
                4'd3: get_char = "J";
                4'd4: get_char = "A";
                default: get_char = " ";
            endcase
        end
        TEXT_POSTAC: begin
            case (idx)
                4'd0: get_char = "P";
                4'd1: get_char = "O";
                4'd2: get_char = "S";
                4'd3: get_char = "T";
                4'd4: get_char = "A";
                4'd5: get_char = "C";
                default: get_char = " ";
            endcase
        end
        TEXT_WYGRALES: begin
            case (idx)
                4'd0: get_char = "W";
                4'd1: get_char = "Y";
                4'd2: get_char = "G";
                4'd3: get_char = "R";
                4'd4: get_char = "A";
                4'd5: get_char = "L";
                4'd6: get_char = "E";
                4'd7: get_char = "S";
                default: get_char = " ";
            endcase
        end
        TEXT_PRZEGRALES: begin
            case (idx)
                4'd0: get_char = "P";
                4'd1: get_char = "R";
                4'd2: get_char = "Z";
                4'd3: get_char = "E";
                4'd4: get_char = "G";
                4'd5: get_char = "R";
                4'd6: get_char = "A";
                4'd7: get_char = "L";
                4'd8: get_char = "E";
                4'd9: get_char = "S";
                default: get_char = " ";
            endcase
        end
        TEXT_WYBIERZ: begin
            case (idx)
                4'd0: get_char = "W";
                4'd1: get_char = "Y";
                4'd2: get_char = "B";
                4'd3: get_char = "I";
                4'd4: get_char = "E";
                4'd5: get_char = "R";
                4'd6: get_char = "Z";
                default: get_char = " ";
            endcase
        end
        TEXT_SWOJA: begin
            case (idx)
                4'd0: get_char = "S";
                4'd1: get_char = "W";
                4'd2: get_char = "O";
                4'd3: get_char = "J";
                4'd4: get_char = "A";
                default: get_char = " ";
            endcase
        end
        TEXT_POCZEKAJ: begin
            case (idx)
                4'd0: get_char = "P";
                4'd1: get_char = "O";
                4'd2: get_char = "C";
                4'd3: get_char = "Z";
                4'd4: get_char = "E";
                4'd5: get_char = "K";
                4'd6: get_char = "A";
                4'd7: get_char = "J";
                default: get_char = " ";
            endcase
        end
        TEXT_NA_RYWALA: begin
            case (idx)
                4'd0: get_char = "N";
                4'd1: get_char = "A";
                4'd2: get_char = " ";
                4'd3: get_char = "R";
                4'd4: get_char = "Y";
                4'd5: get_char = "W";
                4'd6: get_char = "A";
                4'd7: get_char = "L";
                4'd8: get_char = "A";
                default: get_char = " ";
            endcase
        end
        TEXT_CZEKAM: begin
            case (idx)
                4'd0: get_char = "C";
                4'd1: get_char = "Z";
                4'd2: get_char = "E";
                4'd3: get_char = "K";
                4'd4: get_char = "A";
                4'd5: get_char = "M";
                default: get_char = " ";
            endcase
        end
        TEXT_NA_LINK: begin
            case (idx)
                4'd0: get_char = "N";
                4'd1: get_char = "A";
                4'd2: get_char = " ";
                4'd3: get_char = "L";
                4'd4: get_char = "I";
                4'd5: get_char = "N";
                4'd6: get_char = "K";
                default: get_char = " ";
            endcase
        end
        TEXT_NA_WYNIK: begin
            case (idx)
                4'd0: get_char = "N";
                4'd1: get_char = "A";
                4'd2: get_char = " ";
                4'd3: get_char = "W";
                4'd4: get_char = "Y";
                4'd5: get_char = "N";
                4'd6: get_char = "I";
                4'd7: get_char = "K";
                default: get_char = " ";
            endcase
        end
        TEXT_OSTATNIA: begin
            case (idx)
                4'd0: get_char = "O";
                4'd1: get_char = "S";
                4'd2: get_char = "T";
                4'd3: get_char = "A";
                4'd4: get_char = "T";
                4'd5: get_char = "N";
                4'd6: get_char = "I";
                4'd7: get_char = "A";
                default: get_char = " ";
            endcase
        end
        TEXT_NIEPOPRAWNA: begin
            case (idx)
                4'd0: get_char = "N";
                4'd1: get_char = "I";
                4'd2: get_char = "E";
                4'd3: get_char = "P";
                4'd4: get_char = "O";
                4'd5: get_char = "P";
                4'd6: get_char = "R";
                4'd7: get_char = "A";
                4'd8: get_char = "W";
                4'd9: get_char = "N";
                4'd10: get_char = "A";
                default: get_char = " ";
            endcase
        end
        TEXT_ERROR: begin
            case (idx)
                4'd0: get_char = "E";
                4'd1: get_char = "R";
                4'd2: get_char = "R";
                4'd3: get_char = "O";
                4'd4: get_char = "R";
                default: get_char = " ";
            endcase
        end
        default: begin
            get_char = " ";
        end
    endcase
end
endfunction

font_rom u_font_rom (
    .char_code (char_code_nxt),
    .row       (font_row_nxt),
    .pixels    (font_pixels_nxt)
);

always_comb begin
    show_end_turn = (s0_game_state == S_MY_TURN);

    text_active_nxt = 1'b0;
    text_id_nxt = TEXT_NONE;
    text_x_nxt = 11'd0;
    text_y_nxt = 11'd0;
    text_len_nxt = 4'd0;
    text_color_nxt = COLOR_WHITE;

    case (s0_game_state)
        S_WAIT_LINK: begin
            if (inside_text(s0_hcount, s0_vcount, STATUS_LEN6_X, STATUS_TEXT_Y1, 6)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_CZEKAM;
                text_x_nxt = STATUS_LEN6_X;
                text_y_nxt = STATUS_TEXT_Y1;
                text_len_nxt = 4'd6;
                text_color_nxt = COLOR_BLACK;
            end else if (inside_text(s0_hcount, s0_vcount, STATUS_LEN7_X, STATUS_TEXT_Y2, 7)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_NA_LINK;
                text_x_nxt = STATUS_LEN7_X;
                text_y_nxt = STATUS_TEXT_Y2;
                text_len_nxt = 4'd7;
                text_color_nxt = COLOR_BLACK;
            end
        end

        S_SELECT_SECRET: begin
            if (inside_text(s0_hcount, s0_vcount, STATUS_LEN7_X, STATUS_TEXT_Y1, 7)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_WYBIERZ;
                text_x_nxt = STATUS_LEN7_X;
                text_y_nxt = STATUS_TEXT_Y1;
                text_len_nxt = 4'd7;
                text_color_nxt = COLOR_BLACK;
            end else if (inside_text(s0_hcount, s0_vcount, STATUS_LEN5_X, STATUS_TEXT_Y2, 5)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_SWOJA;
                text_x_nxt = STATUS_LEN5_X;
                text_y_nxt = STATUS_TEXT_Y2;
                text_len_nxt = 4'd5;
                text_color_nxt = COLOR_BLACK;
            end else if (inside_text(s0_hcount, s0_vcount, STATUS_LEN6_X, STATUS_TEXT_Y3, 6)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_POSTAC;
                text_x_nxt = STATUS_LEN6_X;
                text_y_nxt = STATUS_TEXT_Y3;
                text_len_nxt = 4'd6;
                text_color_nxt = COLOR_BLACK;
            end
        end

        S_LOCAL_READY: begin
            if (inside_text(s0_hcount, s0_vcount, STATUS_LEN8_X, STATUS_TEXT_Y1, 8)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_POCZEKAJ;
                text_x_nxt = STATUS_LEN8_X;
                text_y_nxt = STATUS_TEXT_Y1;
                text_len_nxt = 4'd8;
                text_color_nxt = COLOR_BLACK;
            end else if (inside_text(s0_hcount, s0_vcount, STATUS_LEN9_X, STATUS_TEXT_Y2, 9)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_NA_RYWALA;
                text_x_nxt = STATUS_LEN9_X;
                text_y_nxt = STATUS_TEXT_Y2;
                text_len_nxt = 4'd9;
                text_color_nxt = COLOR_BLACK;
            end
        end

        S_WAIT_GUESS_RESULT: begin
            if (inside_text(s0_hcount, s0_vcount, STATUS_LEN6_X, STATUS_TEXT_Y1, 6)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_CZEKAM;
                text_x_nxt = STATUS_LEN6_X;
                text_y_nxt = STATUS_TEXT_Y1;
                text_len_nxt = 4'd6;
                text_color_nxt = COLOR_BLACK;
            end else if (inside_text(s0_hcount, s0_vcount, STATUS_LEN8_X, STATUS_TEXT_Y2, 8)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_NA_WYNIK;
                text_x_nxt = STATUS_LEN8_X;
                text_y_nxt = STATUS_TEXT_Y2;
                text_len_nxt = 4'd8;
                text_color_nxt = COLOR_BLACK;
            end
        end

        S_FINAL_CHECK: begin
            if (inside_text(s0_hcount, s0_vcount, STATUS_LEN8_X, STATUS_TEXT_Y1, 8)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_OSTATNIA;
                text_x_nxt = STATUS_LEN8_X;
                text_y_nxt = STATUS_TEXT_Y1;
                text_len_nxt = 4'd8;
                text_color_nxt = COLOR_BLACK;
            end else if (inside_text(s0_hcount, s0_vcount, STATUS_LEN6_X, STATUS_TEXT_Y2, 6)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_POSTAC;
                text_x_nxt = STATUS_LEN6_X;
                text_y_nxt = STATUS_TEXT_Y2;
                text_len_nxt = 4'd6;
                text_color_nxt = COLOR_BLACK;
            end
        end

        S_WRONG_GUESS_FEEDBACK: begin
            if (inside_text(s0_hcount, s0_vcount, STATUS_LEN11_X, STATUS_TEXT_Y1, 11)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_NIEPOPRAWNA;
                text_x_nxt = STATUS_LEN11_X;
                text_y_nxt = STATUS_TEXT_Y1;
                text_len_nxt = 4'd11;
                text_color_nxt = COLOR_RED;
            end else if (inside_text(s0_hcount, s0_vcount, STATUS_LEN6_X, STATUS_TEXT_Y2, 6)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_POSTAC;
                text_x_nxt = STATUS_LEN6_X;
                text_y_nxt = STATUS_TEXT_Y2;
                text_len_nxt = 4'd6;
                text_color_nxt = COLOR_RED;
            end
        end

        S_COMM_ERROR: begin
            if (inside_text(s0_hcount, s0_vcount, STATUS_LEN5_X, STATUS_TEXT_Y1, 5)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_ERROR;
                text_x_nxt = STATUS_LEN5_X;
                text_y_nxt = STATUS_TEXT_Y1;
                text_len_nxt = 4'd5;
                text_color_nxt = COLOR_RED;
            end else if (inside_text(s0_hcount, s0_vcount, STATUS_LEN7_X, STATUS_TEXT_Y2, 7)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_NA_LINK;
                text_x_nxt = STATUS_LEN7_X;
                text_y_nxt = STATUS_TEXT_Y2;
                text_len_nxt = 4'd7;
                text_color_nxt = COLOR_RED;
            end
        end

        S_WIN: begin
            if (inside_text(s0_hcount, s0_vcount, STATUS_LEN8_X, STATUS_TEXT_Y2, 8)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_WYGRALES;
                text_x_nxt = STATUS_LEN8_X;
                text_y_nxt = STATUS_TEXT_Y2;
                text_len_nxt = 4'd8;
                text_color_nxt = COLOR_GREEN;
            end
        end

        S_LOSE: begin
            if (inside_text(s0_hcount, s0_vcount, STATUS_LEN10_X, STATUS_TEXT_Y2, 10)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_PRZEGRALES;
                text_x_nxt = STATUS_LEN10_X;
                text_y_nxt = STATUS_TEXT_Y2;
                text_len_nxt = 4'd10;
                text_color_nxt = COLOR_RED;
            end
        end

        default: begin
            text_active_nxt = 1'b0;
        end
    endcase

    if (!text_active_nxt) begin
        if (!show_end_turn && inside_text(s0_hcount, s0_vcount, START_TEXT_X, START_TEXT_Y, 5)) begin
            text_active_nxt = 1'b1;
            text_id_nxt = TEXT_START;
            text_x_nxt = START_TEXT_X;
            text_y_nxt = START_TEXT_Y;
            text_len_nxt = 4'd5;
        end else if (show_end_turn && inside_text(s0_hcount, s0_vcount, END_TEXT_X, END_TEXT_Y1, 6)) begin
            text_active_nxt = 1'b1;
            text_id_nxt = TEXT_KONIEC;
            text_x_nxt = END_TEXT_X;
            text_y_nxt = END_TEXT_Y1;
            text_len_nxt = 4'd6;
        end else if (show_end_turn && inside_text(s0_hcount, s0_vcount, END_TURY_TEXT_X, END_TEXT_Y2, 4)) begin
            text_active_nxt = 1'b1;
            text_id_nxt = TEXT_TURY;
            text_x_nxt = END_TURY_TEXT_X;
            text_y_nxt = END_TEXT_Y2;
            text_len_nxt = 4'd4;
        end else if (inside_text(s0_hcount, s0_vcount, RESET_TEXT_X, RESET_TEXT_Y1, 5)) begin
            text_active_nxt = 1'b1;
            text_id_nxt = TEXT_RESET;
            text_x_nxt = RESET_TEXT_X;
            text_y_nxt = RESET_TEXT_Y1;
            text_len_nxt = 4'd5;
        end else if (inside_text(s0_hcount, s0_vcount, RESET_GRY_TEXT_X, RESET_TEXT_Y2, 3)) begin
            text_active_nxt = 1'b1;
            text_id_nxt = TEXT_GRY;
            text_x_nxt = RESET_GRY_TEXT_X;
            text_y_nxt = RESET_TEXT_Y2;
            text_len_nxt = 4'd3;
        end else if (inside_text(s0_hcount, s0_vcount, PANEL_TEXT_X, PANEL_TEXT_Y1, 5)) begin
            text_active_nxt = 1'b1;
            text_id_nxt = TEXT_TWOJA;
            text_x_nxt = PANEL_TEXT_X;
            text_y_nxt = PANEL_TEXT_Y1;
            text_len_nxt = 4'd5;
            text_color_nxt = COLOR_BLACK;
        end else if (inside_text(s0_hcount, s0_vcount, PANEL_POSTAC_TEXT_X, PANEL_TEXT_Y2, 6)) begin
            text_active_nxt = 1'b1;
            text_id_nxt = TEXT_POSTAC;
            text_x_nxt = PANEL_POSTAC_TEXT_X;
            text_y_nxt = PANEL_TEXT_Y2;
            text_len_nxt = 4'd6;
            text_color_nxt = COLOR_BLACK;
        end
    end
end

always_comb begin
    local_x_nxt = '0;
    char_start_nxt = '0;
    char_index_nxt = 4'd0;
    char_cell_x_nxt = 5'd0;
    font_col_nxt = 3'd0;
    font_row_nxt = 3'd0;
    char_code_nxt = " ";

    if (s1_text_active) begin
        local_x_nxt = s1_hcount[7:0] - s1_text_x[7:0];
        font_row_nxt = (s1_vcount - s1_text_y) >> 1;

        if (local_x_nxt < 8'd12) begin
            char_index_nxt = 4'd0;
        end else if (local_x_nxt < 8'd24) begin
            char_index_nxt = 4'd1;
        end else if (local_x_nxt < 8'd36) begin
            char_index_nxt = 4'd2;
        end else if (local_x_nxt < 8'd48) begin
            char_index_nxt = 4'd3;
        end else if (local_x_nxt < 8'd60) begin
            char_index_nxt = 4'd4;
        end else if (local_x_nxt < 8'd72) begin
            char_index_nxt = 4'd5;
        end else if (local_x_nxt < 8'd84) begin
            char_index_nxt = 4'd6;
        end else if (local_x_nxt < 8'd96) begin
            char_index_nxt = 4'd7;
        end else if (local_x_nxt < 8'd108) begin
            char_index_nxt = 4'd8;
        end else if (local_x_nxt < 8'd120) begin
            char_index_nxt = 4'd9;
        end else begin
            char_index_nxt = 4'd10;
        end

        case (char_index_nxt)
            4'd0: char_start_nxt = 8'd0;
            4'd1: char_start_nxt = 8'd12;
            4'd2: char_start_nxt = 8'd24;
            4'd3: char_start_nxt = 8'd36;
            4'd4: char_start_nxt = 8'd48;
            4'd5: char_start_nxt = 8'd60;
            4'd6: char_start_nxt = 8'd72;
            4'd7: char_start_nxt = 8'd84;
            4'd8: char_start_nxt = 8'd96;
            4'd9: char_start_nxt = 8'd108;
            default: char_start_nxt = 8'd120;
        endcase

        char_cell_x_nxt = local_x_nxt - char_start_nxt;
        font_col_nxt = char_cell_x_nxt >> 1;
        char_code_nxt = get_char(s1_text_id, char_index_nxt);
    end
end

always_comb begin
    rgb_nxt = s2_rgb;

    if (s2_vblnk || s2_hblnk) begin
        rgb_nxt = COLOR_BLACK;
    end else if (s2_text_active &&
                 (s2_char_index < s2_text_len) &&
                 (s2_font_row < FONT_H) &&
                 select_font_bit(s2_font_pixels, s2_font_col)) begin
        rgb_nxt = s2_text_color;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        s0_vcount <= '0;
        s0_vsync <= '0;
        s0_vblnk <= '0;
        s0_hcount <= '0;
        s0_hsync <= '0;
        s0_hblnk <= '0;
        s0_rgb <= '0;
        s0_game_state <= S_RESET;

        s1_vcount <= '0;
        s1_vsync <= '0;
        s1_vblnk <= '0;
        s1_hcount <= '0;
        s1_hsync <= '0;
        s1_hblnk <= '0;
        s1_rgb <= '0;
        s1_text_active <= 1'b0;
        s1_text_id <= TEXT_NONE;
        s1_text_x <= '0;
        s1_text_y <= '0;
        s1_text_len <= '0;
        s1_text_color <= COLOR_WHITE;

        s2_vcount <= '0;
        s2_vsync <= '0;
        s2_vblnk <= '0;
        s2_hcount <= '0;
        s2_hsync <= '0;
        s2_hblnk <= '0;
        s2_rgb <= '0;
        s2_text_active <= 1'b0;
        s2_text_len <= '0;
        s2_text_color <= COLOR_WHITE;
        s2_char_index <= '0;
        s2_font_col <= '0;
        s2_font_row <= '0;
        s2_font_pixels <= '0;

        out.vcount <= '0;
        out.vsync <= '0;
        out.vblnk <= '0;
        out.hcount <= '0;
        out.hsync <= '0;
        out.hblnk <= '0;
        out.rgb <= '0;
    end else begin
        s0_vcount <= in.vcount;
        s0_vsync <= in.vsync;
        s0_vblnk <= in.vblnk;
        s0_hcount <= in.hcount;
        s0_hsync <= in.hsync;
        s0_hblnk <= in.hblnk;
        s0_rgb <= in.rgb;
        s0_game_state <= game_state;

        s1_vcount <= s0_vcount;
        s1_vsync <= s0_vsync;
        s1_vblnk <= s0_vblnk;
        s1_hcount <= s0_hcount;
        s1_hsync <= s0_hsync;
        s1_hblnk <= s0_hblnk;
        s1_rgb <= s0_rgb;
        s1_text_active <= text_active_nxt;
        s1_text_id <= text_id_nxt;
        s1_text_x <= text_x_nxt;
        s1_text_y <= text_y_nxt;
        s1_text_len <= text_len_nxt;
        s1_text_color <= text_color_nxt;

        s2_vcount <= s1_vcount;
        s2_vsync <= s1_vsync;
        s2_vblnk <= s1_vblnk;
        s2_hcount <= s1_hcount;
        s2_hsync <= s1_hsync;
        s2_hblnk <= s1_hblnk;
        s2_rgb <= s1_rgb;
        s2_text_active <= s1_text_active;
        s2_text_len <= s1_text_len;
        s2_text_color <= s1_text_color;
        s2_char_index <= char_index_nxt;
        s2_font_col <= font_col_nxt;
        s2_font_row <= font_row_nxt;
        s2_font_pixels <= font_pixels_nxt;

        out.vcount <= s2_vcount;
        out.vsync <= s2_vsync;
        out.vblnk <= s2_vblnk;
        out.hcount <= s2_hcount;
        out.hsync <= s2_hsync;
        out.hblnk <= s2_hblnk;
        out.rgb <= rgb_nxt;
    end
end

endmodule
