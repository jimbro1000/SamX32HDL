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
	input [3:0] Colour1, // alpha
	input Sel1,
	input [3:0] Colour2, // semi
	input Sel2,
	input [3:0] Colour3, // graphic
	input backporch,
	input viewportActive,
	input [3:0] Colour4, // border
	input VC,
	input [127:0] PaletteDef,
	input [7:0] Border,
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
		if (!backporch & viewportActive & !Sel1 & !Sel2 & !VC) begin
			case (Colour)
				4'b0000:
					RGB = {PaletteDef[7],PaletteDef[5],PaletteDef[2],1'b0,PaletteDef[6],PaletteDef[4],PaletteDef[1],1'b0,PaletteDef[3],PaletteDef[0],2'b00};
				4'b0001:
					RGB = {PaletteDef[15],PaletteDef[13],PaletteDef[10],1'b0,PaletteDef[14],PaletteDef[12],PaletteDef[9],1'b0,PaletteDef[11],PaletteDef[8],2'b00};
				4'b0010:
					RGB = {PaletteDef[23],PaletteDef[21],PaletteDef[18],1'b0,PaletteDef[22],PaletteDef[20],PaletteDef[17],1'b0,PaletteDef[19],PaletteDef[16],2'b00};
				4'b0011:
					RGB = {PaletteDef[31],PaletteDef[29],PaletteDef[26],1'b0,PaletteDef[30],PaletteDef[28],PaletteDef[25],1'b0,PaletteDef[27],PaletteDef[24],2'b00};
				4'b0100:
					RGB = {PaletteDef[39],PaletteDef[37],PaletteDef[34],1'b0,PaletteDef[38],PaletteDef[36],PaletteDef[33],1'b0,PaletteDef[35],PaletteDef[32],2'b00};
				4'b0101: 
					RGB = {PaletteDef[47],PaletteDef[45],PaletteDef[42],1'b0,PaletteDef[46],PaletteDef[44],PaletteDef[41],1'b0,PaletteDef[43],PaletteDef[40],2'b00};
				4'b0110:
					RGB = {PaletteDef[55],PaletteDef[53],PaletteDef[50],1'b0,PaletteDef[54],PaletteDef[52],PaletteDef[49],1'b0,PaletteDef[51],PaletteDef[48],2'b00};
				4'b0111:
					RGB = {PaletteDef[63],PaletteDef[61],PaletteDef[58],1'b0,PaletteDef[62],PaletteDef[60],PaletteDef[57],1'b0,PaletteDef[59],PaletteDef[56],2'b00};
				4'b1000:
					RGB = {PaletteDef[71],PaletteDef[69],PaletteDef[66],1'b0,PaletteDef[70],PaletteDef[68],PaletteDef[65],1'b0,PaletteDef[67],PaletteDef[64],2'b00};
				4'b1001:
					RGB = {PaletteDef[79],PaletteDef[77],PaletteDef[74],1'b0,PaletteDef[78],PaletteDef[76],PaletteDef[73],1'b0,PaletteDef[75],PaletteDef[72],2'b00};
				4'b1010:
					RGB = {PaletteDef[87],PaletteDef[85],PaletteDef[82],1'b0,PaletteDef[86],PaletteDef[84],PaletteDef[81],1'b0,PaletteDef[83],PaletteDef[80],2'b00};
				4'b1011:
					RGB = {PaletteDef[95],PaletteDef[93],PaletteDef[90],1'b0,PaletteDef[94],PaletteDef[92],PaletteDef[89],1'b0,PaletteDef[91],PaletteDef[88],2'b00};
				4'b1100:
					RGB = {PaletteDef[103],PaletteDef[101],PaletteDef[98],1'b0,PaletteDef[102],PaletteDef[100],PaletteDef[97],1'b0,PaletteDef[99],PaletteDef[96],2'b00};
				4'b1101:
					RGB = {PaletteDef[111],PaletteDef[109],PaletteDef[106],1'b0,PaletteDef[110],PaletteDef[108],PaletteDef[105],1'b0,PaletteDef[107],PaletteDef[104],2'b00};
				4'b1110:
					RGB = {PaletteDef[119],PaletteDef[117],PaletteDef[114],1'b0,PaletteDef[118],PaletteDef[116],PaletteDef[113],1'b0,PaletteDef[115],PaletteDef[112],2'b00};
				default:
					RGB = {PaletteDef[127],PaletteDef[125],PaletteDef[122],1'b0,PaletteDef[126],PaletteDef[124],PaletteDef[121],1'b0,PaletteDef[123],PaletteDef[120],2'b00};
			endcase
		end else begin
			if (!backporch & !viewportActive & !VC) begin // use border definition
				RGB = {Border[7],Border[5],Border[2],1'b0,Border[6],Border[4],Border[1],1'b0,Border[3],Border[0],2'b00};
			end else // use compatible palette
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
	end

endmodule
