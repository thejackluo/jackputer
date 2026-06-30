module Or8Way(
    input wire [7:0] in,
    output wire out
);
    wire or01;
    wire or0123;
    wire or23;
    wire or45;
    wire or67;
    wire out4567;

    Or or_0(.a(in[0]), .b(in[1]), .out(or01));
    Or or_1(.a(in[2]), .b(in[3]), .out(or23));
    Or or_2(.a(in[4]), .b(in[5]), .out(or45));
    Or or_3(.a(in[6]), .b(in[7]), .out(or67));
    Or or_4(.a(or01), .b(or23), .out(or0123));
    Or or_5(.a(or45), .b(or67), .out(out4567));
    Or or_6(.a(or0123), .b(out4567), .out(out));
endmodule
