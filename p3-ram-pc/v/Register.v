module Register(
    input wire [15:0] in,
    input wire load,
    output wire [15:0] out
);
    Bit bit_0(.in(in[0]), .load(load), .out(out[0]));
    Bit bit_1(.in(in[1]), .load(load), .out(out[1]));
    Bit bit_2(.in(in[2]), .load(load), .out(out[2]));
    Bit bit_3(.in(in[3]), .load(load), .out(out[3]));
    Bit bit_4(.in(in[4]), .load(load), .out(out[4]));
    Bit bit_5(.in(in[5]), .load(load), .out(out[5]));
    Bit bit_6(.in(in[6]), .load(load), .out(out[6]));
    Bit bit_7(.in(in[7]), .load(load), .out(out[7]));
    Bit bit_8(.in(in[8]), .load(load), .out(out[8]));
    Bit bit_9(.in(in[9]), .load(load), .out(out[9]));
    Bit bit_10(.in(in[10]), .load(load), .out(out[10]));
    Bit bit_11(.in(in[11]), .load(load), .out(out[11]));
    Bit bit_12(.in(in[12]), .load(load), .out(out[12]));
    Bit bit_13(.in(in[13]), .load(load), .out(out[13]));
    Bit bit_14(.in(in[14]), .load(load), .out(out[14]));
    Bit bit_15(.in(in[15]), .load(load), .out(out[15]));
endmodule
