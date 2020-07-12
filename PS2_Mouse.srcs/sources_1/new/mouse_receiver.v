`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/01/28 11:17:28
// Design Name: Assessment 1 - Mouse Interface
// Module Name: mouse_receiver
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: A receiver used in the mouse interface
// 
// Dependencies: None
// 
// Revision:
// Revision 2.0	 - Implementation Complete
// Revision 1.0  - Blank Filled
// Revision 0.01 - File Created
// Additional Comments:
//	Interface:
//		RESET:           Reset the transmitter to the default state.
//		CLK:             The on-board clock (100MHz).
//		CLK_MOUSE_IN:	 The PS2 clock line.
//		DATA_MOUSE_IN:	 The PS2 data line.
//		READ_ENABLE:	 Enables the receiver to read data from the device.
//		BYTE_READ:		 The byte read from the device.
//		BYTE_ERROR_CODE: "00" for error-free. "01" for parity bit error. "10" for stop bit error.
//		BYTE_READY:		 Indicates that a byte has been received.
//////////////////////////////////////////////////////////////////////////////////


module mouse_receiver(
    // standard inputs
    input                   RESET,				// connect to the middle button to reset the receiver
    input                   CLK,				// connect to the on-board clock line (100MHz)
    // mouse IO - CLK
    input                   CLK_MOUSE_IN, 		// connect to the PS2 clock line
    // mouse IO - DATA
    input                   DATA_MOUSE_IN,		// connect to the PS2 data line
    // control
    input                   READ_ENABLE, 		// connect to the output of the master state machine
    output      [7:0]       BYTE_READ,			// connect to the input of the master state machine
    output      [1:0]       BYTE_ERROR_CODE,	// connect to the input of the master state machine
    output                  BYTE_READY			// connect to the input of the master state machine
    );
    
    //////////////////////////////////////////////
    // clk mouse delayed to detect clock edges
    reg ClkMouseInDly;
	
    always@(posedge CLK)
		ClkMouseInDly <= CLK_MOUSE_IN;
    //////////////////////////////////////////////
    
    // a simple state machine to handle the incoming 11-bit codewords
    reg 	[2:0]   Curr_State,          Next_State;
    reg 	[7:0]   Curr_MSCodeShiftReg, Next_MSCodeShiftReg;
    reg 	[3:0]   Curr_BitCounter,     Next_BitCounter;
    reg             Curr_ByteReceived,   Next_ByteReceived;
    reg 	[1:0]   Curr_MSCodeStatus,   Next_MSCodeStatus;
    reg 	[15:0] 	Curr_TimeoutCounter, Next_TimeoutCounter;
    
    // sequential    
    always@(posedge CLK) begin
        if(RESET) begin
            Curr_State          <= 3'b000;
            Curr_MSCodeShiftReg <= 8'h00;
            Curr_BitCounter     <= 0;
            Curr_ByteReceived   <= 1'b0;
            Curr_MSCodeStatus   <= 2'b00;
            Curr_TimeoutCounter <= 0;
        end else begin
            Curr_State          <= Next_State;
            Curr_MSCodeShiftReg <= Next_MSCodeShiftReg;
            Curr_BitCounter     <= Next_BitCounter;
            Curr_ByteReceived   <= Next_ByteReceived;
            Curr_MSCodeStatus   <= Next_MSCodeStatus;
            Curr_TimeoutCounter <= Next_TimeoutCounter;
        end
    end
    
    // combinatorial
    always@* begin 	// "*" means sensitive to all changes!
    // defaults to make the State Machine more readable
        Next_State          = Curr_State;
        Next_MSCodeShiftReg = Curr_MSCodeShiftReg;
        Next_BitCounter     = Curr_BitCounter;
        Next_ByteReceived   = 1'b0;
        Next_MSCodeStatus   = Curr_MSCodeStatus;
        Next_TimeoutCounter = Curr_TimeoutCounter + 1'b1;
        
        // the states
        case (Curr_State)
            // falling edge of Mouse clock and MouseData is low i.e. start bit
            3'b000: begin
                if(READ_ENABLE & ClkMouseInDly & ~CLK_MOUSE_IN & ~DATA_MOUSE_IN) begin
                    Next_State        = 3'b001;
                    Next_MSCodeStatus = 2'b00;
                end
                Next_BitCounter = 0;
            end

            // read successive byte bits from the mouse here
            3'b001: begin
                if(Curr_TimeoutCounter == 100000) // 1ms timeout   
                    Next_State = 3'b000;
                else if(Curr_BitCounter == 8) begin // if last bit go to parity bit check 
                    Next_State      = 3'b010;
                    Next_BitCounter = 0;
                end else if(ClkMouseInDly & ~CLK_MOUSE_IN) begin // shift byte bits in
                    Next_MSCodeShiftReg[6:0] = Curr_MSCodeShiftReg[7:1];
                    Next_MSCodeShiftReg[7]   = DATA_MOUSE_IN;
                    Next_BitCounter 		 = Curr_BitCounter + 1;
                    Next_TimeoutCounter 	 = 0;
                end
            end

            // check parity bit
            3'b010: begin
            // falling edge of Mouse clock and MouseData is odd parity
                if(Curr_TimeoutCounter == 100000)
                    Next_State = 3'b000;
                else if(ClkMouseInDly & ~CLK_MOUSE_IN) begin
                    if (DATA_MOUSE_IN != ~^Curr_MSCodeShiftReg[7:0]) // parity bit error
                        Next_MSCodeStatus[0] = 1'b1;
                    Next_BitCounter 	= 0;
                    Next_State 			= 3'b011;
                    Next_TimeoutCounter = 0;
                end
            end
            
            // detect the Stop bit and set MSCodeStatus[1] accordingly
            3'b011: begin
				if(Curr_TimeoutCounter == 100000)
                    Next_State = 3'b000;
                else if(ClkMouseInDly & ~CLK_MOUSE_IN) begin
                    if(DATA_MOUSE_IN) begin
					// if the stop bit is received correctly, go to the next state; otherwise, set the MSB of MSCodeStatus to be "1".
                        Next_State 			 = 3'b100;
                        Next_BitCounter 	 = 0;
                        Next_TimeoutCounter  = 0;
                    end else
						Next_MSCodeStatus[1] = 1'b1;
                end
            end
			            
            // the final state
            3'b100: begin
				// raise the ByteReceived to indicate that a byte is received
				Next_ByteReceived 	= 1'b1;
                Next_State 			= 3'b000;
				Next_BitCounter 	= 0;
				Next_TimeoutCounter = 0;
            end
            
            // the default state
            default: begin
                Next_State 			= 3'b000;
                Next_MSCodeShiftReg = 8'h00;
                Next_BitCounter 	= 0;
                Next_ByteReceived 	= 1'b0;
                Next_MSCodeStatus 	= 2'b00;
                Next_TimeoutCounter = 0;
            end
        endcase
    end
    
	// assign outputs
	// control 
    assign BYTE_READY      = Curr_ByteReceived;
    assign BYTE_READ 	   = Curr_MSCodeShiftReg;
    assign BYTE_ERROR_CODE = Curr_MSCodeStatus;
endmodule