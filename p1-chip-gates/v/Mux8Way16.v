module Mux8Way16(
    input wire [15:0] a,
    input wire [15:0] b,
    input wire [15:0] c,
    input wire [15:0] d,
    input wire [15:0] e,
    input wire [15:0] f,
    input wire [15:0] g,
    input wire [15:0] h,
    input wire [2:0] sel,
    output wire [15:0] out
);
    wire [15:0] MuxaTod;
    wire [15:0] MuxeToh;

    Mux4Way16 mux4way16_0(.a(a), .b(b), .c(c), .d(d), .sel(sel[1:0]), .out(MuxaTod));
    Mux4Way16 mux4way16_1(.a(e), .b(f), .c(g), .d(h), .sel(sel[1:0]), .out(MuxeToh));
    Mux16 mux16_2(.a(MuxaTod), .b(MuxeToh), .sel(sel[2]), .out(out));
endmodule
