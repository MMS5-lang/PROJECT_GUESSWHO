/**
 * Copyright (C) 2026 AGH University of Science and Technology
 * MTM UEC
 * Author: Piotr Kaczmarczyk
 * Modified by: Lukasz Kadlubowski
 *
 * Description:
 * Testbench for vga_timing module.
 */

 module vga_timing_tb;
    timeunit 1ns;
    timeprecision 1ps;
    import vga_pkg::*;

    
    /* -----------------------------------------------------------------------------
     * Local parameters
     * -------------------------------------------------------------------------- */
    localparam CLK_PERIOD = 25; // 40 MHz clock
    localparam RST_START_TIME = 1.25*CLK_PERIOD;
    localparam RST_ACTIVE_TIME = 2.00*CLK_PERIOD;
    
    /* -----------------------------------------------------------------------------
     * Local variables and signals
     * -------------------------------------------------------------------------- */
    logic clk;
    logic rst_n;
    
    logic [10:0] vcount, hcount;
    logic vsync, hsync, vblnk, hblnk;
    
    /* -----------------------------------------------------------------------------
     * Clock and reset generation
     * -------------------------------------------------------------------------- */
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    initial begin
        rst_n = 1'b1;
        #(RST_START_TIME) rst_n = 1'b0;
        #(RST_ACTIVE_TIME) rst_n = 1'b1;
    end
    
    /* -----------------------------------------------------------------------------
     * Dut placement
     * -------------------------------------------------------------------------- */
    vga_timing dut(
        .clk,
        .rst_n,
        .vcount,
        .vsync,
        .vblnk,
        .hcount,
        .hsync,
        .hblnk
    );
    
    /* -----------------------------------------------------------------------------
     * Immediate assertions
     * -------------------------------------------------------------------------- */
    
    /* hcount : max value */
    assert property (
        /* run assertion at each positive clock edge: */
        @(posedge clk)
        /* except during reset (optional): */
        disable iff (!rst_n || $realtime < RST_START_TIME)
        /* check whether this condition is true: */
        hcount < HOR_TOTAL_TIME
    ) else begin
        /* if condition is not true, display error message */
        $error("hcount: max value exceeded");
    end
    
    /* hcount : zero after max value */
    assert property (
        @(posedge clk)
        hcount == (HOR_TOTAL_TIME - 1) |=> hcount == 0
    ) else begin
        $error("hcount: return to 0 after expected max value failed");
    end
    
    /* hcount : incrementation with every clock tick */
    assert property (
        @(posedge clk)
        disable iff (!rst_n)
        (hcount < HOR_TOTAL_TIME - 1) |=> (hcount == $past(hcount) + 1)
    ) else begin
        $error("hcount: increment at every clk failed");
    end
    
    /* vcount : max value */
    assert property (
        @(posedge clk)
        disable iff (!rst_n || $realtime < RST_START_TIME)
        vcount < VER_TOTAL_TIME
    ) else begin
        $error("vcount: max value exceeded");
    end
    
    /* vcount : zero after max value */
    assert property (
        @(posedge clk)
        vcount == (VER_TOTAL_TIME - 1) |=> ##(HOR_TOTAL_TIME - 1) vcount == 0
    ) else begin
        $error("vcount: return to 0 after expected max value failed");
    end
    
    /* vcount : incrementation with every clock tick */
    assert property (
        @(posedge clk)
        (hcount == HOR_TOTAL_TIME - 1) && vcount < (VER_TOTAL_TIME - 1) |=> (vcount == $past(vcount) + 1)
    ) else begin
        $error("vcount: increment at hcount reset failed");
    end
    
    /* hblnk : set */
    assert property (
        @(posedge clk)
        hcount >= HOR_BLANK_START && hcount < HOR_BLANK_START + HOR_BLANK_TIME - 1 |-> hblnk
    ) else begin
        $error("hblnk: set failed");
    end
    
    /* hblnk : clear */
    assert property (
        @(posedge clk)
        hcount < HOR_BLANK_START |-> !hblnk
    ) else begin
        $error("hblnk: clear failed");
    end
    
    /* vblnk : set */
    assert property (
        @(posedge clk)
        vcount >= VER_BLANK_START && vcount < VER_BLANK_START + VER_BLANK_TIME - 1 |-> vblnk
    ) else begin
        $error("vblnk set failed");
    end
    
    /* vblnk : clear */
    assert property (
        @(posedge clk)
        vcount < VER_BLANK_START |-> !vblnk
    ) else begin
        $error("vblnk: clear failed");
    end
    
    /* hsync : set */
    assert property (
        @(posedge clk)
        hcount >= HOR_SYNC_START && hcount < HOR_SYNC_START + HOR_SYNC_TIME - 1 |-> hsync
    ) else begin
        $error("hsync: set failed");
    end
    
    /* hsync : clear */
    assert property (
        @(posedge clk)
        (hcount < HOR_SYNC_START) || (hcount > (HOR_SYNC_START + HOR_SYNC_TIME - 1)) |-> !hsync
    ) else begin
        $error("hsync: clear failed");
    end
    
    /* vsync : set */
    assert property (
        @(posedge clk)
        vcount >= VER_SYNC_START && vcount < VER_SYNC_START + VER_SYNC_TIME - 1 |-> vsync
    ) else begin
        $error("vsync: set failed");
    end
    
    /* vsync : clear */
    assert property (
        @(posedge clk)
        vcount < VER_SYNC_START || vcount > VER_SYNC_START + VER_SYNC_TIME - 1 |-> !vsync
    ) else begin
        $error("vsync: clear failed");
    end
    
    /* -----------------------------------------------------------------------------
     * Main test
     * -------------------------------------------------------------------------- */
    initial begin
        // Let assertions observe several complete frames.
        #20ms;
        $finish;
    end
    
endmodule
    
