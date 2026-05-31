/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Milosz M. Karolina M.
 *
 * Description:
 * Testbench for cursor mode selection and cursor ROM image generation.
 */

module cursor_modes_tb;

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;
import guess_who_pkg::*;

localparam int CLK_PERIOD = 10;
localparam int IMG_W = 96;
localparam int IMG_H = 96;
localparam logic [11:0] BG_COLOR = 12'h1_2_3;

logic clk;
logic rst_n;
logic [11:0] mouse_x;
logic [11:0] mouse_y;
game_state_t game_state;
cursor_mode_t cursor_mode;
logic mouse_over_hitbox;

vga_if cursor_in ();
vga_if cursor_out ();

cursor_mode_controller dut_cursor_mode_controller (
    .mouse_x           (mouse_x),
    .mouse_y           (mouse_y),
    .game_state        (game_state),
    .cursor_mode       (cursor_mode),
    .mouse_over_hitbox (mouse_over_hitbox)
);

draw_mouse dut_draw_mouse (
    .clk,
    .rst_n,
    .xpos        (mouse_x),
    .ypos        (mouse_y),
    .cursor_mode (cursor_mode),
    .in          (cursor_in.in),
    .out         (cursor_out.out)
);

initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD / 2) begin
        clk = ~clk;
    end
end

task automatic wait_clk;
begin
    @(posedge clk);
    #1;
end
endtask

task automatic clear_pixel_bus;
begin
    cursor_in.hcount = '0;
    cursor_in.vcount = '0;
    cursor_in.hsync = 1'b0;
    cursor_in.vsync = 1'b0;
    cursor_in.hblnk = 1'b0;
    cursor_in.vblnk = 1'b0;
    cursor_in.rgb = '0;
end
endtask

task automatic drive_cursor_pixel(input int h, input int v, input logic [11:0] rgb);
begin
    cursor_in.hcount = h[10:0];
    cursor_in.vcount = v[10:0];
    cursor_in.hsync = 1'b1;
    cursor_in.vsync = 1'b1;
    cursor_in.hblnk = 1'b0;
    cursor_in.vblnk = 1'b0;
    cursor_in.rgb = rgb;
    repeat (3) begin
        wait_clk;
    end
end
endtask

task automatic write_byte(input int fd, input int value);
begin
    $fwriteb(fd, "%c", value[7:0]);
end
endtask

task automatic write_u16_le(input int fd, input int value);
begin
    write_byte(fd, value);
    write_byte(fd, value >> 8);
end
endtask

task automatic write_u32_le(input int fd, input int value);
begin
    write_byte(fd, value);
    write_byte(fd, value >> 8);
    write_byte(fd, value >> 16);
    write_byte(fd, value >> 24);
end
endtask

task automatic write_bmp_header(input int fd);
    int image_bytes;
    int file_bytes;
begin
    image_bytes = IMG_W * IMG_H * 3;
    file_bytes = 54 + image_bytes;

    write_byte(fd, "B");
    write_byte(fd, "M");
    write_u32_le(fd, file_bytes);
    write_u16_le(fd, 0);
    write_u16_le(fd, 0);
    write_u32_le(fd, 54);
    write_u32_le(fd, 40);
    write_u32_le(fd, IMG_W);
    write_u32_le(fd, IMG_H);
    write_u16_le(fd, 1);
    write_u16_le(fd, 24);
    write_u32_le(fd, 0);
    write_u32_le(fd, image_bytes);
    write_u32_le(fd, 2835);
    write_u32_le(fd, 2835);
    write_u32_le(fd, 0);
    write_u32_le(fd, 0);
end
endtask

task automatic write_rgb444_as_bgr888(input int fd, input logic [11:0] rgb);
begin
    write_byte(fd, int'({rgb[3:0], rgb[3:0]}));
    write_byte(fd, int'({rgb[7:4], rgb[7:4]}));
    write_byte(fd, int'({rgb[11:8], rgb[11:8]}));
end
endtask

task automatic expect_cursor_mode(
    input string label,
    input game_state_t state,
    input int x,
    input int y,
    input cursor_mode_t expected_mode,
    input logic expected_hitbox
);
begin
    game_state = state;
    mouse_x = x[11:0];
    mouse_y = y[11:0];
    #1;
    assert (cursor_mode == expected_mode)
        else $error("%s cursor mode mismatch", label);
    assert (mouse_over_hitbox == expected_hitbox)
        else $error("%s hitbox flag mismatch", label);
end
endtask

task automatic generate_cursor_bmp(
    input string filename,
    input game_state_t state,
    input int origin_x,
    input int origin_y,
    input cursor_mode_t expected_mode
);
    int fd;
    int x;
    int y;
    int visible_pixels;
    string path;
begin
    expect_cursor_mode(filename, state, origin_x, origin_y, expected_mode,
        ((origin_x >= BOARD_X) && (origin_x < BOARD_X + BOARD_W) &&
         (origin_y >= BOARD_Y) && (origin_y < BOARD_Y + BOARD_H)) ||
        ((origin_x >= START_X) && (origin_x < START_X + BUTTON_W) &&
         (origin_y >= BUTTON_Y) && (origin_y < BUTTON_Y + BUTTON_H)) ||
        ((origin_x >= RESET_X) && (origin_x < RESET_X + BUTTON_W) &&
         (origin_y >= BUTTON_Y) && (origin_y < BUTTON_Y + BUTTON_H)));

    path = {"../../results/", filename};
    fd = $fopen(path, "wb");
    assert (fd != 0) else $fatal(1, "Could not open %s", path);

    write_bmp_header(fd);
    visible_pixels = 0;

    for (y = IMG_H - 1; y >= 0; y--) begin
        for (x = 0; x < IMG_W; x++) begin
            drive_cursor_pixel(origin_x + x, origin_y + y, BG_COLOR);
            write_rgb444_as_bgr888(fd, cursor_out.rgb);
            if (cursor_out.rgb != BG_COLOR) begin
                visible_pixels++;
            end
        end
    end

    $fclose(fd);
    assert (visible_pixels > 100)
        else $error("%s did not produce enough visible cursor pixels", filename);
    $display("Info: wrote ../../results/%s with %0d visible cursor pixels",
        filename, visible_pixels);
end
endtask

initial begin
    rst_n = 1'b0;
    mouse_x = 12'd900;
    mouse_y = 12'd650;
    game_state = S_MY_TURN;
    clear_pixel_bus();

    repeat (3) begin
        wait_clk;
    end

    rst_n = 1'b1;
    wait_clk;

    expect_cursor_mode("outside normal", S_MY_TURN, 900, 650, CURSOR_POINTER, 1'b0);
    expect_cursor_mode("board hover", S_MY_TURN, BOARD_X + 20, BOARD_Y + 20,
        CURSOR_POINTER_HOVER, 1'b1);
    expect_cursor_mode("start hover", S_SELECT_SECRET, START_X + 2, BUTTON_Y + 2,
        CURSOR_POINTER_HOVER, 1'b1);
    expect_cursor_mode("reset hover", S_WIN, RESET_X + 2, BUTTON_Y + 2,
        CURSOR_POINTER_HOVER, 1'b1);
    expect_cursor_mode("busy outside", S_OPPONENT_TURN, 900, 650,
        CURSOR_BUSY, 1'b0);
    expect_cursor_mode("busy over board", S_OPPONENT_TURN, BOARD_X + 20, BOARD_Y + 20,
        CURSOR_BUSY, 1'b1);

    generate_cursor_bmp("cursor_pointer_b.bmp", S_MY_TURN, 900, 650, CURSOR_POINTER);
    generate_cursor_bmp("cursor_pointer_toon_b.bmp", S_MY_TURN,
        BOARD_X + 40, BOARD_Y + 40, CURSOR_POINTER_HOVER);
    generate_cursor_bmp("cursor_busy_hourglass.bmp", S_OPPONENT_TURN,
        BOARD_X + 40, BOARD_Y + 40, CURSOR_BUSY);

    $finish;
end

endmodule
