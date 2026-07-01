module RAM64(
    input wire [15:0] in,
    input wire load,
    input wire [5:0] address,
    output wire [15:0] out
);
    wire [15:0] Rx00;
    wire [15:0] Rx10;
    wire [15:0] Rx20;
    wire [15:0] Rx30;
    wire [15:0] Rx40;
    wire [15:0] Rx50;
    wire [15:0] Rx60;
    wire [15:0] Rx70;
    wire l0;
    wire l1;
    wire l2;
    wire l3;
    wire l4;
    wire l5;
    wire l6;
    wire l7;

    DMux8Way dmux8way_0(.in(load), .sel(address[5:3]), .a(l0), .b(l1), .c(l2), .d(l3), .e(l4), .f(l5), .g(l6), .h(l7));
    RAM8 ram8_1(.in(in), .load(l0), .address(address[2:0]), .out(Rx00));
    RAM8 ram8_2(.in(in), .load(l1), .address(address[2:0]), .out(Rx10));
    RAM8 ram8_3(.in(in), .load(l2), .address(address[2:0]), .out(Rx20));
    RAM8 ram8_4(.in(in), .load(l3), .address(address[2:0]), .out(Rx30));
    RAM8 ram8_5(.in(in), .load(l4), .address(address[2:0]), .out(Rx40));
    RAM8 ram8_6(.in(in), .load(l5), .address(address[2:0]), .out(Rx50));
    RAM8 ram8_7(.in(in), .load(l6), .address(address[2:0]), .out(Rx60));
    RAM8 ram8_8(.in(in), .load(l7), .address(address[2:0]), .out(Rx70));
    Mux8Way16 mux8way16_9(.a(Rx00), .b(Rx10), .c(Rx20), .d(Rx30), .e(Rx40), .f(Rx50), .g(Rx60), .h(Rx70), .sel(address[5:3]), .out(out));
endmodule
