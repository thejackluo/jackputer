module RAM4K(
    input wire [15:0] in,
    input wire load,
    input wire [11:0] address,
    output wire [15:0] out
);
    wire [15:0] Rx0000;
    wire [15:0] Rx1000;
    wire [15:0] Rx2000;
    wire [15:0] Rx3000;
    wire [15:0] Rx4000;
    wire [15:0] Rx5000;
    wire [15:0] Rx6000;
    wire [15:0] Rx7000;
    wire l0;
    wire l1;
    wire l2;
    wire l3;
    wire l4;
    wire l5;
    wire l6;
    wire l7;

    DMux8Way dmux8way_0(.in(load), .sel(address[11:9]), .a(l0), .b(l1), .c(l2), .d(l3), .e(l4), .f(l5), .g(l6), .h(l7));
    RAM512 ram512_1(.in(in), .load(l0), .address(address[8:0]), .out(Rx0000));
    RAM512 ram512_2(.in(in), .load(l1), .address(address[8:0]), .out(Rx1000));
    RAM512 ram512_3(.in(in), .load(l2), .address(address[8:0]), .out(Rx2000));
    RAM512 ram512_4(.in(in), .load(l3), .address(address[8:0]), .out(Rx3000));
    RAM512 ram512_5(.in(in), .load(l4), .address(address[8:0]), .out(Rx4000));
    RAM512 ram512_6(.in(in), .load(l5), .address(address[8:0]), .out(Rx5000));
    RAM512 ram512_7(.in(in), .load(l6), .address(address[8:0]), .out(Rx6000));
    RAM512 ram512_8(.in(in), .load(l7), .address(address[8:0]), .out(Rx7000));
    Mux8Way16 mux8way16_9(.a(Rx0000), .b(Rx1000), .c(Rx2000), .d(Rx3000), .e(Rx4000), .f(Rx5000), .g(Rx6000), .h(Rx7000), .sel(address[11:9]), .out(out));
endmodule
