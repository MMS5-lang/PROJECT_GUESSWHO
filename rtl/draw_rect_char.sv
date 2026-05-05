/**
 * Moduł rysujący zdefiniowany obszar z tekstem na ekranie VGA.
 */
module draw_rect_char #(
    parameter int XPOS = 120, 
    parameter int YPOS = 100  
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [7:0] char_line_pixels,
    output logic [7:0] char_xy,    
    output logic [3:0] char_line,  
    vga_if.in    in,
    vga_if.out   out
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int WIDTH  = 32 * 8;  
    localparam int HEIGHT = 8 * 16; 

    logic [11:0] x_local;
    logic [11:0] y_local;
    logic in_rect;

    always_comb begin
        x_local = in.hcount - XPOS;
        y_local = in.vcount - YPOS;
        in_rect = (in.hcount >= XPOS) && (in.hcount < XPOS + WIDTH) &&
                  (in.vcount >= YPOS) && (in.vcount < YPOS + HEIGHT);
        
       
        if (in_rect) begin
            char_xy = {y_local[6:4], x_local[7:3]}; 
        end else begin
            char_xy = '0;
        end
    end

   
    always_ff @(posedge clk) begin
        if (in_rect)
            char_line <= y_local[3:0];
        else
            char_line <= '0;
    end


    logic [10:0] hcount_dly, vcount_dly;
    logic        hsync_dly, vsync_dly, hblnk_dly, vblnk_dly;
    logic [11:0] rgb_dly;
    logic        in_rect_dly; 

    delay #(
        .WIDTH(39), 
        .CLK_DEL(2)     
    ) u_delay_vga (
        .clk(clk),
        .rst_n(rst_n),
        .din({in.hcount, in.vcount, in.hsync, in.vsync, in.hblnk, in.vblnk, in.rgb, in_rect}),
        .dout({hcount_dly, vcount_dly, hsync_dly, vsync_dly, hblnk_dly, vblnk_dly, rgb_dly, in_rect_dly})
    );

    assign out.hcount = hcount_dly;
    assign out.vcount = vcount_dly;
    assign out.hsync  = hsync_dly;
    assign out.vsync  = vsync_dly;
    assign out.hblnk  = hblnk_dly;
    assign out.vblnk  = vblnk_dly;

 
    logic [11:0] x_local_dly;
    logic pixel_on;
    assign x_local_dly = hcount_dly - XPOS;
    assign pixel_on    = char_line_pixels[3'd7 - x_local_dly[2:0]];

 
    always_comb begin
        if (out.vblnk || out.hblnk) begin
            out.rgb = 12'h0_0_0;
        end else if (in_rect_dly) begin
            if (pixel_on)
                out.rgb = 12'hF_F_F; // kolor czcionki
            else
                out.rgb = 12'h9_6_E; // kolor tla
        end else begin
            out.rgb = rgb_dly;
        end
    end

endmodule