module Not16(
    input wire [15:0] in,
    output wire [15:0] out
);
    Not not0(.in(in[0]), .out(out[0]));
    Not not1(.in(in[1]), .out(out[1]));
    Not not2(.in(in[2]), .out(out[2]));
    Not not3(.in(in[3]), .out(out[3]));
    Not not4(.in(in[4]), .out(out[4]));
    Not not5(.in(in[5]), .out(out[5]));
    Not not6(.in(in[6]), .out(out[6]));
    Not not7(.in(in[7]), .out(out[7]));
    Not not8(.in(in[8]), .out(out[8]));
    Not not9(.in(in[9]), .out(out[9]));
    Not not10(.in(in[10]), .out(out[10]));
    Not not11(.in(in[11]), .out(out[11]));
    Not not12(.in(in[12]), .out(out[12]));
    Not not13(.in(in[13]), .out(out[13]));
    Not not14(.in(in[14]), .out(out[14]));
    Not not15(.in(in[15]), .out(out[15]));
endmodule
