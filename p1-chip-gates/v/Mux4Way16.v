module Mux4Way16(
    input wire [15:0] a,
    input wire [15:0] b,
    input wire [15:0] c,
    input wire [15:0] d,
    input wire [1:0] sel,
    output wire [15:0] out
);
    wire [15:0] aMuxb;
    wire [15:0] cMuxd;

    Mux16 mux16_0(.a(a), .b(b), .sel(sel[0]), .out(aMuxb));
    Mux16 mux16_1(.a(c), .b(d), .sel(sel[0]), .out(cMuxd));
    Mux16 mux16_2(.a(aMuxb), .b(cMuxd), .sel(sel[1]), .out(out));
endmodule
