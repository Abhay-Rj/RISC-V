`include "RVBase.v"

module TB();

reg Rst,Clk;

	Pops RVCPU(Clk,Rst);

initial begin
	Rst=1'b0;
	Clk =1'b0;
	#5 Rst=1'b1;

	forever	#5 Clk = !Clk;
	end

initial
	begin

	 $dumpfile("M.vcd");
      $dumpvars(0, TB);


	#200 $finish;
	end
endmodule