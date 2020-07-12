`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/03/01 11:37:58
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: seven_seg_interface
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: The 7-segment displays peripheral controlled by the microprocessor.
// 
// Dependencies: seg_7_interface.v, generic_counter.v, mux_4_to_1.v, seg7decoder.v
// 
// Revision:
// Revision 1.0  - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 	Interface:
//		CLK: 		The on-board clock (100MHz).
//		RESET: 		Reset the interface to the default state.
//		BUS_DATA: 	Wires connecting the processor and the 7-segment displays peripheral. The peripheral can read data through these.
//		BUS_ADDR: 	The microprocessor can send the addresses of instructions through these.
//		WE: 		Enables the 7-segment displays peripheral to display new digits.
//		SEG_SELECT: Selects one of the four digits in the 7-segment displays.
//		DEC_OUT: 	Drives the segments in the 7-segment displays.
//
//	The Block Diagram:
/* 
						CLK   RESET                                                             
						 /      /                                                               
						 |      |                                                               
						 |      |                                                               
					 +---\------\-----------------------------------------------------+         
					 |                                                                |         
					 |                                                                |                          
					 |    +-------------------+          +-----------------------+    |                          
					 |    |                   | DIGIT_0  |                       |    |                          
		 BUS_DATA----------                   ------------                       |    |                          
					 |    |                   | DIGIT_1  |                       |    |                          
					 |    |      Address      ------------       7-segment       |    |                          
		 BUS_ADDR----------      Mapping      | DIGIT_2  |       Interface       |    |                          
					 |    |                   ------------                       |    |                          
					 |    |                   | DIGIT_3  |                       |    |                          
			   WE----------                   ------------                       |    |                          
					 |    +-------------------+          +-------/---------/-----+    |                          
					 |                                           |         |          |                          
					 |                                           |         |          |                          
					 |                                           |         |          |                          
					 +-------------------------------------------|---------|----------+                          
																 |         |                                     
																 \         \                                     
															SEG_SELECT  DEC_OUT                                  

*/ 
//////////////////////////////////////////////////////////////////////////////////


module seven_seg_interface(
	// standard signals
	input 		 CLK,		 // the on-board clock (100MHz), connects to the on-board clock line
	input 		 RESET,		 // reset the 7-segment interface to the default state, connects to the middle button on the board
	// bus signals
	input  [7:0] BUS_DATA, 	 // the context of the data memory (RAM), connects to the inout port of the microprocessor
	input  [7:0] BUS_ADDR, 	 // the address of the data memory (RAM), connects to the output of the microprocessor
	// control
	input 		 WE,		 // enables the writing functions of the interface, connects to the output of the microprocessor
	// 7 segment outputs
    output [3:0] SEG_SELECT, // selects one of the four digits on the 7-segment displays, connects to the anodes of the 7-segment displays
    output [7:0] DEC_OUT	 // drives the segments in the 7-segment displays, connects to the cathodes of the eight segments
    );
	
	
	// 7-segment display base address in the memory map
	parameter [7:0] SevenSegBaseAddr = 8'hD0;
		
	////////////////////////////
	// BaseAddr + 0 -> displays the X byte
	// BaseAddr + 1 -> displays the Y byte
	// BaseAddr + 2 -> displays the initialisation indicator
	////////////////////////////
	
	// define registers to hold the bus data
	reg [3:0] Digit0;	// the rightmost digit
	reg [3:0] Digit1;
	reg [3:0] Digit2;
	reg [3:0] Digit3;	// the leftmost digit
	reg Dot;

	// the configuration for displaying the X/Y bytes and the initialisation indicator
	always@(posedge CLK) begin
		// reset all registers to 0
		if(RESET) begin
			Digit0 <= 0;
			Digit1 <= 0;
			Digit2 <= 0;
			Digit3 <= 0;
			Dot <= 0;
		end else begin
			// only work when being enabled
			if(WE) begin
				// a case statement is used to determine the instructions to be executed according to the BUS_ADDR
				case(BUS_ADDR)
					// displaying the X byte configuration
					(SevenSegBaseAddr + 8'h00): begin
						Digit2 <= BUS_DATA[3:0];
						Digit3 <= BUS_DATA[7:4];
					end
					
					// displaying the Y byte configuration
					(SevenSegBaseAddr + 8'h01): begin
						Digit0 <= BUS_DATA[3:0];
						Digit1 <= BUS_DATA[7:4];
					end
					
					// displays the initialisation indicator: MouseStatus[3]
					(SevenSegBaseAddr + 8'h02):
						Dot <= BUS_DATA[3];
					
					// default to keep the same digits
					default: begin
						Digit0 <= Digit0;
						Digit1 <= Digit1;
						Digit2 <= Digit2;
						Digit3 <= Digit3;
					end
				endcase
			end else begin
				// keep the same digits when not enable
				Digit0 <= Digit0;
				Digit1 <= Digit1;
				Digit2 <= Digit2;
				Digit3 <= Digit3;
			end
		end
	end
			
	// instantiate the seg_7_interface
	seg_7_interface seven_segment (
		.CLK	   (CLK),				// on-board clock (100MHz)
		.RESET	   (RESET),				// reset the 7-segment displays
		.DIGIT_IN_0({1'b0, Digit0}),	// the rightmost digit
		.DIGIT_IN_1({1'b0, Digit1}),
		.DIGIT_IN_2({Dot, Digit2}),
		.DIGIT_IN_3({1'b0, Digit3}), 	// the leftmost digit
		.SEG_SELECT(SEG_SELECT),		// selects one of the four digits on the 7-segment displays
		.DEC_OUT   (DEC_OUT)			// drives the segments in the 7-segment displays
	);
	
endmodule