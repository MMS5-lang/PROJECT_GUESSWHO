/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Small ROM with procedural traits for every Guess Who character.
 * Now expanded to 12-bit trait vectors.
 */

module face_traits_rom
import guess_who_pkg::*;
(
    output logic [11:0] traits,
    input  logic [CHAR_ID_W-1:0] char_id
);

timeunit 1ns;
timeprecision 1ps;

/*
 * Bity: [11]Broda, [10]Czapka_z_daszkiem, [9]Kapelusz,
 * [8]Zwykle_Okulary, [7]Wlosy_2(Dlugie), [6]Wlosy_1(Krotkie),
 * [5]Kolor_Wlosow, [4]Kolor_Oczu, [3]Kolor_Skory,
 * [2]Okulary_Przeciwsłoneczne, [1]Kolor_Czapki, [0]Pejsy.
 */
always_comb begin
    case (char_id)
        5'd0:  traits = 12'b1000_1000_1000;
        5'd1:  traits = 12'b0100_0101_1100;
        5'd2:  traits = 12'b0010_1000_0000;
        5'd3:  traits = 12'b1011_1000_0001;
        5'd4:  traits = 12'b0000_1011_1100;
        5'd5:  traits = 12'b0001_1010_0000;
        5'd6:  traits = 12'b1100_0011_0010;
        5'd7:  traits = 12'b1010_0101_1100;
        5'd8:  traits = 12'b0000_1000_0000;
        5'd9:  traits = 12'b0000_0110_1000;
        5'd10: traits = 12'b0100_1000_0000;
        5'd11: traits = 12'b0001_0100_1010;
        5'd12: traits = 12'b1011_1011_1001;
        5'd13: traits = 12'b1000_0101_0000;
        5'd14: traits = 12'b0100_1000_1111;
        5'd15: traits = 12'b0000_1001_1000;
        5'd16: traits = 12'b0000_0110_0100;
        5'd17: traits = 12'b1001_0001_0000;
        default: traits = 12'b0000_0000_0000;
    endcase
end

endmodule
