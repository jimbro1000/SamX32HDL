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
	reg [3:0] offset;

	always @(negedge Clk) begin
		if (Load == 1'b1) begin
			pixelData <= Data;
			offset <= 4'b1111;
		end else
			offset <= offset - 4'd1;
	end

	always @(negedge Clk) begin
		case (offset[3:2])
			2'b11, 2'b10:
				Colour <= pixelData[7] ? 4'b0000 : SColour;
			default:
				Colour <= pixelData[3] ? 4'b0000 : SColour;
		endcase
	end

endmodule
