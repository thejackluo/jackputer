module Xor(
    input wire a,
    input wire b,
    output wire out
);
    wire aNdb;
    wire aOb;

    Or or_0(.a(a), .b(b), .out(aOb));
    Nand nand_1(.a(a), .b(b), .out(aNdb));
    And and_2(.a(aOb), .b(aNdb), .out(out));
endmodule
