/**
 * Pamięć ROM przechowująca 256 znaków do wyświetlenia w oknie tekstowym.
 */
module char_rom #(
    parameter string TEXT = "Tekst ktory sie nie wystwietli"
)(
    input  logic       clk,
    input  logic [7:0] char_xy,
    output logic [6:0] char_code
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [7:0] rom [0:255];

    initial begin
        for (int i = 0; i < 256; i++) begin
            if (i < TEXT.len())
                rom[i] = TEXT[i];
            else
                rom[i] = 8'h20; // Spacja
        end
    end

    always_ff @(posedge clk) begin
        char_code <= rom[char_xy][6:0];
    end

endmodule