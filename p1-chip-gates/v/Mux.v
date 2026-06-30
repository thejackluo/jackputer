module Mux(
    input wire a,
    input wire b,
    input wire sel,
    output wire out
);
    wire NotSel;
    wire Sa;
    wire Sb;

    Not not_0(.in(sel), .out(NotSel));
    And and_1(.a(NotSel), .b(a), .out(Sa));
    And and_2(.a(sel), .b(b), .out(Sb));
    Or or_3(.a(Sa), .b(Sb), .out(out));
endmodule
