module SpriteCollisionGrapher(
	input clk,
	input [7:0] objectA,
	input [7:0] objectB,
	input [7:0] objectC,
	input [7:0] objectD,
	input [7:0] inGraphA,
	input [7:0] inGraphB,
	input [7:0] inGraphC,
	input [7:0] inGraphD,
	output reg [7:0] outGraphA,
	output reg [7:0] outGraphB,
	output reg [7:0] outGraphC,
	output reg [7:0] outGraphD
);

	// object structure
	// [7:5] = id
	// [4:1] = hitgroup 3..0
	// [0] = active pixel

	wire[2:0] idA;
	wire[2:0] idB;
	wire[2:0] idC;
	wire[2:0] idD;
	
	assign idA = objectA[7:5];
	assign idB = objectB[7:5];
	assign idC = objectC[7:5];
	assign idD = objectD[7:5];

	always @(negedge clk) begin
		outGraphA = inGraphA;
		outGraphB = inGraphB;
		outGraphC = inGraphC;
		outGraphD = inGraphD;
		
		if (objectA[0] == 1'b1) begin
			if (objectB[0] == 1'b1 && ~((objectA[4:1] & objectB[4:1]) == 4'd0)) begin
				outGraphA[idB] = 1'b1;
				outGraphB[idA] = 1'b1;
			end
			if (objectC[0] == 1'b1 && ~((objectA[4:1] & objectC[4:1]) == 4'd0)) begin
				outGraphA[idC] = 1'b1;
				outGraphC[idA] = 1'b1;
			end
			if (objectD[0] == 1'b1 && ~((objectA[4:1] & objectD[4:1]) == 4'd0)) begin
				outGraphA[idD] = 1'b1;
				outGraphD[idA] = 1'b1;
			end
		end

		if (objectB[0] == 1'b1) begin
			if (objectC[0] == 1'b1 && ~((objectB[4:1] & objectC[4:1]) == 4'd0)) begin
				outGraphA[idC] = 1'b1;
				outGraphC[idB] = 1'b1;
			end
			if (objectD[0] == 1'b1 && ~((objectB[4:1] & objectD[4:1]) == 4'd0)) begin
				outGraphA[idD] = 1'b1;
				outGraphD[idB] = 1'b1;
			end
		end

		if (objectC[0] == 1'b1) begin
			if (objectD[0] == 1'b1 && ~((objectC[4:1] & objectD[4:1]) == 4'd0)) begin
				outGraphC[idD] = 1'b1;
				outGraphD[idC] = 1'b1;
			end
		end
	
	end


endmodule

module SpriteCollisionGrapher_testbench();

	reg clk;
	reg [7:0] objectA;
	reg [7:0] objectB;
	reg [7:0] objectC;
	reg [7:0] objectD;
	reg [7:0] inGraphA;
	reg [7:0] inGraphB;
	reg [7:0] inGraphC;
	reg [7:0] inGraphD;
	wire [7:0] outGraphA;
	wire [7:0] outGraphB;
	wire [7:0] outGraphC;
	wire [7:0] outGraphD;

	SpriteCollisionGrapher uut(
		.clk(clk),
		.objectA(objectA),
		.objectB(objectB),
		.objectC(objectC),
		.objectD(objectD),
		.inGraphA(inGraphA),
		.inGraphB(inGraphB),
		.inGraphC(inGraphC),
		.inGraphD(inGraphD),
		.outGraphA(outGraphA),
		.outGraphB(outGraphB),
		.outGraphC(outGraphC),
		.outGraphD(outGraphD)
	);
	
	initial begin
		clk <= 1'b1;
		// id2 id1 id0 s3 s2 s1 s0 m
		objectA <= 8'b00000001;
		objectB <= 8'b00100001;
		objectC <= 8'b01000001;
		objectD <= 8'b01100001;
		inGraphA <= 8'd0;
		inGraphB <= 8'd0;
		inGraphC <= 8'd0;
		inGraphD <= 8'd0;
		
		#20 clk <= ~clk;
		#20 clk <= ~clk;
		
		objectA[4:1] <= 4'b0001;
		objectB[4:1] <= 4'b0011;
		objectC[4:1] <= 4'b0110;
		objectD[4:1] <= 4'b1100;
		
		#20 clk <= ~clk;
		#20 clk <= ~clk;
		
	end

endmodule

/* 
vsim rtl_work.SpriteCollisionGrapher_testbench -voptargs="+acc"
add wave -position end  sim:/SpriteCollisionGrapher_testbench/clk
add wave -position end  sim:/SpriteCollisionGrapher_testbench/objectA
add wave -position end  sim:/SpriteCollisionGrapher_testbench/objectB
add wave -position end  sim:/SpriteCollisionGrapher_testbench/objectC
add wave -position end  sim:/SpriteCollisionGrapher_testbench/objectD
add wave -position end  sim:/SpriteCollisionGrapher_testbench/inGraphA
add wave -position end  sim:/SpriteCollisionGrapher_testbench/inGraphB
add wave -position end  sim:/SpriteCollisionGrapher_testbench/inGraphC
add wave -position end  sim:/SpriteCollisionGrapher_testbench/inGraphD
add wave -position end  sim:/SpriteCollisionGrapher_testbench/outGraphA
add wave -position end  sim:/SpriteCollisionGrapher_testbench/outGraphB
add wave -position end  sim:/SpriteCollisionGrapher_testbench/outGraphC
add wave -position end  sim:/SpriteCollisionGrapher_testbench/outGraphD
*/