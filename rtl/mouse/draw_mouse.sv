/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk, Milosz M. Karolina M.
 *
 * Description:
 * Mouse cursor overlay using RGB444 cursor ROM images.
 */

module draw_mouse (
    input  logic                       clk,
    input  logic                       rst_n,
    vga_if.out                         out,
    input  logic [11:0]                xpos,
    input  logic [11:0]                ypos,
    input  guess_who_pkg::cursor_mode_t cursor_mode,
    vga_if.in                          in
);

timeunit 1ns;
timeprecision 1ps;

localparam int CURSOR_W = 64;
localparam int CURSOR_H = 64;
localparam int CURSOR_PIXELS = CURSOR_W * CURSOR_H;
localparam int CURSOR_ADDR_W = $clog2(CURSOR_PIXELS);

(* rom_style = "block" *) logic [11:0] pointer_rom [0:CURSOR_PIXELS-1];
(* rom_style = "block" *) logic [11:0] pointer_hover_rom [0:CURSOR_PIXELS-1];
(* rom_style = "block" *) logic [11:0] busy_rom [0:CURSOR_PIXELS-1];

logic [11:0] cursor_x_end;
logic [11:0] cursor_y_end;
logic [11:0] cursor_dx;
logic [11:0] cursor_dy;
logic cursor_on_nxt;
logic [CURSOR_ADDR_W-1:0] cursor_addr_nxt;

logic cursor_on_q;
logic blank_q;
logic [11:0] cursor_pixel_q;
logic [11:0] rgb_in_q;
logic [10:0] vcount_q;
logic vsync_q;
logic vblnk_q;
logic [10:0] hcount_q;
logic hsync_q;
logic hblnk_q;

initial begin
    $readmemh("../../rtl/assets/cursors/pointer_b.dat", pointer_rom);
    $readmemh("../../rtl/assets/cursors/pointer_toon_b.dat", pointer_hover_rom);
    $readmemh("../../rtl/assets/cursors/busy_hourglass_outline_detail.dat", busy_rom);
end

assign cursor_x_end = xpos + 12'd64;
assign cursor_y_end = ypos + 12'd64;
assign cursor_dx = {1'b0, in.hcount} - xpos;
assign cursor_dy = {1'b0, in.vcount} - ypos;

always_comb begin
    cursor_on_nxt = ({1'b0, in.hcount} >= xpos) &&
                    ({1'b0, in.hcount} < cursor_x_end) &&
                    ({1'b0, in.vcount} >= ypos) &&
                    ({1'b0, in.vcount} < cursor_y_end);

    cursor_addr_nxt = '0;

    if (cursor_on_nxt) begin
        cursor_addr_nxt = {cursor_dy[5:0], cursor_dx[5:0]};
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cursor_on_q <= 1'b0;
        blank_q <= 1'b0;
        cursor_pixel_q <= '0;
        rgb_in_q <= '0;
        vcount_q <= '0;
        vsync_q <= 1'b0;
        vblnk_q <= 1'b0;
        hcount_q <= '0;
        hsync_q <= 1'b0;
        hblnk_q <= 1'b0;
        out.vcount <= '0;
        out.vsync <= 1'b0;
        out.vblnk <= 1'b0;
        out.hcount <= '0;
        out.hsync <= 1'b0;
        out.hblnk <= 1'b0;
        out.rgb <= '0;
    end else begin
        cursor_on_q <= cursor_on_nxt;
        blank_q <= in.hblnk || in.vblnk;
        rgb_in_q <= in.rgb;
        vcount_q <= in.vcount;
        vsync_q <= in.vsync;
        vblnk_q <= in.vblnk;
        hcount_q <= in.hcount;
        hsync_q <= in.hsync;
        hblnk_q <= in.hblnk;

        case (cursor_mode)
            guess_who_pkg::CURSOR_POINTER_HOVER: begin
                cursor_pixel_q <= pointer_hover_rom[cursor_addr_nxt];
            end

            guess_who_pkg::CURSOR_BUSY: begin
                cursor_pixel_q <= busy_rom[cursor_addr_nxt];
            end

            default: begin
                cursor_pixel_q <= pointer_rom[cursor_addr_nxt];
            end
        endcase

        out.vcount <= vcount_q;
        out.vsync <= vsync_q;
        out.vblnk <= vblnk_q;
        out.hcount <= hcount_q;
        out.hsync <= hsync_q;
        out.hblnk <= hblnk_q;

        if (blank_q) begin
            out.rgb <= 12'h0_0_0;
        end else if (cursor_on_q && (cursor_pixel_q != 12'h0_0_0)) begin
            out.rgb <= cursor_pixel_q;
        end else begin
            out.rgb <= rgb_in_q;
        end
    end
end

endmodule
