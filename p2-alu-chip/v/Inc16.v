module Inc16(
    input wire [15:0] in,
    output wire [15:0] out
);
    wire c0;
    wire c1;
    wire c10;
    wire c11;
    wire c12;
    wire c13;
    wire c14;
    wire c15;
    wire c2;
    wire c3;
    wire c4;
    wire c5;
    wire c6;
    wire c7;
    wire c8;
    wire c9;

    HalfAdder halfadder_0(.a(in[0]), .b(1'b1), .sum(out[0]), .carry(c0));
    HalfAdder halfadder_1(.a(in[1]), .b(c0), .sum(out[1]), .carry(c1));
    HalfAdder halfadder_2(.a(in[2]), .b(c1), .sum(out[2]), .carry(c2));
    HalfAdder halfadder_3(.a(in[3]), .b(c2), .sum(out[3]), .carry(c3));
    HalfAdder halfadder_4(.a(in[4]), .b(c3), .sum(out[4]), .carry(c4));
    HalfAdder halfadder_5(.a(in[5]), .b(c4), .sum(out[5]), .carry(c5));
    HalfAdder halfadder_6(.a(in[6]), .b(c5), .sum(out[6]), .carry(c6));
    HalfAdder halfadder_7(.a(in[7]), .b(c6), .sum(out[7]), .carry(c7));
    HalfAdder halfadder_8(.a(in[8]), .b(c7), .sum(out[8]), .carry(c8));
    HalfAdder halfadder_9(.a(in[9]), .b(c8), .sum(out[9]), .carry(c9));
    HalfAdder halfadder_10(.a(in[10]), .b(c9), .sum(out[10]), .carry(c10));
    HalfAdder halfadder_11(.a(in[11]), .b(c10), .sum(out[11]), .carry(c11));
    HalfAdder halfadder_12(.a(in[12]), .b(c11), .sum(out[12]), .carry(c12));
    HalfAdder halfadder_13(.a(in[13]), .b(c12), .sum(out[13]), .carry(c13));
    HalfAdder halfadder_14(.a(in[14]), .b(c13), .sum(out[14]), .carry(c14));
    HalfAdder halfadder_15(.a(in[15]), .b(c14), .sum(out[15]), .carry(c15));
endmodule
