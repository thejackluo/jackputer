module FullAdder(
    input wire a,
    input wire b,
    input wire c,
    output wire sum,
    output wire carry
);
    wire aAb;
    wire aAc;
    wire aObOc;
    wire aXb;
    wire bAc;

    Xor xor_0(.a(a), .b(b), .out(aXb));
    Xor xor_1(.a(aXb), .b(c), .out(sum));
    And and_2(.a(a), .b(b), .out(aAb));
    And and_3(.a(a), .b(c), .out(aAc));
    And and_4(.a(b), .b(c), .out(bAc));
    Or or_5(.a(aAb), .b(aAc), .out(aObOc));
    Or or_6(.a(aObOc), .b(bAc), .out(carry));
endmodule
