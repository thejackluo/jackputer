module DMux4Way(
    input wire in,
    input wire [1:0] sel,
    output wire a,
    output wire b,
    output wire c,
    output wire d
);
    wire Da;
    wire Db;

    DMux dmux_0(.in(in), .sel(sel[1]), .a(Da), .b(Db));
    DMux dmux_1(.in(Da), .sel(sel[0]), .a(a), .b(b));
    DMux dmux_2(.in(Db), .sel(sel[0]), .a(c), .b(d));
endmodule
