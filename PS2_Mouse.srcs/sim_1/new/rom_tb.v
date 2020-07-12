`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/03/07 17:15:32
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: rom_tb
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: A testbench designed to test the functionalities of the ROM module.
// 
// Dependencies: rom.v
// 
// Revision:
// Revision 1.0  - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rom_tb(

    );
	
	// define registers for the inputs
	// standard signals
	reg 	   CLK;		// the on-board clock (100MHz)
	// bus signals
	reg  [7:0] ADDR;	// address of the instruction memory (ROM)
	
	// define wires for the outputs
	wire [7:0] DATA;	// data of the instruction memory (ROM)
	
	// instantiate the ROM module
	rom ROM_uut(
		.CLK (CLK),		// the on-board clock (100MHz)
		.ADDR(ADDR),	// address of the instruction memory (ROM)
		.DATA(DATA)		// data of the instruction memory (ROM)
	);	

	// set up the standard inputs
	initial begin
		CLK   = 0;
		forever #1 CLK = ~CLK;
	end
	
	// set up the bus signals
	initial begin
		ADDR = 0;
		forever #100 begin
			if(ADDR <= 255)
				ADDR = ADDR + 1;
			else
				ADDR = 0;
		end
	end
	
endmodule