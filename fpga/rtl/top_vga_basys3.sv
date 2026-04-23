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

    wire clk_100MHz;
    wire clk_40MHz;
    wire locked;
    wire pclk_mirror;
    wire rst_btn_n;
    wire rst_100MHz_n;
    wire rst_40MHz_n;
    (* ASYNC_REG = "TRUE" *) logic [1:0] rst_100MHz_shift;
    (* ASYNC_REG = "TRUE" *) logic [1:0] rst_40MHz_shift;

    // For details on synthesis attributes used above, see AMD Xilinx UG 901:
    // https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/Synthesis-Attributes


    /**
     * Signal assignments
     */

    assign JA1 = pclk_mirror;
    assign rst_btn_n = !btnC;
    assign rst_100MHz_n = rst_100MHz_shift[1];
    assign rst_40MHz_n  = rst_40MHz_shift[1];


    /**
     * FPGA submodule placement
     */
 

    clk_wiz_0 u_clk_wiz (
        .clk        (clk),
        .clk_100MHz (clk_100MHz),
        .clk_40MHz  (clk_40MHz),
        .locked     (locked)
    );
    // Mirror pclk on a pin for use by the testbench;
    // not functionally required for this design to work.

    ODDR pclk_oddr (
        .Q(pclk_mirror),
        .C(clk_40MHz),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );

    /**
     * Reset synchronization
     */
    always_ff @(posedge clk_100MHz or negedge rst_btn_n) begin
        if (!rst_btn_n) begin
            rst_100MHz_shift <= 2'b00;
        end else if (!locked) begin
            rst_100MHz_shift <= 2'b00;
        end else begin
            rst_100MHz_shift <= {rst_100MHz_shift[0], 1'b1};
        end
    end

    always_ff @(posedge clk_40MHz or negedge rst_btn_n) begin
        if (!rst_btn_n) begin
            rst_40MHz_shift <= 2'b00;
        end else if (!locked) begin
            rst_40MHz_shift <= 2'b00;
        end else begin
            rst_40MHz_shift <= {rst_40MHz_shift[0], 1'b1};
        end
    end


    /**
     * Project functional top module
     */

    top_vga u_top_vga (
        .clk          (clk_40MHz),
        .clk_100MHz   (clk_100MHz),
        .rst_n        (rst_40MHz_n),
        .rst_100MHz_n (rst_100MHz_n),
        .ps2_clk      (PS2Clk),
        .ps2_data     (PS2Data),
        .r            (vgaRed),
        .g            (vgaGreen),
        .b            (vgaBlue),
        .hs           (Hsync),
        .vs           (Vsync)
    );

endmodule
