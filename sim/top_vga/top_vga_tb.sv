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
     * Main test - TESTOWANIE WIZUALNE POJEDYNCZYCH STANÓW FSM
     */
    initial begin
        $display("Rozpoczynam test renderowania stanow...");
       
        // 1. Inicjalizacja i Reset
        rst_n = 1'b0;
        capture_enabled = 1'b0;
        force dut.mouse_xpos = 12'd400; 
        force dut.mouse_ypos = 12'd300;
        force dut.left_click_pulse = 1'b0;
        force dut.right_click_pulse = 1'b0;
        

        //force dut.u_draw_bg.sw0 = 1'b1; 
        
        #200;
        rst_n = 1'b1;
        #1000;
 
        // =============================================================
        // MIEJSCE NA TESTOWANY STAN 
        // =============================================================
        
        // Opcja A: Ekran WYGRANEJ (Zwycięstwo)
        //force dut.u_game_core.state = S_WIN;

        // Opcja B: Ekran PRZEGRANEJ (Porażka)
        //force dut.u_game_core.state = S_LOSE;

        // Opcja C: Ruch Przeciwnika (Oczekiwanie)
        //force dut.u_game_core.state = S_OPPONENT_TURN;

        // Opcja D: Błąd połączenia UART
        //force dut.u_game_core.state = S_COMM_ERROR;

        // Opcja E: Ekran oczekiwania na przeciwnika przed startem
        //force dut.u_game_core.state = S_LOCAL_READY;

        // Opcja F: Własna tura (Możliwość strzelania)
         force dut.u_game_core.state = S_MY_TURN;
    
        /*
        // --- SCENARIUSZ 1: Wybrana postać w okienku UI ---
        // Symulujemy środek gry (nasza tura), postać o ID = 4.
    
        force dut.u_game_core.state = S_MY_TURN;
        force dut.u_game_core.local_secret_id = 5'd4; 
        force dut.u_game_core.selected_id = 5'd4;
        force dut.u_game_core.has_secret = 1'b1;
        */


       /*
        // --- SCENARIUSZ 2: Wyeliminowana połowa planszy (Niebieskie maski) ---
        // Ustawiamy maskę eliminacji. Każda '1' to wyeliminowana postać (przyciemniona).
        force dut.u_game_core.state = S_MY_TURN;
        force dut.u_game_core.local_secret_id = 5'd10; // Jakaś nasza postać
        force dut.u_game_core.has_secret = 1'b1;
        force dut.u_game_core.eliminated_mask = 18'b11_0000_0000_0000_1111; 
       */
      /*
        // --- SCENARIUSZ 3: Najechanie myszką na postać (Obrys/Hover) ---
        // Ustawiamy naszą turę i teleportujemy myszkę nad pierwszą kartę na planszy 
        force dut.u_game_core.state = S_MY_TURN;
        
        // Zmień te współrzędne X i Y, aby trafić w środek jakiejś karty na planszy
        // (zakładam, że pierwsza karta jest gdzieś w okolicach X=100, Y=150)
        force dut.mouse_xpos = 12'd100; 
        force dut.mouse_ypos = 12'd150; 
        */


        // --- SCENARIUSZ 4: Zaznaczony ostatni strzał (Czerwona maska) ---
        // Pokazujemy stan "WRONG_GUESS_FEEDBACK", czyli gracz strzelał i nie trafił.
        // Karta o ID = 7 powinna zaświecić się na czerwono.
        force dut.u_game_core.state = S_WRONG_GUESS_FEEDBACK;
        force dut.u_game_core.last_guess_id = 5'd7; 
     
        $display("Czekam na pelne klatki VGA...");
        wait_until_sync_low();
        capture_enabled = 1'b1;
        
        repeat (2) begin
            @(posedge capture_vs);
        end
        capture_enabled = 1'b0;

        $display("Gotowe! Sprawdz folder results/ (pliki .tif)");
        $finish;
    end
endmodule