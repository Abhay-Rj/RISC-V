module Data_Memory_File(Address,DataIn,DataOut,Wen,Clk,Rst);
	
	output      [31:0] DataOut;
	input [31:0] Address,DataIn;
	input 	    	  Clk,Wen,Rst;

	reg        [31:0] registerbank [0:31];

	always @(posedge Clk) 
	begin
		if(~Rst) 
			begin
				for (int i = 0; i < 31; i++) 
				begin
					registerbank[i]<= 32'd0;
				end
			 end
	end
	

	assign DataOut = registerbank[Address] ;

	always @(posedge Clk) 
	begin
		if(Wen)
			registerbank[Address] <= DataIn;
	end
endmodule
