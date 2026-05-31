/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Miłosz M. Karolina M.
 *
 * Description:
 * Small 5x7 uppercase font used by the VGA text renderer.
 */

module font_rom (
    input  logic [7:0] char_code,
    input  logic [2:0] row,
    output logic [4:0] pixels
);

timeunit 1ns;
timeprecision 1ps;

always_comb begin
    pixels = 5'b00000;

    unique case (char_code)
        "A": begin
            case (row)
                3'd0: pixels = 5'b01110;
                3'd1: pixels = 5'b10001;
                3'd2: pixels = 5'b10001;
                3'd3: pixels = 5'b11111;
                3'd4: pixels = 5'b10001;
                3'd5: pixels = 5'b10001;
                3'd6: pixels = 5'b10001;
                default: pixels = 5'b00000;
            endcase
        end
        "B": begin
            case (row)
                3'd0: pixels = 5'b11110;
                3'd1: pixels = 5'b10001;
                3'd2: pixels = 5'b10001;
                3'd3: pixels = 5'b11110;
                3'd4: pixels = 5'b10001;
                3'd5: pixels = 5'b10001;
                3'd6: pixels = 5'b11110;
                default: pixels = 5'b00000;
            endcase
        end
        "C": begin
            case (row)
                3'd0: pixels = 5'b01111;
                3'd1: pixels = 5'b10000;
                3'd2: pixels = 5'b10000;
                3'd3: pixels = 5'b10000;
                3'd4: pixels = 5'b10000;
                3'd5: pixels = 5'b10000;
                3'd6: pixels = 5'b01111;
                default: pixels = 5'b00000;
            endcase
        end
        "E": begin
            case (row)
                3'd0: pixels = 5'b11111;
                3'd1: pixels = 5'b10000;
                3'd2: pixels = 5'b10000;
                3'd3: pixels = 5'b11110;
                3'd4: pixels = 5'b10000;
                3'd5: pixels = 5'b10000;
                3'd6: pixels = 5'b11111;
                default: pixels = 5'b00000;
            endcase
        end
        "G": begin
            case (row)
                3'd0: pixels = 5'b01110;
                3'd1: pixels = 5'b10001;
                3'd2: pixels = 5'b10000;
                3'd3: pixels = 5'b10111;
                3'd4: pixels = 5'b10001;
                3'd5: pixels = 5'b10001;
                3'd6: pixels = 5'b01110;
                default: pixels = 5'b00000;
            endcase
        end
        "I": begin
            case (row)
                3'd0: pixels = 5'b11111;
                3'd1: pixels = 5'b00100;
                3'd2: pixels = 5'b00100;
                3'd3: pixels = 5'b00100;
                3'd4: pixels = 5'b00100;
                3'd5: pixels = 5'b00100;
                3'd6: pixels = 5'b11111;
                default: pixels = 5'b00000;
            endcase
        end
        "J": begin
            case (row)
                3'd0: pixels = 5'b00111;
                3'd1: pixels = 5'b00010;
                3'd2: pixels = 5'b00010;
                3'd3: pixels = 5'b00010;
                3'd4: pixels = 5'b10010;
                3'd5: pixels = 5'b10010;
                3'd6: pixels = 5'b01100;
                default: pixels = 5'b00000;
            endcase
        end
        "K": begin
            case (row)
                3'd0: pixels = 5'b10001;
                3'd1: pixels = 5'b10010;
                3'd2: pixels = 5'b10100;
                3'd3: pixels = 5'b11000;
                3'd4: pixels = 5'b10100;
                3'd5: pixels = 5'b10010;
                3'd6: pixels = 5'b10001;
                default: pixels = 5'b00000;
            endcase
        end
        "L": begin
            case (row)
                3'd0: pixels = 5'b10000;
                3'd1: pixels = 5'b10000;
                3'd2: pixels = 5'b10000;
                3'd3: pixels = 5'b10000;
                3'd4: pixels = 5'b10000;
                3'd5: pixels = 5'b10000;
                3'd6: pixels = 5'b11111;
                default: pixels = 5'b00000;
            endcase
        end
        "M": begin
            case (row)
                3'd0: pixels = 5'b10001;
                3'd1: pixels = 5'b11011;
                3'd2: pixels = 5'b10101;
                3'd3: pixels = 5'b10101;
                3'd4: pixels = 5'b10001;
                3'd5: pixels = 5'b10001;
                3'd6: pixels = 5'b10001;
                default: pixels = 5'b00000;
            endcase
        end
        "N": begin
            case (row)
                3'd0: pixels = 5'b10001;
                3'd1: pixels = 5'b11001;
                3'd2: pixels = 5'b10101;
                3'd3: pixels = 5'b10011;
                3'd4: pixels = 5'b10001;
                3'd5: pixels = 5'b10001;
                3'd6: pixels = 5'b10001;
                default: pixels = 5'b00000;
            endcase
        end
        "O": begin
            case (row)
                3'd0: pixels = 5'b01110;
                3'd1: pixels = 5'b10001;
                3'd2: pixels = 5'b10001;
                3'd3: pixels = 5'b10001;
                3'd4: pixels = 5'b10001;
                3'd5: pixels = 5'b10001;
                3'd6: pixels = 5'b01110;
                default: pixels = 5'b00000;
            endcase
        end
        "P": begin
            case (row)
                3'd0: pixels = 5'b11110;
                3'd1: pixels = 5'b10001;
                3'd2: pixels = 5'b10001;
                3'd3: pixels = 5'b11110;
                3'd4: pixels = 5'b10000;
                3'd5: pixels = 5'b10000;
                3'd6: pixels = 5'b10000;
                default: pixels = 5'b00000;
            endcase
        end
        "R": begin
            case (row)
                3'd0: pixels = 5'b11110;
                3'd1: pixels = 5'b10001;
                3'd2: pixels = 5'b10001;
                3'd3: pixels = 5'b11110;
                3'd4: pixels = 5'b10100;
                3'd5: pixels = 5'b10010;
                3'd6: pixels = 5'b10001;
                default: pixels = 5'b00000;
            endcase
        end
        "S": begin
            case (row)
                3'd0: pixels = 5'b01111;
                3'd1: pixels = 5'b10000;
                3'd2: pixels = 5'b10000;
                3'd3: pixels = 5'b01110;
                3'd4: pixels = 5'b00001;
                3'd5: pixels = 5'b00001;
                3'd6: pixels = 5'b11110;
                default: pixels = 5'b00000;
            endcase
        end
        "T": begin
            case (row)
                3'd0: pixels = 5'b11111;
                3'd1: pixels = 5'b00100;
                3'd2: pixels = 5'b00100;
                3'd3: pixels = 5'b00100;
                3'd4: pixels = 5'b00100;
                3'd5: pixels = 5'b00100;
                3'd6: pixels = 5'b00100;
                default: pixels = 5'b00000;
            endcase
        end
        "U": begin
            case (row)
                3'd0: pixels = 5'b10001;
                3'd1: pixels = 5'b10001;
                3'd2: pixels = 5'b10001;
                3'd3: pixels = 5'b10001;
                3'd4: pixels = 5'b10001;
                3'd5: pixels = 5'b10001;
                3'd6: pixels = 5'b01110;
                default: pixels = 5'b00000;
            endcase
        end
        "W": begin
            case (row)
                3'd0: pixels = 5'b10001;
                3'd1: pixels = 5'b10001;
                3'd2: pixels = 5'b10001;
                3'd3: pixels = 5'b10101;
                3'd4: pixels = 5'b10101;
                3'd5: pixels = 5'b11011;
                3'd6: pixels = 5'b10001;
                default: pixels = 5'b00000;
            endcase
        end
        "Y": begin
            case (row)
                3'd0: pixels = 5'b10001;
                3'd1: pixels = 5'b10001;
                3'd2: pixels = 5'b01010;
                3'd3: pixels = 5'b00100;
                3'd4: pixels = 5'b00100;
                3'd5: pixels = 5'b00100;
                3'd6: pixels = 5'b00100;
                default: pixels = 5'b00000;
            endcase
        end
        "Z": begin
            case (row)
                3'd0: pixels = 5'b11111;
                3'd1: pixels = 5'b00001;
                3'd2: pixels = 5'b00010;
                3'd3: pixels = 5'b00100;
                3'd4: pixels = 5'b01000;
                3'd5: pixels = 5'b10000;
                3'd6: pixels = 5'b11111;
                default: pixels = 5'b00000;
            endcase
        end
        default: begin
            pixels = 5'b00000;
        end
    endcase
end

endmodule
