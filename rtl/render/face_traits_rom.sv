/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Small ROM with procedural traits for every Guess Who character.
 */

module face_traits_rom (
    input  logic [guess_who_pkg::CHAR_ID_W-1:0] char_id,
    output logic [7:0] traits
);

timeunit 1ns;
timeprecision 1ps;

import guess_who_pkg::*;

always_comb begin
    case (char_id)
        5'd0:  traits = 8'b10000001;
        5'd1:  traits = 8'b01100001;
        5'd2:  traits = 8'b00000101;
        5'd3:  traits = 8'b00100111;
        5'd4:  traits = 8'b10110100;
        5'd5:  traits = 8'b10000101;
        5'd6:  traits = 8'b00100110;
        5'd7:  traits = 8'b10001110;
        5'd8:  traits = 8'b10001000;
        5'd9:  traits = 8'b10111001;
        5'd10: traits = 8'b01110101;
        5'd11: traits = 8'b10001011;
        5'd12: traits = 8'b01001100;
        5'd13: traits = 8'b01111001;
        5'd14: traits = 8'b10101110;
        5'd15: traits = 8'b01011111;
        5'd16: traits = 8'b01101001;
        5'd17: traits = 8'b10010000;
        default: traits = 8'b00000000;
    endcase
end

endmodule
