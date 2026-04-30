`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:23:51 06/08/2025 
// Design Name: 
// Module Name:    SemiShift 
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
module SemiShift(
	input [7:0] Data,
	input Clk,
	input Load,
	input [3:0] SColour,
	output reg [3:0] Colour
);

	reg [7:0] pixelData;
	reg [1:0] offset;

	always @(negedge Clk) begin
		if (Load)
			offset <= 2'b11;
		else
			offset <= offset - 2'd1;
		case (offset)
			2'b11, 2'b10:
				Colour <= pixelData[7] ? 4'b0000 : SColour;
			default:
				Colour <= pixelData[3] ? 4'b0000 : SColour;
		endcase
	end

	always @(posedge Load) begin
		pixelData <= Data;
	end

endmodule
