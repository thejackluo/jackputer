module Bit(
    input wire in,
    input wire load,
    output wire out
);
    wire loop;
    wire muxOut;
    wire _1_out_wire;

    Mux mux_0(.a(loop), .b(in), .sel(load), .out(muxOut));
    DFF dff_1(.out(_1_out_wire), .in(muxOut));
    assign loop = _1_out_wire;
    assign out = _1_out_wire;
endmodule
