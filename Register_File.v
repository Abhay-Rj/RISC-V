module RegisterFile(data1,data2,read1,read2,writeReg,writeData,Clk,Rst,regWen);
	output      [31:0] data1,data2;
	input 		[31:0] writeData;
	input      	[ 4:0] read1,read2,writeReg;
	input 	    	  Clk,regWen,Rst;

	reg       	 [31:0] registerbank [0:31];

initial begin $readmemh("Rmem.txt",registerbank); end

	always @(posedge Clk) 
	begin
		if(~Rst) 
			begin
			 	$readmemh("Rmem.txt",registerbank);
			 end
	end
	
	assign data1 = registerbank[read1];	// Port for Rs1
	assign data2 = registerbank[read2];	// Port for Rs2

	always @(negedge Clk) 					// Writing at Negative Edge of clock
	begin
			registerbank[0] <= 32'd0;
		if(regWen)
			registerbank[writeReg] <= writeData;
	end
endmodule