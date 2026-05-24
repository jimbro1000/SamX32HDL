
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
	input [3:0] Colour5, // Enhanced mode palette index
	input VC,
	input [127:0] PaletteDef,
	input [7:0] Border,
	output reg [11:0] RGB
);

	wire [3:0] CColour;
	wire paletteMode;
	wire [2:0] ColourSelect;
	wire borderMode;
	wire [11:0] RGB5; // blank
	wire [11:0] RGB1; // alpha

	assign ColourSelect = {viewportActive, Sel1, Sel2};
	
	// backporch must return full black (default case)
	// viewport active multiplexes graphic input (alpha, semi, graphic)
	// sel1 = colour1
	// sel2 = colour2
	// !sel1 & !sel2 = colour3
	// anything else must be a border
	assign paletteMode = (viewportActive == 1'b1) & (backporch == 1'b0) & (Sel1 == 1'b0) & (Sel2 == 1'b0); // not backporch, text or semi - border is a direct palette colour!
	assign CColour = backporch == 1'b1 ? 4'b1111 : ColourSelect == 4'b100 ? Colour3 : ColourSelect == 4'b110 ? Colour1 : ColourSelect == 4'b101 ? Colour2 : Colour4;
	assign borderMode = (backporch == 1'b0 & viewportActive == 1'b0);
	
	Palette6847 blankChannel(
		.clk(clk),
		.index(4'b1111),
		.RGB(RGB5)
	);
	
	Palette6847 frameChannel(
		.clk(clk),
		.index(CColour),
		.RGB(RGB1)
	);
	
	always @(clk) begin
		if (VC == 1'b0) begin
			if (paletteMode) begin //  !backporch & viewportActive & !Sel1 & !Sel2 & !VC) begin
				case (Colour5)
					4'b0000:
						RGB <= {PaletteDef[7],PaletteDef[5],PaletteDef[2],1'b0,PaletteDef[6],PaletteDef[4],PaletteDef[1],1'b0,PaletteDef[3],PaletteDef[0],2'b00};
					4'b0001:
						RGB <= {PaletteDef[15],PaletteDef[13],PaletteDef[10],1'b0,PaletteDef[14],PaletteDef[12],PaletteDef[9],1'b0,PaletteDef[11],PaletteDef[8],2'b00};
					4'b0010:
						RGB <= {PaletteDef[23],PaletteDef[21],PaletteDef[18],1'b0,PaletteDef[22],PaletteDef[20],PaletteDef[17],1'b0,PaletteDef[19],PaletteDef[16],2'b00};
					4'b0011:
						RGB <= {PaletteDef[31],PaletteDef[29],PaletteDef[26],1'b0,PaletteDef[30],PaletteDef[28],PaletteDef[25],1'b0,PaletteDef[27],PaletteDef[24],2'b00};
					4'b0100:
						RGB <= {PaletteDef[39],PaletteDef[37],PaletteDef[34],1'b0,PaletteDef[38],PaletteDef[36],PaletteDef[33],1'b0,PaletteDef[35],PaletteDef[32],2'b00};
					4'b0101: 
						RGB <= {PaletteDef[47],PaletteDef[45],PaletteDef[42],1'b0,PaletteDef[46],PaletteDef[44],PaletteDef[41],1'b0,PaletteDef[43],PaletteDef[40],2'b00};
					4'b0110:
						RGB <= {PaletteDef[55],PaletteDef[53],PaletteDef[50],1'b0,PaletteDef[54],PaletteDef[52],PaletteDef[49],1'b0,PaletteDef[51],PaletteDef[48],2'b00};
					4'b0111:
						RGB <= {PaletteDef[63],PaletteDef[61],PaletteDef[58],1'b0,PaletteDef[62],PaletteDef[60],PaletteDef[57],1'b0,PaletteDef[59],PaletteDef[56],2'b00};
					4'b1000:
						RGB <= {PaletteDef[71],PaletteDef[69],PaletteDef[66],1'b0,PaletteDef[70],PaletteDef[68],PaletteDef[65],1'b0,PaletteDef[67],PaletteDef[64],2'b00};
					4'b1001:
						RGB <= {PaletteDef[79],PaletteDef[77],PaletteDef[74],1'b0,PaletteDef[78],PaletteDef[76],PaletteDef[73],1'b0,PaletteDef[75],PaletteDef[72],2'b00};
					4'b1010:
						RGB <= {PaletteDef[87],PaletteDef[85],PaletteDef[82],1'b0,PaletteDef[86],PaletteDef[84],PaletteDef[81],1'b0,PaletteDef[83],PaletteDef[80],2'b00};
					4'b1011:
						RGB <= {PaletteDef[95],PaletteDef[93],PaletteDef[90],1'b0,PaletteDef[94],PaletteDef[92],PaletteDef[89],1'b0,PaletteDef[91],PaletteDef[88],2'b00};
					4'b1100:
						RGB <= {PaletteDef[103],PaletteDef[101],PaletteDef[98],1'b0,PaletteDef[102],PaletteDef[100],PaletteDef[97],1'b0,PaletteDef[99],PaletteDef[96],2'b00};
					4'b1101:
						RGB <= {PaletteDef[111],PaletteDef[109],PaletteDef[106],1'b0,PaletteDef[110],PaletteDef[108],PaletteDef[105],1'b0,PaletteDef[107],PaletteDef[104],2'b00};
					4'b1110:
						RGB <= {PaletteDef[119],PaletteDef[117],PaletteDef[114],1'b0,PaletteDef[118],PaletteDef[116],PaletteDef[113],1'b0,PaletteDef[115],PaletteDef[112],2'b00};
					default:
						RGB <= {PaletteDef[127],PaletteDef[125],PaletteDef[122],1'b0,PaletteDef[126],PaletteDef[124],PaletteDef[121],1'b0,PaletteDef[123],PaletteDef[120],2'b00};
				endcase
			end else if (borderMode) begin
				RGB <= {Border[7],Border[5],Border[2],Border[7],Border[6],Border[4],Border[1],Border[6],Border[3],Border[0],Border[3],Border[0]};
			end else begin // backporch
				RGB <= RGB5;
			end
		end else begin // vompatibility mode = 1
			RGB <= RGB1;
		end // vcompatibility mode
	end // always

endmodule

module ColourMux_testbench();

	reg clk;
	reg [3:0] Colour1;
	reg [3:0] Colour2;
	reg [3:0] Colour3;
	reg [3:0] Colour4;
	reg [3:0] Colour5;
	reg sel1;
	reg sel2;
	reg backporch;
	reg viewportActive;
	reg VC;
	reg [127:0] PaletteDef;
	reg [7:0] Border;
	wire [11:0] RGB;

	ColourMux uut(
		.clk(clk),
		.Colour1(Colour1), // alpha
		.Sel1(sel1),
		.Colour2(Colour2), // semi
		.Sel2(sel2),
		.Colour3(Colour3), // graphic
		.backporch(backporch),
		.viewportActive(viewportActive),
		.Colour4(Colour4), // border
		.Colour5(Colour5), // palette index
		.VC(VC),
		.PaletteDef(PaletteDef),
		.Border(Border),
		.RGB(RGB)
	);
	
	initial begin
		clk <= 1'b0;
		Colour1 <= 4'd1;
		Colour2 <= 4'd2;
		Colour3 <= 4'd3;
		Colour4 <= 4'd4;
		Colour5 <= 4'd1;
		sel1 <= 1'b0;
		sel2 <= 1'b0;
		backporch <= 1'b1;
		viewportActive <= 1'b0;
		VC <= 1'b1;
		Border <= 8'b10100100;
		PaletteDef <= 128'b00111000000010000001000000100000001111110000100100010010001001001111111101011011101011011111011000001001010100101010010000000000;
		
		#(200) sel1 <= 1'b1;
		#(200) sel1 <= 1'b0; sel2 <= 1'b1;
		#(200) sel2 <= 1'b0; backporch <= 1'b0;
		#(200) sel1 <= 1'b1;
		#(200) sel1 <= 1'b0; sel2 <= 1'b1;
		#(200) sel2 <= 1'b0; viewportActive <= 1'b1;
		#(200) sel1 <= 1'b1;
		#(200) sel1 <= 1'b0; sel2 <= 1'b1;
		#(200) sel2 <= 1'b0; viewportActive <= 1'b0;
	end

	always begin
		#(100) clk <= ~clk;
	end
	
endmodule
