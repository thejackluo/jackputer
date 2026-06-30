module And(
    input wire a,
    input wire b,
    output wire out
);
    wire aNandb;

    Nand nand_0(.a(a), .b(b), .out(aNandb));
    Not not_1(.in(aNandb), .out(out));
endmodule
