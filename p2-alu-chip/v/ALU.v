module ALU(
    input wire [15:0] x,
    input wire [15:0] y,
    input wire zx,
    input wire nx,
    input wire zy,
    input wire ny,
    input wire f,
    input wire no,
    output wire [15:0] out,
    output wire zr,
    output wire ng
);
    wire NotZr;
    wire [15:0] Notx1;
    wire [15:0] Noty1;
    wire [14:0] drop;
    wire [7:0] outHigh;
    wire [7:0] outLow;
    wire [15:0] result;
    wire [15:0] x1;
    wire [15:0] x2;
    wire [15:0] xAddy;
    wire [15:0] xAndy;
    wire [15:0] xNRy;
    wire [15:0] xRy;
    wire [15:0] y1;
    wire [15:0] y2;
    wire zr1;
    wire zr2;
    wire [15:0] _10_out_wire;
    wire [15:0] _11_out_wire;

    Mux16 mux16_0(.a(x), .b({16{1'b0}}), .sel(zx), .out(x1));
    Not16 not16_1(.in(x1), .out(Notx1));
    Mux16 mux16_2(.a(x1), .b(Notx1), .sel(nx), .out(x2));
    Mux16 mux16_3(.a(y), .b({16{1'b0}}), .sel(zy), .out(y1));
    Not16 not16_4(.in(y1), .out(Noty1));
    Mux16 mux16_5(.a(y1), .b(Noty1), .sel(ny), .out(y2));
    Add16 add16_6(.a(x2), .b(y2), .out(xAddy));
    And16 and16_7(.a(x2), .b(y2), .out(xAndy));
    Mux16 mux16_8(.a(xAndy), .b(xAddy), .sel(f), .out(xRy));
    Not16 not16_9(.in(xRy), .out(xNRy));
    Mux16 mux16_10(.out(_10_out_wire), .a(xRy), .b(xNRy), .sel(no));
    assign out = _10_out_wire;
    assign result = _10_out_wire;
    assign outLow = _10_out_wire[7:0];
    assign outHigh = _10_out_wire[15:8];
    And16 and16_11(.out(_11_out_wire), .a(result), .b({16{1'b1}}));
    assign ng = _11_out_wire[15];
    assign drop = _11_out_wire[14:0];
    Or8Way or8way_12(.in(outLow), .out(zr1));
    Or8Way or8way_13(.in(outHigh), .out(zr2));
    Or or_14(.a(zr1), .b(zr2), .out(NotZr));
    Not not_15(.in(NotZr), .out(zr));
endmodule
