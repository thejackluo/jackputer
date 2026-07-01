module RAM512(
    input wire [15:0] in,
    input wire load,
    input wire [8:0] address,
    output wire [15:0] out
);
    wire [15:0] Rx000;
    wire [15:0] Rx100;
    wire [15:0] Rx200;
    wire [15:0] Rx300;
    wire [15:0] Rx400;
    wire [15:0] Rx500;
    wire [15:0] Rx600;
    wire [15:0] Rx700;
    wire l0;
    wire l1;
    wire l2;
    wire l3;
    wire l4;
    wire l5;
    wire l6;
    wire l7;

    DMux8Way dmux8way_0(.in(load), .sel(address[8:6]), .a(l0), .b(l1), .c(l2), .d(l3), .e(l4), .f(l5), .g(l6), .h(l7));
    RAM64 ram64_1(.in(in), .load(l0), .address(address[5:0]), .out(Rx000));
    RAM64 ram64_2(.in(in), .load(l1), .address(address[5:0]), .out(Rx100));
    RAM64 ram64_3(.in(in), .load(l2), .address(address[5:0]), .out(Rx200));
    RAM64 ram64_4(.in(in), .load(l3), .address(address[5:0]), .out(Rx300));
    RAM64 ram64_5(.in(in), .load(l4), .address(address[5:0]), .out(Rx400));
    RAM64 ram64_6(.in(in), .load(l5), .address(address[5:0]), .out(Rx500));
    RAM64 ram64_7(.in(in), .load(l6), .address(address[5:0]), .out(Rx600));
    RAM64 ram64_8(.in(in), .load(l7), .address(address[5:0]), .out(Rx700));
    Mux8Way16 mux8way16_9(.a(Rx000), .b(Rx100), .c(Rx200), .d(Rx300), .e(Rx400), .f(Rx500), .g(Rx600), .h(Rx700), .sel(address[8:6]), .out(out));
endmodule
