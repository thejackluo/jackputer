module DMux8Way(
    input wire in,
    input wire [2:0] sel,
    output wire a,
    output wire b,
    output wire c,
    output wire d,
    output wire e,
    output wire f,
    output wire g,
    output wire h
);
    wire Da;
    wire De;

    DMux dmux_0(.in(in), .sel(sel[2]), .a(Da), .b(De));
    DMux4Way dmux4way_1(.in(Da), .sel(sel[1:0]), .a(a), .b(b), .c(c), .d(d));
    DMux4Way dmux4way_2(.in(De), .sel(sel[1:0]), .a(e), .b(f), .c(g), .d(h));
endmodule
