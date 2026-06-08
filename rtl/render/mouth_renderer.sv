module mouth_rom (
    input  logic clk,
    input  logic [8:0] addr,
    output logic [11:0] rgb_happy,
    output logic [11:0] rgb_sad
);
    (* rom_style = "block" *) logic [11:0] rom_happy [0:259];
    (* rom_style = "block" *) logic [11:0] rom_sad [0:259];

    initial begin
        $readmemh("../../rtl/assets/faces/mouth_happy.dat", rom_happy);
        $readmemh("../../rtl/assets/faces/mouth_sad.dat", rom_sad);
    end

    always_ff @(posedge clk) begin
        rgb_happy <= rom_happy[addr];
        rgb_sad   <= rom_sad[addr];
    end
endmodule