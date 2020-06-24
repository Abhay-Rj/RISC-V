module SignExt(Out,Instruction);

output [31:0] Out;
input  [31:0] Instruction;

wire [6:0] Opcode;
wire [31:0] Ins;

assign Opcode = Instruction[6:0];	// Extract Opcode
assign Ins = Instruction;
// Extracts and Extends the Immediate values from different types of Instruction
	always@(Instruction)
		begin
			case(Opcode)
				7'b0000011,7'b1100111 : Out = {{20{Ins[31]}},Ins[31:20]};
				// 12 Bit Imm at Ins[31:20] for I-type and Jalr
				7'b0100011	: Out = {{20{Ins[31]}},Ins[31:25],Ins[11:7]};
				// 12 Bit Imm at Ins[31:25],Ins[11:7] for S-Type
				7'b1100111  : Out = {{20{Ins[31]}},Ins[31],Ins[7],Ins[30:25],Ins[11:8]};
				// 12 Bit Imm for SB-type
				7'b0110111  : Out = {{12{Ins[31]}},Ins[31],Ins[19:12],Ins[20],Ins[30:21]};
				//  20 Bit Imm for U-Type
				7'b1101111	: Out = {{12{Ins[31]}},Ins[31:12]};
				// 	20 Bit Imm for UJ-Type
				default:	  Out= 32'hZZZZ;
			endcase // Opcode
		end
endmodule

module Shft1(Out,In); // Left shift by 1 bit

output [31:0] Out;
input  [31:0] In;

assign Out={In[30:0],1'b0};

endmodule