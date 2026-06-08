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
* Testbench for top_vga.
*/

module top_vga_tb;

    timeunit 1ns;
    timeprecision 1ps;
   
    // Importujemy pakiet, aby móc używać nazw stanów zamiast liczb!
    import guess_who_pkg::*;
    import vga_pkg::*;
 
    /**
     * Local parameters
     */
    localparam real CLK_PERIOD = 15.384615;     // 65 MHz
    localparam int CLK_100MHZ_PERIOD = 10;      // 100 MHz
 
    /**
     * Local variables and signals
     */
    logic clk;
    logic clk_100mhz;
    logic rst_n;
    tri1  ps2_clk;
    tri1  ps2_data;
   
    // Edytor DVT będzie ostrzegał, że te sygnały nie są czytane - zignoruj to.
    // W testbenchu to normalne, że podłączamy wyjścia, ale nie zawsze ich używamy.
    wire  vs;
    wire  hs;
    wire [3:0] r;
    wire [3:0] g;
    wire [3:0] b;
    wire pmod_uart_tx;
    logic capture_enabled;
    wire capture_vs;
    wire active_pixel;

    assign capture_vs = capture_enabled && vs;
    assign active_pixel = (dut.if_mouse.hcount < HOR_PIXELS) &&
                          (dut.if_mouse.vcount < VER_PIXELS);
 
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
        .rst_100mhz_n (rst_n),
        .player_id      (1'b0),
        .pmod_uart_rx (1'b1),
        .ps2_clk    (ps2_clk),
        .ps2_data   (ps2_data),
        .pmod_uart_tx (pmod_uart_tx),
        .vs         (vs),
        .hs         (hs),
        .r          (r),
        .g          (g),
        .b          (b)
    );
 
    tiff_writer #(
        .XDIM(HOR_PIXELS),
        .YDIM(VER_PIXELS),
        .FILE_DIR("../../results"),
        .MAX_FRAMES(3)
    ) u_tiff_writer (
        .clk(clk),
        .r({r,r}),
        .g({g,g}),
        .b({b,b}),
        .pixel_valid(active_pixel),
        .go(capture_vs)
    );

    task automatic wait_until_sync_low;
    begin
        @(posedge clk iff rst_n &&
            (dut.if_tim.vcount == VER_SYNC_START + 1) &&
            (dut.if_tim.hcount == 11'd0));
    end
    endtask
 
    /**
     * Main test - SYMULACJA Z LOGIKĄ GRY I WIRTUALNĄ MYSZKĄ
     */
    initial begin
        $display("Rozpoczynam test z pelna logika gry...");
       
        rst_n = 1'b0;
        capture_enabled = 1'b0;
        force dut.mouse_xpos = 12'd0;
        force dut.mouse_ypos = 12'd0;
        force dut.left_click_pulse = 1'b0;
        force dut.right_click_pulse = 1'b0;

        //force dut.u_draw_bg.sw0 = 1'b1;
        #200;
        rst_n = 1'b1;
        #1000;
 
        force dut.u_game_core.state = S_MY_TURN;
        #20;
        release dut.u_game_core.state;
        #1000;
 
        force dut.mouse_xpos = 12'd250;
        force dut.mouse_ypos = 12'd100;
        #500;
 
        $display("Klikam lewym przyciskiem myszy...");
        force dut.right_click_pulse = 1'b1;
        #50;
        force dut.right_click_pulse = 1'b0;
 
        #1000;
        $display("Czekam na trzy pelne klatki VGA...");
        wait_until_sync_low();
        capture_enabled = 1'b1;
        repeat (4) begin
            @(posedge capture_vs);
        end
        capture_enabled = 1'b0;

        $display("Gotowe! Sprawdz folder results/");
        $finish;
    end

endmodule
