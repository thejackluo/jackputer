module HalfAdder(
    input wire a,
    input wire b,
    output wire sum,
    output wire carry
);
    Xor xor_0(.a(a), .b(b), .out(sum));
    And and_1(.a(a), .b(b), .out(carry));
endmodule
