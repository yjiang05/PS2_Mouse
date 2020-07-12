`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/02/01 18:57:46
// Design Name: Assessment 1 - Mouse Interface
// Module Name: mouse_transceiver
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: A wrapper including the transmitter, the receiver, and the master state machine used in the mouse interface
// 
// Dependencies: mouse_receiver.v, mouse_transmitter.v, mouse_master_state_machine.v
// 
// Revision:
// Revision 2.0  - Extra Features Added
// Revision 1.1  - Implementation Complete
// Revision 1.0  - Blank Filled
// Revision 0.01 - File Created
// Additional Comments:
// 	Interface:
//		RESET:Reset the transceiver to the default state.
//		CLK:         The on-board clock (100MHz).
//		CLK_MOUSE:   The PS2 clock line.
//		DATA_MOUSE:  The PS2 data line.
//		MouseStatus: The status byte of the mouse device.
//		MouseX: 	 The X direction byte of the mouse device.
//		MouseY: 	 The Y direction byte of the mouse device.
//      MouseSW:     The byte of the mouse scrolling wheel
//
//
//	The block diagram
//
/*                                             CLK        RESET
                                             /           /
                                             |           |
                                             |           |
                                             |           |
         +-----------------------------------\-----------\-------------------------------------+     
         |                                                                                     |     
         |                                                                                     |     
         |                                            +------------------------------------+   |     
         |                                            | RESET                        CLK   |   |     
         |                                            |                                    |   |     
         |                                            |                                    |   |     
         |   +------------------------------+         |                                    |   |     
         |   |                              |         |                                    |   |     
         |   | RESET                SendByte----------- SendByte                           |   |     
         |   | CLK                ByteToSend----------- ByteToSend      Transmitter        |   |     
         |   |                      ByteSent----------- ByteSent                           |   |     
         |   |                              |         |                                    |   |     
         |   |                              |         |                                    |   |     
         |   |                              |         |                                    |   |     
         |   |                              |         |                                    |   |     
         |   |                              |         |     DATA_MOUSE          CLK_MOUSE  |   |     
         |   |                              |         +---------/-------------------/------+   |     
         |   |                              |                   |                    ---------------CLK_line
         |   |          Master              |                   --------------------|---------------Data_line
         |   |       State Machine          |         +---------\-------------------\------+   |     
         |   |                              |         |     DATA_MOUSE          CLK_MOUSE  |   |     
         |   |                              |         |                                    |   |
         |   |                              |         |                                    |   |
         |   |                              |         |                                    |   |
         |   |                       Read_EN----------- Read_EN                            |   |
         |   |                      ByteRead----------- ByteRead        Receiver           |   |
         |   |                     ErrorCode----------- ErrorCode                          |   |
         |   |                     ByteReady----------- ByteReady                          |   |
         |   |                 SendInterrupt-----/    |                                    |   |
         |   |                              |    |    |                                    |   |
         |   |                              |    |    |                                    |   |
         |   |                           SW ---/ |    |                                    |   |
         |   |                              |  | |    |                                    |   |
         |   |                              |  | |    |                                    |   |
         |   |                              |  | |    |                                    |   |             
         |   | Mouse      Mouse      Mouse  |  | |    |     RESET               CLK        |   |             
         |   |Status       DX         DY    |  | |    |                                    |   |             
         |   +---/----------/----------/----+  | |    +------------------------------------+   |             
         |       |          |          |       | |                                             |             
         |       |          |          |       | |                                             |             
         |       |          |          |       | |                                             |             
         |       |          |          |       | |                                             |             
         |       |          |          |       | |                                             |             
         |   +---\----------\----------\----+  | |                                             |             
         |   | Mouse      Mouse      Mouse  |  | |                                             |             
         |   |Status       DX         DY    |  | |                                             |             
         |   |                              |  | |                                             |             
         |   |                           SW ---\ |                                             |             
         |   |                              |    |                                             |             
         |   |       Pre-Processing         |    |                                             |             
         |   |                              -----\                                             |             
         |   |                              |                                                  |             
         |   |                           SW -----/                                             |             
         |   |                              |    |                                             |             
         |   | Mouse      Mouse      Mouse  |    |                                             |             
         |   |Status       DX         DY    |    |                                             |             
         |   +---/----------/----------/----+    |                                             |             
         |       |          |          |         |                                             |             
         +-------|----------|----------|---------|---------------------------------------------+             
                 |          |          |         |                                                           
                 |          |          |         |                                                  
                 \          \          \         \                                                  
              Status       Dx         Dy        SW                                             
 */
//////////////////////////////////////////////////////////////////////////////////


module mouse_transceiver(
	// standard inputs
    input 			 RESET, 	  // connect to the middle button to reset the receiver
    input 			 CLK,		  // connect to the on-board clock line (100MHz)
	input			 SPEED,
	// IO - mouse side
    inout 			 CLK_MOUSE,   // connect to the PS2 clock line
    inout 			 DATA_MOUSE,  // connect to the PS2 data line
	// mouse data information
    output reg [3:0] MouseStatus, // connect to the input of the top wrapper
    output reg [7:0] MouseX,	  // connect to the input of the top wrapper
    output reg [7:0] MouseY,	  // connect to the input of the top wrapper
	output reg [7:0] MouseSW,	  // connect to the input of the top wrapper 
	// interrupt signal
	output 			 MouseInterrupt
    );
	
	// X, Y Limits of Mouse Position e.g. VGA Screen with 160 x 120 resolution
	parameter [7:0] MouseLimitX  = 160;
	parameter [7:0] MouseLimitY  = 120;
	// limit for the value of the scrolling wheel
	parameter [7:0] MouseLimitSW = 255;
	/////////////////////////////////////////////////////////////////////
	
	//TriState Signals
	//Clk
	reg  ClkMouseIn;
	wire ClkMouseOutEnTrans;
	
	//Data
	wire DataMouseIn;
	wire DataMouseOutTrans;
	wire DataMouseOutEnTrans;
	
	//Clk Output - can be driven by host or device
	assign CLK_MOUSE   = ClkMouseOutEnTrans ? 1'b0 : 1'bz;
	
	//Clk Input
	assign DataMouseIn = DATA_MOUSE;

	//Clk Output - can be driven by host or device
	assign DATA_MOUSE  = DataMouseOutEnTrans ? DataMouseOutTrans : 1'bz;
	/////////////////////////////////////////////////////////////////////

	//This section filters the incoming Mouse clock to make sure that
	//it is stable before data is latched by either transmitter
	//or receiver modules
	reg [7:0] MouseClkFilter;
	
	always@(posedge CLK) begin
		if(RESET)
			ClkMouseIn <= 1'b0;
		else begin
			// a simple shift register
			MouseClkFilter[7:1] <= MouseClkFilter[6:0];
			MouseClkFilter[0] 	<= CLK_MOUSE;
			
			//falling edge
			if(ClkMouseIn & (MouseClkFilter == 8'h00))
				ClkMouseIn <= 1'b0;
			
			//rising edge
			else if(~ClkMouseIn & (MouseClkFilter == 8'hFF))
				ClkMouseIn <= 1'b1;
		end
	end
	
	///////////////////////////////////////////////////////
	// instantiate the transmitter module
	// define the intermediate wires
	wire 	   SendByteToMouse;
	wire 	   ByteSentToMouse;
	wire [7:0] ByteToSendToMouse;
	
	mouse_transmitter tx(
		// standard inputs
		.RESET 				(RESET),
		.CLK				(CLK),
		// mouse IO - CLK
		.CLK_MOUSE_IN		(ClkMouseIn),
		.CLK_MOUSE_OUT_EN	(ClkMouseOutEnTrans),
		// mouse IO - DATA
		.DATA_MOUSE_IN		(DataMouseIn),
		.DATA_MOUSE_OUT		(DataMouseOutTrans),
		.DATA_MOUSE_OUT_EN	(DataMouseOutEnTrans),
		// control
		.SEND_BYTE			(SendByteToMouse),
		.BYTE_TO_SEND		(ByteToSendToMouse),
		.BYTE_SENT			(ByteSentToMouse)
	);

	///////////////////////////////////////////////////////
	// instantiate the receiver module
	// define the intermediate wires
	wire 	   ByteReady;
	wire 	   ReadEnable;
	wire [7:0] ByteRead;
	wire [1:0] ByteErrorCode;
	
	mouse_receiver rx(
		// standard inputs
		.RESET		     (RESET),
		.CLK			 (CLK),
		// mouse IO - CLK
		.CLK_MOUSE_IN    (ClkMouseIn),
		// mouse IO - DATA
		.DATA_MOUSE_IN   (DataMouseIn),
		// control
		.READ_ENABLE     (ReadEnable),
		.BYTE_READ	   	 (ByteRead),
		.BYTE_ERROR_CODE (ByteErrorCode),
		.BYTE_READY	     (ByteReady)
	);

	///////////////////////////////////////////////////////
	// instantiate the master state machine module
	// define the intermediate wires
	wire 	   SendInterrupt;
	wire [7:0] MouseStatusRaw;
	wire [7:0] MouseDxRaw;
	wire [7:0] MouseDyRaw;
	wire [7:0] MouseSWRaw;
	// for the debugger
	wire [5:0] MasterStateCode;
	
	mouse_master_state_machine MSM(
		// standard inputs
		.RESET			   (RESET),
		.CLK			   (CLK),
		// transmitter interface
		.SEND_BYTE		   (SendByteToMouse),
		.BYTE_TO_SEND	   (ByteToSendToMouse),
		.BYTE_SENT		   (ByteSentToMouse),
		// receiver interface
		.READ_ENABLE 	   (ReadEnable),
		.BYTE_READ		   (ByteRead),
		.BYTE_ERROR_CODE   (ByteErrorCode),
		.BYTE_READY	       (ByteReady),
		// data registers
		.MOUSE_STATUS	   (MouseStatusRaw),
		.MOUSE_DX		   (MouseDxRaw),
		.MOUSE_DY		   (MouseDyRaw),
		.MOUSE_SW		   (MouseSWRaw),
		.SEND_INTERRUPT	   (SendInterrupt),
		// for the debugger
		.MASTER_STATE_CODE (MasterStateCode)
	);
	
	// Pre-processing - handling of overflow and signs.
	// More importantly, this keeps tabs on the actual X/Y
	// location of the mouse.
	wire signed [8:0] MouseDx;
	wire signed [8:0] MouseDy;
	wire signed [8:0] MouseDSW;
	wire signed [8:0] MouseNewX;
	wire signed [8:0] MouseNewY;
	wire signed [8:0] MouseNewSW;

	// DX and DY are modified to take account of overflow and direction
	assign MouseDx = (MouseStatusRaw[6]) ? (MouseStatusRaw[4] ? {MouseStatusRaw[4],8'h00} : {MouseStatusRaw[4],8'hFF} ) : {MouseStatusRaw[4],MouseDxRaw[7:0]};
	// Similar to the X bit but now looking at the Y bit
	assign MouseDy = (MouseStatusRaw[7]) ? (MouseStatusRaw[5] ? {MouseStatusRaw[5],8'h00} : {MouseStatusRaw[5],8'hFF} ) : {MouseStatusRaw[5],MouseDyRaw[7:0]};
	
	// SW is modified to take account of direction
	assign MouseDSW = (MouseSWRaw == 8'h00)?0:(MouseSWRaw[7]?1:-1);
	
	// calculate new mouse position
	assign MouseNewX = {1'b0,MouseX} + MouseDx*(1+SPEED);
	// adds the movement in the Y direction of the mouse to the coordinate
	assign MouseNewY = {1'b0,MouseY} + MouseDy*(1+SPEED);
	// adds the movement of the scrolling wheel to the coordinate
	assign MouseNewSW = {1'b0,MouseSW} + MouseDSW;
	
	always@(posedge CLK) begin
		if(RESET) begin
			MouseStatus <= 0;
			MouseX 		<= MouseLimitX/2;
			MouseY 		<= MouseLimitY/2;
			MouseSW     <= 0;
			
		end else if (SendInterrupt) begin
			// status is stripped of all unnecessary info
			MouseStatus <= MouseStatusRaw[3:0];
		
			// X is modified based on DX with limits on max and min
			if(MouseNewX < 0)
				MouseX <= 0;
			else if(MouseNewX > (MouseLimitX-1))
				MouseX <= MouseLimitX-1;
			else
				MouseX <= MouseNewX[7:0];

			// Y is modified based on DY with limits on max and min
			if(MouseNewY < 0)
				MouseY <= 0;
			else if(MouseNewY > (MouseLimitY-1))
				MouseY <= MouseLimitY-1;
			else
				MouseY <= MouseNewY[7:0];
				
			// SW is modified based on DSW with limits on max and min
			if(MouseNewSW < 0)
				MouseSW <= 0;
			else if(MouseNewSW > (MouseLimitSW-1))
				MouseSW <= MouseLimitSW-1;
			else
				MouseSW <= MouseNewSW[7:0];	
		end
	end
	
	assign MouseInterrupt = SendInterrupt;

	// instantiate the ila debugger
	ila_0 ila_debugger (
		.clk   (CLK), 				// input wire clk
		.probe0(RESET), 			// input wire [0:0]  probe0  
		.probe1(CLK_MOUSE), 		// input wire [0:0]  probe1 
		.probe2(DATA_MOUSE), 		// input wire [0:0]  probe2 
		.probe3(ByteErrorCode), 	// input wire [1:0]  probe3 
		.probe4(MasterStateCode), 	// input wire [5:0]  probe4 
		.probe5(ByteToSendToMouse), // input wire [7:0]  probe5 
		.probe6(ByteRead) 			// input wire [7:0]  probe6
	);
endmodule