module Register_File(RS1Sel,RS2Sel,RDSel,Wen,RS1Dat,RS2Dat,RDDat,Clk,Rst);
	input [31:0] RDDat;
	output      [31:0] RS1Dat,RS2Dat;
	input      [ 4:0] RS1Sel,RS2Sel,RDSel;
	input 	    	  Clk,Wen,Rst;

	reg        [31:0] registerbank [0:31];

	always @(posedge Clk) 
	begin
		if(~Rst) 
			begin
			 	registerbank[ 0]<= 32'd0;
			 	registerbank[ 1]<= 32'd1;
			 	registerbank[ 2]<= 32'd2;
			 	registerbank[ 3]<= 32'd03;
			 	registerbank[ 4]<= 32'd04;
			 	registerbank[ 5]<= 32'd05;
			 	registerbank[ 6]<= 32'd06;
			 	registerbank[ 7]<= 32'd07;
			 	registerbank[ 8]<= 32'd08;
			 	registerbank[ 9]<= 32'd09;
			 	registerbank[10]<= 32'd12;
			 	registerbank[11]<= 32'd11;
			 	registerbank[12]<= 32'd12;
			 	registerbank[13]<= 32'd13;
			 	registerbank[14]<= 32'd14;
			 	registerbank[15]<= 32'd15;
			 	registerbank[16]<= 32'd16;
			 	registerbank[17]<= 32'd17;
			 	registerbank[18]<= 32'd18;
			 	registerbank[19]<= 32'd19;
			 	registerbank[20]<= 32'd20;
			 	registerbank[21]<= 32'd21;
			 	registerbank[22]<= 32'd0;
			 	registerbank[23]<= 32'd0;
			 	registerbank[24]<= 32'd0;
			 	registerbank[25]<= 32'd0;
			 	registerbank[26]<= 32'd0;
			 	registerbank[27]<= 32'd0;
			 	registerbank[28]<= 32'd0;
			 	registerbank[29]<= 32'd0;
			 	registerbank[30]<= 32'd0;
			 	registerbank[31]<= 32'd0;			 
			 end
	end
	

	assign RS1Dat = registerbank[RS1Sel] ;
	assign RS2Dat = registerbank[RS2Sel];

	always @(negedge Clk) 
	begin
		if(1)
			registerbank[RDSel] <= RDDat;
	end
endmodule
