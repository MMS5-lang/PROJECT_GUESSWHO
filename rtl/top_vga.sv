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
        input  logic rst_100MHz_n,
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
    localparam int RECT_THICKNESS = 5;
    localparam logic [11:0] RECT_COLOUR = 12'hF00;
    localparam logic [11:0] MOUSE_MAX_X = 12'd799;
    localparam logic [11:0] MOUSE_MAX_Y = 12'd599;

    /**
     * Local variables and signals
     */
    logic [11:0] mouse_xpos_raw;
    logic [11:0] mouse_ypos_raw;
    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_xpos_sync1;
    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_ypos_sync1;
    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_xpos;
    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_ypos;
    logic [3:0]  mouse_zpos_unused;
    logic        mouse_left_unused;
    logic        mouse_middle_unused;
    logic        mouse_right_unused;
    logic        mouse_new_event_unused;


    logic [11:0] init_value;
    logic [2:0]  init_step;
    logic        init_setx;
    logic        init_sety;
    logic        init_setmax_x;
    logic        init_setmax_y;
    logic [11:0] wire_pixel;
    logic [11:0] rgb_pixel;
    vga_if if_tim ();
    vga_if if_bg ();
    vga_if if_rect ();
    vga_if if_mouse ();

    /**
     * Signal assignments
     */

    assign if_tim.rgb = 12'h8_8_8;
    assign vs      = if_mouse.vsync;
    assign hs      = if_mouse.hsync;
    assign {r,g,b} = if_mouse.rgb;

    /**
     * Sequential and combinational logic
     */
    // After reset, configure the mouse controller:
    // start from (0,0) and limit motion to the visible 800x600 area.
    always_ff @(posedge clk_100MHz or negedge rst_100MHz_n) begin : mouse_init_ff_blk
        if (!rst_100MHz_n) begin
            init_step <= '0;
        end else if (init_step != 3'd4) begin
            init_step <= init_step + 3'd1;
        end
    end

    always_comb begin : mouse_init_comb_blk
        init_value    = '0;
        init_setx     = 1'b0;
        init_sety     = 1'b0;
        init_setmax_x = 1'b0;
        init_setmax_y = 1'b0;

        case (init_step)
            3'd0: begin
                init_value = 12'd0;
                init_setx  = 1'b1;
            end
            3'd1: begin
                init_value = 12'd0;
                init_sety  = 1'b1;
            end
            3'd2: begin
                init_value    = MOUSE_MAX_X;
                init_setmax_x = 1'b1;
            end
            3'd3: begin
                init_value    = MOUSE_MAX_Y;
                init_setmax_y = 1'b1;
            end
            default: begin
            end
        endcase
    end

    // Transfer the mouse coordinates from the 100 MHz domain
    // to the 40 MHz VGA domain.
    always_ff @(posedge clk or negedge rst_n) begin : mouse_sync_ff_blk
        if (!rst_n) begin
            mouse_xpos_sync1 <= '0;
            mouse_ypos_sync1 <= '0;
            mouse_xpos <= '0;
            mouse_ypos <= '0;
        end else begin
            mouse_xpos_sync1 <= mouse_xpos_raw;
            mouse_ypos_sync1 <= mouse_ypos_raw;
            mouse_xpos <= mouse_xpos_sync1;
            mouse_ypos <= mouse_ypos_sync1;
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
        .clk       (clk_100MHz),
        .rst       (!rst_100MHz_n),
        .xpos      (mouse_xpos_raw),
        .ypos      (mouse_ypos_raw),
        .zpos      (mouse_zpos_unused),
        .left      (mouse_left_unused),
        .middle    (mouse_middle_unused),
        .right     (mouse_right_unused),
        .new_event (mouse_new_event_unused),
        .value     (init_value),
        .setx      (init_setx),
        .sety      (init_sety),
        .setmax_x  (init_setmax_x),
        .setmax_y  (init_setmax_y),
        .ps2_clk   (ps2_clk),
        .ps2_data  (ps2_data)
    );

    draw_bg u_draw_bg (
        .clk,
        .rst_n,
        .in     (if_tim.in),
        .out    (if_bg.out)
    );

    draw_rect #(
        .WIDTH(RECT_WIDTH),
        .HEIGHT(RECT_HEIGHT),
        .THICKNESS(RECT_THICKNESS),
        .COLOUR(RECT_COLOUR)
    ) u_draw_rect (
        .clk   (clk),
        .rst_n (rst_n),
        .xpos  (mouse_xpos),
        .ypos  (mouse_ypos),
        .in    (if_bg.in),
        .out   (if_rect.out),
        .rgb_pixel (rgb_pixel),
        .pixel_addr (wire_pixel)
    );

    draw_mouse u_draw_mouse (
        .clk   (clk),
        .rst_n (rst_n),
        .xpos  (mouse_xpos),
        .ypos  (mouse_ypos),
        .in    (if_rect.in),
        .out   (if_mouse.out)
    );

    image_rom u_image_rom (
        .clk (clk),
        .address(wire_pixel),
        .rgb(rgb_pixel)
    );

endmodule
