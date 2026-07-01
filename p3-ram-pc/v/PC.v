module PC(
    input wire [15:0] in,
    input wire reset,
    input wire load,
    input wire inc,
    output wire [15:0] out
);
    wire [15:0] out1;
    wire [15:0] out2;
    wire [15:0] out3;
    wire [15:0] tmp;
    wire [15:0] tmpInc;
    wire [15:0] _4_out_wire;

    Mux16 mux16_0(.a(out2), .b({16{1'b0}}), .sel(reset), .out(out3));
    Mux16 mux16_1(.a(out1), .b(in), .sel(load), .out(out2));
    Inc16 inc16_2(.in(tmp), .out(tmpInc));
    Mux16 mux16_3(.a(tmp), .b(tmpInc), .sel(inc), .out(out1));
    Register register_4(.out(_4_out_wire), .in(out3), .load(1'b1));
    assign out = _4_out_wire;
    assign tmp = _4_out_wire;
endmodule
