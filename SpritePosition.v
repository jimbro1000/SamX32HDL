module SpritePosition(
	input clk,
	input [10:0] X,
	input [8:0] Y,
	input [10:0] posX,
	input [8:0] posY,
	input [1:0] scaleX,
	input [1:0] scaleY,
	
	output spriteEnable,
	output reg startX,
	output reg startY
);

	reg activeY;
	reg activeX;
	
	initial begin
		activeY <= 1'b0;
		activeX <= 1'b0;
	end

	wire [9:0] endY;
	wire [11:0] endX;
	
	assign endY = posY + (scaleY == 0 ? 7'd8 : scaleY == 1 ? 7'd16 : scaleY == 2 ? 7'd32 : 7'd64);
	assign endX = posX + (scaleX == 0 ? 7'd8 : scaleX == 1 ? 7'd16 : scaleX == 2 ? 7'd32 : 7'd64);	

	always @(negedge clk) begin
		if (Y == posY) begin
			startY <= 1'b1;
			activeY <= 1'b1;
		end else if (Y == endY)
			activeY <= 1'b0;
		else
			startY <= 1'b0;
			
		if (X == (posX - 1) && activeY) begin
			startX <= 1'b1;
			activeX <= 1'b1;
		end else if (X == (endX - 1))
			activeX <= 1'b0;
		else
			startX <= 1'b0;
	end
	
	assign spriteEnable = activeX & activeY;

endmodule

module SpritePosition_testbench();

	reg clk;
	reg [10:0] X;
	reg [8:0] Y;
	reg [10:0] posX;
	reg [8:0] posY;
	reg [1:0] scaleX;
	reg [1:0] scaleY;
	
	wire spriteEnable;
	wire startX;
	wire startY;

	SpritePosition uut(
		.clk(clk),
		.X(X),
		.Y(Y),
		.posX(posX),
		.posY(posY),
		.scaleX(scaleX),
		.scaleY(scaleY),
		.spriteEnable(spriteEnable),
		.startX(startX),
		.startY(startY)
	);
	
	initial begin
		clk <= 1'b0;
		posX <= 11'd20;
		posY <= 9'd10;
		X <= 11'd0;
		Y <= 9'd0;
		scaleX <= 2'd0;
		scaleY <= 2'd0;
	end
	
	always begin
		#20 clk <= ~clk;
	end
	
	wire nextFrame;
	
	always @(negedge clk) begin
		if (X == 11'd90) begin
			X <= 11'd0;
			if (Y == 10'd80)
				Y <= 10'd0;
			else
				Y <= Y + 10'd1;
		end else
			X <= X + 11'd1;
	end
	
	assign nextFrame = Y == 10'd80;
	
	always @(negedge nextFrame) begin
		scaleX = scaleX + 1;
		if (scaleX == 0)
			scaleY = scaleY + 1;
	end

endmodule

/* 
vsim rtl_work.SpritePosition_testbench -voptargs="+acc"
*/