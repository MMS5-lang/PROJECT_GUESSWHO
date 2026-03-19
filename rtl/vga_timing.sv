/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Vga timing controller.
 */

module vga_timing (
        input  logic clk,
        input  logic rst,
        output logic [10:0] vcount,
        output logic vsync,
        output logic vblnk,
        output logic [10:0] hcount,
        output logic hsync,
        output logic hblnk
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;


/* Local variables and signals */

    logic [10:0] vcount_nxt, hcount_nxt;
    logic vsync_nxt, vblnk_nxt, hsync_nxt, hblnk_nxt;
    
    /* Internal logic */
    
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            vcount <= 'b0;
            hcount<= 'b0;            
        end else begin
            vcount <= vcount_nxt;
            hcount <= hcount_nxt;
        end
    end
    
    always_comb begin
        vcount_nxt = vcount;
        hcount_nxt = hcount;
            if (hcount == HOR_TOTAL_TIME - 1) begin
                hcount_nxt = '0;
                if (vcount == VER_TOTAL_TIME - 1) begin
                    vcount_nxt = '0;
                end else begin
                    vcount_nxt = vcount + 1;
                end
            end else begin
                hcount_nxt = hcount + 1;
            end
        end
    

endmodule
