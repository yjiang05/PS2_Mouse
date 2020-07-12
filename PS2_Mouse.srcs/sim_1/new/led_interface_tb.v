`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/03/08 10:07:25
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: led_interface_tb
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: A testbench designed to test the functionalities of the LED interface module.
// 
// Dependencies: led_interface.v
// 
// Revision:
// Revision 1.0  - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module led_interface_tb(

    );
	
	// define registers for the inputs
	// standard signals
	reg 	  CLK;		// the on-board clock (100MHz)
	reg 	  RESET;	// reset the LED interface to the default state
	// bus signals
	reg [7:0] BUS_DATA;	// the context of the data memory (RAM)
	reg [7:0] BUS_ADDR;	// the address of the data memory (RAM)
	// control
	reg 	  WE;		// enables the writing functions of the interface
	
	// define wire for output
	wire [1:0] LED_OUT;	// indicates the clicks of left and right buttons of the mouse
	
	// instantiate the LED interface
	led_interface LED_interface_uut(
		.CLK	 (CLK),			// the on-board clock (100MHz)
		.RESET	 (RESET),		// reset the LED interface to the default state
		.BUS_DATA(BUS_DATA),	// the context of the data memory (RAM)
		.BUS_ADDR(BUS_ADDR),	// the address of the data memory (RAM)
		.WE		 (WE),			// enables the writing functions of the interface
		.LED_OUT (LED_OUT)		// indicates the clicks of left and right buttons of the mouse
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
		BUS_DATA = 8'b00001000;
		forever begin
			#200 BUS_DATA = 8'b00001001;
			#200 BUS_DATA = 8'b00001001;
			#200 BUS_DATA = 8'b00001010;
			#200 BUS_DATA = 8'b00001011;
			#200 BUS_DATA = 8'b00001000;
		end
	end
	
	// set up the control signal
	initial begin
		WE = 1;
		forever #1000 WE = ~WE;
	end
endmodule