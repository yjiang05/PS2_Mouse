`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/02/25 17:06:37
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: timer
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: The timer peripheral, generating an interrupt signal periodically.
// 
// Dependencies: None
// 
// Revision:
// Revision 1.0  - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 	Interface:
//		CLK: 				 The on-board clock (100MHz).
//		RESET: 				 Reset the peripheral to the default state.
//		BUS_DATA: 			 Wires connecting the processor and the timer peripheral. The peripheral can read and write data through these.
//		BUS_ADDR: 			 The microprocessor can send the addresses of instructions through these.
//		BUS_WE: 			 Enables the timer peripheral.
//		BUS_INTERRUPT_RAISE: Connects to the microprocessor and sends an interrupt.
//		BUS_INTERRUPT_ACK: 	 Connects to the microprocessor and receives the interrupt acknowledgement from the microprocessor.
//////////////////////////////////////////////////////////////////////////////////


module timer(
	// standard signals
    input 		CLK, 					// the on-board clock (100MHz), connects to the on-board clock line
    input 		RESET,					// reset the timer to the default state, connects to the middle button on the board
	// bus signals
    inout [7:0] BUS_DATA,				// the context of the data memory (RAM), connects to the inout port of the microprocessor
    input [7:0] BUS_ADDR,				// the address of the data memory (RAM), connects to the output of the microprocessor
    input 		BUS_WE,					// enables the writing functions of the timer, connects to the output of the microprocessor
    output 		BUS_INTERRUPT_RAISE,	// interrupt raise to the processor, connects to the input of the microprocessor
    input 		BUS_INTERRUPT_ACK		// interrupt acknowledgement from the processor, connects to the output of the microprocessor
    );
	
	parameter [7:0] TimerBaseAddr = 8'hF0; 	// timer base address in the memory map
	parameter InitialIterruptRate = 100; 	// default interrupt rate leading to 1 interrupt every 100 ms
	parameter InitialIterruptEnable = 1'b1; // by default the interrupt is enabled
	
	//////////////////////
	// BaseAddr + 0 -> reports current timer value
	// BaseAddr + 1 -> Address of a timer interrupt interval register, 100 ms by default
	// BaseAddr + 2 -> Resets the timer, restart counting from zero
	// BaseAddr + 3 -> Address of an interrupt Enable register, allows the microprocessor to disable the timer
	// this module will raise an interrupt flag when the designated time is up
	// it will automatically set the time of the next interrupt to the time of the last interrupt plus a configurable value (in milliseconds)
	// interrupt rate configuration - the rate is initialised to 100 by the parameter above
	// but can also be set by the processor by writing to mem address BaseAddr + 1
	
	// define a register to hold the value
	reg [7:0] InterruptRate;
	
	always@(posedge CLK) begin
		if(RESET)
			InterruptRate <= InitialIterruptRate;
		else if((BUS_ADDR == TimerBaseAddr + 8'h01) & BUS_WE)
			InterruptRate <= BUS_DATA;
	end
	
	// interrupt enable configuration - if this is not set to 1, no interrupts will be created
	reg InterruptEnable;

	always@(posedge CLK) begin
		if(RESET)
			InterruptEnable <= InitialIterruptEnable;
		else if((BUS_ADDR == TimerBaseAddr + 8'h03) & BUS_WE)
			InterruptEnable <= BUS_DATA[0];
	end
	
	// first we must lower the clock speed from 100MHz to 1 KHz (1ms period)
	reg [31:0] DownCounter;
	
	always@(posedge CLK) begin
		if(RESET)
			DownCounter <= 0;
		else begin
			if(DownCounter == 32'd99999)
				DownCounter <= 0;
			else
				DownCounter <= DownCounter + 1'b1;
		end
	end
	
	// now we can record the last time an interrupt was sent, and add a value to it to determine if it is time to raise the interrupt
	// but first, let us generate the 1ms counter (Timer)
	reg [31:0] Timer;
	
	always@(posedge CLK) begin
		if(RESET | (BUS_ADDR == TimerBaseAddr + 8'h02))
			Timer <= 0;
		else begin
			if((DownCounter == 0))
				Timer <= Timer + 1'b1;
			else
				Timer <= Timer;
		end
	end

	// interrupt generation
	reg 	   TargetReached;
	reg [31:0] LastTime;
	
	always@(posedge CLK) begin
		if(RESET) begin
			LastTime 	  <= 0;
			TargetReached <= 1'b0;
		end else if((LastTime + InterruptRate) == Timer) begin
			if(InterruptEnable)
				TargetReached <= 1'b1;
			LastTime <= Timer;
		end else
			TargetReached <= 1'b0;
	end
	
	// broadcast the interrupt
	reg Interrupt;
	
	always@(posedge CLK) begin
		if(RESET)
			Interrupt <= 1'b0;
		else if(TargetReached)
			Interrupt <= 1'b1;
		else if(BUS_INTERRUPT_ACK)
			Interrupt <= 1'b0;
	end
	
	assign BUS_INTERRUPT_RAISE = Interrupt;
	
	// tristate output for interrupt timer output value
	reg TransmitTimerValue;
	
	always@(posedge CLK) begin
		if(BUS_ADDR == TimerBaseAddr)
			TransmitTimerValue <= 1'b1;
		else
			TransmitTimerValue <= 1'b0;
	end
	
	assign BUS_DATA = (TransmitTimerValue) ? Timer[7:0] : 8'hZZ;
	
endmodule