`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:00:45 06/08/2025 
// Design Name: 
// Module Name:    ColourMux 
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
module ColourMux(
	input clk,
	input [3:0] Colour1,
	input Sel1,
	input [3:0] Colour2,
	input Sel2,
	input [3:0] Colour3,
	input backporch,
	input viewportActive,
	input [3:0] Colour4,
	output reg [11:0] RGB
);

	wire [3:0] Colour;

	// backporch must return full black (default case)
	// viewport active multiplexes graphic input (alpha, semi, graphic)
	// sel1 = colour1
	// sel2 = colour2
	// !sel1 & !sel2 = colour3
	// anything else must be a border
	assign Colour = backporch ? 4'b1111 : viewportActive ? Sel1 ? Colour1 : Sel2 ? Colour2 : Colour3 : Colour4;

	always @(clk) begin
		case (Colour)
			4'b0000:
				RGB = 12'b000000000000; // almost black
			4'b0001:
				RGB = 12'b001111110000; // green
			4'b0010:
				RGB = 12'b111111110000; // yellow
			4'b0011:
				RGB = 12'b001000101111; // blue
			4'b0100:
				RGB = 12'b111100000000; // red
			4'b0101: 
				RGB = 12'b111111111111; // white (buff)
			4'b0110:
				RGB = 12'b001111111100; // cyan
			4'b0111:
				RGB = 12'b111100111111; // magenta
			4'b1000:
				RGB = 12'b111111000000; // orange
			4'b1001:
				RGB = 12'b111111000100; // bright orange
			4'b1010:
				RGB = 12'b000001000000; // dark green
			4'b1011:
				RGB = 12'b010000100010; // dark red
			4'b1110:
				RGB = 12'b000000100000; // dark green border
			default:
				RGB = 12'b000000000000; // backporch black
		endcase
	end

endmodule
