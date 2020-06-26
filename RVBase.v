/* Risc V 32 Bit RV32I Processor 
	5 Stage in-order pipelined with Data Forwarding and Hazard Detection Stalling.
*/
`include "ALU.v"
`include "Register_File.v"
`include "Memory_File.v"
`include "Instruction_Memory.v"
`include "Mux.v"
`include "ControlDecoder.v"
`include "ImmediateGen.v"


module Pops(Clk,Rst);

	input Clk,Rst;

//---------IF Stage Declarations----------------------------------

	wire PCSrc;
	wire [31:0] PCin,PC,PC_4;
	wire [31:0] AddressIn,Instruction;
	reg  [31:0] PCreg;

//---------ID Stage Declarations-------------------------------------------

	wire ALUsrc,MemRead,MemWrite,MemtoReg,RegWrite,AddSel,Link,Branch,Lui;
	wire regWen_WB;
	wire [1:0] ALUOp;
	wire [2:0] funct3_ID;
	wire [4:0] Rs1_ID,Rs2_ID,rd_WB;
	wire [6:0] Opcode;
	wire [9:0] ControlWire1;
	wire [31:0] data1,data2,writeData_WB,Instruction_ID,Immediate_ID;

//---------EX Stage Declarations-------------------------------------------

	wire Zero,Lui_Ex,ALUsrc_Ex,RegWrite_EX;
	wire [1:0] AluOp_Ex;
	wire [2:0] funct3;
	wire [3:0] ALUCnt;
	wire [4:0] Rd_EX;
	wire [6:0] funct7;
	wire [31:0] ALUresult,A,B,A0,B0,A1,B1;
	wire [31:0] Imm32,BrAdd,PC_EX,data1_Ex,data2_Ex;

//---------MEM Stage Declarations------------------------------------------

	wire zero_MEM,AddSel_MEM,Link_MEM,branch_MEM,memWrite_MEM,memRead_MEM,RegWrite_MEM;
	wire [ 4:0] Rd_MEM;
	wire [31:0] OffsetAddress,BranchOffset,ALUAddress,ReadData,WriteData_MEM,writeBack_MEM,PCLink;


//---------WB Stage Declarations-------------------------------------------
	
	wire RegWrite_WB,MemtoReg_WB;
	wire [31:0] readData_WB,writeBack_WB;

//-------------------------------------------------------------------------

	wire memRead_EX;
	
	wire [ 4:0] Rs1_ID_EX,Rs2_ID_EX,Rd_EX_MEM,Rd_MEM_WB;

	reg stallIF,stallID,NOP;
	reg [1:0] InA,InB;
	reg flushIF,flushID,flushEX;
	reg [ 95:0] IF_ID_pipereg;
	reg [194:0] ID_EX_pipereg;
	reg [140:0] EX_MEM_pipereg;
	reg [ 70:0] MEM_WB_pipereg;

	
always@(posedge Clk or negedge Rst)
begin
		if(~Rst)
			PCreg   <= 32'd0;
		else if(stallIF==1'b0)                 // Check for IF Stall
			PCreg	<= PCin ;				  // Update PC at posedge CLK1
		else
			PCreg	<= PCreg;				// Incase of a Stall do not update PC
	end

	/*----------------------------------------------------------------------------------------------------------
												INSTRUCTION FETCH
	-----------------------------------------------------------------------------------------------------------*/
assign PC=PCreg;
assign PCSrc = (zero_MEM^branch_MEM)||Link_MEM ;

	Add 	PCAddressIncrement(PC_4,PC,32'd4);		             // Adder for PC increment PC_4=PC+4

	InstructionMemoryFile IMF (AddressIn,Instruction,Clk,Rst); // Instruction Memory

	Mux2 	PCAddressSel(PCin,PC_4,OffsetAddress,PCSrc);      // Next Address Selection 32 bit wide 2X1 Mux


	always@(posedge Clk or negedge Rst)
	begin 
		if(~Rst)
			IF_ID_pipereg <= 96'd0;
		else if(stallID==1'b0)					        // Stall Check for ID Stage
		 begin
			IF_ID_pipereg[31: 0] <= Instruction;	  // Forward Instruction to  ID
			IF_ID_pipereg[63:32] <= PC;				 // Forward PC address to ID
			IF_ID_pipereg[95:64] <= PC_4;			// Forward PC+4 address to ID
		 end
	 	else								      // Stall the ID , repeat ID
	 		IF_ID_pipereg		 <= IF_ID_pipereg;

	 	if(flushIF==1'b1)					   // IF needs to be Flushed
		 		IF_ID_pipereg 	 <= 96'd0;
	end

/*----------------------------------------------------------------------------------------------------------
												INSTRUCTION DECODE
	-----------------------------------------------------------------------------------------------------------*/
assign Instruction_ID 	= IF_ID_pipereg[31:0]; 	   // Extract Instruction
assign Opcode 			= IF_ID_pipereg[6:0];     // Extract Opcode
assign funct3_ID 		= IF_ID_pipereg[14:12];
assign Rs2_ID	  		= IF_ID_pipereg[24:20];  // Extract reg select bits for rs1 
assign Rs1_ID	  		= IF_ID_pipereg[19:15];	// Extract reg select bits for rs2
assign Rd 				= IF_ID_pipereg[11: 7];// Extract reg select bits for rd

assign ControlWire1= (NOP || flushID)?10'bXXXXXXXXXX:{Lui,ALUOp,ALUsrc,AddSel,Link,Branch,MemWrite,MemRead,RegWrite,MemtoReg};
// Incase of a No operation or Flush ID signal deassert all the signals.

	Control ControlDecoder(Opcode,funct3_ID,ALUsrc,MemtoReg,RegWrite,MemRead,MemWrite,AddSel,Link,Branch,ALUOp,Lui);
	//  Decodes instructions in ID stage and forwards the control signals to other stages
	RegisterFile GPR(data1,data2,Rs1_ID,Rs2_ID,rd_WB,writeData_WB,Clk,Rst,RegWrite_WB);
	//  General Purpose Register File x0-x31, two read ports and a write port
	ImGen	ImmediateGen(Immediate_ID,Instruction_ID);
	//  Generates 32 bit Immediate value as per instruction
	
always @(posedge Clk or negedge Rst)
 begin
 	if(~Rst)
 		ID_EX_pipereg <= 185'd0;
 	else
 	begin
		ID_EX_pipereg[ 31: 0 ] <= IF_ID_pipereg[63:32]; 	  // Forward PC.
		ID_EX_pipereg[ 63:32 ] <= data1 ;	  			     //  Forward Rs1 Data
		ID_EX_pipereg[ 95:64 ] <= data2 ;				  	//   Forward Rs2 Data
		ID_EX_pipereg[127:96 ] <= Immediate_ID ;		   //    Forward Immediate Data
		ID_EX_pipereg[159:128] <= IF_ID_pipereg[63:32];	  //     Forward PC+4
		ID_EX_pipereg[164:160] <= Rd ;					 //      Forward Rd Select
		ID_EX_pipereg[174:165] <= ControlWire1 ; 	 	//       Forward Control Signals
		ID_EX_pipereg[184:175] <= {Instruction_ID[14:12],Instruction_ID[31:25]} ;// {func3,func7}
		ID_EX_pipereg[194:185] <= {Rs1_ID,Rs2_ID};    // Store for Forwarding
 	end
 end
 /*----------------------------------------------------------------------------------------------------------
												EXECUTION
	-----------------------------------------------------------------------------------------------------------*/
assign Imm32=ID_EX_pipereg[127:96];
assign PC_EX=ID_EX_pipereg[ 31: 0];

assign data1_Ex = ID_EX_pipereg[ 63:32 ];
assign data2_Ex = ID_EX_pipereg[ 95:64 ];

assign ALUsrc_Ex 	=ID_EX_pipereg[171];
assign AluOp_Ex	 	=ID_EX_pipereg[173:172];
assign Lui_Ex	 	=ID_EX_pipereg[174];
assign RegWrite_EX 	=ID_EX_pipereg[166];
assign Rd_EX    	=ID_EX_pipereg[164:160];

assign funct3=ID_EX_pipereg[184:182];
assign funct7=ID_EX_pipereg[181:175];

assign ControlWire2= (flushEX)?8'hXX:{Zero,ID_EX_pipereg[171:165]};
	// flush EX deasserts control introducing Bubbles/No operations

	Add AddressAdder(BrAdd,PC_EX,{Imm32[30:0],1'b0}); 
	// Adder for Computing Branch Addresses (Imm32 bits are left shifted)
	Mux4 BusA1(A1,data1_Ex,ALUAddress,writeData_WB,32'd0,InA); // Forward Reg A mux
	Mux4 BusB1(B1,data2_Ex,ALUAddress,writeData_WB,32'd0,InB);// Forward Reg B mux

	Mux2 BusA0(A,A1,32'd0,Lui_Ex); 		 // Mux : Loads Rs1 Data to 0 for Lui instrucion
	Mux2 BusB0(B,B1,Imm32,ALUsrc_Ex);   // Mux : Selects between Immediate or Rs2 Data

	ALU  ALUUnit(Zero,ALUresult,A,B,ALUCnt);			 // ALU Unit takes in 4 bit Control from ALUCtrl
	ALUControl ALUCtrl(ALUCnt,AluOp_Ex,funct3,funct7);	// 2nd Level Control Decoder

always@(posedge Clk or negedge Rst)
begin
	if(~Rst)
		EX_MEM_pipereg <=140'd0;
	else
		begin
		EX_MEM_pipereg [ 31: 0 ] <= ALUresult;					  // ALU Result
		EX_MEM_pipereg [ 63: 32] <= BrAdd;						 // PC+Offset ,Branch Address
		EX_MEM_pipereg [ 95: 64] <= B1;							// Rs2 data to write to Memory
		EX_MEM_pipereg [127: 96] <= ID_EX_pipereg[159:128];	   // PC+4
		EX_MEM_pipereg [132:128] <= Rd_EX;					  // RD.EX
		EX_MEM_pipereg [140:133] <= ControlWire2;			 // Control Signals for further stages
	end
end

 /*----------------------------------------------------------------------------------------------------------
												MEMORY READ/WRITE
	-----------------------------------------------------------------------------------------------------------*/

assign ControlWire3 = EX_MEM_pipereg[134:133];

assign BranchOffset	= EX_MEM_pipereg [63:32];	 // Branch address = PC+ Shifted Immediate
assign ALUAddress  	= EX_MEM_pipereg [31: 0];	// ALU address    = Reg + Immediate
assign WriteData_MEM= EX_MEM_pipereg [95:64];  // RS2 Data for writing to memory
assign PCLink =EX_MEM_pipereg [127: 96];
assign Rd_MEM =EX_MEM_pipereg [132:128];

assign zero_MEM  	= EX_MEM_pipereg[140];	// Used for Branches
assign AddSel_MEM  	= EX_MEM_pipereg[139];
assign Link_MEM		= EX_MEM_pipereg[138];   // Set for Unconditional Jumps
assign branch_MEM	= EX_MEM_pipereg[137];	//  Set for Branches
assign memWrite_MEM = EX_MEM_pipereg[136];
assign memRead_MEM  = EX_MEM_pipereg[135];
assign RegWrite_MEM = EX_MEM_pipereg[134];


	Mux2 AddressSel(OffsetAddress,BranchOffset,ALUAddress,AddSel_MEM); // Selects between PC Offset/Reg Offset
	Mux2 LinkSel(writeBack_MEM,ALUAddress,PCLink,Link_MEM); 		  // Selects between writing back PC+4/ALUOut
	DataMemoryFile DMF(ReadData,ALUAddress,WriteData_MEM,memWrite_MEM,memRead_MEM,Clk,Rst);

always @(posedge Clk or negedge Rst) 
begin
	if(~Rst) 
	MEM_WB_pipereg <= 70'd0;
	else
	 begin
	 	MEM_WB_pipereg[31:0 ] <= ReadData; // Data read from Memory
	 	MEM_WB_pipereg[63:32] <= writeBack_MEM; // Data from ALU / Link Reg
	 	MEM_WB_pipereg[68:64] <= Rd_MEM; // Write Data Select Register
	 	MEM_WB_pipereg[70:69] <= ControlWire3; // Control Signals
	end
end
/*----------------------------------------------------------------------------------------------------------
												REGISTER WRITEBACK
	-----------------------------------------------------------------------------------------------------------*/

assign RegWrite_WB  = MEM_WB_pipereg[70];
assign MemtoReg_WB  = MEM_WB_pipereg[69];
assign readData_WB  = MEM_WB_pipereg[31: 0];
assign writeBack_WB = MEM_WB_pipereg[63:32];
assign rd_WB 		= MEM_WB_pipereg[68:64];

 	Mux2 WriteBackSel(writeData_WB,readData_WB,writeBack_WB,MemtoReg_WB); 

/*----------------------------------------------------------------------------------------------------------
												HAZARD DETECTION  (STALLS, FLUSHES)
	-----------------------------------------------------------------------------------------------------------*/

assign memRead_EX= ID_EX_pipereg[166];

always@(*)				// Stall due to Load 
	begin
		if(memRead_EX && ((Rd_EX == Rs1_ID) || (Rd_EX == Rs2_ID)))
			begin
				stallIF=1'b1;
				stallID=1'b1;
				NOP=1'b1;
			end
		else
			begin
				stallIF=1'b0;
				stallID=1'b0;
				NOP=1'b1;
			end
	end

always@(*)				// Branch & Jump Flush
	begin
		if(PCSrc)	// Next address is Jump/Branch
			begin
				flushIF=1'b1;
				flushID=1'b1;
				flushEX=1'b1;
			end
		else
			begin
				flushIF=1'b0;
				flushID=1'b0;
				flushEX=1'b0;
			end
	end

/*----------------------------------------------------------------------------------------------------------
												FORWARDING UNIT
	-----------------------------------------------------------------------------------------------------------*/

assign Rs1_ID_EX = ID_EX_pipereg  [194:190];
assign Rs2_ID_EX = ID_EX_pipereg  [189:185];
assign Rd_EX_MEM = EX_MEM_pipereg [132:128];
assign Rd_MEM_WB = MEM_WB_pipereg [ 68:64];


always@(*)			// Register Forwarding Unit 
	begin
		if(RegWrite_MEM  && Rd_EX_MEM !=5'd0 && Rd_EX_MEM == Rs1_ID_EX) // ID -- EX  Dependency Rs1
			InA=2'b01;
		else if(RegWrite_WB   && Rd_MEM_WB !=5'd0 && Rd_MEM_WB == Rs1_ID_EX) // ID -- MEM Dependency Rs1
			InA=2'b10;
		else 
			InA=2'b00;

		if(RegWrite_MEM  && Rd_EX_MEM !=5'd0 && Rd_EX_MEM == Rs2_ID_EX) // ID -- EX  Dependency Rs2
			InB=2'b01;
		else if(RegWrite_WB   && Rd_MEM_WB !=5'd0 && Rd_MEM_WB == Rs2_ID_EX) // ID -- MEM Dependency Rs2
			InB=2'b10;
		else 
			InB=2'b00;
	end	


endmodule
/*----------------------------------------------------------------------------------------------------------
												      END
	-----------------------------------------------------------------------------------------------------------*/