/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Package with vga related constants.
 */

package vga_pkg;

    // Parameters for VGA Display 800 x 600 @ 60fps using a 40 MHz clock;
    localparam int HOR_PIXELS = 800;
    localparam int VER_PIXELS = 600;

    localparam int HOR_TOTAL_TIME  = 1056;
    localparam int HOR_BLANK_START = 800;
    localparam int HOR_BLANK_TIME  = 256;
    localparam int HOR_SYNC_START  = 840;
    localparam int HOR_SYNC_TIME   = 128;

    localparam int VER_TOTAL_TIME  = 628;
    localparam int VER_BLANK_START = 600;
    localparam int VER_BLANK_TIME  = 28;
    localparam int VER_SYNC_START  = 601;
    localparam int VER_SYNC_TIME   = 4;
    // Add VGA timing parameters here and refer to them in other modules.

endpackage
