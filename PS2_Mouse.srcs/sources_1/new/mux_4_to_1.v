`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: School of Engineering, The University of Edinburgh
// Engineer: Yunfan Jiang (s1886282)
// 
// Create Date: 2020/02/04 10:03:12
// Design Name: Assessment 1 - Mouse Interface
// Module Name: mux_4_to_1
// Project Name: Digital Systems Laboratory 4
// Target Devices: DIGILENT Basys3
// Tool Versions: Vivado 2015.2
// Description: A 4-to-1 multiplexer
// 
// Dependencies: None
// 
// Revision:
// Revision 1.0	 - Implementation Complete
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mux_4_to_1(
    input 	   [1:0] SIGNAL_SELECT, 	// select signal 
    input 	   [4:0] SIGNAL_IN_0,		// input signal 1
    input 	   [4:0] SIGNAL_IN_1,		// input signal 2
    input 	   [4:0] SIGNAL_IN_2,		// input signal 3
    input 	   [4:0] SIGNAL_IN_3,		// input signal 4
    output reg [4:0] SIGNAL_OUT			// output signal
    );
	
	always@ (SIGNAL_SELECT | SIGNAL_IN_0 | SIGNAL_IN_1 | SIGNAL_IN_2 | SIGNAL_IN_3) begin
		// a "case" statement is used to realise the functionalities
		case (SIGNAL_SELECT)
			2'b00: SIGNAL_OUT <= SIGNAL_IN_0;
			2'b01: SIGNAL_OUT <= SIGNAL_IN_1;
			2'b10: SIGNAL_OUT <= SIGNAL_IN_2;
			2'b11: SIGNAL_OUT <= SIGNAL_IN_3;
			
			default: SIGNAL_OUT <= 5'b00000;
		endcase
	end
endmodule