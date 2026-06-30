module Or(
    input wire a,
    input wire b,
    output wire out
);
    wire na;
    wire nb;

    Not not0(.in(a), .out(na));
    Not not1(.in(b), .out(nb));
    Nand nand0(.a(na), .b(nb), .out(out));
endmodule
