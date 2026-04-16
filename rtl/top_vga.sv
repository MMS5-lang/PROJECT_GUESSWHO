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
        input  logic clk_100MHz,
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
     * Local variables and signals
     */
     logic [11:0] mouse_xpos;
     logic [11:0] mouse_ypos;
 
     logic [11:0] mouse_xpos_sync1, mouse_xpos_sync2;
     logic [11:0] mouse_ypos_sync1, mouse_ypos_sync2;

     always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mouse_xpos_sync1 <= '0;
            mouse_xpos_sync2 <= '0;
            mouse_ypos_sync1 <= '0;
            mouse_ypos_sync2 <= '0;
        end else begin
            mouse_xpos_sync1 <= mouse_xpos;
            mouse_xpos_sync2 <= mouse_xpos_sync1;
            
            mouse_ypos_sync1 <= mouse_ypos;
            mouse_ypos_sync2 <= mouse_ypos_sync1;
        end
    end
    // VGA signals from timing
    // VGA signals from background
     vga_if if_tim ();
     vga_if if_bg ();
     vga_if if_rect ();


    /**
     * Signals assignments
     */

     assign vs = if_rect.vsync;
     assign hs = if_rect.hsync;
     assign {r,g,b} = if_rect.rgb;


    /**
     * Submodules instances
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

    draw_bg u_draw_bg (
        .clk,
        .rst_n,
        .in     (if_tim.in),
        .out    (if_bg.out)
    );

    draw_rect #(
        .X_POS(80),
        .Y_POS(180), 
        .WIDTH(530), 
        .HEIGHT(240),    
        .THICKNESS(5), 
        .COLOUR(12'hF00)
    ) u_draw_rect (
        .clk    (clk),
        .rst_n  (rst_n),
        .in     (if_bg.in),   
        .out    (if_rect.out) 
    );
endmodule
