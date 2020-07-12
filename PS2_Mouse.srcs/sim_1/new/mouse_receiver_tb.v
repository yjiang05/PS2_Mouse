`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/02/21 13:56:07
// Design Name: Assessment 1 - Mouse Interface
// Module Name: mouse_receiver_tb
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: This is the testbench designed to test the functionalities of the receiver module.
// 
// Dependencies: mouse_receiver.v
// 
// Revision:
// Revision 1.00 - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mouse_receiver_tb(

    );
	
	// define registers for the inputs
	// standard inputs
	reg RESET;
	reg CLK;
	// mouse IO - CLK
	reg CLK_MOUSE_IN;
	// mouse IO - DATA
	reg DATA_MOUSE_IN;
	// control
	reg READ_ENABLE;
	
	// define wires for the outputs
    wire       BYTE_READY;
	wire [7:0] BYTE_READ;
    wire [1:0] BYTE_ERROR_CODE;
	
	// instantiate the receiver module
	mouse_receiver rx_uut (
		.RESET			(RESET),
		.CLK			(CLK),
		.CLK_MOUSE_IN	(CLK_MOUSE_IN),
		.DATA_MOUSE_IN  (DATA_MOUSE_IN),
		.READ_ENABLE	(READ_ENABLE),
		.BYTE_READ		(BYTE_READ),
		.BYTE_ERROR_CODE(BYTE_ERROR_CODE),
		.BYTE_READY		(BYTE_READY)
	);
	
	// set up the standard inputs
	initial begin
		RESET = 0;
		CLK   = 0;
		forever #1 CLK = ~CLK;
	end
	
	// set up the control signal
	initial begin
		READ_ENABLE = 1;
		// test the functionality of READ_ENABLE
		forever #1800000 READ_ENABLE = ~READ_ENABLE;
	end
	
	// set up the mouse IO - CLK
	initial begin
		CLK_MOUSE_IN = 0;
		forever #10000 CLK_MOUSE_IN = ~CLK_MOUSE_IN;
	end
	
	// set up the mouse IO - DATA
	initial begin
		DATA_MOUSE_IN = 0;
		forever begin
			// test byte "FF"
			#19999 DATA_MOUSE_IN = 0; // start bit
			#19999 DATA_MOUSE_IN = 1; // 1st bit
			#19999 DATA_MOUSE_IN = 1; // 2nd bit
			#19999 DATA_MOUSE_IN = 1; // 3rd bit
			#19999 DATA_MOUSE_IN = 1; // 4th bit
			#19999 DATA_MOUSE_IN = 1; // 5th bit
			#19999 DATA_MOUSE_IN = 1; // 6th bit
			#19999 DATA_MOUSE_IN = 1; // 7th bit
			#19999 DATA_MOUSE_IN = 1; // 8th bit
			#19999 DATA_MOUSE_IN = 1; // parity bit
			#19999 DATA_MOUSE_IN = 1; // stop bit
			
			// test byte "00"
			#19999 DATA_MOUSE_IN = 0; // start bit
			#19999 DATA_MOUSE_IN = 0; // 1st bit
			#19999 DATA_MOUSE_IN = 0; // 2nd bit
			#19999 DATA_MOUSE_IN = 0; // 3rd bit
			#19999 DATA_MOUSE_IN = 0; // 4th bit
			#19999 DATA_MOUSE_IN = 0; // 5th bit
			#19999 DATA_MOUSE_IN = 0; // 6th bit
			#19999 DATA_MOUSE_IN = 0; // 7th bit
			#19999 DATA_MOUSE_IN = 0; // 8th bit
			#19999 DATA_MOUSE_IN = 1; // parity bit
			#19999 DATA_MOUSE_IN = 1; // stop bit

			// test byte "3C"
			#19999 DATA_MOUSE_IN = 0; // start bit
			#19999 DATA_MOUSE_IN = 0; // 1st bit
			#19999 DATA_MOUSE_IN = 0; // 2nd bit
			#19999 DATA_MOUSE_IN = 1; // 3rd bit
			#19999 DATA_MOUSE_IN = 1; // 4th bit
			#19999 DATA_MOUSE_IN = 1; // 5th bit
			#19999 DATA_MOUSE_IN = 1; // 6th bit
			#19999 DATA_MOUSE_IN = 0; // 7th bit
			#19999 DATA_MOUSE_IN = 0; // 8th bit
			#19999 DATA_MOUSE_IN = 1; // parity bit
			#19999 DATA_MOUSE_IN = 1; // stop bit

			// test byte "50"
			#19999 DATA_MOUSE_IN = 0; // start bit
			#19999 DATA_MOUSE_IN = 0; // 1st bit
			#19999 DATA_MOUSE_IN = 0; // 2nd bit
			#19999 DATA_MOUSE_IN = 0; // 3rd bit
			#19999 DATA_MOUSE_IN = 0; // 4th bit
			#19999 DATA_MOUSE_IN = 1; // 5th bit
			#19999 DATA_MOUSE_IN = 0; // 6th bit
			#19999 DATA_MOUSE_IN = 1; // 7th bit
			#19999 DATA_MOUSE_IN = 0; // 8th bit
			#19999 DATA_MOUSE_IN = 1; // parity bit
			#19999 DATA_MOUSE_IN = 1; // stop bit

			// test byte "FA"
			#19999 DATA_MOUSE_IN = 0; // start bit
			#19999 DATA_MOUSE_IN = 0; // 1st bit
			#19999 DATA_MOUSE_IN = 1; // 2nd bit
			#19999 DATA_MOUSE_IN = 0; // 3rd bit
			#19999 DATA_MOUSE_IN = 1; // 4th bit
			#19999 DATA_MOUSE_IN = 1; // 5th bit
			#19999 DATA_MOUSE_IN = 1; // 6th bit
			#19999 DATA_MOUSE_IN = 1; // 7th bit
			#19999 DATA_MOUSE_IN = 1; // 8th bit
			#19999 DATA_MOUSE_IN = 1; // parity bit
			#19999 DATA_MOUSE_IN = 1; // stop bit
			
			// test the byte error code when parity bit error occurs
			#19999 DATA_MOUSE_IN = 0; // start bit
			#19999 DATA_MOUSE_IN = 0; // 1st bit
			#19999 DATA_MOUSE_IN = 1; // 2nd bit
			#19999 DATA_MOUSE_IN = 0; // 3rd bit
			#19999 DATA_MOUSE_IN = 1; // 4th bit
			#19999 DATA_MOUSE_IN = 1; // 5th bit
			#19999 DATA_MOUSE_IN = 1; // 6th bit
			#19999 DATA_MOUSE_IN = 1; // 7th bit
			#19999 DATA_MOUSE_IN = 1; // 8th bit
			#19999 DATA_MOUSE_IN = 0; // parity bit
			#19999 DATA_MOUSE_IN = 1; // stop bit

			// test the byte error code when stop bit error occurs
			#19999 DATA_MOUSE_IN = 0; // start bit
			#19999 DATA_MOUSE_IN = 0; // 1st bit
			#19999 DATA_MOUSE_IN = 1; // 2nd bit
			#19999 DATA_MOUSE_IN = 0; // 3rd bit
			#19999 DATA_MOUSE_IN = 1; // 4th bit
			#19999 DATA_MOUSE_IN = 1; // 5th bit
			#19999 DATA_MOUSE_IN = 1; // 6th bit
			#19999 DATA_MOUSE_IN = 1; // 7th bit
			#19999 DATA_MOUSE_IN = 1; // 8th bit
			#19999 DATA_MOUSE_IN = 1; // parity bit
			#19999 DATA_MOUSE_IN = 0; // stop bit
		end
	end
endmodule