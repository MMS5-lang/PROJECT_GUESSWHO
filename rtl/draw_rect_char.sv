/**
 * Draw a 32 x 8 text area using data from character and font ROMs.
 */
module draw_rect_char #(
        parameter int XPOS = 120,
        parameter int YPOS = 100
    )(
        input  logic       clk,
        input  logic       rst_n,
        input  logic [7:0] char_line_pixels,
        output logic [7:0] char_xy,
        output logic [3:0] char_line,
        vga_if.in          in,
        vga_if.out         out
    );

    timeunit 1ns;
    timeprecision 1ps;

    localparam int CHAR_WIDTH  = 8;
    localparam int CHAR_HEIGHT = 16;
    localparam int CHAR_COLS   = 32;
    localparam int CHAR_ROWS   = 8;
    localparam int WIDTH       = CHAR_COLS * CHAR_WIDTH;
    localparam int HEIGHT      = CHAR_ROWS * CHAR_HEIGHT;
    localparam int VGA_DELAY   = 3;
    localparam int DELAY_WIDTH = 39;

    logic [11:0] x_local;
    logic [11:0] y_local;
    logic        in_rect;

    logic [7:0] char_xy_nxt;
    logic [3:0] char_line_nxt;
    logic [3:0] char_line_pipe;

    logic [10:0] hcount_dly;
    logic [10:0] vcount_dly;
    logic        hsync_dly;
    logic        vsync_dly;
    logic        hblnk_dly;
    logic        vblnk_dly;
    logic [11:0] rgb_dly;
    logic        in_rect_dly;

    logic [11:0] x_local_dly;
    logic        pixel_on;
    logic [11:0] rgb_nxt;

    assign x_local_dly = hcount_dly - XPOS;
    assign pixel_on    = char_line_pixels[3'd7 - x_local_dly[2:0]];

    delay #(
        .WIDTH   (DELAY_WIDTH),
        .CLK_DEL (VGA_DELAY)
    ) u_delay_vga (
        .clk   (clk),
        .rst_n (1'b1),
        .din   ({in.hcount, in.vcount, in.hsync, in.vsync, in.hblnk, in.vblnk, in.rgb, in_rect}),
        .dout  ({hcount_dly, vcount_dly, hsync_dly, vsync_dly, hblnk_dly, vblnk_dly, rgb_dly, in_rect_dly})
    );

    always_comb begin
        x_local = in.hcount - XPOS;
        y_local = in.vcount - YPOS;
        in_rect = (in.hcount >= XPOS) && (in.hcount < XPOS + WIDTH) &&
                  (in.vcount >= YPOS) && (in.vcount < YPOS + HEIGHT);

        char_xy_nxt   = '0;
        char_line_nxt = '0;
        if (in_rect) begin
            char_xy_nxt   = {y_local[6:4], x_local[7:3]};
            char_line_nxt = y_local[3:0];
        end
    end

    // No async reset here: these registers drive BRAM address pins in char/font ROMs.
    always_ff @(posedge clk) begin
        char_xy        <= char_xy_nxt;
        char_line_pipe <= char_line_nxt;
        char_line      <= char_line_pipe;
    end

    always_comb begin
        if (vblnk_dly || hblnk_dly) begin
            rgb_nxt = 12'h0_0_0;
        end else if (in_rect_dly) begin
            if (pixel_on) begin
                rgb_nxt = 12'hF_F_F;
            end else begin
                rgb_nxt = 12'h0_7_0;
            end
        end else begin
            rgb_nxt = rgb_dly;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out.hcount <= '0;
            out.vcount <= '0;
            out.hsync  <= '0;
            out.vsync  <= '0;
            out.hblnk  <= '0;
            out.vblnk  <= '0;
            out.rgb    <= '0;
        end else begin
            out.hcount <= hcount_dly;
            out.vcount <= vcount_dly;
            out.hsync  <= hsync_dly;
            out.vsync  <= vsync_dly;
            out.hblnk  <= hblnk_dly;
            out.vblnk  <= vblnk_dly;
            out.rgb    <= rgb_nxt;
        end
    end

endmodule
