module Mux(
    input wire a,
    input wire b,
    input wire sel,
    output wire out
);
    wire NotSel;
    wire Sa;
    wire Sb;

    Not not0(.in(sel), .out(NotSel));
    And and0(.a(NotSel), .b(a), .out(Sa));
    And and1(.a(sel), .b(b), .out(Sb));
    Or or0(.a(Sa), .b(Sb), .out(out));
endmodule
