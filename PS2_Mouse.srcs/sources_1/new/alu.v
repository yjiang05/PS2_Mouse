`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/02/25 17:21:11
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: alu
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: Centre of the processor, performs the arithmetic operations.
// 
// Dependencies: None
// 
// Revision:
// Revision 1.0	 - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 	Interface:
//		CLK: 		 The on-board clock (100MHz).
//		RESET: 		 Reset the interface to the default state.
//		IN_A: 		 One of the two operands.
//		IN_B: 		 One of the two operands.
//		ALU_Op_Code: A four-bit code, dictating which operation to be performed.
//////////////////////////////////////////////////////////////////////////////////


module alu(
	// standard signals
    input 		 CLK,		  // the on-board clock (100MHz), connects to the on-board clock line
    input 		 RESET,		  // reset the ALU to the default state, connects to the middle button on the board 
	// I/Os
    input  [7:0] IN_A, 		  // value of the register A, connects to the A operand register in the processor
    input  [7:0] IN_B,		  // value of the register B, connects to the B operand register in the processor
    input  [3:0] ALU_Op_Code, // the operation code, connects to the ROM data in the processor
    output [7:0] OUT_RESULT	  // result of the ALU module, connects to the ALU output wire bus in the processor
    );
	
	// define the register for the ALU output
	reg [7:0] Out;
	
	// arithmetic computation
	always@(posedge CLK) begin
		// reset the output to 0
		if(RESET)
			Out <= 0;
		else begin
		
			// maths operations
			case (ALU_Op_Code)
				
				// add A + B
				4'h0: Out <= IN_A + IN_B;

				// subtract A - B
				4'h1: Out <= IN_A - IN_B;
				
				// multiply A * B
				4'h2: Out <= IN_A * IN_B;
				
				// shift Left A << 1
				4'h3: Out <= IN_A << 1;
				
				// shift Right A >> 1
				4'h4: Out <= IN_A >> 1;
				
				// increment A+1
				4'h5: Out <= IN_A + 1'b1;
				
				// increment B+1
				4'h6: Out <= IN_B + 1'b1;
				
				// decrement A-1
				4'h7: Out <= IN_A - 1'b1;
				
				// decrement B-1
				4'h8: Out <= IN_B - 1'b1;
				
				// in/equality Operations
				// A == B
				4'h9: Out <= (IN_A == IN_B) ? 8'h01 : 8'h00;
				
				// A > B
				4'hA: Out <= (IN_A > IN_B) ? 8'h01 : 8'h00;
				
				// A < B
				4'hB: Out <= (IN_A < IN_B) ? 8'h01 : 8'h00;
				
				// default A
				default: Out <= IN_A;
			endcase
		end
	end
	// connects the output port to the register
	assign OUT_RESULT = Out;
endmodule