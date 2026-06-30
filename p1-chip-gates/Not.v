module Not(
    input wire in,
    output wire out
);
    Nand nand0(.a(in), .b(in), .out(out));
endmodule
