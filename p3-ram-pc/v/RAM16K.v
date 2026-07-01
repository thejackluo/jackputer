module RAM16K(
    input wire [15:0] in,
    input wire load,
    input wire [13:0] address,
    output wire [15:0] out
);
    wire [15:0] Rx00000;
    wire [15:0] Rx10000;
    wire [15:0] Rx20000;
    wire [15:0] Rx30000;
    wire l0;
    wire l1;
    wire l2;
    wire l3;

    DMux4Way dmux4way_0(.in(load), .sel(address[13:12]), .a(l0), .b(l1), .c(l2), .d(l3));
    RAM4K ram4k_1(.in(in), .load(l0), .address(address[11:0]), .out(Rx00000));
    RAM4K ram4k_2(.in(in), .load(l1), .address(address[11:0]), .out(Rx10000));
    RAM4K ram4k_3(.in(in), .load(l2), .address(address[11:0]), .out(Rx20000));
    RAM4K ram4k_4(.in(in), .load(l3), .address(address[11:0]), .out(Rx30000));
    Mux4Way16 mux4way16_5(.a(Rx00000), .b(Rx10000), .c(Rx20000), .d(Rx30000), .sel(address[13:12]), .out(out));
endmodule
