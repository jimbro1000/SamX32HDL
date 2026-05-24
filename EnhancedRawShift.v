module EnhancedRawShift(
	input [7:0] Data,			// bitmap data input
	input Clk,					// pixel clock (14.31818MHz)
	input [2:0] Divider,		// fast_mode + CRES
	input Load,					// data load clock
	output reg [3:0] Pixel	// pixel palette output
);

	reg [7:0] pixelData;
	reg [3:0] offset;
	
	initial begin
		offset <= 4'b1111;
		pixelData <= 8'd0;
	end
	
	always @(negedge Clk) begin
		if (Load == 1'b1) begin
			pixelData <= Data;
			offset <= 4'b1111;
		end else
			offset <= offset - 4'd1;
	end
	
	always @(Clk) begin
		case (Divider)
			3'd0: Pixel <= {3'd0, pixelData[offset[3:1]]}; // slow 1BPP
			3'd4: Pixel <= {3'd0, pixelData[offset[2:0]]}; // fast 1BPP
			3'd1: begin // slow 2BPP
				case (offset[3:2])
					2'b11: Pixel <= {2'd0, pixelData[7:6]};
					2'b10: Pixel <= {2'd0, pixelData[5:4]};
					2'b01: Pixel <= {2'd0, pixelData[3:2]};
					2'b00: Pixel <= {2'd0, pixelData[1:0]};
				endcase
			end
			3'd5: begin // fast 2BPP
				case (offset[2:1])
					2'b11: Pixel <= {2'd0, pixelData[7:6]};
					2'b10: Pixel <= {2'd0, pixelData[5:4]};
					2'b01: Pixel <= {2'd0, pixelData[3:2]};
					2'b00: Pixel <= {2'd0, pixelData[1:0]};
				endcase
			end
			3'd2: begin // slow 4BPP
				case (offset[3])
					1'b1: Pixel <= pixelData[7:4];
					1'b0: Pixel <= pixelData[3:0];
				endcase
			end
			3'd6: begin // fast 4BPP
				case (offset[2])
					1'b1: Pixel <= pixelData[7:4];
					1'b0: Pixel <= pixelData[3:0];
				endcase
			end
			default: Pixel <= pixelData[7:4]; // slow or fast 8BPP is handled elsewhere
		endcase
	end


endmodule
