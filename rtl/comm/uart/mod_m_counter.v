/**
 * UART example support module copied from the provided UART project.
 *
 * Original source:
 * - Listing 4.11 from the provided UART.rar project.
 * - Based on examples used in the AGH UEC2 UART lab materials.
 *
 * Description:
 * Modulo-M counter used as the UART baud-rate tick generator.
 */

module mod_m_counter
   #(
    parameter N = 4,
              M = 10
   )
   (
    input wire clk, reset,
    output wire max_tick,
    output wire [N-1:0] q
   );

   reg [N-1:0] r_reg;
   wire [N-1:0] r_next;

   always @(posedge clk, posedge reset)
      if (reset)
         r_reg <= 0;
      else
         r_reg <= r_next;

   assign r_next = (r_reg == (M - 1)) ? 0 : r_reg + 1;
   assign q = r_reg;
   assign max_tick = (r_reg == (M - 1)) ? 1'b1 : 1'b0;

endmodule
