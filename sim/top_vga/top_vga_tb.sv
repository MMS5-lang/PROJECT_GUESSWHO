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
 * Testbench for top_vga.
 */

module top_vga_tb;

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local parameters
     */
    localparam real CLK_PERIOD = 15.384615;     // 65 MHz
    localparam int CLK_100MHZ_PERIOD = 10;      // 100 MHz
    localparam int RST_START_TIME = 30;
    localparam int RST_ACTIVE_TIME = 30;

    /**
     * Local variables and signals
     */
    logic clk;
    logic clk_100mhz;
    logic rst_n;
    tri1  ps2_clk;
    tri1  ps2_data;
    wire  vs;
    wire  hs;
    wire [3:0] r;
    wire [3:0] g;
    wire [3:0] b;

    /**
     * Clock generation
     */
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) begin
            clk = ~clk;
        end
    end

    initial begin
        clk_100mhz = 1'b0;
        forever #(CLK_100MHZ_PERIOD / 2) begin
            clk_100mhz = ~clk_100mhz;
        end
    end

    /**
     * Submodule instances
     */
    top_vga dut (
        .clk        (clk),
        .clk_100mhz (clk_100mhz),
        .rst_n      (rst_n),
        .ps2_clk    (ps2_clk),
        .ps2_data   (ps2_data),
        .vs         (vs),
        .hs         (hs),
        .r          (r),
        .g          (g),
        .b          (b)
    );

    tiff_writer #(
        .XDIM(16'd1344),
        .YDIM(16'd806),
        .FILE_DIR("../../results")
    ) u_tiff_writer (
        .clk(clk),
        .r({r,r}),
        .g({g,g}),
        .b({b,b}),
        .go(vs)
    );

    /**
     * Main test
     */
    initial begin
        rst_n = 1'b1;
        #(RST_START_TIME);
        rst_n = 1'b0;
        #(RST_ACTIVE_TIME);
        rst_n = 1'b1;

        $display("If simulation ends before the testbench");
        $display("completes, use the menu option to run all.");
        $display("Prepare to wait a long time...");
        $display("Initial HS state: %b", hs);

        wait (vs == 1'b0);
        @(negedge vs) begin
            $display("Info: negedge VS at %t", $time);
        end
        @(negedge vs) begin
            $display("Info: negedge VS at %t", $time);
        end

        $display("Simulation is over, check the waveforms.");
        $finish;
    end

endmodule
