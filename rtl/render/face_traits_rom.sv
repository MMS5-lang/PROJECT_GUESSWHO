/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Small ROM with procedural traits for every Guess Who character.
 * Now expanded to 12-bit trait vectors.
 */

 module face_traits_rom (
    input  logic [guess_who_pkg::CHAR_ID_W-1:0] char_id,
    output logic [11:0] traits
);

timeunit 1ns;
timeprecision 1ps;

import guess_who_pkg::*;

// Bity: [11]Broda, [10]Czapka_z_daszkiem, [9]Kapelusz, [8]Zwykłe_Okulary, [7]Włosy_2(Długie), [6]Włosy_1(Krótkie)
//       [5]Kolor_Włosów(1=Blond,0=Brunet), [4]Kolor_Oczu(1=Ziel.,0=Nieb.), [3]Kolor_Skóry(1=Biała,0=Czarna)
//       [2]Okulary_Przeciwsłoneczne, [1]Kolor_Czapki(1=Czarna,0=Zielona), [0]Pejsy
always_comb begin
    case (char_id)
        5'd0:  traits = 12'b0000_0110_1000;
        5'd1:  traits = 12'b0100_0101_1000;
        5'd2:  traits = 12'b0010_1000_0000;
        5'd3:  traits = 12'b1011_1000_0001;
        5'd4:  traits = 12'b0000_1011_1100;
        5'd5:  traits = 12'b0000_0100_0001;
        5'd6:  traits = 12'b1000_0010_1010;
        5'd7:  traits = 12'b0011_0101_1000;
        5'd8:  traits = 12'b0000_1000_0000;
        5'd9:  traits = 12'b1000_0111_1001;
        5'd10: traits = 12'b0100_1000_1100;
        5'd11: traits = 12'b0010_0011_0000;
        5'd12: traits = 12'b0001_1010_1000;
        5'd13: traits = 12'b1000_0101_0000;
        5'd14: traits = 12'b0100_0110_1011;
        5'd15: traits = 12'b0000_1001_1000;
        5'd16: traits = 12'b0010_0110_0100;
        5'd17: traits = 12'b1001_0001_0000;
        default: traits = 12'b0000_0000_0000;
    endcase
end

endmodule