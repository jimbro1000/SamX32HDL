`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:32:36 06/08/2025 
// Design Name: 
// Module Name:    ColourMap 
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
module ColourMap(
    input [1:0] Pixel,
    input [2:0] Mode,
	 input AnG,
    input Css,
    output reg [3:0] Colour
    );

	always @(Mode, AnG, Css, Pixel) begin
		if (AnG) begin
			case (Mode)
				3'b000, 3'b010, 3'b100, 3'b110:
					if (Css)
						Colour <= ({2'b00,Pixel}) + 4'b0101; // 4 colour green set
					else
						Colour <= ({2'b00,Pixel}) + 4'b0001; // 4 colour white set
				default:
					if (Css)
						if (Pixel == 2'b00)
							Colour <= 4'b0000; //black
						else
							Colour <= 4'b0101; //white
					else if (Pixel == 2'b00)
						Colour <= 4'b1010; //dark green
					else
						Colour <= 4'b0001; //green
			endcase
		end else begin
			if (Css)
				if (Pixel == 2'b00)
					Colour <= 4'b1011; //dark red
				else
					Colour <= 4'b1001; //bright orange
			else
				if (Pixel == 2'b00)
					Colour <= 4'b1010; //dark green
				else
					Colour <= 4'b0001; //green
		end
	end

endmodule