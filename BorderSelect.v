module BorderSelect(
	input [2:0] GM,
	input AnG,
	input CSS,
	output reg [3:0] Colour
);

	always @(GM or AnG or CSS) begin
		if (AnG) begin
//			if (GM[0] == 1'b1)
				if (CSS)
					Colour = 4'b0101; // 4 colour white set
				else
					Colour = 4'b0001; // 4 colour green set
//			else
//				if (CSS)
//					Colour = 4'b0101; // 2 colour white set
//				else
//					Colour = 4'b0001; // 2 colour green set
		end else if (CSS)
			Colour = 4'b1011; // alpha mode green
		else
			Colour = 4'b1110; // alpha mode orange
	end

endmodule