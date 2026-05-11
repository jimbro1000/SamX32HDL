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
	input [2:0] GMode,
	input FrameFormat,
	input AnG,
	input Clk,
	input VC_EN,
	input BP,
	input [2:0] HRES,
	input [8:0] LeftBorderMargin,
	input [8:0] RightBorderMargin,
	input [8:0] TopMargin,
	input [8:0] BottomMargin,
	input [1:0] CRES,
	input VideoLoadClock,
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
	wire [8:0] frameTopRow;
	wire [8:0] frameBottomRow;
	wire [10:0] leftpreload;
	wire [10:0] rightpreload;
	wire [10:0] LeftBorder;
	wire [10:0] RightBorder;
	wire slowMode;
	reg u_da0;
	reg hBlank;
	reg vBlank;
	
	assign LeftBorder = {LeftBorderMargin, 2'b00};
	assign RightBorder = {RightBorderMargin, 2'b00};

	// horizontal beam counter using gclk for frame timing accuracy
	reg [10:0] colCounter;
	// vertical beam counter
	reg [8:0] lineCounter;
	// preload data pixel counter
	reg [6:0] daCount;
	// enable data address count - stops at end of line, starts 2 clocks before first display byte on each line
	reg daCountEnable;
	// how many clock counts needed to trigger a change to da
	reg [7:0] daResetLimit;
	reg [3:0] alphaRowCounter;
	
	// horizontal
	parameter leftSync = 11'd56; //14; // 4us duration
	parameter leftMargin = 11'd112; //28; // 12us duration //42
	parameter rightMargin = 11'd892; //223; // suggested 8 cycles of front porch //225
	parameter allcols = 11'd908; //227; // 64us duration (63.55 at 3.57MHz x 227 / 63.9 at 14.32MHz x 916 )
	// vertical
	parameter vsync = 9'd7;
	// best = 7, 20, 95, 287, 311
	// target = 32, 45, 95, 287, 311 
	
	// parameter activecols = 128;// * 2 = 256
	// to achieve 40 data access cycles per line the preload must start at 66-69 clock cycles

	always @(negedge Clk) begin
		if (colCounter == allcols) begin
			colCounter <= 0;
			HSn <= 1'b0;
			hBlank <= 1'b1;
			daCountEnable <= 1'b0;
			if (lineCounter == (FrameFormat == 1'b1 ? 9'd258 : 9'd311)) begin
				lineCounter <= 0;
				FSn <= 1'b0;
				vBlank <= 1'b1;
			end else begin
				// logic will deliberately fall through
				lineCounter <= lineCounter + 9'd1;
				if (lineCounter == vsync)
					FSn <= 1'b1;
				if (lineCounter == (FrameFormat == 1'b1 ? 9'd32 : 9'd57))
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
			// logic will deliberately fall through
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
			if (activeRow && colCounter == LeftBorder)
				active <= 1'b1;
			if (activeRow && colCounter == RightBorder)
				active <= 1'b0;
		end

		daCount <= daCount + 2'd1;
		if (daCount == daResetLimit)
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
	// fine when single speed video but need to operate on double speed and falling edge of Q moves on cpu double speed
	// better clock trigger required! States 3 and B of state machine would be ideal - effectively the z_video signal
	always @(posedge VideoLoadClock) begin
		DA0 <= u_da0;
	end
	
	assign alphaRow = alphaRowCounter;
		
	reg [4:0] preloadOffset = 5'd16;
	assign leftpreload = LeftBorderMargin - preloadOffset;
	assign rightpreload = RightBorderMargin - preloadOffset;

//	always @(CRES) begin // very speculatively split into logic on bits per pixel but likely unnecessary...
//		if (VC_EN == 1'b0 && CRES == 2'd0) begin
//			case (HRES)
//				3'b101 : begin
//					preloadOffset <= 5'd8; // 640 x 1 pixels wide
//					daResetLimit <= 8'd8;
//				end
//				3'b100 : begin
//					preloadOffset <= 5'd8; // 512 x 1 pixels wide
//					daResetLimit <= 8'd8;
//				end
//				3'b011 : begin
//					preloadOffset <= 5'd16; // 320 x 1 pixels wide
//					daResetLimit <= 8'd16;
//				end
//				default: begin
//					preloadOffset <= 5'd16; // 256 x 1 pixels wide
//					daResetLimit <= 8'd16;
//				end
//			endcase
//		end else if (CRES == 2'd1) begin
//			case (HRES)
//				3'b101 : begin
//					preloadOffset <= 5'd8; // 320 x 1 pixels wide
//					daResetLimit <= 8'd16;
//				end
//				3'b100 : begin
//					preloadOffset <= 5'd8; // 256 x 1 pixels wide
//					daResetLimit <= 8'd16;
//				end
//				3'b011 : begin
//					preloadOffset <= 5'd16; // 160 x 2 pixels wide
//					daResetLimit <= 8'd32;
//				end
//				default: begin
//					preloadOffset <= 5'd16; // 128 x 2 pixels wide
//					daResetLimit <= 8'd32;
//				end
//			endcase
//		end else if (CRES == 2'd2) begin
//			case (HRES)
//				3'b101 : begin
//					preloadOffset <= 5'd8; // 160 x 2 pixels wide
//					daResetLimit <= 8'd32;
//				end
//				3'b100 : begin
//					preloadOffset <= 5'd8; // 128 x 2 pixels wide
//					daResetLimit <= 8'd32;
//				end
//				3'b011 : begin
//					preloadOffset <= 5'd16; // 80 x 4 pixels wide
//					daResetLimit <= 8'd64;
//				end
//				default: begin
//					preloadOffset <= 5'd16; // 64 x 4 pixels wide
//					daResetLimit <= 8'd64;
//				end
//			endcase
//		end else begin // 8BPP
//			case (HRES)
//				3'b111 : begin
//					preloadOffset <= 5'd1; // actually 256 byte width
//					daResetLimit <= 8'd1;
//				end
//				3'b101 : begin
//					preloadOffset <= 5'd8; // 40 x 8 pixels wide
//					daResetLimit <= 8'd64;
//				end
//				3'b011 : begin
//					preloadOffset <= 5'd8; // 32 x 8 pixels wide
//					daResetLimit <= 8'd64;
//				end
////				7'd40 : begin
////					preloadOffset <= 5'd16; // 20 x 16 pixels wide
////					daResetLimit <= 8'd128;
////				end
//				default: begin
//					preloadOffset <= 5'd16; // 16 x 16 pixels wide
//					daResetLimit <= 8'd128;
//				end
//			endcase
//		end
//	end
	
	initial begin
	   u_da0 = 1'b1;
		colCounter = 0;
		lineCounter = 0;
		Clk3 = 0;
		alphaRowCounter = 0;
		daCount = 7'd0;
	end

	// vertical sync active low
	// assign FSn = ~(lineCounter[8:2] == 6'd0); 
	// 8 lines of vsync according to spec - 6847 produces nearer 40 lines...use 32 need to fix this for NTSC if I start at 16 instead of 0
	// Spectrum ULA generates just 4 lines of vsync and 8 lines of blank
	
	// backporch active high
	assign BackPorch = hBlank || vBlank;
	
	// general signals
	assign slowMode = VC_EN && AnG && (GMode == 3'b000);
	assign PixelClk = slowMode ? Clk3 : Clk;
	assign frameTopRow = TopMargin; //FrameFormat ? toprow2 : toprow; // FrameFormat 0=PAL/1=NTSC
	assign frameBottomRow = BottomMargin; //FrameFormat ? bottomrow2 : bottomrow;

endmodule