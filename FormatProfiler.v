module FormatProfiler (
	input clk, 								// video clock (14.318MHz)
	input format, 							// 0 = PAL, 1 = NTSC
	input [2:0] GM, 						// 6847 graphic mode
	input AnG, 								// 6847 Alpha/Graphic select. Alpha = 0
	input VC_EN, 							// vcompatibility mode. 1 = 6847
	input BP, 								// bitmap mode. 1 = bitmap
	input [2:0] HRES, 					// horizontal resolution
	input [1:0] LPF, 						// lines per field
	
	output reg [8:0] LeftMargin, 		// left edge of viewport / 4
	output reg [8:0] RightMargin, 	// right edge of viewport / 4
	output reg [8:0] TopMargin, 		// top edge of viewport
	output reg [8:0] BottomMargin, 	// bottom edge of viewport
	output reg fast_video 				// fast read cycle required. 1 = 1.79MHz/0 = 0.89MHz
);

initial begin
	// default to PAL alpha
	// hsync = 57 // backporch = 114 // left border = 64 // right border = 192
	LeftMargin <= 9'd64;
	RightMargin <= 9'd192;
	TopMargin <= 9'd84;
	BottomMargin <= 9'd276;
	fast_video <= 1'b0;
end

always @(negedge clk) begin
	if (VC_EN == 1'b1)  // vcompatibility mode
		if (AnG == 1'b1 & GM == 3'b001) begin
			LeftMargin <= 9'd64;
			RightMargin <= 9'd192;
			TopMargin <= format == 1'b1 ? 9'd41 : 9'd80;
			BottomMargin <= format == 1'b1 ? 9'd241 : 9'd280;
			fast_video <= 1'b0;	
		end else begin
			LeftMargin <= 9'd64;
			RightMargin <= 9'd192;
			TopMargin <= format == 1'b1 ? 9'd45 : 9'd84;
			BottomMargin <= format == 1'b1 ? 9'd237 : 9'd276;
			fast_video <= 1'b0;	
		end
	else begin // enhanced mode
		case (LPF)
			2'b00: begin
				TopMargin <= format == 1'b1 ? 9'd45 : 9'd84;
				BottomMargin <= format == 1'b1 ? 9'd237 : 9'd276;
			end
			2'b01: begin
				TopMargin <= format == 1'b1 ? 9'd41 : 9'd80;
				BottomMargin <= format == 1'b1 ? 9'd241 : 9'd280;
			end
			default: begin
				TopMargin <= format == 1'b1 ? 9'd33 : 9'd68;
				BottomMargin <= format == 1'b1 ? 9'd258 : 9'd293;
			end
		endcase
		if (BP == 1'b1) begin //bitmap mode
			case (HRES)
				3'b000: begin // 16 bpr
					LeftMargin <= 9'd64;
					RightMargin <= 9'd192;
					fast_video <= 1'b0;
				end
				3'b010: begin // 32 bpr
					LeftMargin <= 9'd64;
					RightMargin <= 9'd192;
					fast_video <= 1'b0;
				end
				3'b001: begin // 20 bpr
					LeftMargin <= 9'd48;
					RightMargin <= 9'd208;
					fast_video <= 1'b0;
				end
				3'b011: begin // 40 bpr
					LeftMargin <= 9'd48;
					RightMargin <= 9'd208;
					fast_video <= 1'b0;
				end
				3'b100: begin // 64 bpr - fast video
					LeftMargin <= 9'd64;
					RightMargin <= 9'd192;
					fast_video <= 1'b1;
				end
				3'b101: begin // 80 bpr - fast video
					LeftMargin <= 9'd48;
					RightMargin <= 9'd208;
					fast_video <= 1'b1;
				end
				3'b110, 3'b111: begin // default - unsafe modes to fast basic (should be byte per pixel, at fast mode than is a 4x1 pixel, in slow it is 8x1 pixel
					LeftMargin <= 9'd64;
					RightMargin <= 9'd223;
					fast_video <= 1'b1;
				end
			endcase
		end else begin //text mode
			// BPP <= 1;
			case ({HRES[2],HRES[0]})
				2'b00: begin // 32 cols
					LeftMargin <= 9'd23;
					RightMargin <= 9'd223;
					fast_video <= 1'b0;
				end
				2'b01: begin // 40 cols
					LeftMargin <= 9'd20;
					RightMargin <= 9'd231;
					fast_video <= 1'b0;
				end
				2'b10: begin // 64 cols
					LeftMargin <= 9'd23;
					RightMargin <= 9'd223;
					fast_video <= 1'b1;
				end
				2'b11: begin // 80 cols
					LeftMargin <= 9'd20;
					RightMargin <= 9'd231;
					fast_video <= 1'b1;
				end
			endcase
		end // text mode
	end // enhanced display modes
end // always

endmodule

module FormatProfiler_testbench();

	reg clk;
	reg format;
	reg [2:0] GM;
	reg AnG;
	reg VC_EN;
	reg BP;
	reg [2:0] HRES;
	reg [1:0] LPF;
	
	wire [8:0] LeftMargin;
	wire [8:0] RightMargin;
	wire [8:0] TopMargin;
	wire [8:0] BottomMargin;
	wire fast_video;

FormatProfiler uut (
	.clk(clk),
	.format(format),
	.GM(GM),
	.AnG(AnG),
	.VC_EN(VC_EN),
	.BP(BP),
	.HRES(HRES),
	.LPF(LPF),
	
	.LeftMargin(LeftMargin),
	.RightMargin(RightMargin),
	.TopMargin(TopMargin),
	.BottomMargin(BottomMargin),
	.fast_video(fast_video)
);

	initial begin
		clk <= 1'b0;
		format <= 1'b0;
		AnG <= 1'b0;
		VC_EN <= 1'b1;
		GM <= 3'd0;
		HRES <= 3'd0;
		LPF <= 2'd0;
		BP <= 1'b0;
		
		#200 AnG <= 1'b1;
		#200 GM <= 3'd1;
		#200 GM <= 3'd2;
		#200 GM <= 3'd3;
		#200 GM <= 3'd4;
		#200 GM <= 3'd5;
		#200 GM <= 3'd6;
		#200 GM <= 3'd7;
		#200 format <= 1'b1; AnG <= 1'b0; GM <= 3'd0;
		#200 GM <= 3'd1;
		#200 GM <= 3'd2;
		#200 GM <= 3'd3;
		#200 GM <= 3'd4;
		#200 GM <= 3'd5;
		#200 GM <= 3'd6;
		#200 GM <= 3'd7;
		#200 format <= 1'b0;	VC_EN <= 1'b0; // extended display modes
		HRES <= 3'b000;
		LPF <= 2'b00;
		BP <= 1'b1;
		#200 HRES <= 3'b001;
		#200 HRES <= 3'b010;
		#200 HRES <= 3'b011;
		#200 HRES <= 3'b100;
		#200 HRES <= 3'b101;
		#200 HRES <= 3'b111;
		#200 format <= 1'b1; HRES <= 3'b000;
		#200 HRES <= 3'b001;
		#200 HRES <= 3'b010;
		#200 HRES <= 3'b011;
		#200 HRES <= 3'b100;
		#200 HRES <= 3'b101;
		#200 HRES <= 3'b111;
	end
	
	always begin
		#100 clk <= ~clk;
	end

endmodule

