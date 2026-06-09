/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Draws simple labels and game messages on top of the VGA image.
 */

module text_renderer
import vga_pkg::*;
import guess_who_pkg::*;
(
    input  logic clk,
    input  logic rst_n,
    vga_if.out   out,
    input  game_state_t game_state,
    input  logic local_ready,
    input  logic remote_ready,
    input  logic [CHAR_COUNT-1:0] eliminated_mask,
    vga_if.in    in
);

timeunit 1ns;
timeprecision 1ps;

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
localparam logic [10:0] STATUS_LEN12_X = pos11(PANEL_X + ((CELL_W - 12 * TEXT_PITCH) / 2));
localparam logic [10:0] STATUS_LEN13_X = pos11(PANEL_X + ((CELL_W - 13 * TEXT_PITCH) / 2));
localparam logic [10:0] STATUS_TEXT_Y1 = pos11(PANEL_Y + CELL_H + 8);
localparam logic [10:0] STATUS_TEXT_Y2 = pos11(PANEL_Y + CELL_H + 28);
localparam logic [10:0] STATUS_TEXT_Y3 = pos11(PANEL_Y + CELL_H + 48);
localparam logic [10:0] REMAINING_TEXT_X = pos11(BOARD_X);
localparam logic [10:0] REMAINING_TEXT_Y = pos11(BOARD_Y - 28);
localparam logic [10:0] INSTR_TEXT_X = pos11(PANEL_X);
localparam logic [10:0] INSTR_TEXT_Y1 = pos11(RESET_Y + BUTTON_H + 20);
localparam logic [10:0] INSTR_TEXT_Y2 = pos11(RESET_Y + BUTTON_H + 40);

typedef enum logic [5:0] {
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
    TEXT_ERROR,
    TEXT_TWOJA_TURA,
    TEXT_TURA_RYWALA,
    TEXT_ZADAJ,
    TEXT_PYTANIE,
    TEXT_ODPOWIEDZ,
    TEXT_TY_GOTOWY,
    TEXT_RYWAL_CZEKA,
    TEXT_RYWAL_GOTOWY,
    TEXT_POZOSTALO,
    TEXT_SPRAWDZAM,
    TEXT_LPM_ZGADNIJ,
    TEXT_PPM_ELIMINUJ,
    TEXT_NA_PYTANIE
} text_id_t;

logic [11:0] rgb_nxt;
logic        show_start;
logic        show_end_turn;
logic        show_remaining;
logic        show_instructions;
logic [4:0]  remaining_count_nxt;

logic [10:0] s0_vcount;
logic        s0_vsync;
logic        s0_vblnk;
logic [10:0] s0_hcount;
logic        s0_hsync;
logic        s0_hblnk;
logic [11:0] s0_rgb;
game_state_t s0_game_state;
logic        s0_local_ready;
logic        s0_remote_ready;
logic [CHAR_COUNT-1:0] s0_eliminated_mask;

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
logic [4:0]  s1_remaining_count;

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

function automatic logic [4:0] count_remaining(input logic [CHAR_COUNT-1:0] mask);
    logic [4:0] count;
    int i;
begin
    count = '0;

    for (i = 0; i < CHAR_COUNT; i++) begin
        if (!mask[i]) begin
            count = count + 5'd1;
        end
    end

    count_remaining = count;
end
endfunction

function automatic logic [7:0] digit_char(input logic [3:0] digit);
begin
    case (digit)
        4'd0: digit_char = "0";
        4'd1: digit_char = "1";
        4'd2: digit_char = "2";
        4'd3: digit_char = "3";
        4'd4: digit_char = "4";
        4'd5: digit_char = "5";
        4'd6: digit_char = "6";
        4'd7: digit_char = "7";
        4'd8: digit_char = "8";
        default: digit_char = "9";
    endcase
end
endfunction

function automatic logic [7:0] remaining_digit_char(input logic [4:0] count, input logic tens);
    logic [3:0] ones_digit;
begin
    if (count >= 5'd10) begin
        ones_digit = count - 5'd10;
        remaining_digit_char = tens ? "1" : digit_char(ones_digit);
    end else begin
        remaining_digit_char = tens ? "0" : digit_char(count[3:0]);
    end
end
endfunction

function automatic logic state_has_remaining(input game_state_t state);
begin
    case (state)
        S_MY_TURN,
        S_OPPONENT_TURN,
        S_WAIT_GUESS_RESULT,
        S_WRONG_GUESS_FEEDBACK,
        S_FINAL_CHECK,
        S_WIN,
        S_LOSE: begin
            state_has_remaining = 1'b1;
        end
        default: begin
            state_has_remaining = 1'b0;
        end
    endcase
end
endfunction

function automatic logic [7:0] get_char(input text_id_t id, input logic [3:0] idx, input logic [4:0] remaining_count);
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
        TEXT_TWOJA_TURA: begin
            case (idx)
                4'd0: get_char = "T";
                4'd1: get_char = "W";
                4'd2: get_char = "O";
                4'd3: get_char = "J";
                4'd4: get_char = "A";
                4'd5: get_char = " ";
                4'd6: get_char = "T";
                4'd7: get_char = "U";
                4'd8: get_char = "R";
                4'd9: get_char = "A";
                default: get_char = " ";
            endcase
        end
        TEXT_TURA_RYWALA: begin
            case (idx)
                4'd0: get_char = "T";
                4'd1: get_char = "U";
                4'd2: get_char = "R";
                4'd3: get_char = "A";
                4'd4: get_char = " ";
                4'd5: get_char = "R";
                4'd6: get_char = "Y";
                4'd7: get_char = "W";
                4'd8: get_char = "A";
                4'd9: get_char = "L";
                4'd10: get_char = "A";
                default: get_char = " ";
            endcase
        end
        TEXT_ZADAJ: begin
            case (idx)
                4'd0: get_char = "Z";
                4'd1: get_char = "A";
                4'd2: get_char = "D";
                4'd3: get_char = "A";
                4'd4: get_char = "J";
                default: get_char = " ";
            endcase
        end
        TEXT_PYTANIE: begin
            case (idx)
                4'd0: get_char = "P";
                4'd1: get_char = "Y";
                4'd2: get_char = "T";
                4'd3: get_char = "A";
                4'd4: get_char = "N";
                4'd5: get_char = "I";
                4'd6: get_char = "E";
                default: get_char = " ";
            endcase
        end
        TEXT_ODPOWIEDZ: begin
            case (idx)
                4'd0: get_char = "O";
                4'd1: get_char = "D";
                4'd2: get_char = "P";
                4'd3: get_char = "O";
                4'd4: get_char = "W";
                4'd5: get_char = "I";
                4'd6: get_char = "E";
                4'd7: get_char = "D";
                4'd8: get_char = "Z";
                default: get_char = " ";
            endcase
        end
        TEXT_TY_GOTOWY: begin
            case (idx)
                4'd0: get_char = "T";
                4'd1: get_char = "Y";
                4'd2: get_char = " ";
                4'd3: get_char = "G";
                4'd4: get_char = "O";
                4'd5: get_char = "T";
                4'd6: get_char = "O";
                4'd7: get_char = "W";
                4'd8: get_char = "Y";
                default: get_char = " ";
            endcase
        end
        TEXT_RYWAL_CZEKA: begin
            case (idx)
                4'd0: get_char = "R";
                4'd1: get_char = "Y";
                4'd2: get_char = "W";
                4'd3: get_char = "A";
                4'd4: get_char = "L";
                4'd5: get_char = " ";
                4'd6: get_char = "C";
                4'd7: get_char = "Z";
                4'd8: get_char = "E";
                4'd9: get_char = "K";
                4'd10: get_char = "A";
                default: get_char = " ";
            endcase
        end
        TEXT_RYWAL_GOTOWY: begin
            case (idx)
                4'd0: get_char = "R";
                4'd1: get_char = "Y";
                4'd2: get_char = "W";
                4'd3: get_char = "A";
                4'd4: get_char = "L";
                4'd5: get_char = " ";
                4'd6: get_char = "G";
                4'd7: get_char = "O";
                4'd8: get_char = "T";
                4'd9: get_char = "O";
                4'd10: get_char = "W";
                4'd11: get_char = "Y";
                default: get_char = " ";
            endcase
        end
        TEXT_POZOSTALO: begin
            case (idx)
                4'd0: get_char = "P";
                4'd1: get_char = "O";
                4'd2: get_char = "Z";
                4'd3: get_char = "O";
                4'd4: get_char = "S";
                4'd5: get_char = "T";
                4'd6: get_char = "A";
                4'd7: get_char = "L";
                4'd8: get_char = "O";
                4'd9: get_char = " ";
                4'd10: get_char = remaining_digit_char(remaining_count, 1'b1);
                4'd11: get_char = remaining_digit_char(remaining_count, 1'b0);
                default: get_char = " ";
            endcase
        end
        TEXT_SPRAWDZAM: begin
            case (idx)
                4'd0: get_char = "S";
                4'd1: get_char = "P";
                4'd2: get_char = "R";
                4'd3: get_char = "A";
                4'd4: get_char = "W";
                4'd5: get_char = "D";
                4'd6: get_char = "Z";
                4'd7: get_char = "A";
                4'd8: get_char = "M";
                default: get_char = " ";
            endcase
        end
        TEXT_LPM_ZGADNIJ: begin
            case (idx)
                4'd0: get_char = "L";
                4'd1: get_char = "P";
                4'd2: get_char = "M";
                4'd3: get_char = " ";
                4'd4: get_char = "Z";
                4'd5: get_char = "G";
                4'd6: get_char = "A";
                4'd7: get_char = "D";
                4'd8: get_char = "N";
                4'd9: get_char = "I";
                4'd10: get_char = "J";
                default: get_char = " ";
            endcase
        end
        TEXT_PPM_ELIMINUJ: begin
            case (idx)
                4'd0: get_char = "P";
                4'd1: get_char = "P";
                4'd2: get_char = "M";
                4'd3: get_char = " ";
                4'd4: get_char = "E";
                4'd5: get_char = "L";
                4'd6: get_char = "I";
                4'd7: get_char = "M";
                4'd8: get_char = "I";
                4'd9: get_char = "N";
                4'd10: get_char = "U";
                4'd11: get_char = "J";
                default: get_char = " ";
            endcase
        end
        TEXT_NA_PYTANIE: begin
            case (idx)
                4'd0: get_char = "N";
                4'd1: get_char = "A";
                4'd2: get_char = " ";
                4'd3: get_char = "P";
                4'd4: get_char = "Y";
                4'd5: get_char = "T";
                4'd6: get_char = "A";
                4'd7: get_char = "N";
                4'd8: get_char = "I";
                4'd9: get_char = "E";
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
    remaining_count_nxt = count_remaining(s0_eliminated_mask);
end

always_comb begin
    show_start = (s0_game_state == S_SELECT_SECRET);
    show_end_turn = (s0_game_state == S_MY_TURN);
    show_remaining = state_has_remaining(s0_game_state);
    show_instructions = (s0_game_state == S_MY_TURN);

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
            if (inside_text(s0_hcount, s0_vcount, s0_local_ready ? STATUS_LEN9_X : STATUS_LEN8_X, STATUS_TEXT_Y1, s0_local_ready ? 9 : 8)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = s0_local_ready ? TEXT_TY_GOTOWY : TEXT_POCZEKAJ;
                text_x_nxt = s0_local_ready ? STATUS_LEN9_X : STATUS_LEN8_X;
                text_y_nxt = STATUS_TEXT_Y1;
                text_len_nxt = s0_local_ready ? 4'd9 : 4'd8;
                text_color_nxt = COLOR_BLACK;
            end else if (inside_text(s0_hcount, s0_vcount, s0_remote_ready ? STATUS_LEN12_X : STATUS_LEN11_X, STATUS_TEXT_Y2, s0_remote_ready ? 12 : 11)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = s0_remote_ready ? TEXT_RYWAL_GOTOWY : TEXT_RYWAL_CZEKA;
                text_x_nxt = s0_remote_ready ? STATUS_LEN12_X : STATUS_LEN11_X;
                text_y_nxt = STATUS_TEXT_Y2;
                text_len_nxt = s0_remote_ready ? 4'd12 : 4'd11;
                text_color_nxt = COLOR_BLACK;
            end
        end

        S_MY_TURN: begin
            if (inside_text(s0_hcount, s0_vcount, STATUS_LEN10_X, STATUS_TEXT_Y1, 10)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_TWOJA_TURA;
                text_x_nxt = STATUS_LEN10_X;
                text_y_nxt = STATUS_TEXT_Y1;
                text_len_nxt = 4'd10;
                text_color_nxt = COLOR_BLACK;
            end else if (inside_text(s0_hcount, s0_vcount, STATUS_LEN5_X, STATUS_TEXT_Y2, 5)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_ZADAJ;
                text_x_nxt = STATUS_LEN5_X;
                text_y_nxt = STATUS_TEXT_Y2;
                text_len_nxt = 4'd5;
                text_color_nxt = COLOR_BLACK;
            end else if (inside_text(s0_hcount, s0_vcount, STATUS_LEN7_X, STATUS_TEXT_Y3, 7)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_PYTANIE;
                text_x_nxt = STATUS_LEN7_X;
                text_y_nxt = STATUS_TEXT_Y3;
                text_len_nxt = 4'd7;
                text_color_nxt = COLOR_BLACK;
            end
        end

        S_OPPONENT_TURN: begin
            if (inside_text(s0_hcount, s0_vcount, STATUS_LEN11_X, STATUS_TEXT_Y1, 11)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_TURA_RYWALA;
                text_x_nxt = STATUS_LEN11_X;
                text_y_nxt = STATUS_TEXT_Y1;
                text_len_nxt = 4'd11;
                text_color_nxt = COLOR_BLACK;
            end else if (inside_text(s0_hcount, s0_vcount, STATUS_LEN9_X, STATUS_TEXT_Y2, 9)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_ODPOWIEDZ;
                text_x_nxt = STATUS_LEN9_X;
                text_y_nxt = STATUS_TEXT_Y2;
                text_len_nxt = 4'd9;
                text_color_nxt = COLOR_BLACK;
            end else if (inside_text(s0_hcount, s0_vcount, STATUS_LEN10_X, STATUS_TEXT_Y3, 10)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_NA_PYTANIE;
                text_x_nxt = STATUS_LEN10_X;
                text_y_nxt = STATUS_TEXT_Y3;
                text_len_nxt = 4'd10;
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
            end else if (inside_text(s0_hcount, s0_vcount, STATUS_LEN9_X, STATUS_TEXT_Y3, 9)) begin
                text_active_nxt = 1'b1;
                text_id_nxt = TEXT_SPRAWDZAM;
                text_x_nxt = STATUS_LEN9_X;
                text_y_nxt = STATUS_TEXT_Y3;
                text_len_nxt = 4'd9;
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
        if (show_remaining && inside_text(s0_hcount, s0_vcount, REMAINING_TEXT_X, REMAINING_TEXT_Y, 12)) begin
            text_active_nxt = 1'b1;
            text_id_nxt = TEXT_POZOSTALO;
            text_x_nxt = REMAINING_TEXT_X;
            text_y_nxt = REMAINING_TEXT_Y;
            text_len_nxt = 4'd12;
            text_color_nxt = COLOR_BLACK;
        end else if (show_instructions && inside_text(s0_hcount, s0_vcount, INSTR_TEXT_X, INSTR_TEXT_Y1, 11)) begin
            text_active_nxt = 1'b1;
            text_id_nxt = TEXT_LPM_ZGADNIJ;
            text_x_nxt = INSTR_TEXT_X;
            text_y_nxt = INSTR_TEXT_Y1;
            text_len_nxt = 4'd11;
            text_color_nxt = COLOR_BLACK;
        end else if (show_instructions && inside_text(s0_hcount, s0_vcount, INSTR_TEXT_X, INSTR_TEXT_Y2, 12)) begin
            text_active_nxt = 1'b1;
            text_id_nxt = TEXT_PPM_ELIMINUJ;
            text_x_nxt = INSTR_TEXT_X;
            text_y_nxt = INSTR_TEXT_Y2;
            text_len_nxt = 4'd12;
            text_color_nxt = COLOR_BLACK;
        end else if (show_start && inside_text(s0_hcount, s0_vcount, START_TEXT_X, START_TEXT_Y, 5)) begin
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
        end else if (local_x_nxt < 8'd132) begin
            char_index_nxt = 4'd10;
        end else if (local_x_nxt < 8'd144) begin
            char_index_nxt = 4'd11;
        end else begin
            char_index_nxt = 4'd12;
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
            4'd10: char_start_nxt = 8'd120;
            4'd11: char_start_nxt = 8'd132;
            default: char_start_nxt = 8'd144;
        endcase

        char_cell_x_nxt = local_x_nxt - char_start_nxt;
        font_col_nxt = char_cell_x_nxt >> 1;
        char_code_nxt = get_char(s1_text_id, char_index_nxt, s1_remaining_count);
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
        s0_local_ready <= 1'b0;
        s0_remote_ready <= 1'b0;
        s0_eliminated_mask <= '0;

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
        s1_remaining_count <= '0;

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
        s0_local_ready <= local_ready;
        s0_remote_ready <= remote_ready;
        s0_eliminated_mask <= eliminated_mask;

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
        s1_remaining_count <= remaining_count_nxt;

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
