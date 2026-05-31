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
 * Top level synthesizable module including the project top and all the FPGA-referred modules.
 */

module top_basys3 #(
    parameter int RESET_DEBOUNCE_COUNTER_BITS = 21
) (
    input  wire clk,
    input  wire btnC,
    output wire Vsync,
    output wire Hsync,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output wire JA1,
    output wire JA2,
    input  wire [0:0] sw,
    input  wire JA3,
    inout  wire PS2Clk,
    inout  wire PS2Data
);

timeunit 1ns;
timeprecision 1ps;

/**
 * Local variables and signals
 */
logic clk_100mhz;
logic clk_65mhz;
logic clk_locked;
logic pclk_mirror;
logic raw_rst_n;
logic rst_65mhz_n;
logic rst_100mhz_n;
logic reset_released_db;

/**
 * Signal assignments
 */
assign JA1   = pclk_mirror;
assign raw_rst_n = clk_locked && !btnC && reset_released_db;

/**
 * FPGA submodule placement
 */
clk_wiz_0 u_clk_wiz (
    .clk        (clk),
    .clk100MHz  (clk_100mhz),
    .clk65MHz   (clk_65mhz),
    .locked     (clk_locked)
);

debounce #(
    .N (RESET_DEBOUNCE_COUNTER_BITS)
) u_reset_debounce (
    .clk      (clk_100mhz),
    .reset    (!clk_locked),
    .sw       (!btnC),
    .db_level (reset_released_db),
    .db_tick  ()
);

reset_sync u_rst_65mhz_sync (
    .clk    (clk_65mhz),
    .arst_n (raw_rst_n),
    .rst_n  (rst_65mhz_n)
);

reset_sync u_rst_100mhz_sync (
    .clk    (clk_100mhz),
    .arst_n (raw_rst_n),
    .rst_n  (rst_100mhz_n)
);

/* Mirror pclk on a pin for use by the testbench. */
ODDR pclk_oddr (
    .Q  (pclk_mirror),
    .C  (clk_65mhz),
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
    .clk        (clk_65mhz),
    .clk_100mhz (clk_100mhz),
    .rst_n      (rst_65mhz_n),
    .rst_100mhz_n (rst_100mhz_n),
    .player_id  (sw[0]),
    .pmod_uart_rx (JA3),
    .ps2_clk    (PS2Clk),
    .ps2_data   (PS2Data),
    .pmod_uart_tx (JA2),
    .r          (vgaRed),
    .g          (vgaGreen),
    .b          (vgaBlue),
    .hs         (Hsync),
    .vs         (Vsync)
);

endmodule
