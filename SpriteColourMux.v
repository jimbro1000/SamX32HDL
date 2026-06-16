module SpriteColourMux(
	input [12:0] bitmapRGB,
	input [12:0] spriteRGB,
	input spriteActive,
	output [12:0] outputRGB
);

	assign outputRGB = spriteActive ? spriteRGB : bitmapRGB;

endmodule

