module Palette6847(
	input clk,
	input [3:0] index,
	output reg [11:0] RGB
);

	always @(clk) begin
		case (index)
			4'b0000:
				RGB <= 12'b000000000000; // almost black
			4'b0001:
				RGB <= 12'b001111110000; // green
			4'b0010:
				RGB <= 12'b111111110000; // yellow
			4'b0011:
				RGB <= 12'b001000101111; // blue
			4'b0100:
				RGB <= 12'b111100000000; // red
			4'b0101: 
				RGB <= 12'b111111111111; // white (buff)
			4'b0110:
				RGB <= 12'b001111111100; // cyan
			4'b0111:
				RGB <= 12'b111100111111; // magenta
			4'b1000:
				RGB <= 12'b111111000000; // orange
			4'b1001:
				RGB <= 12'b111111000100; // bright orange
			4'b1010:
				RGB <= 12'b000001000000; // dark green
			4'b1011:
				RGB <= 12'b010000100010; // dark red
			4'b1110:
				RGB <= 12'b000000100000; // dark green border
			default:
				RGB <= 12'b000000000000; // backporch black
		endcase
	end

endmodule
