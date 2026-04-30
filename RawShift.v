`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:12:50 06/08/2025 
// Design Name: 
// Module Name:    RawShift 
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
module RawShift(
	input [7:0] Data,
	input Clk,
	input Divider,
	input Load,
	output reg [1:0] Pixel
);

	reg [7:0] pixelData;
	reg [1:0] offset;
	
	always @(negedge Clk) begin
		if (Load)
			offset <= 2'b11;
		else
			offset <= offset - 2'd1;
	end
	
	always @(posedge Load) begin
		pixelData <= Data;
	end
	
	always @(Clk) begin
		if (Divider == 0)
			Pixel <= {1'b0,pixelData[{offset, Clk}]};
		else
			case (offset)
				2'b11:
					Pixel <= pixelData[7:6];
				2'b10:
					Pixel <= pixelData[5:4];
				2'b01:
					Pixel <= pixelData[3:2];
				default:
					Pixel <= pixelData[1:0];
			endcase
	end
	
endmodule
