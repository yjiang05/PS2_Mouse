`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/03/07 18:33:35
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: ram_tb
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: A testbench designed to test the functionalities of the RAM module.
// 
// Dependencies: ram.v
// 
// Revision:
// Revision 1.0  - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ram_tb(

    );
	
	// define registers for the inputs
	// standard signals
	reg 	  CLK;			// the on-board clock (100MHz)
	// bus signals
	reg 	  BUS_WE;		// enables the RAM to write data
	reg [7:0] BUS_ADDR;		// the address of the data memory (RAM)
	
	// define wire for the output
	// bus signals
	wire [7:0] BUS_DATA;	// the context of the data memory (RAM)
	
	// instantiate the RAM module
	ram RAM_uut(
		.CLK 	 (CLK),			// the on-board clock (100MHz)
		.BUS_WE  (BUS_WE),		// enables the RAM to write data
		.BUS_ADDR(BUS_ADDR),	// the address of the data memory (RAM)
		.BUS_DATA(BUS_DATA)		// the context of the data memory (RAM)
	);

	// set up the standard inputs
	initial begin
		CLK   = 0;
		forever #1 CLK = ~CLK;
	end

	// set up the bus signals
	initial begin
		BUS_WE 	 = 0;
		BUS_ADDR = 0;
		
		forever #100 begin
			if(BUS_ADDR <= 255)
				BUS_ADDR = BUS_ADDR + 1;
			else
				BUS_ADDR = 0;
		end
	end
endmodule