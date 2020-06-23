module ALU(Zero,ALUresult,A,B,AluOp);
output			Zero;
output	reg	[31:0]	ALUresult; 
input  		[31:0]	A,B;
input 		[ 3:0]	AluOp;

assign Zero = (ALUresult==0);

always@(AluOp,A,B)
	begin
		case (AluOp)
			4'b0000 : ALUresult<= A&B;   	 	//AND
			4'b0001 : ALUresult<= A|B;		//OR
			4'b0010 : ALUresult<= A+B;			//ADD
			4'b0110 : ALUresult<= A-B;		//SUB
			4'b0111 : ALUresult<= (A<B)?1:0;	// SLT
			4'b1100 : ALUresult<= ~(A|B);	//NOR

			4'b1101 : ALUresult<= A<<B; 	//sll
			4'b1110 : ALUresult<= A>>B;			//srl
			4'b1000 : ALUresult<= A>>>B;	//sra

			default : ALUresult <=0;
		endcase
	end
endmodule

module Add(Result,A,B);
	output  reg [31:0] Result;
	input 		[31:0] A,B;

	initial begin Result=32'd0; end

always @(A,B)
begin
	Result=A+B;
end
endmodule