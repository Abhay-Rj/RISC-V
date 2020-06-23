module InstructionMemoryFile(Address,Data,Clk,Rst);
	output      [31:0] 	Data;
	input 		[31:0]	Address;
	input 	    	  	Clk,Rst;

	reg        	[ 7:0] 	imembank [0:63];  //  8x64  64B memory

initial begin $readmemh("Instruction_Memory.txt",imembank);  end 

assign Data = {imembank[Address+3'b11],imembank[Address+2'b10],imembank[Address+2'b01],imembank[Address]} ;

endmodule