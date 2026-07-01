module RAM8(
    input wire [15:0] in,
    input wire load,
    input wire [2:0] address,
    output wire [15:0] out
);
    wire [15:0] R0x0;
    wire [15:0] R0x1;
    wire [15:0] R0x2;
    wire [15:0] R0x3;
    wire [15:0] R0x4;
    wire [15:0] R0x5;
    wire [15:0] R0x6;
    wire [15:0] R0x7;
    wire l0;
    wire l1;
    wire l2;
    wire l3;
    wire l4;
    wire l5;
    wire l6;
    wire l7;

    DMux8Way dmux8way_0(.in(load), .sel(address), .a(l0), .b(l1), .c(l2), .d(l3), .e(l4), .f(l5), .g(l6), .h(l7));
    Register register_1(.in(in), .load(l0), .out(R0x0));
    Register register_2(.in(in), .load(l1), .out(R0x1));
    Register register_3(.in(in), .load(l2), .out(R0x2));
    Register register_4(.in(in), .load(l3), .out(R0x3));
    Register register_5(.in(in), .load(l4), .out(R0x4));
    Register register_6(.in(in), .load(l5), .out(R0x5));
    Register register_7(.in(in), .load(l6), .out(R0x6));
    Register register_8(.in(in), .load(l7), .out(R0x7));
    Mux8Way16 mux8way16_9(.a(R0x0), .b(R0x1), .c(R0x2), .d(R0x3), .e(R0x4), .f(R0x5), .g(R0x6), .h(R0x7), .sel(address), .out(out));
endmodule
