module BorderSelect(
	input [2:0] GM,
	input AnG,
	input CSS,
	output reg [3:0] Colour
);

	always @(GM or AnG or CSS) begin
		if (AnG) begin
			if (GM[0] == 1'b1)
				if (CSS)
					Colour = 4'b0000;
				else
					Colour = 4'b0001;
			else
				if (CSS)
					Colour = 4'b0101;
				else
					Colour = 4'b0001;
		end else if (CSS)
			Colour = 4'b1011;
		else
			Colour = 4'b1110;
	end

endmodule