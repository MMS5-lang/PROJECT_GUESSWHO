/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Package with vga related constants.
 */

package vga_pkg;

    // Parameters for VGA Display 1024 x 768 @ 60fps using a 65 MHz clock.
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
    // Add VGA timing parameters here and refer to them in other modules.

    localparam int BOARD_COLS = 6;
    localparam int BOARD_ROWS = 3;
    localparam int CELL_W = 140;
    localparam int CELL_H = 220;
    localparam int BOARD_X = 32; 
    localparam int BOARD_Y = 32;
    localparam int BOARD_W = BOARD_COLS * CELL_W;
    localparam int BOARD_H = BOARD_ROWS * CELL_H;


endpackage
