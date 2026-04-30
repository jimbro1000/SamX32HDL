`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:06:08 06/08/2025 
// Design Name: 
// Module Name:    Semi4Rom 
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
module Semi4Rom(
	input Clk,
   input [7:0] Data,
   input [3:0] Row,
   output reg [7:0] SData,
   output reg [3:0] SColour
);

	reg [1:0] index;
	
	always @(negedge Clk) begin
		if (Row == 4'd0)
			index <= Data[3:2];
		if (Row == 4'd6)
			index <= Data[1:0];
		SColour <= ({1'b0,Data[6:4]}) + 4'd1;
		case (index)
			2'd0: SData <= 8'b11111111;
			2'd1: SData <= 8'b11110000;
			2'd2: SData <= 8'b00001111;
			default: SData <= 8'b00000000;
		endcase
	end
endmodule
