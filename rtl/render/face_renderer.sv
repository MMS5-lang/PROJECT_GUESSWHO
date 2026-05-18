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

localparam int HAIR_1_W = 132;   
localparam int HAIR_1_H = 64;  
localparam int HAIR_1_X_OFF = 4; 
localparam int HAIR_1_Y_OFF = 27;

localparam int HAIR_LONG_W = 130;   
localparam int HAIR_LONG_H = 140;  
localparam int HAIR_LONG_X_OFF = 4; 
localparam int HAIR_LONG_Y_OFF = 35;

localparam int PAYOT_W = 8;   
localparam int PAYOT_Y_START = HAIR_1_Y_OFF + HAIR_1_H; 
localparam int PAYOT_Y_END = PAYOT_Y_START + 80;        
localparam int PAYOT_L_X = HEAD_X_OFF + 12 ;                  
localparam int PAYOT_R_X = HEAD_X_OFF + HEAD_W - PAYOT_W - 12; 

logic [11:0] head_rom [0:HEAD_W*HEAD_H-1];
logic [11:0] glasses_rom [0:GLASSES_W*GLASSES_H-1];
logic [11:0] hair_1_rom [0:HAIR_1_W*HAIR_1_H-1];
logic [11:0] hair_long_rom [0:HAIR_LONG_W*HAIR_LONG_H-1];

initial begin
    $readmemh("../../head_shape.dat", head_rom);
    $readmemh("../../glasses.dat", glasses_rom);
    $readmemh("../../hair_1.dat", hair_1_rom);
    $readmemh("../../hair_long.dat", hair_long_rom);
end

// Format 4-bitowy: [7] wlosy dlugie (2) , [6] wlosy krotkie(1), [5] kolor wlosow (blond brunet) [4] kolor oczu (niebieskie, zielone), [3] Kolor skóry (bialy, czarny), [2] Okulary (tak, nie), [1] Czapka(tak, nie), [0] pejsy (tak, nie)
localparam logic [7:0] CHAR_TRAITS [0:17] = '{
    8'b11000001, 8'b11100001, 8'b01000101, 8'b00100111, 8'b10110100, 8'b10000101,
    8'b00100110, 8'b11001110, 8'b10001000, 8'b10111001, 8'b11110101, 8'b11001011, 
    8'b01001100, 8'b01111001, 8'b10101110, 8'b01011111, 8'b00101001, 8'b10110001  
};

logic in_board;
logic [10:0] rel_x, rel_y;
logic [10:0] cell_x, cell_y;
logic [2:0] row;
logic [3:0] col;
logic [6:0] char_idx;
logic [7:0] my_traits;

logic [10:0] head_lx, head_ly;
logic [11:0] head_pixel;
logic in_head_area;

logic [10:0] glasses_lx, glasses_ly;
logic [11:0] glasses_pixel;
logic in_glasses_area;

logic [10:0] hair_1_lx, hair_1_ly;
logic [11:0] hair_1_pixel;
logic in_hair_1_area;

logic [10:0] hair_long_lx, hair_long_ly;
logic [11:0] hair_long_pixel;
logic in_hair_long_area;

logic is_payot;

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

    //GŁOWA 
    head_lx = cell_x - HEAD_X_OFF;
    head_ly = cell_y - HEAD_Y_OFF;
    in_head_area = (cell_x >= HEAD_X_OFF && cell_x < HEAD_X_OFF + HEAD_W) &&
                   (cell_y >= HEAD_Y_OFF && cell_y < HEAD_Y_OFF + HEAD_H);

    if (in_head_area)
        head_pixel = head_rom[head_ly * HEAD_W + head_lx];
    else
        head_pixel = 12'hf_0_f; 

    //OKULARY
    glasses_lx = cell_x - GLASSES_X_OFF;
    glasses_ly = cell_y - GLASSES_Y_OFF;
    in_glasses_area = my_traits[2] && 
                      (cell_x >= GLASSES_X_OFF && cell_x < GLASSES_X_OFF + GLASSES_W) &&
                      (cell_y >= GLASSES_Y_OFF && cell_y < GLASSES_Y_OFF + GLASSES_H);

    if (in_glasses_area)
        glasses_pixel = glasses_rom[glasses_ly * GLASSES_W + glasses_lx];
    else
        glasses_pixel = 12'hf_0_f;

    // WŁOSY 1
    hair_1_lx = cell_x - HAIR_1_X_OFF;
    hair_1_ly = cell_y - HAIR_1_Y_OFF;
    in_hair_1_area = my_traits[6] && 
                     (cell_x >= HAIR_1_X_OFF && cell_x < HAIR_1_X_OFF + HAIR_1_W) &&
                     (cell_y >= HAIR_1_Y_OFF && cell_y < HAIR_1_Y_OFF + HAIR_1_H);

    if (in_hair_1_area)
        hair_1_pixel = hair_1_rom[hair_1_ly * HAIR_1_W + hair_1_lx];
    else 
        hair_1_pixel = 12'hf_0_f;

    // WŁOSY DLUGIE
    hair_long_lx = cell_x - HAIR_LONG_X_OFF;
    hair_long_ly = cell_y - HAIR_LONG_Y_OFF;
    in_hair_long_area = my_traits[7] && 
                     (cell_x >= HAIR_LONG_X_OFF && cell_x < HAIR_LONG_X_OFF + HAIR_LONG_W) &&
                     (cell_y >= HAIR_LONG_Y_OFF && cell_y < HAIR_LONG_Y_OFF + HAIR_LONG_H);

    if (in_hair_long_area)
        hair_long_pixel = hair_long_rom[hair_long_ly * HAIR_LONG_W + hair_long_lx];
    else 
        hair_long_pixel = 12'hf_0_f;
    

    // PEJSY
    is_payot = my_traits[0] && 
               (cell_y >= PAYOT_Y_START && cell_y < PAYOT_Y_END) &&
               ((cell_x >= PAYOT_L_X && cell_x < PAYOT_L_X + PAYOT_W) || 
                (cell_x >= PAYOT_R_X && cell_x < PAYOT_R_X + PAYOT_W));

    if (in.vblnk || in.hblnk) begin
        rgb_nxt = 12'h0_0_0;
   
    end else if (in_board && in.rgb == 12'hf_f_f) begin
    
        if (in_glasses_area && glasses_pixel != 12'hf_0_f) begin
            rgb_nxt = glasses_pixel;
            
        end else if (in_hair_1_area && hair_1_pixel != 12'hf_0_f) begin   
            if (hair_1_pixel == 12'h3_2_2)
                rgb_nxt = my_traits[5] ? 12'hd_b_7 : 12'h2_1_0; 
            else if (hair__pixel == 12'h0_0_0)
                rgb_nxt = my_traits[5] ? 12'hd_b_7 : 12'h2_1_0;
            else
                rgb_nxt = hair_1_pixel;

        end else if (in_hair_long_area && hair_long_pixel != 12'hf_0_f) begin   
            if (hair_long_pixel == 12'h3_2_2)
                rgb_nxt = my_traits[5] ? 12'hd_b_7 : 12'h2_1_0;
            else if (hair_long_pixel == 12'h0_0_0)
                rgb_nxt = my_traits[5] ? 12'hd_b_7 : 12'h2_1_0;
            else
                rgb_nxt = hair_long_pixel;            
                
        end else if (is_payot) begin   
            rgb_nxt = my_traits[5] ? 12'hd_b_7 : 12'h2_1_0; 

        end else if (in_head_area && head_pixel != 12'hf_0_f) begin
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