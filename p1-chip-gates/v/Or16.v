module Or16(
    input wire [15:0] a,
    input wire [15:0] b,
    output wire [15:0] out
);
    Or or_0(.a(a[0]), .b(b[0]), .out(out[0]));
    Or or_1(.a(a[1]), .b(b[1]), .out(out[1]));
    Or or_2(.a(a[2]), .b(b[2]), .out(out[2]));
    Or or_3(.a(a[3]), .b(b[3]), .out(out[3]));
    Or or_4(.a(a[4]), .b(b[4]), .out(out[4]));
    Or or_5(.a(a[5]), .b(b[5]), .out(out[5]));
    Or or_6(.a(a[6]), .b(b[6]), .out(out[6]));
    Or or_7(.a(a[7]), .b(b[7]), .out(out[7]));
    Or or_8(.a(a[8]), .b(b[8]), .out(out[8]));
    Or or_9(.a(a[9]), .b(b[9]), .out(out[9]));
    Or or_10(.a(a[10]), .b(b[10]), .out(out[10]));
    Or or_11(.a(a[11]), .b(b[11]), .out(out[11]));
    Or or_12(.a(a[12]), .b(b[12]), .out(out[12]));
    Or or_13(.a(a[13]), .b(b[13]), .out(out[13]));
    Or or_14(.a(a[14]), .b(b[14]), .out(out[14]));
    Or or_15(.a(a[15]), .b(b[15]), .out(out[15]));
endmodule
