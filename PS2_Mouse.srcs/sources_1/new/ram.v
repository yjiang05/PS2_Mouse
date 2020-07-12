`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/02/25 16:46:18
// Design Name: Assessment 2 - Microprocessor-based Mouse Interface
// Module Name: ram
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT BASYS 3 ARTIX 7
// Tool Versions: Vivado 2015.2
// Description: The data memory.
// 
// Dependencies: ram_v1.txt
// 
// Revision:
// Revision 1.1  - Bug-free
// Revision 1.0  - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 	Interface:
//		CLK: The on-board clock (100MHz).
//		BUS_WE: Enables the RAM to write data.
//		BUS_ADDR: The microprocessor can send the addresses of instructions through these.
//		BUS_DATA: Wires connecting the processor and the RAM. The RAM can read and write data through these.
//////////////////////////////////////////////////////////////////////////////////


module ram(
	// standard signals
    input 		CLK,	  // the on-board clock (100MHz), connects to the on-board clock line
	// bus signals
    input 		BUS_WE,	  // enables the RAM to write data, connects to the output of the microprocessor
    input [7:0] BUS_ADDR, // the address of the data memory (RAM), connects to the output of the microprocessor
    inout [7:0] BUS_DATA  // the context of the data memory (RAM), connects to the inout port of the microprocessor
    );
	
	parameter RAMBaseAddr = 0;		// base address of the RAM
	parameter RAMAddrWidth = 7;		// 128 x 8-bits memory

	// tristate
	reg 	   RAMBusWE;			// control the output of the tristate
	reg  [7:0] Out;
	wire [7:0] BufferedBusData;
	
	// only place data on the bus if the processor is NOT writing, and it is addressing this memory
	assign BUS_DATA 	   = (RAMBusWE) ? Out : 8'hZZ;
	assign BufferedBusData = BUS_DATA;
	
	// memory
	reg [7:0] Mem [2**RAMAddrWidth-1:0];
	
	// initialise the memory for data preloading, initialising variables, and declaring constants
	initial $readmemh("ram_v1.txt", Mem);
	
	// single port ram
	always@(posedge CLK) begin
	// brute-force RAM address decoding
		if((BUS_ADDR >= RAMBaseAddr) & (BUS_ADDR < RAMBaseAddr + 128)) begin
			if(BUS_WE) begin
				RAMBusWE 		   <= 1'b0;
				Mem[BUS_ADDR[6:0]] <= BufferedBusData;
			end else
				RAMBusWE <= 1'b1;
		end else
			RAMBusWE <= 1'b0;
		Out <= Mem[BUS_ADDR[6:0]];
	end
endmodule