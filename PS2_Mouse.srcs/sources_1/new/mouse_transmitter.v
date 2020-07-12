`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/01/31 17:28:29
// Design Name: Assessment 1 - Mouse Interface
// Module Name: mouse_transmitter
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT Basys3
// Tool Versions: Vivado 2015.2
// Description: A transmitter used in the mouse interface
// 
// Dependencies: None
// 
// Revision:
// Revision 2.1  - Implementation Complete
// Revision 2.0  - Debugged (State 4'h8 "Wait for device to bring clock line low" in the state machine)
// Revision 1.0	 - Blanks Filled
// Revision 0.01 - File Created
// Additional Comments:
// 	Interfaces:
//		RESET:             Reset the transmitter to the default state.
//		CLK:               The on-board clock (100MHz).
//		CLK_MOUSE_IN:      The PS2 clock line.
//		CLK_MOUSE_OUT_EN:  Allows for the control of the clock line.
//		DATA_MOUSE_IN:     The PS2 data line.
//		DATA_MOUSE_OUT:    The data sent to the PS2 device.
//		DATA_MOUSE_OUT_EN: Allows for the control of the data line.
//		SEND_BYTE: 	  	   Controls the transmitter to send a byte.
//		BYTE_TO_SEND:  	   The byte to be sent.
//		BYTE_SENT:         High after a byte being sent.
//////////////////////////////////////////////////////////////////////////////////


module mouse_transmitter(
	// standard inputs
    input 			RESET,			  	// connect to the middle button to reset the transmitter
    input 			CLK,			  	// connect to the on-board clock line (100MHz)
	// mouse IO - CLK
    input 			CLK_MOUSE_IN,	  	// connect to the PS2 clock line
    output 			CLK_MOUSE_OUT_EN, 	// allows for the control of the clock line
	// moues IO - DATA
    input 			DATA_MOUSE_IN,	  	// connect to the PS2 data line
    output 			DATA_MOUSE_OUT,	  	// connect to the PS2 data line
    output 			DATA_MOUSE_OUT_EN,	// allows for the control of the data line
	// control
    input 			SEND_BYTE,			// connect to the output of the master state machine
    input	[7:0]	BYTE_TO_SEND,		// connect to the output of the master state machine
    output 			BYTE_SENT			// connect to the input of the master state machine
    );
	
	//////////////////////////////////////////////////////////
	// clk mouse delayed to detect clock edges
	reg ClkMouseInDly;
	
	always@(posedge CLK)
		ClkMouseInDly <= CLK_MOUSE_IN;
	//////////////////////////////////////////////////////////
	
	// now a state machine to control the flow of write data
	reg 	[3:0] 	Curr_State, 		 Next_State;
	reg 			Curr_MouseClkOutWE,  Next_MouseClkOutWE;
	reg 			Curr_MouseDataOut, 	 Next_MouseDataOut;
	reg 			Curr_MouseDataOutWE, Next_MouseDataOutWE;
	reg 	[15:0] 	Curr_SendCounter, 	 Next_SendCounter;
	reg 			Curr_ByteSent, 		 Next_ByteSent;
	reg 	[7:0] 	Curr_ByteToSend, 	 Next_ByteToSend;
	
	// sequential
	always@(posedge CLK) begin
		if(RESET) begin
			Curr_State 			<= 4'h0;
			Curr_MouseClkOutWE 	<= 1'b0;
			Curr_MouseDataOut 	<= 1'b0;
			Curr_MouseDataOutWE <= 1'b0;
			Curr_SendCounter 	<= 0;
			Curr_ByteSent 		<= 1'b0;
			Curr_ByteToSend 	<= 0;
		end else begin
			Curr_State 			<= Next_State;
			Curr_MouseClkOutWE 	<= Next_MouseClkOutWE;
			Curr_MouseDataOut 	<= Next_MouseDataOut;
			Curr_MouseDataOutWE <= Next_MouseDataOutWE;
			Curr_SendCounter 	<= Next_SendCounter;
			Curr_ByteSent 		<= Next_ByteSent;
			Curr_ByteToSend 	<= Next_ByteToSend;
		end
	end
	
	// combinatorial
	always@* begin
		// default values
		Next_State 			= Curr_State;
		Next_MouseClkOutWE 	= 1'b0;
		Next_MouseDataOut 	= 1'b0;
		Next_MouseDataOutWE = Curr_MouseDataOutWE;
		Next_SendCounter 	= Curr_SendCounter;
		Next_ByteSent 		= 1'b0;
		Next_ByteToSend 	= Curr_ByteToSend;
		
		case(Curr_State)
			// iDLE
			4'h0 : begin
				if(SEND_BYTE) begin
					Next_State 		= 4'h1;
					Next_ByteToSend = BYTE_TO_SEND;
				end
				Next_MouseDataOutWE = 1'b0;
			end

			// bring clock line low for at least 100 microsecs i.e. 10000 clock cycles @ 100MHz
			4'h1 : begin
				if(Curr_SendCounter == 12000) begin
					Next_State 	   	 = 4'h2;
					Next_SendCounter = 0;
				end else
					Next_SendCounter = Curr_SendCounter + 1'b1;
				Next_MouseClkOutWE = 1'b1;
			end

			// bring the data line low and release the clock line
			4'h2 : begin
				Next_State 			= 4'h3;
				Next_MouseDataOutWE = 1'b1;
			end
			
			// start sending
			4'h3 : begin	// change data at falling edge of clock, start bit = 0
				if(ClkMouseInDly & ~CLK_MOUSE_IN)
					Next_State = 4'h4;
			end
			
			// send bits 0 to 7 - we need to send the byte
			4'h4 : begin	// change data at falling edge of clock
				if(ClkMouseInDly & ~CLK_MOUSE_IN) begin
					if(Curr_SendCounter == 7) begin
						Next_State 		 = 4'h5;
						Next_SendCounter = 0;
					end else
						Next_SendCounter = Curr_SendCounter + 1'b1;
				end
				Next_MouseDataOut = Curr_ByteToSend[Curr_SendCounter];
			end
			
			// send the parity bit
			4'h5 : begin 	// change data at falling edge of clock
				if(ClkMouseInDly & ~CLK_MOUSE_IN)
					Next_State = 4'h6;
				Next_MouseDataOut = ~^Curr_ByteToSend[7:0];
			end
			
			// release Data line
			4'h6 : begin
				Next_State 			= 4'h7;
				Next_MouseDataOutWE = 1'b0;
			end

			/*
			Wait for Device to bring Data line low, then wait for Device to bring Clock line low, and finally wait for
			Device to release both Data and Clock.
			*/
			
			// wait for device to bring data line low
			4'h7: begin
				if (~DATA_MOUSE_IN) begin
					Next_State = 4'h8;
				end
			end
			
			// wait for device to bring clock line low
			4'h8: begin
				if (ClkMouseInDly & ~CLK_MOUSE_IN) begin
					Next_State = 4'h9;
				end
			end
			
			// wait for device to release both data and clock lines
			4'h9: begin
				if (DATA_MOUSE_IN & CLK_MOUSE_IN) begin 	// the device releases the data and clock by setting them high
					Next_ByteSent = 1'b1;
					Next_State = 4'h0;
				end
			end
			
			// default state
			default: begin
				Next_State 			= 4'h0;
				Next_MouseClkOutWE  = 1'b0;
				Next_MouseDataOut 	= 1'b0;
				Next_MouseDataOutWE = 1'b0;
				Next_SendCounter 	= 0;
				Next_ByteSent 		= 1'b0;
				Next_ByteToSend 	= 0;
			end	
		endcase
	end
	
	///////////////////////////////////////////////////////////////
	// assign outputs
	// mouse IO - CLK
	assign CLK_MOUSE_OUT_EN  = Curr_MouseClkOutWE;
	// mouse IO - DATA
	assign DATA_MOUSE_OUT 	 = Curr_MouseDataOut;
	assign DATA_MOUSE_OUT_EN = Curr_MouseDataOutWE;
	// control
	assign BYTE_SENT 	 	 = Curr_ByteSent;
endmodule