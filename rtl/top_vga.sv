/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2025  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 *
 * Description:
 * The project top module.
 */

module top_vga (
        input  logic clk,
        input  logic clk_100mhz,
        input  logic rst_n,
        inout  wire  ps2_clk,
        inout  wire  ps2_data,
        output logic vs,
        output logic hs,
        output logic [3:0] r,
        output logic [3:0] g,
        output logic [3:0] b
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local parameters
     */
    localparam int RECT_WIDTH     = 48;
    localparam int RECT_HEIGHT    = 64;
    localparam logic [11:0] MOUSE_MAX_X = 12'd799;
    localparam logic [11:0] MOUSE_MAX_Y = 12'd599;

    /**
     * Local variables and signals
     */
    logic [11:0] mouse_xpos_raw;
    logic [11:0] mouse_ypos_raw;
    logic        mouse_left_raw;

    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_xpos_sync1;
    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_ypos_sync1;
    (* ASYNC_REG = "TRUE" *) logic        mouse_left_sync1;
    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_xpos;
    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_ypos;
    (* ASYNC_REG = "TRUE" *) logic        mouse_left;

    logic [11:0] mouse_xpos_clip;
    logic [11:0] mouse_ypos_clip;
    logic [11:0] rect_xpos;
    logic [11:0] rect_ypos;
    logic [11:0] rect_pixel_addr;
    logic [11:0] rect_rgb_pixel;

    logic [7:0] char_xy;
    logic [3:0] char_line;
    logic [6:0] char_code;
    logic [10:0] font_addr;
    logic [7:0] char_pixels;

    vga_if if_tim ();
    vga_if if_bg ();
    vga_if if_rect ();
    vga_if if_mouse ();
    vga_if if_char();


    /**
     * Signal assignments
     */
    assign if_tim.rgb = 12'h8_8_8;
    assign vs         = if_mouse.vsync;
    assign hs         = if_mouse.hsync;
    assign {r, g, b}  = if_mouse.rgb;

    assign mouse_xpos_clip = (mouse_xpos > MOUSE_MAX_X) ? MOUSE_MAX_X : mouse_xpos;
    assign mouse_ypos_clip = (mouse_ypos > MOUSE_MAX_Y) ? MOUSE_MAX_Y : mouse_ypos;

    assign font_addr = {char_code, char_line};

    /**
     * Sequential logic
     */
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mouse_xpos_sync1 <= '0;
            mouse_ypos_sync1 <= '0;
            mouse_left_sync1 <= '0;
            mouse_xpos       <= '0;
            mouse_ypos       <= '0;
            mouse_left       <= '0;
        end else begin
            mouse_xpos_sync1 <= mouse_xpos_raw;
            mouse_ypos_sync1 <= mouse_ypos_raw;
            mouse_left_sync1 <= mouse_left_raw;
            mouse_xpos       <= mouse_xpos_sync1;
            mouse_ypos       <= mouse_ypos_sync1;
            mouse_left       <= mouse_left_sync1;
        end
    end

    /**
     * Submodule instances
     */
    vga_timing u_vga_timing (
        .clk,
        .rst_n,
        .vcount (if_tim.vcount),
        .vsync  (if_tim.vsync),
        .vblnk  (if_tim.vblnk),
        .hcount (if_tim.hcount),
        .hsync  (if_tim.hsync),
        .hblnk  (if_tim.hblnk)
    );

    MouseCtl u_mouse_ctl (
        .clk       (clk_100mhz),
        .rst       (!rst_n),
        .xpos      (mouse_xpos_raw),
        .ypos      (mouse_ypos_raw),
        .zpos      (),
        .left      (mouse_left_raw),
        .middle    (),
        .right     (),
        .new_event (),
        .value     ('0),
        .setx      (1'b0),
        .sety      (1'b0),
        .setmax_x  (1'b0),
        .setmax_y  (1'b0),
        .ps2_clk   (ps2_clk),
        .ps2_data  (ps2_data)
    );

    draw_bg u_draw_bg (
        .clk,
        .rst_n,
        .in  (if_tim.in),
        .out (if_bg.out)
    );

    char_rom #(
        .TEXT("Bardzo ciekawe cwiczenie :)")
    ) u_char_rom (
        .clk(clk),
        .char_xy(char_xy),
        .char_code(char_code)
    );
    font_rom u_font_rom (
        .clk(clk),
        .addr(font_addr),
        .char_line_pixels(char_pixels)
    );

    draw_rect_char #(
        .XPOS(100), 
        .YPOS(50)   
    ) u_draw_rect_char (
        .clk(clk),
        .rst_n(rst_n),
        .char_line_pixels(char_pixels),
        .char_xy(char_xy),
        .char_line(char_line),
        .in(if_bg.in),
        .out(if_char.out)
    );

    draw_rect_ctl #(
        .RECT_HEIGHT (RECT_HEIGHT)
    ) u_draw_rect_ctl (
        .clk,
        .rst_n,
        .mouse_left,
        .mouse_xpos (mouse_xpos_clip),
        .mouse_ypos (mouse_ypos_clip),
        .xpos       (rect_xpos),
        .ypos       (rect_ypos)
    );

    draw_rect #(
        .WIDTH     (RECT_WIDTH),
        .HEIGHT    (RECT_HEIGHT)
    ) u_draw_rect (
        .clk        (clk),
        .rst_n      (rst_n),
        .xpos       (rect_xpos),
        .ypos       (rect_ypos),
        .rgb_pixel  (rect_rgb_pixel),
        .pixel_addr (rect_pixel_addr),
        .in         (if_char.in),
        .out        (if_rect.out)
    );

    image_rom u_image_rom (
        .clk     (clk),
        .address (rect_pixel_addr),
        .rgb     (rect_rgb_pixel)
    );

    draw_mouse u_draw_mouse (
        .clk   (clk),
        .rst_n (rst_n),
        .xpos  (mouse_xpos_clip),
        .ypos  (mouse_ypos_clip),
        .in    (if_rect.in),
        .out   (if_mouse.out)
    );

endmodule
