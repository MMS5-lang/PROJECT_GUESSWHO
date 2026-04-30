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
 * Top level synthesizable module including the project top and all the FPGA-referred modules.
 */

module top_vga_basys3 (
        input  wire clk,
        input  wire btnC,
        inout  wire PS2Clk,
        inout  wire PS2Data,
        output wire Vsync,
        output wire Hsync,
        output wire [3:0] vgaRed,
        output wire [3:0] vgaGreen,
        output wire [3:0] vgaBlue,
        output wire JA1
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */
    logic clk_100mhz;
    logic clk_40mhz;
    logic pclk_mirror;
    logic rst_n;

    /**
     * Signal assignments
     */
    assign JA1   = pclk_mirror;
    assign rst_n = !btnC;

    /**
     * FPGA submodule placement
     */
    clk_wiz_0 u_clk_wiz (
        .clk        (clk),
        .clk_100MHz (clk_100mhz),
        .clk_40MHz  (clk_40mhz),
        .locked     ()
    );

    // Mirror pclk on a pin for use by the testbench.
    ODDR pclk_oddr (
        .Q  (pclk_mirror),
        .C  (clk_40mhz),
        .CE (1'b1),
        .D1 (1'b1),
        .D2 (1'b0),
        .R  (1'b0),
        .S  (1'b0)
    );

    /**
     * Project functional top module
     */
    top_vga u_top_vga (
        .clk        (clk_40mhz),
        .clk_100mhz (clk_100mhz),
        .rst_n      (rst_n),
        .ps2_clk    (PS2Clk),
        .ps2_data   (PS2Data),
        .r          (vgaRed),
        .g          (vgaGreen),
        .b          (vgaBlue),
        .hs         (Hsync),
        .vs         (Vsync)
    );

endmodule
