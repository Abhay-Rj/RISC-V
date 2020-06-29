module Mux2(Out,I0,I1,Sel); // 2 X 1 ,32 Bit wide

output [31:0] Out;
input  [31:0] I0,I1;
input  Sel;

assign Out=(~Sel)?I0:I1;

endmodule

module Mux4(Out,I0,I1,I2,I3,Sel); // 4 X 1 ,32 Bit wide

	output reg [31:0] Out;
	input  [31:0] I0,I1,I2,I3;
	input  [ 1:0] Sel;

always@(I0,I1,I2,I3,Sel)
begin
	case(Sel)
		2'b00: Out=I0;
		2'b01: Out=I1;
		2'b10: Out=I2;
		2'b11: Out=I3;
		default: Out=I0;
	endcase // Sel
end
endmodule
