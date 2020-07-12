`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/02/29 11:43:31
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: mouse_interface
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: A mouse interface controlled by the microprocessor.
// 
// Dependencies: mouse_transceiver.v, mouse_transmitter.v, mouse_receiver.v, mouse_master_state_machine.v.
// 
// Revision:
// Revision 2.0  - Extra Features Added
// Revision 1.1  - Bug-free
// Revision 1.0  - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 	Interface:
//		CLK: 				 The on-board clock (100MHz).
//		RESET: 				 Reset the interface to the default state.
//		SPEED:				 Controls the moving speed of the pointers.
//		BUS_DATA: 			 Wires connecting the microprocessor and the mouse driver. The mouse driver can read and send data via them.
//		BUS_ADDR: 			 The microprocessor can send the addresses of instructions through these.
//		BUS_INTERRUPT_RAISE: Connects to the microprocessor and sends an interrupt.
//		BUS_INTERRUPT_ACK: 	 Connects to the microprocessor and receives the interrupt acknowledgement from the microprocessor.
//		CLK_MOUSE: 			 The PS2 clock line.
//		DATA_MOUSE: 		 The PS2 data line.
//
//	The block diagram:
//
/* 
							 BUS_DATA        BUS_ADDR            BUS_INTERRUPT_ACK                   
								/              /                       /                             
								|              |                       |                             
								|              |                       |                             
					   +--------\--------------\-----------------------\-----------------+           
			  RESET-----                                                                 |           
					   |                    MouseStatus        +---------------+         |           
					   |              --------------------------               |         |           
				CLK-----              |                        |               |         |           
					   |              |                        |    Address    |         |           
					   |      +-------\-------+    MouseX      |    Mapping    |         |           
					   |      |               ------------------               |         |           
					   |      |               ------------------               |         |           
		  CLK_MOUSE------------               |    MouseY      +------/------/-+         |           
					   |      |     Mouse     ------------------------\      |           |           
					   |      |  Transceiver  |                 MouseZ       \           |           
					   |      |               |    MouseInterrupt          MouseData     |           
		 DATA_MOUSE------------               --------------------------/                |           
					   |      |               |                         |                |           
					   |      |               |                 +-------\-------+        |           
					   |      +---------------+                 |               |        |           
					   |                                        |   Broadcast   |        |           
					   |                                        |      the      |        |           
					   |            MouseData                   |   Interrupt   |        |           
			  SPEED-----               /                        |               |        |           
					   |               |                        +-------/-------+        |           
					   |               |                                |                |           
					   |        -------\------,                         |                |           
					   |         \  Tristate /                          |                |           
					   |          \  Output /                           |                |           
					   |           `.      '-----TransmitMouseValue     |                |           
					   |             \   ,'                             |                |           
					   |              \ /                               |                |           
					   |               /                                |                |           
					   +---------------|--------------------------------|----------------+           
									   |                                |                            
									   \                                \                            
									BUS_DATA                 BUS_INTERRUPT_RAISE                     

*/
//////////////////////////////////////////////////////////////////////////////////


module mouse_interface(
	// standard signals
	input 		CLK,				 // the on-board clock (100MHz), connects to the on-board clock line
	input 		RESET,				 // reset the mouse driver to the default state, connects to the middle button on the board
	// speed control
	input       SPEED,				 // controls the moving speed of the pointers, connects to the input from the on-board slide switch
	// bus signals
	inout [7:0] BUS_DATA, 			 // the context of the data memory (RAM), connects to the inout port of the microprocessor
	input [7:0] BUS_ADDR, 			 // the address of the data memory (RAM), connects to the output of the microprocessor
	input 		BUS_INTERRUPT_ACK, 	 // interrupt acknowledgement from the processor, connects to the output of the microprocessor
	output 		BUS_INTERRUPT_RAISE, // interrupt raise to the processor, connects to the input of the microprocessor
	// IO - mouse side
	inout 		CLK_MOUSE,			 // connects to the PS2 clock line
	inout 		DATA_MOUSE			 // connects to the PS2 data line
    );
	
	
	// mouse base address in the memory map
	parameter [7:0] MouseBaseAddr = 8'hA0;
	
	// define wires used to connect the transceiver module
	wire 	   MouseInterrupt;	// interrupt signal of the mouse driver from the transceiver
	wire [3:0] mouse_status;	// value of the mouse status from the transceiver
	wire [7:0] mouse_X;			// value of the mouse X from the transceiver
	wire [7:0] mouse_Y;			// value of the mouse Y from the transceiver
	wire [7:0] mouse_SW;		// value of the mouse scrolling wheel from the transceiver

	// instantiate the transceiver module
	mouse_transceiver transceiver (
		.RESET		   (RESET),			// reset the mouse transceiver
		.CLK		   (CLK),			// on-board clock (100MHz)
		.SPEED		   (SPEED),			// controls the moving speed of the pointers
		.CLK_MOUSE	   (CLK_MOUSE),		// the PS2 clock line
		.DATA_MOUSE	   (DATA_MOUSE),	// the PS2 data line
		.MouseStatus   (mouse_status),	// the value of the mouse status
		.MouseX		   (mouse_X),		// the value of the mouse X
		.MouseY		   (mouse_Y),		// the value of the mouse Y
		.MouseSW	   (mouse_SW),		// the value of the mouse scrolling wheel
		.MouseInterrupt(MouseInterrupt)	// interrupt signal of the mouse driver from the transceiver
	);
	
	
	////////////////////////////
	// BaseAddr + 0 -> reports the MouseStatus
	// BaseAddr + 1 -> reports the MouseX
	// BaseAddr + 2 -> reports the MouseY
	// BaseAddr + 3 -> reports the Mouse Scrolling Wheel
	////////////////////////////
	
	// define a register to hold the bus data from the mouse
	reg [7:0] MouseData;
	
	always@(posedge CLK) begin
		if(RESET)
			MouseData <= 8'h00;
		else begin
			// a case statement is used to realise the MouseData reporting configuration
			case(BUS_ADDR)
				// reports the MouseStatus
				(MouseBaseAddr + 8'h00):
					MouseData <= mouse_status;
				// reports the MouseX
				(MouseBaseAddr + 8'h01):
					MouseData <= mouse_X;
				// reports the MouseY
				(MouseBaseAddr + 8'h02):
					MouseData <= mouse_Y;
				// reports the MouseSW
				(MouseBaseAddr + 8'h03):
					MouseData <= mouse_SW;				
			endcase
		end
	end
					
	// broadcast the interrupt
	reg Interrupt;
	
	always@(posedge CLK) begin
		// set the interrupt to 0 when reset
		if(RESET)
			Interrupt <= 1'b0;
		// set the interrupt to 1 when the mouse transceiver sends an interrupt
		else if(MouseInterrupt)
			Interrupt <= 1'b1;
		// set the interrupt to 0 when the microprocessor sends back an acknowledgement
		else if(BUS_INTERRUPT_ACK)
			Interrupt <= 1'b0;
	end
	
	// connects the output to the interrupt register
	assign BUS_INTERRUPT_RAISE = Interrupt;
	
	// tristate output for interrupt mouse output value
	reg TransmitMouseValue;
	
	// enable the tristate output of the BUS_DATA when BUS_ADDR is in the range of the memory map of the mouse driver
	always@(posedge CLK) begin
		if((BUS_ADDR >= MouseBaseAddr) & (BUS_ADDR <= MouseBaseAddr+8'h03))
			TransmitMouseValue <= 1'b1;
		else
			TransmitMouseValue <= 1'b0;
	end
	// the tristate output configuration
	assign BUS_DATA = (TransmitMouseValue) ? MouseData[7:0] : 8'hZZ;
endmodule