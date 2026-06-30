module DMux(
    input wire in,
    input wire sel,
    output wire a,
    output wire b
);
    wire NotSel;

    Not not0(.in(sel), .out(NotSel));
    And and0(.a(in), .b(NotSel), .out(a));
    And and1(.a(in), .b(sel), .out(b));
endmodule
