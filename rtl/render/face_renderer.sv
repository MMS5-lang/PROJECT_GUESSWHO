/**
 * Description:
 * Generowanie proceduralne twarzy dla 18 postaci na planszy.
 */

 module face_renderer (
    input  logic clk,
    input  logic rst_n,
    vga_if.in    in,
    vga_if.out   out
);

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;

logic [11:0] rgb_nxt;

localparam int HEAD_W = 105;   // Szerokość Twojego rysunku
localparam int HEAD_H = 120;  // Wysokość Twojego rysunku
localparam int HEAD_X_OFF = 10; // Pozycja X wewnątrz karty (140x200)
localparam int HEAD_Y_OFF = 60; // Pozycja Y wewnątrz karty

logic [11:0] head_rom [0:HEAD_W*HEAD_H-1];

initial begin
    $readmemh("../../head_shape.dat", head_rom);
end

// Format 4-bitowy: [3] Kolor skóry, [2] Okulary, [1] Czapka, [0] Broda
localparam logic [3:0] CHAR_TRAITS [0:17] = '{
    4'b0000, 4'b0001, 4'b0010, 4'b0011, 4'b0100, 4'b0101,
    4'b0110, 4'b0111, 4'b1000, 4'b1001, 4'b1010, 4'b1011, 
    4'b1100, 4'b1101, 4'b1110, 4'b1111, 4'b0100, 4'b1000  
};

logic in_board;
logic [10:0] rel_x, rel_y;
logic [10:0] cell_x, cell_y;
logic [2:0] row;
logic [3:0] col;
logic [4:0] char_idx;
logic [3:0] my_traits;

logic [10:0] head_lx, head_ly;
logic [11:0] head_pixel;
logic in_head_area;


logic is_hat, is_glasses, is_beard;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        out.vcount <= '0;
        out.vsync  <= '0;
        out.vblnk  <= '0;
        out.hcount <= '0;
        out.hsync  <= '0;
        out.hblnk  <= '0;
        out.rgb    <= '0;
    end else begin
        out.vcount <= in.vcount;
        out.vsync  <= in.vsync;
        out.vblnk  <= in.vblnk;
        out.hcount <= in.hcount;
        out.hsync  <= in.hsync;
        out.hblnk  <= in.hblnk;
        out.rgb    <= rgb_nxt;
    end
end

always_comb begin
    rel_x = in.hcount - BOARD_X;
    rel_y = in.vcount - BOARD_Y;

    in_board = (in.hcount >= BOARD_X) && (in.hcount < BOARD_X + BOARD_W) &&
               (in.vcount >= BOARD_Y) && (in.vcount < BOARD_Y + BOARD_H);

    col = rel_x / CELL_W;
    row = rel_y / CELL_H;
    cell_x = rel_x % CELL_W;
    cell_y = rel_y % CELL_H;


    char_idx = (row * 6) + col;
    if (char_idx > 17) char_idx = 17; 
    my_traits = CHAR_TRAITS[char_idx];

    head_lx = cell_x - HEAD_X_OFF;
    head_ly = cell_y - HEAD_Y_OFF;
    
    in_head_area = (cell_x >= HEAD_X_OFF && cell_x < HEAD_X_OFF + HEAD_W) &&
                   (cell_y >= HEAD_Y_OFF && cell_y < HEAD_Y_OFF + HEAD_H);

    if (in_head_area)
        head_pixel = head_rom[head_ly * HEAD_W + head_lx];
    else
        head_pixel = 12'hf_0_f; 

    is_hat     = my_traits[1] && (cell_x >= 20 && cell_x < 120) && (cell_y >= 30 && cell_y < 60);
    is_glasses = my_traits[2] && (cell_x >= 35 && cell_x < 105) && (cell_y >= 80 && cell_y < 100);
    is_beard   = my_traits[0] && (cell_x >= 40 && cell_x < 100) && (cell_y >= 130 && cell_y < 160);

    if (in.vblnk || in.hblnk) begin
        rgb_nxt = 12'h0_0_0;
        
   
    end else if (in_board && in.rgb == 12'hf_f_f) begin
        if (is_hat)          rgb_nxt = 12'h2_2_d;
        else if (is_glasses) rgb_nxt = 12'h0_0_0; 
        else if (is_beard)   rgb_nxt = 12'h5_2_0; 

    else if (in_head_area && head_pixel != 12'hf_0_f) begin
        if (head_pixel == 12'hf_f_f) 
            rgb_nxt = my_traits[3] ? 12'h8_5_2 : 12'hf_d_b; 
        else
            rgb_nxt = head_pixel;    // reszta tak samo, mozna zmienic kolor oczu jest 12'h9_5_3
            
    end else begin
        rgb_nxt = in.rgb; 
    end
    
end else begin
    rgb_nxt = in.rgb; 
end
end

endmodule
