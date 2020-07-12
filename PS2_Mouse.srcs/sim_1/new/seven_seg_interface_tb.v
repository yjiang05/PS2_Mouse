`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/03/08 10:40:07
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: seven_seg_interface_tb
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: A testbench designed to test the functionalities of the 7-segment displays module.
// 
// Dependencies: seven_seg_interface.v
// 
// Revision:
// Revision 1.0  - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module seven_seg_interface_tb(

    );
	
	// define registers for the inputs
	// standard signals
	reg 	  CLK;			// the on-board clock (100MHz)
	reg 	  RESET;		// reset the 7-segment interface to the default state
	// control
	reg 	  WE;			// enables the writing functions of the interface
	// bus signals
	reg [7:0] BUS_DATA;		// the context of the data memory (RAM)
	reg [7:0] BUS_ADDR;		// the address of the data memory (RAM)
	
	// define wires for the outputs
	wire [3:0] SEG_SELECT;	// selects one of the four digits on the 7-segment displays
	wire [7:0] DEC_OUT;		// drives the segments in the 7-segment displays
	
	// instantiate the 7-segment displays interface
	seven_seg_interface seven_seg_uut(
		.CLK	   (CLK),			// the on-board clock (100MHz)
		.RESET	   (RESET),			// reset the 7-segment interface to the default state
		.BUS_DATA  (BUS_DATA),		// the context of the data memory (RAM)
		.BUS_ADDR  (BUS_ADDR),		// the address of the data memory (RAM)
		.WE		   (WE),			// enables the writing functions of the interface
		.SEG_SELECT(SEG_SELECT),	// selects one of the four digits on the 7-segment displays
		.DEC_OUT   (DEC_OUT)		// drives the segments in the 7-segment displays
	);
	
	// set up the standard inputs
	initial begin
		CLK   = 0;
		RESET = 0;
		forever #1 CLK = ~CLK;
	end
	
	// set up the bus signals
	initial begin
		BUS_ADDR = 0;
		forever #100 begin
			if(BUS_ADDR >= 8'hFF)
				BUS_ADDR = 0;
			else 
				BUS_ADDR = BUS_ADDR + 1;
		end
	end
	
	initial begin
		BUS_DATA = 0;
		forever begin
			#200 BUS_DATA = 8'h3C;
			#200 BUS_DATA = 8'h50;
			#200 BUS_DATA = 8'h9F;
			#200 BUS_DATA = 8'h77;
		end
	end
	
	// set up the control signal
	initial begin
		WE = 1;
		forever #1000 WE = ~WE;
	end
	
endmodule