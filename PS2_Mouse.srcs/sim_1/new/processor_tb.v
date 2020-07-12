`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/03/08 11:44:41
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: processor_tb
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: A testbench designed to test the functionalities of the microprocessor module.
// 
// Dependencies: processor.v
// 
// Revision:
// Revision 1.0  - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module processor_tb(

    );
	
	// define registers for the inputs
	// standard signals
	reg 	   CLK;						// the on-board clock (100MHz)
	reg 	   RESET;					// reset the processor to the default state
	// bus signal
	wire [7:0] BUS_DATA;				// the context of the data memory (RAM)
	// ROM signal
	reg  [7:0] ROM_DATA;				// data of the instruction memory (ROM)
	// interrupt signal
	reg  [1:0] BUS_INTERRUPTS_RAISE;	// interrupts raise from the mouse driver and the timer
	
	// define wires for the outputs
	wire 	   BUS_WE;					// enables the writing functions of peripherals such as 7-segment displays, LEDs,
										// timer, and the RAM
	wire [7:0] BUS_ADDR;				// the address of the data memory (RAM)
	wire [7:0] ROM_ADDRESS;				// address of the instruction memory (ROM)
	wire [1:0] BUS_INTERRUPTS_ACK;		// interrupts acknowledgement to the mouse driver and the timer
	
	// define an intermediate register for the BUS_DATA
	reg [7:0] bus_data;
	assign BUS_DATA = bus_data;
	
	// instantiate the processor module
	processor processor_uut(
		.CLK				 (CLK),						// the on-board clock (100MHz)
		.RESET				 (RESET),					// reset the processor to the default state
		.BUS_DATA			 (BUS_DATA),				// the context of the data memory (RAM)
		.BUS_ADDR			 (BUS_ADDR),				// the address of the data memory (RAM)
		.BUS_WE				 (BUS_WE),					// enables the writing functions of peripherals such as 7-segment displays,
														// LEDs, timer, and the RAM
		.ROM_ADDRESS		 (ROM_ADDRESS),				// address of the instruction memory (ROM)
		.ROM_DATA			 (ROM_DATA),				// data of the instruction memory (ROM)
		.BUS_INTERRUPTS_RAISE(BUS_INTERRUPTS_RAISE),	// interrupts raise from the mouse driver and the timer
		.BUS_INTERRUPTS_ACK	 (BUS_INTERRUPTS_ACK)		// interrupts acknowledgement to the mouse driver and the timer
	);
	
	// set up the standard inputs
	initial begin
		RESET = 0;
		CLK   = 0;
		forever #1 CLK = ~CLK;
	end
	
	// set up the bus signal
	initial begin
		bus_data = 0;
		forever #100 begin
			if(bus_data >= 8'hFF)
				bus_data = 0;
			else 
				bus_data = bus_data + 1;
		end
	end

	// set up the ROM signal
	initial begin
		ROM_DATA = 0;
		forever begin
			#100 ROM_DATA = 8'h00;
			#100 ROM_DATA = 8'hA0;
			#100 ROM_DATA = 8'h02;
			#100 ROM_DATA = 8'hC0;
			#100 ROM_DATA = 8'h02;
			#100 ROM_DATA = 8'hD2;
			#100 ROM_DATA = 8'h00;
			#100 ROM_DATA = 8'hA1;
			#100 ROM_DATA = 8'h01;
			#100 ROM_DATA = 8'hA2;
			#100 ROM_DATA = 8'h02;
			#100 ROM_DATA = 8'hD0;
			#100 ROM_DATA = 8'h03;
			#100 ROM_DATA = 8'hD1;
		end
	end
	
	// set up the interrupt signal
	initial begin
		BUS_INTERRUPTS_RAISE = 0;
		forever begin
			#500 BUS_INTERRUPTS_RAISE = 2'b11;
			#500 BUS_INTERRUPTS_RAISE = 2'b10;
			#500 BUS_INTERRUPTS_RAISE = 2'b01;
			#500 BUS_INTERRUPTS_RAISE = 2'b00;
		end
	end
	
endmodule