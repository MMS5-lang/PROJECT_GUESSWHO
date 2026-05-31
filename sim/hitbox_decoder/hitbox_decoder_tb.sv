/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Milosz M. Karolina M.
 *
 * Description:
 * Testbench for mouse hitbox decoding.
 */

module hitbox_decoder_tb;

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;

logic [11:0] mouse_x;
logic [11:0] mouse_y;
logic left_click;
logic right_click;
logic start_click;
logic reset_click;
logic char_left_click;
logic char_right_click;
logic [guess_who_pkg::CHAR_ID_W-1:0] char_id;

hitbox_decoder dut (
    .mouse_x,
    .mouse_y,
    .left_click,
    .right_click,
    .start_click,
    .reset_click,
    .char_left_click,
    .char_right_click,
    .char_id
);

task automatic drive_click(
    input int x,
    input int y,
    input logic left,
    input logic right
);
begin
    mouse_x = x[11:0];
    mouse_y = y[11:0];
    left_click = left;
    right_click = right;
    #1;
end
endtask

initial begin
    int row;
    int col;
    int expected_id;

    drive_click(0, 0, 1'b0, 1'b0);
    assert (!start_click && !reset_click && !char_left_click && !char_right_click)
        else $error("No click should decode to no hit");

    for (row = 0; row < BOARD_ROWS; row++) begin
        for (col = 0; col < BOARD_COLS; col++) begin
            expected_id = row * BOARD_COLS + col;
            drive_click(
                BOARD_X + col * CELL_W + CELL_W / 2,
                BOARD_Y + row * CELL_H + CELL_H / 2,
                1'b1,
                1'b0
            );
            assert (char_left_click) else $error("Left character click not detected");
            assert (!char_right_click) else $error("Right click should be low");
            assert (char_id == expected_id[guess_who_pkg::CHAR_ID_W-1:0])
                else $error("Wrong character id for left click");

            drive_click(
                BOARD_X + col * CELL_W + CELL_W / 2,
                BOARD_Y + row * CELL_H + CELL_H / 2,
                1'b0,
                1'b1
            );
            assert (char_right_click) else $error("Right character click not detected");
            assert (!char_left_click) else $error("Left click should be low");
            assert (char_id == expected_id[guess_who_pkg::CHAR_ID_W-1:0])
                else $error("Wrong character id for right click");
        end
    end

    drive_click(START_X + 2, START_Y + 2, 1'b1, 1'b0);
    assert (start_click) else $error("START button not detected");
    assert (!reset_click && !char_left_click && !char_right_click)
        else $error("START click should not decode as another hit");

    drive_click(RESET_X + 2, RESET_Y + 2, 1'b1, 1'b0);
    assert (reset_click) else $error("RESET button not detected");
    assert (!start_click && !char_left_click && !char_right_click)
        else $error("RESET click should not decode as another hit");

    drive_click(BOARD_X - 1, BOARD_Y, 1'b1, 1'b1);
    assert (!start_click && !reset_click && !char_left_click && !char_right_click)
        else $error("Click left of board should be ignored");

    drive_click(BOARD_X + BOARD_W, BOARD_Y + BOARD_H - 1, 1'b1, 1'b1);
    assert (!char_left_click && !char_right_click) else $error("Board right edge should be exclusive");

    drive_click(BOARD_X + BOARD_W - 1, BOARD_Y + BOARD_H - 1, 1'b1, 1'b0);
    assert (char_left_click && char_id == 5'd17) else $error("Last board pixel should hit character 17");

    $finish;
end

endmodule
