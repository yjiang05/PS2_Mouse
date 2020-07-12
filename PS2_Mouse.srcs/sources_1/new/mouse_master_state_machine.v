`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/01/28 09:42:20
// Design Name: Assessment 1 - Mouse Interface
// Module Name: mouse_master_state_machine
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: The master state machine used in the mouse interface.
// 
// Dependencies: None
// 
// Revision:
// Revision 4.0  - Extra Features Added
// Revision 3.1  - Implementation Complete
// Revision 3.0  - Debugged (State 4'h8: the device should acknowledge by sending "FA")
// Revision 2.0  - Debugged (State 4'h9: removed the statements that go back to the state 4'h0)
// Revision 1.0	 - Blank Filled
// Revision 0.01 - File Created
// Additional Comments:
// 				   State Table
// 	State Code 		             State Description
// 	6'h00				initial state
// 	6'h01 				initialisation by sending FF
// 	6'h02 				wait for the confirmation of the byte being sent
// 	6'h03               wait for acknowledgement from the device
// 	6'h04				wait for self-test pass confirmation
// 	6'h05 			    wait for device ID
//	6'h06				attempt to set sample rate by sending F3, attempt to enter Microsoft scrolling mouse mode
//  6'h07				wait for confirmation of a byte being sent
//  6'h08				set sample rate 200 by sending C8
//  6'h09				wait for confirmation of a byte being sent
//	6'h0A				wait for confirmation of a byte being received, if the byte received is FA goto next state, else re-initialise
//	6'h0B				attempt to set sample rate by sending F3
//	6'h0C 				wait for confirmation of a byte being sent
//	6'h0D				set sample rate 100 by sending 64
//	6'h0E				wait for confirmation of a byte being sent
//	6'h0F				wait for confirmation of a byte being received, if the byte received is FA goto next state, else re-initialise
//	6'h10				attempt to set sample rate by sending F3
//	6'h11				wait for confirmation of a byte being sent
//	6'h12				set sample rate 80 by sending 50
//	6'h13				wait for confirmation of a byte being sent
//	6'h14				wait for confirmation of a byte being received, if the byte received is FA goto next state, else re-initialise
//	6'h15				attempt to read device type by sending F2
//	6'h16				wait for confirmation of a byte being sent
//	6'h17				wait for confirmation of a byte being received, if the byte received is FA goto next state, else re-initialise
//	6'h18				wait for confirmation of a byte being received, if the byte is 03 goto next state (response 03 if Microsoft scrolling mouse) else re-initialise				
// 	6'h19				send F4 to start transmission
// 	6'h1A 			    wait for the confirmation of the byte being sent
// 	6'h1B				the device acknowledges by sending FA back
// 	6'h1C 				read the first byte and save it as the status byte
// 	6'h1D				read the second byte and save it as the Dx byte
// 	6'h1E				read the third byte and save it as the Dy byte
//	6'h1F				read the last byte and save it as the SW byte
// 	6'h20				send interrupt state
//
//	Interface:
//		RESET:             Reset the transmitter to the default state.
//		CLK:               The on-board clock (100MHz).
//		SEND_BYTE:		   Controls the transmitter to send the byte.
//		BYTE_TO_SEND:	   The byte that the transmitter sends.
//      BYTE_SENT:		   From the transmitter, indicating that the byte is sent.
//      READ_ENABLE:	   Controls the receiver to read the byte.
//      BYTE_READ:		   The byte read by the receiver.
//		BYTE_ERROR_CODE:   "00" for error-free. "01" for parity bit error. "10" for stop bit error.
//		BYTE_READY:		   From the receiver, indicating that the byte is received.
//		MOUSE_DX:		   X direction byte.
//		MOUSE_DY:		   Y direction byte.
//		MOUSE_SW:		   Scrolling wheel byte.
//		MOUSE_STATUS:      Status byte.
//		SEND_INTERRUPT:	   Send the interrupt (use with the microprocessor).
//		MASTER_STATE_CODE: For the debugger.
//////////////////////////////////////////////////////////////////////////////////


module mouse_master_state_machine(
    input        CLK,				// connect to the on-board clock line (100MHz)
    input        RESET,				// connect to the middle button to reset the state machine
    // transmitter control
    output       SEND_BYTE,			// connect to the input of the transmitter
    output [7:0] BYTE_TO_SEND,		// connect to the input of the transmitter
    input        BYTE_SENT,			// connect to the output of the transmitter
    // receiver control
    output       READ_ENABLE,		// connect to the input of the receiver
    input  [7:0] BYTE_READ,			// connect to the output of the receiver
    input  [1:0] BYTE_ERROR_CODE,	// connect to the output of the receiver
    input        BYTE_READY,		// connect to the output of the receiver
    // data registers
    output [7:0] MOUSE_DX,			// connect to the input of the transceiver
    output [7:0] MOUSE_DY,			// connect to the input of the transceiver
	output [7:0] MOUSE_SW,			// connect to the input of the transceiver
    output [7:0] MOUSE_STATUS,		// connect to the input of the transceiver
    output       SEND_INTERRUPT,	// connect to the input of the transceiver
	output [5:0] MASTER_STATE_CODE	// connect to the probe of the ila debugger
    );
    
    //////////////////////////////////////////////
    //          Main state machine - there is a setup sequence
    //
    //  1) Send FF -- reset command
    //  2) Read FA -- Mouse Acknowledge
    //  3) Read AA -- Self-test pass
    //  4) Read 00 -- Mouse ID
	//  5) Send F3 -- Set sample rate
	//  6) Send C8 -- Decimal 200
	//  7) Read FA -- Acknowledge
	//  8) Send F3 -- Set sample rate
	//  9) Send 64 -- Decimal 100
	// 10) Read FA -- Acknowledge
	// 11) Send F3 -- Set sample rate
	// 12) Send 50 -- Decimal 80
	// 13) Read FA -- Acknowledge
	// 14) Send F2 -- Read device type
	// 15) Read FA -- Acknowledge
	// 16) Read 03 -- MouseID
    // 17) Send F4 -- Start transmitting command
    // 18) Read FA -- Mouse acknowledge
    //
    // If at any time this chain is broken, the SM will restart from the beginning.
    // Once it has finished the setup sequence, the read enable flag is raised.
    // The host is then ready to read mouse information 3 bytes at a time:
    // S1) Wait for first read, when it arrives, save it to Status. Goto S2.
    // S2) Wait for second read, when it arrives, save it to DX. Goto S3.
    // S3) Wait for third read, when it arrives, save it to DY. Goto S4.
	// S4) Wait for fourth read, when it arrives, save it to SW. Goto S1.
    // Send interrupt.
    //////////////////////////////////////////////

    // state control
    reg [5:0]  Curr_State, 		   Next_State;
    reg [23:0] Curr_Counter, 	   Next_Counter;
    // transmitter control
    reg        Curr_SendByte, 	   Next_SendByte;
    reg [7:0]  Curr_ByteToSend,    Next_ByteToSend;
    // receiver control
    reg        Curr_ReadEnable,    Next_ReadEnable;
    // data registers
    reg [7:0]  Curr_Status, 	   Next_Status;
    reg [7:0]  Curr_Dx,            Next_Dx;
    reg [7:0]  Curr_Dy, 		   Next_Dy;
	reg [7:0]  Curr_SW,			   Next_SW;
    reg    	   Curr_SendInterrupt, Next_SendInterrupt;
    
    // sequential
    always@(posedge CLK) begin
        if(RESET) begin
            Curr_State         <= 6'h00;
            Curr_Counter       <= 0;
            Curr_SendByte      <= 1'b0;
            Curr_ByteToSend    <= 8'h00;
            Curr_ReadEnable    <= 1'b0;
            Curr_Status        <= 8'h00;
            Curr_Dx            <= 8'h00;
            Curr_Dy            <= 8'h00;
			Curr_SW			   <= 8'h00;
            Curr_SendInterrupt <= 1'b0;
        end else begin
            Curr_State         <= Next_State;
            Curr_Counter       <= Next_Counter;
            Curr_SendByte      <= Next_SendByte;
            Curr_ByteToSend    <= Next_ByteToSend;
            Curr_ReadEnable    <= Next_ReadEnable;
            Curr_Status        <= Next_Status;
            Curr_Dx            <= Next_Dx;
            Curr_Dy            <= Next_Dy;
			Curr_SW            <= Next_SW;
            Curr_SendInterrupt <= Next_SendInterrupt;
        end
    end
    
    // combinatorial
    always@* begin
        Next_State         = Curr_State;
        Next_Counter       = Curr_Counter;
        Next_SendByte      = 1'b0;
        Next_ByteToSend    = Curr_ByteToSend;
        Next_ReadEnable    = 1'b0;
        Next_Status        = Curr_Status;
        Next_Dx            = Curr_Dx;
        Next_Dy            = Curr_Dy;
		Next_SW			   = Curr_SW;
        Next_SendInterrupt = 1'b0;
        
        case(Curr_State)
            // initialise state - wait here for 10ms before trying to initialise the mouse
            6'h00: begin
                if(Curr_Counter == 1000000) begin // 1/100 sec at 100MHZ clock
                    Next_State   = 6'h01;
                    Next_Counter = 0;
                end else
                    Next_Counter = Curr_Counter + 1'b1;
                end 
				
            // start initialisation by sending FF
            6'h01: begin
                Next_State      = 6'h02;
                Next_SendByte   = 1'b1;
                Next_ByteToSend = 8'hFF;
            end
			
            // wait for confirmation of the byte being sent
            6'h02: begin
                if(BYTE_SENT)
                    Next_State = 6'h03;
            end
			
            // wait for confirmation of a byte being received
            // if the byte is FA goto next state, else re-initialise
            6'h03: begin
                if(BYTE_READY) begin
                    if((BYTE_READ == 8'hFA) & (BYTE_ERROR_CODE == 2'b00))
                        Next_State = 6'h04;
                    else
                        Next_State = 6'h00;
                end
                Next_ReadEnable = 1'b1;
            end
			
            // wait for self-test pass confirmation
            // if the byte received is AA goto next state, else re-initialise
            6'h04: begin
                if(BYTE_READY) begin
                    if((BYTE_READ == 8'hAA) & (BYTE_ERROR_CODE == 2'b00))
                        Next_State = 6'h05;
                    else
                        Next_State = 6'h00;
                end
                Next_ReadEnable = 1'b1;
            end
			
            // wait for confirmation of a byte being received
            // if the byte is 00 goto next state (MOUSE ID) else re-initialise
            6'h05: begin
                if(BYTE_READY) begin
                    if((BYTE_READ == 8'h00) & (BYTE_ERROR_CODE == 2'b00))
                        Next_State = 6'h06;
                    else
                        Next_State = 6'h00;
                end
                Next_ReadEnable = 1'b1;
            end
			
			// attempt to set sample rate by sending F3
			// attempt to enter Microsoft scrolling mouse mode
			6'h06: begin
				Next_State 		= 6'h07;
				Next_SendByte 	= 1'b1;
				Next_ByteToSend = 8'hF3;
			end
			
			// wait for confirmation of a byte being sent
			6'h07: begin
				if(BYTE_SENT)
					Next_State = 6'h08;
			end
			
			// set sample rate 200 by sending C8
			6'h08: begin
				Next_State 		= 6'h09;
				Next_SendByte 	= 1'b1;
				Next_ByteToSend = 8'hC8;
			end

			// wait for confirmation of a byte being sent
			6'h09: begin
				if(BYTE_SENT)
					Next_State = 6'h0A;
			end
			
            // wait for confirmation of a byte being received
            // if the byte received is FA goto next state, else re-initialise
			6'h0A: begin
				if(BYTE_READY) begin
					if((BYTE_READ == 8'hFA) & (BYTE_ERROR_CODE == 2'b00))
						Next_State = 6'h0B;
					else
						Next_State = 6'h00;
				end
				Next_ReadEnable = 1'b1;
			end
			
			// attempt to set sample rate by sending F3
			6'h0B: begin
				Next_State 		= 6'h0C;
				Next_SendByte 	= 1'b1;
				Next_ByteToSend = 8'hF3;
			end
			
			// wait for confirmation of a byte being sent
			6'h0C: begin
				if(BYTE_SENT)
					Next_State = 6'h0D;
			end
			
			// set sample rate 100 by sending 64
			6'h0D: begin
				Next_State 		= 6'h0E;
				Next_SendByte 	= 1'b1;
				Next_ByteToSend = 8'h64;
			end

			// wait for confirmation of a byte being sent
			6'h0E: begin
				if(BYTE_SENT)
					Next_State = 6'h0F;
			end

            // wait for confirmation of a byte being received
            // if the byte received is FA goto next state, else re-initialise			
			6'h0F: begin
				if(BYTE_READY) begin
					if((BYTE_READ == 8'hFA) & (BYTE_ERROR_CODE == 2'b00))
						Next_State = 6'h10;
					else
						Next_State = 6'h00;
				end
				Next_ReadEnable = 1'b1;
			end

			// attempt to set sample rate by sending F3
            6'h10 : begin
                Next_State 		= 6'h11;
                Next_SendByte 	= 1'b1;
                Next_ByteToSend = 8'hF3;
            end
			
			// wait for confirmation of a byte being sent
			6'h11 : begin
                if(BYTE_SENT)
                    Next_State = 6'h12;
            end

			// set sample rate 80 by sending 50
            6'h12 : begin
                Next_State 		= 6'h13;
                Next_SendByte 	= 1'b1;
                Next_ByteToSend = 8'h50;
            end

			// wait for confirmation of a byte being sent
            6'h13 : begin
                if(BYTE_SENT)
                    Next_State = 6'h14;
            end

            // wait for confirmation of a byte being received
            // if the byte received is FA goto next state, else re-initialise			
            6'h14 : begin
                if(BYTE_READY) begin
                    if((BYTE_READ == 8'hFA) & (BYTE_ERROR_CODE == 2'b00))
                        Next_State = 6'h15;
                    else
                        Next_State = 6'h00;
                end
                Next_ReadEnable = 1'b1;
            end
			
			// attempt to read device type by sending F2
            6'h15 : begin
                Next_State 		= 6'h16;
                Next_SendByte 	= 1'b1;
                Next_ByteToSend = 8'hF2;
            end
			
			// wait for confirmation of a byte being sent
            6'h16 : begin
                if(BYTE_SENT)
                    Next_State = 6'h17;
            end

            // wait for confirmation of a byte being received
            // if the byte received is FA goto next state, else re-initialise			
            6'h17 : begin
                if(BYTE_READY) begin
                    if((BYTE_READ == 8'hFA) & (BYTE_ERROR_CODE == 2'b00))
                        Next_State = 6'h18;
                    else
                        Next_State = 6'h00;
                end
                Next_ReadEnable = 1'b1;
            end

            // wait for confirmation of a byte being received
            // if the byte is 03 goto next state (response 03 if Microsoft scrolling mouse) else re-initialise
            6'h18 : begin
                if(BYTE_READY) begin
                    if((BYTE_READ == 8'h03) & (BYTE_ERROR_CODE == 2'b00))
                        Next_State = 6'h19;
                    else
                        Next_State = 6'h00;
                end
                Next_ReadEnable = 1'b1;            
            end

            // send F4 - to start mouse transmit
            6'h19: begin
                Next_State 		= 6'h1A;
                Next_SendByte 	= 1'b1;
                Next_ByteToSend = 8'hF4;
            end
			
            // wait for confirmation of the byte being sent
            6'h1A: begin
                if(BYTE_SENT)
                    Next_State = 6'h1B;
            end
			
            // wait for confirmation of a byte being received
            // if the byte is "FA" goto next state, else re-initialise
            6'h1B: begin
                if(BYTE_READY) begin
                    if(BYTE_READ == 8'hFA)
                        Next_State = 6'h1C;
                    else
                        Next_State = 6'h00;
                end
                Next_ReadEnable = 1'b1;
            end

            //////////////////////////////////////////////
            // At this point the SM has initialised the mouse.
            // Now we are constantly reading. If at any time there is an error, we will re-initialise the mouse - just in case.
            //////////////////////////////////////////////
        
            // wait for the confirmation of a byte being received
            // this byte will be the first of four, the status byte
            // if a byte arrives, but is corrupted, then we re-initialise.
            6'h1C: begin
                if(BYTE_READY & (BYTE_ERROR_CODE == 2'b00)) begin
                    Next_State  = 6'h1D;
                    Next_Status = BYTE_READ;
                end
                Next_Counter = 0;
                Next_ReadEnable = 1'b1;
            end
			
            // wait for confirmation of a byte being received
            // this byte will be the second of four, the Dx byte
            6'h1D: begin
                if(BYTE_READY & (BYTE_ERROR_CODE == 2'b00)) begin
                    Next_State = 6'h1E;
                    Next_Dx    = BYTE_READ;
                end
                Next_ReadEnable = 1'b1;
            end
			
            // wait for confirmation of a byte being received
            // this byte will be the third of four, the Dy byte
            6'h1E: begin
                if(BYTE_READY & (BYTE_ERROR_CODE == 2'b00)) begin
                    Next_State = 6'h1F;
                    Next_Dy    = BYTE_READ;
                end
                Next_ReadEnable = 1'b1;
            end
			
            // wait for confirmation of a byte being received
            // this byte will be the last of four, the scrolling wheel byte			
            6'h1F: begin
                if(BYTE_READY & (BYTE_ERROR_CODE == 2'b00)) begin
                    Next_State = 6'h20;
                    Next_SW    = BYTE_READ;
                end
                Next_ReadEnable = 1'b1;
            end

            // send interrupt state
            6'h20: begin
                Next_State 		   = 6'h1C;
                Next_SendInterrupt = 1'b1;
            end
			
            // default state
            default: begin
                Next_State         = 6'h00;
                Next_Counter       = 0;
                Next_SendByte      = 1'b0;
                Next_ByteToSend    = 8'hFF;
                Next_ReadEnable    = 1'b0;
                Next_Status        = 8'h00;
                Next_Dx            = 8'h00;
                Next_Dy            = 8'h00;
				Next_SW            = 8'h00;
                Next_SendInterrupt = 1'b0;
            end
        endcase
    end
    
    //////////////////////////////////////////////
    // tie the SM signals to the IO.
    //////////////////////////////////////////////    
    // transmitter
    assign SEND_BYTE      	 = Curr_SendByte;
    assign BYTE_TO_SEND   	 = Curr_ByteToSend;
    // receiver
    assign READ_ENABLE    	 = Curr_ReadEnable;
    // output mouse data
    assign MOUSE_DX       	 = Curr_Dx;
    assign MOUSE_DY       	 = Curr_Dy;
	assign MOUSE_SW			 = Curr_SW;
    assign MOUSE_STATUS   	 = Curr_Status;
    assign SEND_INTERRUPT 	 = Curr_SendInterrupt;
	// output the state code for the debugger
	assign MASTER_STATE_CODE = Curr_State;
endmodule