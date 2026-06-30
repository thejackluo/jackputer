module Xor(
    input wire a,
    input wire b,
    output wire out
);
    wire aOb;
    wire aNdb;

    Or or0(.a(a), .b(b), .out(aOb));
    Nand nand0(.a(a), .b(b), .out(aNdb));
    And and0(.a(aOb), .b(aNdb), .out(out));
endmodule
