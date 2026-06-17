module SpriteRenderer(
	input clk,
	input HRn,
	input active,
	input [255:0] bitmap,
	input [1:0] scaleX,
	input [1:0] scaleY,
	input [1:0] rotate,
	input mirrorX,
	input mirrorY,
	input startX,
	input startY,
	input [95:0] palette,
	
	output mask,
	output reg [11:0] pixel
);

	reg [2:0] countX;
	reg [2:0] countY;
	
	wire clkOutX;
	wire clkOutY;
	wire xySwitch;
	wire downX;
	wire downY;
	wire [3:0] pixelbits;
	wire clkX;
	wire clkY;
	integer index;
	
	initial begin
		countX <= 3'd0;
		countY <= 3'd0;
	end

	SpriteCountDivider clkXDivider (
		.clk(clkX),
		.divide(scaleX),
		.rst(startX),
		.clkOut(clkOutX)	
	);
	
	SpriteCountDivider clkYDivider (
		.clk(clkY),
		.divide(scaleY),
		.rst(startY),
		.clkOut(clkOutY)
	);
	
	assign downX = ~(
		(!scaleX && !scaleY && rotate[1] && !rotate[0]) |
		(!scaleX && scaleY && rotate[1] && !rotate[0]) |
		(scaleX && !scaleY && !rotate[1]) |
		(scaleX && !scaleY && rotate[1] && rotate[0]) |
		(scaleX && scaleY && !rotate[1]) |
		(scaleX && scaleY && rotate[1] && rotate[0])
	);
	
	assign downY = ~(
		(!scaleX && !scaleY && !rotate[1] && rotate[0]) |
		(!scaleX && !scaleY && rotate[1] && !rotate[0]) |
		(!scaleX && scaleY && !rotate[1] && !rotate[0]) |
		(!scaleX && scaleY && rotate[1] && rotate[0]) |
		(scaleX && !scaleY && !rotate[1] && rotate[0]) |
		(scaleX && !scaleY && rotate[1] && !rotate[0]) |
		(scaleX && scaleY && !rotate[1] && !rotate[0]) |
		(scaleX && scaleY && rotate[1] && rotate[0])
	);
	
	assign xySwitch = rotate[0];
	
	assign clkX = xySwitch ? HRn : clk;
	assign clkY = xySwitch ? clk : HRn;
	
	always @(negedge clkX) begin
		if (downX)
			if (startX)
				countX <= 3'd7;
			else
				countX <= countX - 3'd1;
		else
			if (startX)
				countX <= 3'd0;
			else
				countX <= countX + 3'd1;
	end
	
	always @(negedge clkY) begin
		if (downY)
			if (startY)
				countY <= 3'd7;
			else
				countY <= countY - 3'd1;
		else
			if (startY)
				countY <= 3'd0;
			else
				countY <= countY + 3'd1;

	end
	
	always @(clk) begin
		index <= countX * 4 + countY * 32;
		pixel <= palette[(pixelbits[2:0]*12) +: 12];
	end
	
	assign pixelbits = bitmap[index +: 4];
	assign mask = active & pixelbits[3];

endmodule

module SpriteRenderer_testbench();
	reg clk;
	reg HRn;
	reg active;
	reg [255:0] bitmap;
	reg [1:0] scaleX;
	reg [1:0] scaleY;
	reg [1:0] rotate;
	reg mirrorX;
	reg mirrorY;
	reg startX;
	reg startY;
	wire mask;
	wire [2:0] pixel;
	
	SpriteRenderer uut(
		.clk(clk),
		.HRn(HRn),
		.active(active),
		.bitmap(bitmap),
		.scaleX(scaleX),
		.scaleY(scaleY),
		.rotate(rotate),
		.mirrorX(mirrorX),
		.mirrorY(mirrorY),
		.startX(startX),
		.startY(startY),
	
		.mask(mask),
		.pixel(pixel)
	);

	initial begin
		bitmap [255:252] <= 4'd0;
		bitmap [251:248] <= 4'd9;
		bitmap [247:244] <= 4'd10;
		bitmap [243:240] <= 4'd0;
		bitmap [239:236] <= 4'd0;
		bitmap [235:232] <= 4'd0;
		bitmap [231:228] <= 4'd0;
		bitmap [227:224] <= 4'd0;

		bitmap [223:220] <= 4'd0;
		bitmap [219:216] <= 4'd9;
		bitmap [215:212] <= 4'd10;
		bitmap [211:208] <= 4'd10;
		bitmap [207:204] <= 4'd10;
		bitmap [203:200] <= 4'd10;
		bitmap [199:196] <= 4'd0;
		bitmap [195:192] <= 4'd0;

		bitmap [191:188] <= 4'd0;
		bitmap [187:184] <= 4'd0;
		bitmap [183:180] <= 4'd10;
		bitmap [179:176] <= 4'd10;
		bitmap [175:172] <= 4'd10;
		bitmap [171:168] <= 4'd10;
		bitmap [167:164] <= 4'd10;
		bitmap [163:160] <= 4'd0;

		bitmap [159:156] <= 4'd0;
		bitmap [155:152] <= 4'd0;
		bitmap [151:148] <= 4'd11;
		bitmap [147:144] <= 4'd9;
		bitmap [143:140] <= 4'd8;
		bitmap [139:136] <= 4'd8;
		bitmap [135:132] <= 4'd0;
		bitmap [131:128] <= 4'd0;

		bitmap [127:124] <= 4'd0;
		bitmap [123:120] <= 4'd11;
		bitmap [119:116] <= 4'd11;
		bitmap [115:112] <= 4'd11;
		bitmap [111:108] <= 4'd11;
		bitmap [107:104] <= 4'd8;
		bitmap [103:100] <= 4'd0;
		bitmap [99:96] <= 4'd0;

		bitmap [95:92] <= 4'd0;
		bitmap [91:88] <= 4'd0;
		bitmap [87:84] <= 4'd11;
		bitmap [83:80] <= 4'd11;
		bitmap [79:76] <= 4'd11;
		bitmap [75:72] <= 4'd8;
		bitmap [71:68] <= 4'd0;
		bitmap [69:64] <= 4'd0;

		bitmap [63:60] <= 4'd0;
		bitmap [59:56] <= 4'd0;
		bitmap [57:52] <= 4'd0;
		bitmap [51:48] <= 4'd11;
		bitmap [47:44] <= 4'd11;
		bitmap [43:40] <= 4'd0;
		bitmap [39:36] <= 4'd0;
		bitmap [35:32] <= 4'd0;

		bitmap [31:28] <= 4'd0;
		bitmap [27:24] <= 4'd0;
		bitmap [23:20] <= 4'd12;
		bitmap [19:16] <= 4'd12;
		bitmap [15:12] <= 4'd12;
		bitmap [11:8] <= 4'd12;
		bitmap [7:4] <= 4'd0;
		bitmap [3:0] <= 4'd0;
		
		mirrorX <= 1'b0;
		mirrorY <= 1'b0;
		scaleX <= 2'b0;
		scaleY <= 2'b0;
		rotate <= 2'b0;
		
		startX <= 0;
		startY <= 0;
		
		clk <= 0;
		HRn <= 1;
		active <= 0;
		
		
		#40 startX <= 1; startY <= 1; HRn <= 0; // clk = 1
		#40 startX <= 0; startY <= 0; HRn <= 1;
		// 10 more ticks
		#400 startX <= 1; HRn <= 0;
		#40 startX <= 0; HRn <= 1;
		// 10 more ticks
		#400 startX <= 1; HRn <= 0;
		#40 startX <= 0; HRn <= 1; active <= 1; // sprite should become unmasked from this point
		// 10 more ticks
		#400 startX <= 1; HRn <= 0;
		#40 startX <= 0; HRn <= 1;
		// 10 more ticks
		#400 startX <= 1; HRn <= 0;
		#40 startX <= 0; HRn <= 1;
		// 10 more ticks
		#400 startX <= 1; HRn <= 0;
		#40 startX <= 0; HRn <= 1;
		// 10 more ticks
		#400 startX <= 1; HRn <= 0;
		#40 startX <= 0; HRn <= 1;
		// 10 more ticks
		#400 startX <= 1; HRn <= 0;
		#40 startX <= 0; HRn <= 1;
		
	end
	
	always begin
		#20 clk <= ~clk;
	end

endmodule

/* 
vlog -reportprogress 300 -work work H:/Quartus/samx32/SpriteCountDivider.v
vsim rtl_work.SpriteRenderer_testbench -voptargs="+acc"
add wave -position end  sim:/SpriteRenderer_testbench/startY
add wave -position end  sim:/SpriteRenderer_testbench/startX
add wave -position end  sim:/SpriteRenderer_testbench/scaleY
add wave -position end  sim:/SpriteRenderer_testbench/scaleX
add wave -position end  sim:/SpriteRenderer_testbench/rotate
add wave -position end  sim:/SpriteRenderer_testbench/pixel
add wave -position end  sim:/SpriteRenderer_testbench/mirrorY
add wave -position end  sim:/SpriteRenderer_testbench/mirrorX
add wave -position end  sim:/SpriteRenderer_testbench/mask
add wave -position end  sim:/SpriteRenderer_testbench/clk
add wave -position end  sim:/SpriteRenderer_testbench/bitmap
add wave -position end  sim:/SpriteRenderer_testbench/uut/downY
add wave -position end  sim:/SpriteRenderer_testbench/uut/downX
add wave -position end  sim:/SpriteRenderer_testbench/uut/countY
add wave -position end  sim:/SpriteRenderer_testbench/uut/countX
add wave -position end  sim:/SpriteRenderer_testbench/uut/clkY
add wave -position end  sim:/SpriteRenderer_testbench/uut/clkX
add wave -position end  sim:/SpriteRenderer_testbench/uut/clkOutY
add wave -position end  sim:/SpriteRenderer_testbench/uut/clkOutX
add wave -position end  sim:/SpriteRenderer_testbench/uut/clk
add wave -position end  sim:/SpriteRenderer_testbench/uut/bit
*/