/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Package with vga related constants.
 */

 package vga_pkg;

    /* VGA Display 1024 x 768 @ 60 fps using a 65 MHz clock. */
    localparam int HOR_PIXELS = 1024;
    localparam int VER_PIXELS = 768;
    
    localparam int HOR_TOTAL_TIME  = 1344;
    localparam int HOR_BLANK_START = 1024;
    localparam int HOR_BLANK_TIME  = 320;
    localparam int HOR_SYNC_START  = 1048;
    localparam int HOR_SYNC_TIME   = 136;
    localparam bit HOR_SYNC_POLARITY = 1'b0;
    
    localparam int VER_TOTAL_TIME  = 806;
    localparam int VER_BLANK_START = 768;
    localparam int VER_BLANK_TIME  = 38;
    localparam int VER_SYNC_START  = 771;
    localparam int VER_SYNC_TIME   = 6;
    localparam bit VER_SYNC_POLARITY = 1'b0;
    
    localparam int BOARD_COLS = 6;
    localparam int BOARD_ROWS = 3;
    localparam int CELL_W = 140;
    localparam int CELL_H = 200;
    localparam int BOARD_X = 15;
    localparam int BOARD_Y = 83;
    localparam int BOARD_W = BOARD_COLS * CELL_W;
    localparam int BOARD_H = BOARD_ROWS * CELL_H;
    
    localparam int PANEL_X = 869;
    localparam int PANEL_Y = 170;
    
    localparam int BUTTON_W = 100;
    localparam int BUTTON_H = 50;
    localparam int START_X = 887;
    localparam int START_Y = 451;
    localparam int RESET_X = 887;
    localparam int RESET_Y = 524;
    localparam int BUTTON_Y = START_Y;
    
    // Fixed 6x3 board geometry without runtime division (timing-friendly).
    function automatic logic [2:0] board_col(input logic [10:0] off_x);
        if (off_x >= 11'd700) begin
            board_col = 3'd5;
        end else if (off_x >= 11'd560) begin
            board_col = 3'd4;
        end else if (off_x >= 11'd420) begin
            board_col = 3'd3;
        end else if (off_x >= 11'd280) begin
            board_col = 3'd2;
        end else if (off_x >= 11'd140) begin
            board_col = 3'd1;
        end else begin
            board_col = 3'd0;
        end
    endfunction
    
    function automatic logic [1:0] board_row(input logic [10:0] off_y);
        if (off_y >= 11'd400) begin
            board_row = 2'd2;
        end else if (off_y >= 11'd200) begin
            board_row = 2'd1;
        end else begin
            board_row = 2'd0;
        end
    endfunction
    
    function automatic logic [10:0] board_cell_x(input logic [10:0] off_x, input logic [2:0] col);
        unique case (col)
            3'd0: board_cell_x = off_x;
            3'd1: board_cell_x = off_x - 11'd140;
            3'd2: board_cell_x = off_x - 11'd280;
            3'd3: board_cell_x = off_x - 11'd420;
            3'd4: board_cell_x = off_x - 11'd560;
            default: board_cell_x = off_x - 11'd700;
        endcase
    endfunction
    
    function automatic logic [10:0] board_cell_y(input logic [10:0] off_y, input logic [1:0] row);
        unique case (row)
            2'd0: board_cell_y = off_y;
            2'd1: board_cell_y = off_y - 11'd200;
            default: board_cell_y = off_y - 11'd400;
        endcase
    endfunction
    
    function automatic logic [4:0] board_char_idx(input logic [1:0] row, input logic [2:0] col);
        unique case (row)
            2'd0: board_char_idx = {2'b00, col};
            2'd1: board_char_idx = 5'd6 + {2'b00, col};
            default: board_char_idx = 5'd12 + {2'b00, col};
        endcase
    endfunction
    
    endpackage