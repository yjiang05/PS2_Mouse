`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/02/21 16:24:46
// Design Name: Assessment 1 - Mouse Interface
// Module Name: mouse_master_state_machine_tb
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: This is the testbench designed to test the functionalities of the master state machine module.
// 
// Dependencies: mouse_master_state_machine.v
// 
// Revision:
// Revision 1.00 - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mouse_master_state_machine_tb(

    );
	
	// define registers for the inputs
	// standard inputs
	reg 	  RESET;
	reg 	  CLK;
	// transmitter control
	reg 	  BYTE_SENT;
	// receiver control
	reg 	  BYTE_READY;
	reg [1:0] BYTE_ERROR_CODE;
	reg [7:0] BYTE_READ;
	
	// define wires for the outputs
	wire 	   SEND_BYTE;
	wire 	   READ_ENABLE;
	wire [3:0] MASTER_STATE_CODE;
	wire [7:0] BYTE_TO_SEND;
	wire [7:0] MOUSE_DX;
	wire [7:0] MOUSE_DY;
	wire [7:0] MOUSE_STATUS;
	wire 	   SEND_INTERRUPT;

	// instantiate the master state machine
	mouse_master_state_machine msm_uut(
		.CLK			  (CLK),
		.RESET			  (RESET),
		.SEND_BYTE		  (SEND_BYTE),
		.BYTE_TO_SEND	  (BYTE_TO_SEND),
		.BYTE_SENT		  (BYTE_SENT),
		.READ_ENABLE	  (READ_ENABLE),
		.BYTE_READ		  (BYTE_READ),
		.BYTE_ERROR_CODE  (BYTE_ERROR_CODE),
		.BYTE_READY		  (BYTE_READY),
		.MOUSE_DX		  (MOUSE_DX),
		.MOUSE_DY		  (MOUSE_DY),
		.MOUSE_STATUS	  (MOUSE_STATUS),
		.SEND_INTERRUPT	  (SEND_INTERRUPT),
		.MASTER_STATE_CODE(MASTER_STATE_CODE)
	);
	
	// set up the standard inputs
	initial begin
		RESET = 0;
		CLK = 0;
		forever #1 CLK = ~CLK;
	end

	// set up the transmitter control
	initial begin
		BYTE_SENT = 1;
	end
	
	// set up the receiver control
	initial begin
		BYTE_READY = 1;
		BYTE_ERROR_CODE = 2'b00;
		BYTE_READ = 8'hFA;
		
		// wait here for 10ms before trying to initialise the mouse
		// if the byte is FA goto next state
		#2000008 BYTE_READ = 8'hFA;
		// if the byte received is AA goto next state
		#2 BYTE_READ = 8'hAA;
		// if the byte is 00 (Mouse ID) goto next state
		#2 BYTE_READ = 8'h00;
		// if the byte is FA goto next state 
		#2 BYTE_READ = 8'hFA;
		forever begin
			#7 BYTE_READ = 8'h11;
			#2 BYTE_READ = 8'h22;
			#2 BYTE_READ = 8'h33;
		end
	end
endmodule