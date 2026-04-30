`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:00:14 06/08/2025 
// Design Name: 
// Module Name:    FormatSelect 
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
module FormatSelect(
    input Clk,
    input Format,
	 input FSn,
	 output reg FrameFormat
    );

	always @(posedge FSn) begin
		FrameFormat = Format;
	end
endmodule