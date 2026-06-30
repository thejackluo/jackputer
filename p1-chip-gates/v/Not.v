module Not(
    input wire in,
    output wire out
);
    Nand nand_0(.a(in), .b(in), .out(out));
endmodule
