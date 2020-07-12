`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/03/02 11:59:10
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: microprocessor_based_top_wrapper
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: A top wrapper including the microprocessor, the mouse driver, the 7-segment displays interface, the LED interface, 
//				the timer, the RAM, and the ROM.
// 
// Dependencies: processor.v, mouse_interface.v, seven_seg_interface.v, led_interface.v, timer.v, ram.v, rom.v.
// 
// Revision:
// Revision 2.0  - Extra Features Added
// Revision 1.0  - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 	Interface:
//		CLK: 			The on-board clock (100MHz).
//		RESET: 			Reset the interface to the default state.
//		PRIMARY_BUTTON: Select the primary button of the mouse.
//		SPEED:			Control the moving speed of the pointers.
//		CLK_MOUSE:  	The PS2 clock line.
//		DATA_MOUSE: 	The PS2 data line.
//		LED_OUT: 		Connects to the on-board LEDs, indicating the clicks of left and right buttons.
//		SEG_SELECT: 	Selects one of the four digits in the 7-segment displays.
//		DEC_OUT:    	Drives the segments in the 7-segment displays.
//
//	The block diagram:
//
/* 		   CLK   RESET                                                     SPEED                                                    
			/      /                                                         .                                                      
			|      |                                                         |                                                      
			|      |                                                         |                                                      
			|      |                                                         |                                                      
	  +-----\------\---------------------------------------------------------|---------------------------------+                    
	  |                                                                      |                                 |                    
	  |                                +-------------+                       |                                 |                    
	  |                      BUS_ADDR  |             |    BUS_ADDR           |                                 |                    
	  |    /-----------/----------------             ------------------------|--------/----------/             |                    
	  |    |           |               |             |                       |        |          |             |                    
	  |    |           |     BUS_DATA  |     RAM     |    BUS_DATA           |        |          |             |                    
	  |    |  /-----------/-------------             ------------------------|--/     |          |             |                    
	  |    |  |        |  |            |             |                       |  |     |          |             |                    
	  |    |  |        |  |            |             |                       |  |     |          |             |                    
	  |    |  |        |  |            +--.--------..+                       |  |     |          |             |                    
	  |    |  |        |  |               |        ||                        |  |     |          |             |                    
	  |    |  |        |  |               |    BUS ||BUS                     |  |     |          |             |                    
	  |    |  |        |  |               |   DATA ||ADDR                    |  |     |          |             |                    
	  |    |  |        |  |               |        ||                        |  |     |          |             |                    
	  |    |  |        |  |           BUS_-----------------------------------|--|-----|----------|--/          |                    
	  |    |  |        |  |            WE |        ||                        |  -------------/   |  |          |                    
	  |    |  |        |  |               |        ||                        |  |     |      |   |  |          |                    
	  |    |  |  +-----\--\+         +----\--------\\----+                +--\--\-----\----+ |   |  |          |                    
	  |    |  |  |         |         |                   |                |                | |   |  |          |                    
	  |    |  |  |         |         |                   |                |                --------------------------CLK_MOUSE      
	  |    |  |  |  Timer  |         |   Microprocessor  |                |  Mouse Driver  | |   |  |          |                    
	  |    |  |  |         |         |                   |                |                --------------------------DATA_MOUSE     
	  |    |  |  |         |         |                   |                |                | |   |  |          |                    
	  |    |  |  +--.--/---+         +----.-/--/-/--/--/-+                +--.-.-----------+ |   |  |          |                    
	  |    |  |     |  | BUS_INTERRUPT_ACK| |  | |  |  | BUS_INTERRUPT_ACK   | |             |   |  |          |                    
	  |    |  |     |  \------------------\ |  | |  |  \---------------------\ |             |   |  |          |                    
	  |    |  |     |                       |  | |  |                          |             |   |  |          |                    
	  |    |  |     \-----------------------\  | |  \--------------------------\    /--------\   |  |          |                    
	  |    |  |         BUS_INTERRUPT_RAISE    | |      BUS_INTERRUPT_RAISE         |            |  |          |                    
	  |    |  |                                | |                          BUS_DATA|   /--------\  |          |                    
	  |    |  |BUS_DATA                   DATA | | ADDR                             |   |BUS_ADDR   |          |                    
	  |    |  |  +----------+            +-----\-\-+                      +---------\---\----+      |          |                    
	  |    |  |  |          |            |         |                      |                  |      |BUS_WE    |                    
	  |    |  \---          | BUS_WE     |         |                      |                  --------          |                    
	  |    |     |   LEDs   ----/        |   ROM   |                      |     7-Segment    |      |          |                    
	  |    |     |          |   |        |         |                      |                  |      |          |                    
	  |    \------          |   |        |         |                      |                  |      |          |                    
	  |  BUS_ADDR+-/--/-----+   |        +---------+                      +----/---------/---+      |          |                    
	  |            |  |         |                                              |         |          |          |                    
	  |            |  |         |                                              |         |          |          |                    
	  |      /-----\  |         \----------------------------------------------|---------|----------\          |                    
	  |      |        |                                                        |         |                     |                    
	  |      |        |                                                        |         |                     |                    
	  +------|--------|--------------------------------------------------------|---------|---------------------+                    
			 |        |                                                        |         |                                          
			 |        |                                                        |         |                                          
			 \        \                                                        \         \                                          
		PRIMARY_   LED_OUT                                               SEG_SELECT   DEC_OUT                                       
		 BUTTON   

*/
//////////////////////////////////////////////////////////////////////////////////


module microprocessor_based_top_wrapper(
	input 		 CLK, 		 	 // the on-board clock (100MHz), connects to the on-board clock line
	input 		 RESET,		 	 // reset the interface to the default state, connects to the middle button on the board
	input        PRIMARY_BUTTON, // selects the primary button of the mouse, connects to the slide switch on the board
	input		 SPEED,			 // controls the moving speed of the pointers, connects to the slide switch on the board
	inout 		 CLK_MOUSE,  	 // connects to the PS2 clock line
	inout 		 DATA_MOUSE, 	 // connects to the PS2 data line
	output [9:0] LED_OUT,	 	 // indicates the clicks of left and right buttons of the mouse, connects to the on-board LEDs
	output [3:0] SEG_SELECT, 	 // selects one of the four digits on the 7-segment displays, connects to the anodes of the 7-segment displays
	output [7:0] DEC_OUT	 	 // drives the segments in the 7-segment displays, connects to the cathodes of the eight segments
    );
	
	// define wires to connect each modules
	// bus signals
	wire 	   BUS_WE;					// write enable, enables the writing functions of peripherals such as 7-segment displays, LEDs,
										// timer, and the RAM.
	wire [7:0] BUS_DATA;				// the context of the data memory (RAM)
	wire [7:0] BUS_ADDR;				// the address of the data memory (RAM)
	// ROM signals
	wire [7:0] ROM_DATA;				// the context of the instruction memory (ROM)
	wire [7:0] ROM_ADDRESS;				// the address of the instruction memory (ROM)
	// interrupt signals
	wire [1:0] BUS_INTERRUPTS_ACK;		// interrupts acknowledgement from the processor to the mouse driver and the timer
	wire [1:0] BUS_INTERRUPTS_RAISE;	// interrupts raise from the mouse driver and the timer to the processor
	
	// then instantiate the sub-modules
	// instantiate the microprocessor
	processor microprocessor (
		.CLK				 (CLK),						// on-board clock (100MHz)
		.RESET				 (RESET),					// reset the microprocessor
		.BUS_DATA			 (BUS_DATA),				// the context of the data memory (RAM)
		.BUS_ADDR			 (BUS_ADDR),				// the address of the data memory (RAM)
		.BUS_WE				 (BUS_WE),					// enables the writing of peripherals
		.ROM_ADDRESS		 (ROM_ADDRESS),				// the address of the instruction memory (ROM)
		.ROM_DATA			 (ROM_DATA),				// the context of the instruction memory (ROM)
		.BUS_INTERRUPTS_RAISE(BUS_INTERRUPTS_RAISE),	// interrupts raise from the mouse driver and the timer
		.BUS_INTERRUPTS_ACK	 (BUS_INTERRUPTS_ACK)		// interrupts acknowledgement to the mouse driver and the timer
	);
	
	// instantiate the mouse driver
	mouse_interface mouse_driver (
		.CLK				 (CLK),						// on-board clock (100MHz)
		.RESET				 (RESET),					// reset the mouse driver
		.SPEED				 (SPEED),					// controls the moving speed of the pointers
		.BUS_DATA			 (BUS_DATA),				// the context of the data memory (RAM)
		.BUS_ADDR			 (BUS_ADDR),				// the address of the data memory (RAM)
		.BUS_INTERRUPT_RAISE (BUS_INTERRUPTS_RAISE[0]),	// interrupt to the microprocessor
		.BUS_INTERRUPT_ACK	 (BUS_INTERRUPTS_ACK[0]),	// interrupt acknowledgement from the microprocessor
		.CLK_MOUSE			 (CLK_MOUSE),				// the ps2 clock line
		.DATA_MOUSE			 (DATA_MOUSE)				// the ps2 data line
	);
	
	// instantiate the timer
	timer timer (
		.CLK				 (CLK),						// on-board clock (100MHz)
		.RESET				 (RESET),					// reset the timer
		.BUS_DATA			 (BUS_DATA),				// the context of the data memory (RAM)
		.BUS_ADDR			 (BUS_ADDR),				// the address of the data memory (RAM)
		.BUS_WE				 (BUS_WE),					// enable the timer to set the interrupt rate and InterruptEnable
		.BUS_INTERRUPT_RAISE (BUS_INTERRUPTS_RAISE[1]),	// send an interrupt to the microprocessor
		.BUS_INTERRUPT_ACK   (BUS_INTERRUPTS_ACK[1])	// receive an interrupt acknowledgement from the microprocessor
	);

	// instantiate the LED interface
	led_interface LED_interface(
		.CLK	   	   		 (CLK),						// on-board clock (100MHz)
		.RESET	   	   		 (RESET),					// reset the LED interface
		.BUS_DATA  	   		 (BUS_DATA),				// the context of the data memory (RAM)
		.BUS_ADDR  	   		 (BUS_ADDR),				// the address of the data memory (RAM)
		.WE		   	   		 (BUS_WE),					// enable the LED interface to display the patterns
		.PRIMARY_BUTTON		 (PRIMARY_BUTTON),			// selects the primary button of the mouse
		.LED_OUT   	   		 (LED_OUT)					// indicates the clicks of left and right buttons of the mouse
	);

	// instantiate the seven segment displays
	seven_seg_interface seven_seg (
		.CLK	   (CLK),			// on-board clock (100MHz)
		.RESET	   (RESET),			// reset the 7-segment displays
		.BUS_DATA  (BUS_DATA),		// the context of the data memory (RAM)
		.BUS_ADDR  (BUS_ADDR),		// the address of the data memory (RAM)
		.WE		   (BUS_WE),		// enable the 7-segment displays to display the digits
		.SEG_SELECT(SEG_SELECT),	// selects one of the four digits on the 7-segment displays
		.DEC_OUT   (DEC_OUT)		// drives the segments in the 7-segment displays
	);
		
	// instantiate the RAM
	ram RAM (
		.CLK	   (CLK),			// on-board clock (100MHz)
		.BUS_WE	   (BUS_WE),		// enable the RAM to write data
		.BUS_ADDR  (BUS_ADDR),		// the address of the data memory (RAM)
		.BUS_DATA  (BUS_DATA)		// the context of the data memory (RAM)
	);
	
	// instantiate the ROM
	rom ROM (
		.CLK 	   (CLK),			// on-board clock (100MHz)
		.ADDR	   (ROM_ADDRESS),	// address of the instruction memory (ROM)
		.DATA	   (ROM_DATA)		// data of the instruction memory (ROM)
	);

endmodule