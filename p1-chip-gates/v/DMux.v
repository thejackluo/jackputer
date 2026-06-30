module DMux(
    input wire in,
    input wire sel,
    output wire a,
    output wire b
);
    wire NotSel;

    Not not_0(.in(sel), .out(NotSel));
    And and_1(.a(in), .b(NotSel), .out(a));
    And and_2(.a(in), .b(sel), .out(b));
endmodule
