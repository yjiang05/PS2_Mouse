`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/02/21 15:51:06
// Design Name: Assessment 1 - Mouse Interface
// Module Name: mouse_transmitter_tb
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: This is the testbench designed to test the functionalities of the transmitter module.
// 
// Dependencies: mouse_transmitter.v
// 
// Revision:
// Revision 1.00 - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mouse_transmitter_tb(

    );
	
	// define registers for the inputs
	// standard inputs
	reg 	  RESET;
	reg 	  CLK;
	// mouse IO - CLK
	reg 	  CLK_MOUSE_IN;
	// mouse IO - DATA
	reg 	  DATA_MOUSE_IN;
	// control
	reg 	  SEND_BYTE;
	reg [7:0] BYTE_TO_SEND;
	
	// define wires for the outputs
	wire 	  CLK_MOUSE_OUT_EN;
	wire 	  DATA_MOUSE_OUT;
	wire 	  DATA_MOUSE_OUT_EN;
	wire 	  BYTE_SENT;
	
	// instantiate the transmitter module
	mouse_transmitter tx_uut(
		.RESET			  (RESET),
		.CLK	      	  (CLK),
		.CLK_MOUSE_IN	  (CLK_MOUSE_IN),
		.CLK_MOUSE_OUT_EN (CLK_MOUSE_OUT_EN),
		.DATA_MOUSE_IN	  (DATA_MOUSE_IN),
		.DATA_MOUSE_OUT	  (DATA_MOUSE_OUT),
		.DATA_MOUSE_OUT_EN(DATA_MOUSE_OUT_EN),
		.SEND_BYTE		  (SEND_BYTE),
		.BYTE_TO_SEND	  (BYTE_TO_SEND),
		.BYTE_SENT		  (BYTE_SENT)
	);

	// set up the standard inputs
	initial begin
		RESET = 0;
		CLK   = 0;
		forever #1 CLK = ~CLK;
	end

	// set up the mouse IO - CLK
	initial begin
		CLK_MOUSE_IN = 0;
		forever #10000 CLK_MOUSE_IN = ~CLK_MOUSE_IN;
	end

	// set up the mouse IO - DATA
	initial begin
		DATA_MOUSE_IN = 0;
		forever #5000 DATA_MOUSE_IN = ~DATA_MOUSE_IN;
	end

	// set up the control signal - SEND_BYTE
	initial begin
		SEND_BYTE = 1;
		// test the functionality of SEND_BYTE
		forever #480000 SEND_BYTE = ~SEND_BYTE;
	end
	
	// set up the control signal - BYTE_TO_SEND
	initial begin
		BYTE_TO_SEND = 8'hFF;
		#240000 BYTE_TO_SEND = 8'hF4;
	end
	
endmodule