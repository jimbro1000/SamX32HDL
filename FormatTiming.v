`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    07:34:31 06/08/2025 
// Design Name: 
// Module Name:    FormatTiming 
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
module FormatTiming(
	input Q,
	input [2:0] GMode,
	input FrameFormat,
	input AnG,
	input Clk,
	input VC_EN,
	input BP,
	input [2:0] CRES,
	input [2:0] LPR,
	input [2:0] HRES,
	output PixelClk,
	output reg HSn,
	output reg FSn,
	output BackPorch,
	output reg active,
	output reg Load,
	output [3:0] alphaRow,
	output reg DA0
   );
	
	reg activeRow;
	wire [9:0] frameTopRow;
	wire [9:0] frameBottomRow;
	wire [9:0] frameAllRows;
	wire [9:0] frameVBlank;
	wire [9:0] frameVSync;
	wire slowMode;
	reg u_da0;
	reg hBlank;
	reg vBlank;

	// horizontal beam counter using gclk for frame timing accuracy
	reg [8:0] colCounter;
	// vertical beam counter
	reg [8:0] lineCounter;
	// preload data pixel counter
	reg [1:0] daCount;
	// enable data address count - stops at end of line, starts 2 clocks before first display byte on each line
	reg daCountEnable;
	reg [3:0] alphaRowCounter;
	
	always @(negedge Clk) begin
		if (colCounter == allcols) begin
			colCounter <= 0;
			HSn <= 1'b0;
			hBlank <= 1'b1;
			daCountEnable <= 1'b0;
			if (lineCounter == frameAllRows) begin
				lineCounter <= 0;
				FSn <= 1'b0;
				vBlank <= 1'b1;
			end else begin
				lineCounter <= lineCounter + 9'd1;
				if (lineCounter == frameVSync)
					FSn <= 1'b1;
				if (lineCounter == frameVBlank)
					vBlank <= 1'b0;
				if (lineCounter == frameTopRow)
					activeRow <= 1'b1;
				if (lineCounter == frameBottomRow)
					activeRow <= 1'b0;
				if ((alphaRowCounter == 4'b1011) || (lineCounter == frameTopRow))
					alphaRowCounter <= 4'd0;
				else
					alphaRowCounter <= alphaRowCounter + 4'd1;
			end
			
		end else begin
			colCounter <= colCounter + 9'd1;
			if (colCounter == leftSync)
				HSn <= 1'b1;
			if (colCounter == leftMargin)
				hBlank <= 1'b0;
			if (colCounter == rightMargin)
				hBlank <= 1'b1;
			if (activeRow && colCounter == leftpreload)
				daCountEnable <= 1'b1;
			if (activeRow && colCounter == rightpreload)
				daCountEnable <= 1'b0;
			if (activeRow && colCounter == leftcols)
				active <= 1'b1;
			if (activeRow && colCounter == rightcols)
				active <= 1'b0;
		end

		daCount <= daCount + 2'd1;
		if (daCount == 2'd0)
			if (daCountEnable)
				u_da0 <= ~u_da0;
			else if (HSn)
				u_da0 <= 1'b0;
		Load = slowMode ? colCounter[2:0] == 3'd1 : colCounter[1:0] == 2'd1;
	end
	
	reg Clk3;
	always @(negedge Clk) begin
		Clk3 = ~Clk3;
	end

	// only change DA0 on falling edge of Q, guarantees the change is in phase with SAM
	// may need to move preload to a full 4 cycles before it is needed
	always @(negedge Q) begin
		DA0 <= u_da0;
	end
	
	assign alphaRow = alphaRowCounter;
		
	// horizontal
	parameter leftSync = 9'd14; // 4us duration
	parameter leftMargin = 9'd28; // 12us duration //42
	parameter rightMargin = 9'd223; // suggested 8 cycles of front porch //225
	parameter allcols = 9'd227; // 64us duration (63.55)
	// vertical
	parameter activerows = 9'd192;
	// pal
	parameter vsync = 9'd7;
	parameter topBlank = 9'd57; //pal
	parameter toprow = 9'd84;
	parameter bottomrow = 9'd276; //pal
	parameter allrows = 9'd311;// pal
	// best = 7, 20, 95, 287, 311
	// target = 32, 45, 95, 287, 311 
	
	// ntsc
	parameter vsync2 = 9'd7;
	parameter topBlank2 = 9'd32; //ntsc
	parameter toprow2 = 9'd45;
	parameter bottomrow2 = 9'd237; //ntsc
	parameter allrows2 = 9'd258;// ntsc

	//parameter activecols = 128;// * 2 = 256
	//to achieve 40 data access cycles per line the preload must start at 66-69 clock cycles
	parameter leftcols = 9'd64; //
	parameter rightcols = 9'd192; //leftcols + activecols + 1;
	parameter leftpreload = 9'd63; //leftcols - 4;
	parameter rightpreload = 9'd217; //rightcols - 4;

	initial begin
	   u_da0 = 1'b1;
		colCounter = 0;
		lineCounter = 0;
		Clk3 = 0;
		alphaRowCounter = 0;
		daCount = 2'd0;
	end

	// vertical sync active low
	// assign FSn = ~(lineCounter[8:2] == 6'd0); 
	// 8 lines of vsync according to spec - 6847 produces nearer 40 lines...use 32 need to fix this for NTSC if I start at 16 instead of 0
	// Spectrum ULA generates just 4 lines of vsync and 8 lines of blank
	
	// backporch active high
	assign BackPorch = hBlank || vBlank;
	
	// general signals
	assign slowMode = AnG && (GMode == 3'b000);
	assign PixelClk = slowMode ? Clk3 : Clk;
	assign frameTopRow = FrameFormat ? toprow2 : toprow; // FrameFormat 0=PAL/1=NTSC
	assign frameBottomRow = FrameFormat ? bottomrow2 : bottomrow;
	assign frameAllRows = FrameFormat ? allrows2 : allrows;
	assign frameVBlank = FrameFormat ? topBlank2 : topBlank;
	assign frameVSync = FrameFormat ? vsync2 : vsync;

endmodule