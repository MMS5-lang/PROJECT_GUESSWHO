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

localparam int HEAD_W = 132;   
localparam int HEAD_H = 132;  
localparam int HEAD_X_OFF = 4; 
localparam int HEAD_Y_OFF = 55; 

localparam int GLASSES_W = 112;   
localparam int GLASSES_H = 24;  
localparam int GLASSES_X_OFF = 13; 
localparam int GLASSES_Y_OFF = 92;


logic [11:0] head_rom [0:HEAD_W*HEAD_H-1];
logic [11:0] glasses_rom [0:GLASSES_W*GLASSES_H-1];

initial begin
    $readmemh("../../head_shape.dat", head_rom);
    $readmemh("../../glasses.dat", glasses_rom);
end

// Format 4-bitowy: [4] kolor oczu (niebieskie, zielone), [3] Kolor skóry (bialy, czarny), [2] Okulary (tak, nie), [1] Czapka(tak, nie), [0] Broda (tak, nie)
localparam logic [4:0] CHAR_TRAITS [0:17] = '{
    5'b00000, 5'b00001, 5'b00010, 5'b10011, 5'b10100, 5'b00101,
    5'b10110, 5'b00111, 5'b01000, 5'b11001, 5'b11010, 5'b01011, 
    5'b01100, 5'b11101, 5'b01110, 5'b01111, 5'b10100, 5'b11000  
};

logic in_board;
logic [10:0] rel_x, rel_y;
logic [10:0] cell_x, cell_y;
logic [2:0] row;
logic [3:0] col;
logic [4:0] char_idx;
logic [4:0] my_traits;

logic [10:0] head_lx, head_ly;
logic [11:0] head_pixel;
logic in_head_area;

logic [10:0] glasses_lx, glasses_ly;
logic [11:0] glasses_pixel;
logic in_glasses_area;


logic is_hat, is_beard;

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

    glasses_lx = cell_x - GLASSES_X_OFF;
    glasses_ly = cell_y - GLASSES_Y_OFF;
                   
                   // Ważne: Sprawdzamy, czy w obszarze okularów ORAZ czy postać w ogóle ma na nie "gen" (my_traits[2])
    in_glasses_area = my_traits[2] && 
                                     (cell_x >= GLASSES_X_OFF && cell_x < GLASSES_X_OFF + GLASSES_W) &&
                                     (cell_y >= GLASSES_Y_OFF && cell_y < GLASSES_Y_OFF + GLASSES_H);
    if (in_head_area)
        head_pixel = head_rom[head_ly * HEAD_W + head_lx];
    else
        head_pixel = 12'hf_0_f; 

    if (in_glasses_area)
        glasses_pixel = glasses_rom[glasses_ly * GLASSES_W + glasses_lx];
    else
        glasses_pixel = 12'hf_0_f;

    is_hat     = my_traits[1] && (cell_x >= 20 && cell_x < 120) && (cell_y >= 30 && cell_y < 60);
    is_beard   = my_traits[0] && (cell_x >= 40 && cell_x < 100) && (cell_y >= 130 && cell_y < 160);

    if (in.vblnk || in.hblnk) begin
        rgb_nxt = 12'h0_0_0;
        
   
    end else if (in_board && in.rgb == 12'hf_f_f) begin
        if (is_hat)          rgb_nxt = 12'h2_2_d;
        else if (in_glasses_area && glasses_pixel != 12'hf_0_f) begin
            rgb_nxt = glasses_pixel;
        end else if (is_beard)   rgb_nxt = 12'h5_2_0; 

    else if (in_head_area && head_pixel != 12'hf_0_f) begin
        if (head_pixel == 12'hf_f_f) 
            rgb_nxt = my_traits[3] ? 12'h8_5_2 : 12'hf_d_b; 
        else if (head_pixel == 12'h9_5_3)   
            rgb_nxt = my_traits[4] ? 12'h4_a_f : 12'h3_4_1; 
        else
            rgb_nxt = head_pixel;    
            
    end else begin
        rgb_nxt = in.rgb; 
    end
    
end else begin
    rgb_nxt = in.rgb; 
end
end

endmodule
