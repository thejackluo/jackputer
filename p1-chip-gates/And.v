module And(
    input wire a,
    input wire b,
    output wire out
);
    wire aNandb;

    Nand nand0(.a(a), .b(b), .out(aNandb));
    Not not0(.in(aNandb), .out(out));
endmodule
