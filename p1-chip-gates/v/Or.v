module Or(
    input wire a,
    input wire b,
    output wire out
);
    wire na;
    wire nb;

    Not not_0(.in(a), .out(na));
    Not not_1(.in(b), .out(nb));
    Nand nand_2(.a(na), .b(nb), .out(out));
endmodule
