`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/03/01 12:34:07
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: led_interface
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: The LED peripheral controlled by the microprocessor.
// 
// Dependencies: None
// 
// Revision:
// Revision 2.0  - Extra Features Added
// Revision 1.0  - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 	Interface:
//		CLK: 	  		The on-board clock (100MHz).
//		RESET: 	  		Reset the interface to the default state.
//		BUS_DATA: 		Wires connecting the processor and the LED peripheral. The peripheral can read data through these.
//		BUS_ADDR: 		The microprocessor can send the addresses of instructions through these.
//		WE: 	  		Enables the LED peripheral to display new patterns.
//		PRIMARY_BUTTON: Selects the primary button of the mouse.
//		LED_OUT:  		Turns on the LEDs on the FPGA board.
//////////////////////////////////////////////////////////////////////////////////


module led_interface(
	// standard signals
	input 			 CLK,			 // the on-board clock (100MHz), connects to the on-board clock line
	input 			 RESET, 		 // reset the LED interface to the default state, connects to the middle button on the board
	// control
	input 			 WE,			 // enables the writing functions of the interface, connects to the output of the microprocessor
	// primary button selection
	input            PRIMARY_BUTTON, // selects the primary button of the mouse, connects to the on-board slide switch
	// bus signals
	input 	   [7:0] BUS_DATA,		 // the context of the data memory (RAM), connects to the inout port of the microprocessor
	input 	   [7:0] BUS_ADDR,		 // the address of the data memory (RAM), connects to the output of the microprocessor
	// LED output
	output reg [9:0] LED_OUT 		 // indicates the clicks of left and right buttons of the mouse, connects to the LEDs on the board
    );
	
	
	// LED base address in the memory map
	parameter [7:0] LEDBaseAddr = 8'hC0;

	// the configuration for LED displaying
	always@(posedge CLK) begin
		// reset the register to 0
		if(RESET)
			LED_OUT <= 0;
		else begin
			// only work when being enabled
			if(WE) begin
				// a case statement is used to determine the instructions to be executed according to the BUS_ADDR
				case(BUS_ADDR)
					// displaying the mouse LR buttons
					(LEDBaseAddr + 8'h00): begin
						// determine which is the primary button selected by the users
						if(PRIMARY_BUTTON == 0) begin
							LED_OUT[0] <= BUS_DATA[0];
							LED_OUT[1] <= BUS_DATA[1];
						end else begin
							LED_OUT[0] <= BUS_DATA[1];
							LED_OUT[1] <= BUS_DATA[0];
						end
					end
					
					// displaying the mouse scrolling wheel
					(LEDBaseAddr + 8'h01):
						LED_OUT[9:2] <= BUS_DATA;
					
					// default to keep the same patterns
					default:
						LED_OUT <= LED_OUT;
				endcase
			end else
				// keep the same patterns when not enable
				LED_OUT <= LED_OUT;
		end
	end

endmodule