`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/02/25 17:30:25
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: processor
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: A microprocessor working as the central control unit of the mouse interface, receiving and sending instructions
//				to each sub module.
// 
// Dependencies: alu.v
// 
// Revision:
// Revision 2.1  - Bug-free
// Revision 2.0  - Simplified
// Revision 1.1  - Bug-free
// Revision 1.0	 - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 	Interface:
//		CLK:				  The on-board clock (100MHz).
//		RESET: 				  Reset the interface to the default state.
//		BUS_DATA: 			  Wires connecting the microprocessor and the 8-bit data bus. Modules can save and access data via them.
//		BUS_ADDR: 			  Wires connecting the microprocessor and the 8-bit data address bus.
//							  It is used to send instructions to sub modules.
//		BUS_WE: 			  Bus write enable signal.
//							  Used to enable the writing of the 7-segment displays, the LED interface, the timer, and the RAM.
//		ROM_ADDRESS: 		  Wires connecting the microprocessor and the instruction memory (ROM).
//							  It points to the address of instruction that will be executed.
//		ROM_DATA: 			  Wires connecting the microprocessor and the instruction memory (ROM).
//							  Holds the instruction context.
//		BUS_INTERRUPTS_RAISE: Interrupts received from the mouse driver and the timer.
//		BUS_INTERRUPTS_ACK:   Interrupts sent to the mouse driver and the timer.
//
//	The Block Diagram:
/* 
							  BUS_  ROM_                                                
				   CLK  RESET DATA  DATA           BUS_INTERRUPTS_RAISE                 
					/     /    /     /                     /                            
					|     |    |     |                     |                            
					|     |    |     |                     |                            
				+---\-----\----\-----\---------------------\--------+                   
				|                                                   |                   
				|   +--------------+                                |                   
				|   |              |                                |                   
				|   |              |     IN_A         +---------+   |                   
				|   |              --------------------         |   |                   
				|   |              |     IN_B         |         |   |                   
				|   |     State    --------------------   ALU   |   |                   
				|   |    Machine   |     Op_Code      |         |   |                   
				|   |              --------------------         |   |                   
				|   |              |                  +----/----+   |                   
				|   |              |     Result            |        |                   
				|   |              ------------------------\        |                   
				|   +--------------+                                |                   
				|                                                   |                   
				+--------------/-----/----------/-------/--------/--+                   
							   |     |          |       |        |                      
							   |     |          |       |        |                      
							   \     \          \       \        \                      
							  BUS   BUS        BUS     ROM   BUS_INTERRUPTS_ACK         
							_DATA  _ADDR       _WE   ADDRESS                            

*/
//////////////////////////////////////////////////////////////////////////////////


module processor(
	// standard signals
	input 		 CLK,					// the on-board clock (100MHz), connects to the on-board clock line
	input 		 RESET,					// reset the processor to the default state, connects to the middle button on the board 
	// bus signals
	inout  [7:0] BUS_DATA,				// the context of the data memory (RAM),
										// connects to the input of RAM and inout ports of each peripheral
	output [7:0] BUS_ADDR,				// the address of the data memory (RAM),				
										// connects to the input ports of the RAM and peripherals
	output BUS_WE,						// connects to the input ports of the RAM and peripherals
										// enables the writing functions of peripherals such as 7-segment displays, LEDs,
										// timer, and the RAM
	// ROM signals
	output [7:0] ROM_ADDRESS,			// address of the instruction memory (ROM), connects to the input of the ROM
	input  [7:0] ROM_DATA,				// data of the instruction memory (ROM), connects to the output of the ROM
	// interrupt signals
	input  [1:0] BUS_INTERRUPTS_RAISE,	// interrupts raise from the mouse driver and the timer,
										// connects to the output of the timer and the mouse interface
	output [1:0] BUS_INTERRUPTS_ACK		// interrupts acknowledgement to the mouse driver and the timer,
										// connects to the input of the timer and the mouse interface
    );
	
	// the main data bus is treated as tristate so we need a mechanism to handle this
	// tristate signals that interface with the main state machine
	wire [7:0] BusDataIn;
	reg  [7:0] CurrBusDataOut, 	 NextBusDataOut;
	reg 	   CurrBusDataOutWE, NextBusDataOutWE;
	
	// tristate mechanism
	assign BusDataIn = BUS_DATA;
	assign BUS_WE 	 = CurrBusDataOutWE;
	assign BUS_DATA  = CurrBusDataOutWE ? CurrBusDataOut : 8'hZZ;

	// address of the bus
	reg [7:0] CurrBusAddr, NextBusAddr;
	assign BUS_ADDR = CurrBusAddr;

	// the processor has two internal registers to hold data between operations
	// and a third to hold the current program context when using function calls
	reg 	  CurrRegSelect,   NextRegSelect;
	reg [7:0] CurrRegA, 	   NextRegA;
	reg [7:0] CurrRegB, 	   NextRegB;
	reg [7:0] CurrProgContext, NextProgContext;
	
	// dedicated interrupt output lines - one for each interrupt line
	reg [1:0] CurrInterruptAck, NextInterruptAck;
	assign BUS_INTERRUPTS_ACK = CurrInterruptAck;
	
	// instantiate program memory here
	// there is a program counter which points to the current operation
	// the program counter has an offset that is used to reference information that is part of the current operation
	reg  [7:0] CurrProgCounter, 	  NextProgCounter;
	reg  [1:0] CurrProgCounterOffset, NextProgCounterOffset;
	wire [7:0] ProgMemoryOut;
	wire [7:0] ActualAddress;
	// the actual address equals to the current program counter plus an offset
	assign ActualAddress = CurrProgCounter + CurrProgCounterOffset;
	
	// ROM signals
	assign ProgMemoryOut = ROM_DATA;
	assign ROM_ADDRESS 	 = ActualAddress;
	
	// instantiate the ALU
	// the processor has an integrated ALU that can do several different operations
	wire [7:0] AluOut;
	alu ALU0(
		//standard signals
		.CLK		(CLK),					// on-board clock (100MHz)
		.RESET		(RESET),				// reset the ALU module
		//I/O
		.IN_A		(CurrRegA),				// value of the register A
		.IN_B		(CurrRegB), 			// value of the register B
		.ALU_Op_Code(ProgMemoryOut[7:4]),	// the operation code
		.OUT_RESULT (AluOut)				// result of the ALU module
	);
	
	// the microprocessor is essentially a state machine with one sequential pipeline of states for each operation
	// the current list of operations:
	//  0: Read from memory to A
	//  1: Read from memory to B
	//  2: Write to memory from A
	//  3: Write to memory from B
	//  4: Do maths with the ALU, and save result in reg A
	//  5: Do maths with the ALU, and save result in reg B
	//  6: if A (== or < or > B) GoTo ADDR
	//  7: Goto ADDR
	//  8: Go to IDLE
	//  9: End thread, goto idle state and wait for interrupt.
	// 10: Function call
	// 11: Return from function call
	// 12: Dereference A
	// 13: Dereference B
	
	// program thread selection
	parameter [7:0] 				 
	IDLE 					= 8'hF0, // waits here until an interrupt wakes up the processor
	GET_THREAD_START_ADDR_0 = 8'hF1, // wait
	GET_THREAD_START_ADDR_1 = 8'hF2, // apply the new address to the program counter
	GET_THREAD_START_ADDR_2 = 8'hF3, // wait and goto ChooseOp
	
	// operation selection
	// depending on the value of ProgMemOut, goto one of the instruction start states
	CHOOSE_OPP 				= 8'h00,
	
	// data flow
	READ_FROM_MEM_TO_A 		= 8'h10, // wait to find what address to read and save reg select
	READ_FROM_MEM_TO_B 		= 8'h11, // wait to find what address to read and save reg select
	READ_FROM_MEM_0    		= 8'h12, // set BUS_ADDR to designated address
	READ_FROM_MEM_1    		= 8'h13, // wait - increments program counter by 2 and reset offset
	READ_FROM_MEM_2    		= 8'h14, // writes memory output to chosen register and end op
	WRITE_TO_MEM_FROM_A 	= 8'h20, // reads Op+1 to find what address to write to
	WRITE_TO_MEM_FROM_B 	= 8'h21, // reads Op+1 to find what address to write to
	WRITE_TO_MEM_0 			= 8'h22, // wait - increments program counter by 2 and reset offset
	
	// data manipulation
	DO_MATHS_OPP_SAVE_IN_A 	= 8'h30, // the result of maths op. is available, save it to Reg A
	DO_MATHS_OPP_SAVE_IN_B 	= 8'h31, // the result of maths op. is available, save it to Reg B
	DO_MATHS_OPP_0 			= 8'h32, // wait for new op address to settle and end op
	
    // in/equality
    IF_A_EQUAL_TO_B_GOTO_0  = 8'h40, // based on the ALU result, go to GOTO_0 if A == B, else go to IF_A_EQUAL_TO_B_GOTO_1
    IF_A_EQUAL_TO_B_GOTO_1  = 8'h41, // A does not equal to B, go to CHOOSE_OPP, wait for new op address to settle and end op
    
    // goto addr
    GOTO_0                  = 8'h50, // wait for the next memory to be read
    GOTO_1                  = 8'h51, // load program counter with address
    GOTO_2                  = 8'h52, // go to CHOOSE_OPP, wait for new operation address to settle and end the operation
	GOTO_IDLE				= 8'h53, // go to idle state and wait for interrupts
    
    // function call & return
    FUNCTION_START          = 8'h60, // branch to memory address, save the next program address to execute from after returning from the function
    RETURN                  = 8'h61, // return from a function call, go to CHOOSE_OPP, wait for new op address to settle and end op
    
    
    // dereference operations
    DEREFERENCE_A          	= 8'h70, // read memory address given by the value of register A
    DEREFERENCE_B          	= 8'h71, // read memory address given by the value of register B
    DEREFERENCE_0          	= 8'h72; // set the result as the new register value

	// sequential part of the state machine
	reg [7:0] CurrState, NextState;
	
	always@(posedge CLK) begin
		if(RESET) begin
			CurrState 			  = 8'h00;
			CurrProgCounter 	  = 8'h00;
			CurrProgCounterOffset = 2'h0;
			CurrBusAddr 		  = 8'hFF;	// initial instruction after reset
			CurrBusDataOut 		  = 8'h00;
			CurrBusDataOutWE 	  = 1'b0;
			CurrRegA 			  = 8'h00;
			CurrRegB 			  = 8'h00;
			CurrRegSelect 		  = 1'b0;
			CurrProgContext 	  = 8'h00;
			CurrInterruptAck 	  = 2'b00;
		end else begin
			CurrState 			  = NextState;
			CurrProgCounter 	  = NextProgCounter;
			CurrProgCounterOffset = NextProgCounterOffset;
			CurrBusAddr 		  = NextBusAddr;
			CurrBusDataOut 		  = NextBusDataOut;
			CurrBusDataOutWE 	  = NextBusDataOutWE;
			CurrRegA 			  = NextRegA;
			CurrRegB 			  = NextRegB;
			CurrRegSelect 		  = NextRegSelect;
			CurrProgContext 	  = NextProgContext;
			CurrInterruptAck 	  = NextInterruptAck;
		end
	end
	
	// combinatorial section
	always@* begin
		// generic assignment to reduce the complexity of the rest of the state machine
		NextState 			  = CurrState;
		NextProgCounter 	  = CurrProgCounter;
		NextProgCounterOffset = 2'h0;
		NextBusAddr 		  = 8'hFF;
		NextBusDataOut 		  = CurrBusDataOut;
		NextBusDataOutWE 	  = 1'b0;
		NextRegA 			  = CurrRegA;
		NextRegB 			  = CurrRegB;
		NextRegSelect 		  = CurrRegSelect;
		NextProgContext 	  = CurrProgContext;
		NextInterruptAck 	  = 2'b00;
		
		// case statement to describe each state
		case (CurrState)
		
			///////////////////////////////////////////////////////////////////////////////////////
			// thread states
			IDLE: begin
				if(BUS_INTERRUPTS_RAISE[0]) begin	// interrupt request A
					NextState 		 = GET_THREAD_START_ADDR_0;
					NextProgCounter  = 8'hFF;
					NextInterruptAck = 2'b01;
				end else if(BUS_INTERRUPTS_RAISE[1]) begin	// interrupt request B
					NextState 		 = GET_THREAD_START_ADDR_0;
					NextProgCounter  = 8'hFE;
 					NextInterruptAck = 2'b10;
				end else begin
					NextState 		 = IDLE;
					NextProgCounter  = 8'hFF;	// nothing has happened
					NextInterruptAck = 2'b00;
				end
			end
			
			// wait state - for new prog address to arrive
			GET_THREAD_START_ADDR_0:
				NextState = GET_THREAD_START_ADDR_1;
			
			// assign the new program counter value
			GET_THREAD_START_ADDR_1: begin
				NextState 		= GET_THREAD_START_ADDR_2;
				NextProgCounter = ProgMemoryOut;
			end
			
			// wait for the new program counter value to settle
			GET_THREAD_START_ADDR_2:
				NextState = CHOOSE_OPP;
				
			///////////////////////////////////////////////////////////////////////////////////////
			// CHOOSE_OPP - another case statement to choose which operation to perform
			CHOOSE_OPP: begin
				// the operation to be performed is determined by the 4 LSBs of the ROM data
				case (ProgMemoryOut[3:0])
					4'h0:NextState = READ_FROM_MEM_TO_A;		// read value from memory address and store in register A
					4'h1:NextState = READ_FROM_MEM_TO_B;		// read value from memory address and store in register B
					4'h2:NextState = WRITE_TO_MEM_FROM_A;		// write value of register A to memory address
					4'h3:NextState = WRITE_TO_MEM_FROM_B;		// write value of register B to memory address
					4'h4:NextState = DO_MATHS_OPP_SAVE_IN_A;	// do math operation on register values and store result in register A
					4'h5:NextState = DO_MATHS_OPP_SAVE_IN_B;	// do math operation on register values and store result in register B
					4'h6:NextState = IF_A_EQUAL_TO_B_GOTO_0;	// load program counter with ADDR if A == B 
					4'h7:NextState = GOTO_1;					// load program counter with ADDR
					4'h8:NextState = GOTO_IDLE;					// go to idle state and wait for interrupts
					4'h9:NextState = FUNCTION_START;			// branch to memory address ADDR
					4'hA:NextState = RETURN;					// returns from a function call
					4'hB:NextState = DEREFERENCE_A;				// read memory address given by the value of register A
																// and set the result as the new register A value
					4'hC:NextState = DEREFERENCE_B;				// read memory address given by the value of regsiter B
																// and set the result as the new register B value
					
					default: NextState = CurrState;
				endcase
				NextProgCounterOffset = 2'h1;
			end
			
			///////////////////////////////////////////////////////////////////////////////////////
			// READ_FROM_MEM_TO_A : here starts the memory read operational pipeline
			// wait state - to give time for the memory address to be read, reg select is set to 0
			READ_FROM_MEM_TO_A: begin
				NextState 	  = READ_FROM_MEM_0;
				NextRegSelect = 1'b0;
			end
			
			// READ_FROM_MEM_TO_B : here starts the memory read operational pipeline
			// wait state - to give time for the memory address to be read, reg select is set to 1
			READ_FROM_MEM_TO_B: begin
				NextState 	  = READ_FROM_MEM_0;
				NextRegSelect = 1'b1;
			end

			// the address will be valid during this state, so set the BUS_ADDR to this value
			READ_FROM_MEM_0: begin
				NextState 	= READ_FROM_MEM_1;
				NextBusAddr = ProgMemoryOut;
			end
			
			// wait state - to give time for the mem data to be read
			// increment the program counter here
			// this must be done 2 clock cycles ahead so that it presents the right data when required
			READ_FROM_MEM_1: begin
				NextState 		= READ_FROM_MEM_2;
				NextProgCounter = CurrProgCounter + 2;
			end

			// the data will now have arrived from memory
			// write it to the proper register
			READ_FROM_MEM_2: begin
				NextState = CHOOSE_OPP;
				if(!CurrRegSelect)
					NextRegA = BusDataIn;
				else
					NextRegB = BusDataIn;
			end
			
			///////////////////////////////////////////////////////////////////////////////////////
			// WRITE_TO_MEM_FROM_A : here starts the memory write operational pipeline
			// wait state - to find the address of where we are writing
			// increment the program counter here
			// this must be done 2 clock cycles aheadso that it presents the right data when required
			WRITE_TO_MEM_FROM_A: begin
				NextState 		= WRITE_TO_MEM_0;
				NextRegSelect 	= 1'b0;
				NextProgCounter = CurrProgCounter + 2;
			end
			
			// WRITE_TO_MEM_FROM_B : here starts the memory write operational pipeline
			// wait state - to find the address of where we are writing
			// increment the program counter here
			// this must be done 2 clock cycles ahead so that it presents the right data when required
			WRITE_TO_MEM_FROM_B: begin
				NextState 		= WRITE_TO_MEM_0;
				NextRegSelect 	= 1'b1;
				NextProgCounter = CurrProgCounter + 2;
			end
			
			// the address will be valid during this state
			// so set the BUS_ADDR to this value and write the value to the memory location.
			WRITE_TO_MEM_0: begin
				NextState 	= CHOOSE_OPP;
				NextBusAddr = ProgMemoryOut;
				if(!NextRegSelect)
					NextBusDataOut = CurrRegA;
				else
					NextBusDataOut = CurrRegB;
				NextBusDataOutWE = 1'b1;
			end
			
			///////////////////////////////////////////////////////////////////////////////////////
			// DO_MATHS_OPP_SAVE_IN_A : here starts the DoMaths operational pipeline
			// reg A and reg B must already be set to the desired values
			// the MSBs of the operation type determines the maths operation type
			// at this stage the result is ready to be collected from the ALU
			DO_MATHS_OPP_SAVE_IN_A: begin
				NextState 		= DO_MATHS_OPP_0;
				NextRegA 		= AluOut;
				NextProgCounter = CurrProgCounter + 1;
			end
			
			// DO_MATHS_OPP_SAVE_IN_B : here starts the DoMaths operational pipeline
			// when the result will go into reg B
			DO_MATHS_OPP_SAVE_IN_B: begin
				NextState 		= DO_MATHS_OPP_0;
				NextRegB 		= AluOut;
				NextProgCounter = CurrProgCounter + 1;
			end
			
			// wait state for new program address to settle
			DO_MATHS_OPP_0:
				NextState = CHOOSE_OPP;

			///////////////////////////////////////////////////////////////////////////////////////
            // in/equality: load program counter with address if register A's content is equal to register B's
			// based on the ALU result, go to GOTO_0 if A == B, else go to IF_A_EQUAL_TO_B_GOTO_1
            IF_A_EQUAL_TO_B_GOTO_0: begin
                if(AluOut) begin
                    NextState       = GOTO_0;                   
                    NextProgCounter = CurrProgCounter+1;
                end else begin
                    NextState       = IF_A_EQUAL_TO_B_GOTO_1;
                    NextProgCounter = CurrProgCounter+2;
                end
            end
            
			// register A's content does not equal to register B's, go to CHOOSE_OPP, wait for new op address to settle and end op
            IF_A_EQUAL_TO_B_GOTO_1:
                NextState = CHOOSE_OPP;
            
			///////////////////////////////////////////////////////////////////////////////////////
            // GOTO : branch to address, i.e. load program counter with address
			// wait for the next memory to be read
            GOTO_0:
                NextState = GOTO_1;
				
            // load program counter with address
            GOTO_1: begin
                NextState       = GOTO_2;
                NextProgCounter = ProgMemoryOut;
            end
            
			// go to CHOOSE_OPP, wait for new operation address to settle and end the operation
            GOTO_2:
                NextState = CHOOSE_OPP;
            
			// go to idle state and wait for interrupts
			GOTO_IDLE:
				NextState = IDLE;
            
			///////////////////////////////////////////////////////////////////////////////////////
            // function call & return
            // branch to memory address, save the next program address to execute from after returning from the function
            FUNCTION_START: begin
                NextState       = GOTO_0;
                NextProgContext = CurrProgCounter+1;
                NextProgCounter = ProgMemoryOut;
            end
            
            // return from a function call, go to CHOOSE_OPP, wait for new op address to settle and end op
            RETURN: begin
                NextState       = CHOOSE_OPP;
                NextProgCounter = CurrProgContext; 
            end
            
			///////////////////////////////////////////////////////////////////////////////////////
            // dereference 
			// read memory address given by the value of register A and set the result as the new register A value A <- [A]
            DEREFERENCE_A: begin
                NextState 	  = DEREFERENCE_0;
                NextBusAddr   = CurrRegA;
                NextRegSelect = 1'b0;
            end

			// read memory address given by the value of register B and set the result as the new register B value B <- [B]            
            DEREFERENCE_B: begin
                NextState 	  = DEREFERENCE_0;
                NextBusAddr   = CurrRegB;
                NextRegSelect = 1'b1;             
            end
			
			// set the result as the new register value
            DEREFERENCE_0: begin
                NextState 		= READ_FROM_MEM_2;
                NextProgCounter = CurrProgCounter+1;
            end
            
			// set the default to the idle state
            default:
                NextState = IDLE;
        endcase
	end
endmodule