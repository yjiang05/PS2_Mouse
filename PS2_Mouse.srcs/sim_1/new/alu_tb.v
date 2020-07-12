`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/03/08 12:24:25
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: alu_tb
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: A testbench designed to test the functionalities of the ALU module.
// 
// Dependencies: alu.v
// 
// Revision:
// Revision 1.0  - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu_tb(

    );

	// define registers for the inputs
	// standard signals
	reg 	  CLK;			// the on-board clock (100MHz)
	reg 	  RESET;		// reset the ALU to the default state
	// I/Os
	reg [7:0] IN_A;			// value of the register A
	reg [7:0] IN_B;			// value of the register B
	reg [3:0] ALU_Op_Code;	// the operation code
	
	// define wire for the output
	wire [7:0] OUT_RESULT;	// result of the ALU module
	
	// instantiate the ALU module
	alu alu_uut(
		.CLK		(CLK),			// the on-board clock (100MHz)
		.RESET		(RESET),		// reset the ALU to the default state
		.IN_A		(IN_A),			// value of the register A
		.IN_B		(IN_B),			// value of the register B
		.ALU_Op_Code(ALU_Op_Code),	// the operation code
		.OUT_RESULT	(OUT_RESULT)	// result of the ALU module
	);
	
	// set up the standard inputs
	initial begin
		RESET = 0;
		CLK   = 0;
		forever #1 CLK = ~CLK;
	end
	
	// set up the I/Os
	initial begin
		IN_A 		= 0;
		IN_B 		= 0;
		ALU_Op_Code = 0;
		forever begin
			#10 ALU_Op_Code = 4'h0; IN_A = 8'h05; IN_B = 8'h03;		// add A + B
			#10 ALU_Op_Code = 4'h1; IN_A = 8'h05; IN_B = 8'h03;		// subtract A - B
			#10 ALU_Op_Code = 4'h2; IN_A = 8'h05; IN_B = 8'h03;		// multiply A * B
			#10 ALU_Op_Code = 4'h3; IN_A = 8'b00000010;				// shift Left A << 1
			#10 ALU_Op_Code = 4'h4; IN_A = 8'b00000010;				// shift Right A >> 1
			#10 ALU_Op_Code = 4'h5; IN_A = 8'h05; IN_B = 8'h03;		// increment A+1
			#10 ALU_Op_Code = 4'h6; IN_A = 8'h05; IN_B = 8'h03;		// increment B+1
			#10 ALU_Op_Code = 4'h7; IN_A = 8'h05; IN_B = 8'h03;		// decrement A-1
			#10 ALU_Op_Code = 4'h8; IN_A = 8'h05; IN_B = 8'h03;		// decrement B-1
			#10 ALU_Op_Code = 4'h9; IN_A = 8'h05; IN_B = 8'h05;		// A == B
			#10 ALU_Op_Code = 4'hA; IN_A = 8'h05; IN_B = 8'h03;		// A > B
			#10 ALU_Op_Code = 4'hB; IN_A = 8'h05; IN_B = 8'h03;		// A < B
		end
	end
	
endmodule