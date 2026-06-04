/**
 * San Jose State University
 * EE178 Lab #4
 * Author: Miłosz M. Karolina M.
 *
 * Based on work by prof. Eric Crabilla.
 *
 * 2025  AGH University of Science and Technology
 * MTM UEC2
 *
 * Description:
 * Testbench for top_fpga.
 */

module top_fpga_tb;

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local parameters
     */
    localparam int CLK_PERIOD = 10;     // 100 MHz
    localparam int RST_START_TIME = 1000;
    localparam int RST_ACTIVE_TIME = 2000;

    /**
     * Local variables and signals
     */
    logic clk;
    logic rst_n;
    tri1  PS2Clk;
    tri1  PS2Data;
    wire  pclk;
    wire  pmod_uart_tx;
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

    /**
     * Submodule instances
     */
    top_basys3 #(
        .RESET_DEBOUNCE_COUNTER_BITS (4)
    ) dut (
        .clk      (clk),
        .btnC     (!rst_n),
        .sw       (1'b0),
        .PS2Clk   (PS2Clk),
        .PS2Data  (PS2Data),
        .Vsync    (vs),
        .Hsync    (hs),
        .vgaRed   (r),
        .vgaGreen (g),
        .vgaBlue  (b),
        .JA1      (pclk),
        .JA2      (pmod_uart_tx),
        .JA3      (1'b1)
    );

    tiff_writer #(
        .XDIM(16'd1344),
        .YDIM(16'd806),
        .FILE_DIR("../../results")
    ) u_tiff_writer (
        .clk(pclk),
        .r({r,r}),
        .g({g,g}),
        .b({b,b}),
        .pixel_valid(1'b1),
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
        if ($isunknown(pmod_uart_tx)) begin
            $warning("PMOD UART TX is unknown at %t.", $time);
        end else begin
            $display("Initial PMOD UART TX state: %b", pmod_uart_tx);
        end

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
