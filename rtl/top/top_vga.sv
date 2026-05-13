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

    import vga_pkg::*;

    localparam logic [11:0] MOUSE_MAX_X = HOR_PIXELS - 1;
    localparam logic [11:0] MOUSE_MAX_Y = VER_PIXELS - 1;

    /**
     * Local variables and signals
    */
    logic [11:0] mouse_xpos_raw;
    logic [11:0] mouse_ypos_raw;

    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_xpos_sync1;
    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_ypos_sync1;
    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_xpos;
    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_ypos;

    logic [11:0] mouse_xpos_clip;
    logic [11:0] mouse_ypos_clip;

    vga_if if_tim ();
    vga_if if_bg ();
    vga_if if_ui ();
    vga_if if_face ();
    vga_if if_mouse ();


    /**
     * Signal assignments
     */
    assign if_tim.rgb = 12'h8_8_8;
    assign vs         = if_mouse.vsync;
    assign hs         = if_mouse.hsync;
    assign {r, g, b}  = if_mouse.rgb;

    assign mouse_xpos_clip = (mouse_xpos > MOUSE_MAX_X) ? MOUSE_MAX_X : mouse_xpos;
    assign mouse_ypos_clip = (mouse_ypos > MOUSE_MAX_Y) ? MOUSE_MAX_Y : mouse_ypos;

    /**
     * Sequential logic
     */
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mouse_xpos_sync1 <= '0;
            mouse_ypos_sync1 <= '0;
            mouse_xpos       <= '0;
            mouse_ypos       <= '0;
        end else begin
            mouse_xpos_sync1 <= mouse_xpos_raw;
            mouse_ypos_sync1 <= mouse_ypos_raw;
            mouse_xpos       <= mouse_xpos_sync1;
            mouse_ypos       <= mouse_ypos_sync1;
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
        .left      (),
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
    
    ui_renderer u_ui_renderer (
        .clk,
        .rst_n,
        .in  (if_bg.in),
        .out (if_ui.out)
    );

    face_renderer u_face_renderer (
        .clk,
        .rst_n,
        .in  (if_ui.in),    
        .out (if_face.out)  
    );    

    draw_mouse u_draw_mouse (
        .clk   (clk),
        .rst_n (rst_n),
        .xpos  (mouse_xpos_clip),
        .ypos  (mouse_ypos_clip),
        .in    (if_face.in),
        .out   (if_mouse.out)
    );

endmodule
