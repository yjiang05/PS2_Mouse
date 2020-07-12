`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/02/25 16:56:41
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: rom
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: The instruction memory.
// 
// Dependencies: rom_v1.txt
// 
// Revision:
// Revision 1.1  - Bug-free
// Revision 1.0  - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 	Interface:
//		CLK:  The on-board clock (100MHz).
//		ADDR: The address of the instruction.
//		DATA: The content of the instruction.
//////////////////////////////////////////////////////////////////////////////////


module rom(
	// standard signals
    input 			 CLK, 	// the on-board clock (100MHz), connects to the on-board clock line
	// bus signals
    input 	   [7:0] ADDR,	// address of the instruction memory (ROM), connects to the output of the microprocessor
    output reg [7:0] DATA	// data of the instruction memory (ROM), connects to the input of the microprocessor
    );
	
	parameter RAMAddrWidth = 8;
	
	// memory
	reg [7:0] ROM [2**RAMAddrWidth-1:0];
	
	// load program
	initial $readmemh("rom_v1.txt", ROM);
	
	// single port ram
	always@(posedge CLK)
		DATA <= ROM[ADDR];
endmodule