module FormatProfiler (
	input clk,
	input format,
	input [2:0] GM,
	input AnG,
	input VC_EN,
	input BP,
	input [2:0] HRES,
	input [1:0] LPF,
	output reg [8:0] LeftMargin,
	output reg [8:0] RightMargin,
//	output reg [8:0] AllRows,
//	output reg [8:0] TopBlank,
	output reg [8:0] TopMargin,
	output reg [8:0] BottomMargin,
	output reg fast_video
);

initial begin
	// default to PAL alpha
	// hsync = 57 // backporch = 114 // left border = 231 // right border = 743
	LeftMargin <= 9'd58; //231 / 4 = 58;
	RightMargin <= 9'd186; //743 / 4 = 186;
//	AllRows <= 9'd311;
//	TopBlank <= 9'd57;
	TopMargin <= 9'd84;
	BottomMargin <= 9'd276;
	fast_video <= 1'b0;
end

always @(negedge clk) begin
//	if (format == 1'b1) begin
//		AllRows <= 9'd258;
//		TopBlank <= 9'd32;
//	end else begin
//		AllRows <= 9'd311;
//		TopBlank <= 9'd57;
//	end
////	if (VC_EN == 1'b1) begin // compatibility mode
		LeftMargin <= 9'd58;
		RightMargin <= 9'd186;
		if (format == 1'b1) begin // ntsc
			TopMargin <= 9'd45;
			BottomMargin <= 9'd237;
		end else begin // pal
			TopMargin <= 9'd84;
			BottomMargin <= 9'd276;
		end
		fast_video <= 1'b0;
//	end else begin
//		if (format == 1'b1) begin // ntsc
//			case (LPF)
//				2'b00: begin
//					TopMargin <= 9'd45;
//					BottomMargin <= 9'd237;
//				end
//				2'b01: begin
//					TopMargin <= 9'd41;
//					BottomMargin <= 9'd241;
//				end
//				default: begin
//					TopMargin <= 9'd33;
//					BottomMargin <= 9'd258;
//				end
//			endcase
//		end else begin
//			case (LPF)
//				2'b00: begin
//					TopMargin <= 9'd84;
//					BottomMargin <= 9'd276;
//				end
//				2'b01: begin
//					TopMargin <= 9'd80;
//					BottomMargin <= 9'd280;
//				end
//				default: begin
//					TopMargin <= 9'd68;
//					BottomMargin <= 9'd293;
//				end
//			endcase
//		end
//		if (BP) begin //bitmap mode
//			case (HRES)
//				3'b000: begin // 16 bpr
//					LeftMargin <= 9'd23;
//					RightMargin <= 9'd223;
//					fast_video <= 1'b0;
//				end
//				3'b010: begin // 32 bpr
//					LeftMargin <= 9'd23;
//					RightMargin <= 9'd223;
//					fast_video <= 1'b0;
//				end
//				3'b001: begin // 20 bpr
//					LeftMargin <= 9'd20; //20;
//					RightMargin <= 9'd231; //231;
//					fast_video <= 1'b0;
//				end
//				3'b011: begin // 40 bpr
//					LeftMargin <= 9'd20;
//					RightMargin <= 9'd231;
//					fast_video <= 1'b0;
//				end
//				3'b100: begin // 64 bpr
//					LeftMargin <= 9'd23;
//					RightMargin <= 9'd223;
//					fast_video <= 1'b1;
//				end
//				3'b101: begin // 80 bpr
//					LeftMargin <= 9'd20;
//					RightMargin <= 9'd231;
//					fast_video <= 1'b1;
//				end
//				default: begin // default unsafe modes to basic
//					LeftMargin <= 9'd23;
//					RightMargin <= 9'd223;
//					fast_video <= 1'b0;
//				end
//			endcase
//		end else begin //text mode
//			// BPP <= 1;
//			case ({HRES[2],HRES[0]})
//				2'b00: begin // 32 cols
//					//BytesPerRow <= 7'd32;
//					LeftMargin <= 9'd23;
//					RightMargin <= 9'd223;
//					fast_video <= 1'b0;
//				end
//				2'b01: begin // 40 cols
//					//BytesPerRow <= 7'd40;
//					LeftMargin <= 9'd20;
//					RightMargin <= 9'd231;
//					fast_video <= 1'b0;
//				end
//				2'b10: begin // 64 cols
//					//BytesPerRow <= 7'd64;
//					LeftMargin <= 9'd23;
//					RightMargin <= 9'd223;
//					fast_video <= 1'b1;
//				end
//				default: begin
//					//BytesPerRow <= 7'd80;
//					LeftMargin <= 9'd20;
//					RightMargin <= 9'd231;
//					fast_video <= 1'b1;
//				end
//			endcase
//		end
//	end
end

endmodule
