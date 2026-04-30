`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    10:47:49 06/08/2025 
// Design Name: 
// Module Name:    AlphaSwitch 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module AlphaSwitch(
    input [7:0] Data,
    input Inv,
    output [7:0] AData
    );
	 
	 assign AData = Inv ? 8'd255 ^ Data : Data;
	 
endmodule