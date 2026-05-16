//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:12:50 06/08/2025 
// Design Name: 
// Module Name:    RawShift 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module RawShift(
	input [7:0] Data,
	input Clk,
	input Divider,
	input Load,
	output reg [1:0] Pixel
);

	reg [7:0] pixelData;
	reg [2:0] offset;
	wire PClk;
	wire q;
	
	vdiv4 slowclock(
		.clk(Clk),
		.rst(1'b0),
		.q(PClk)
	);
	
	initial begin
		offset <= 3'b111;
		pixelData <= 8'd0;
	end
	
	always @(negedge Clk) begin
		if (Load == 1'b1) begin
			pixelData <= Data;
			offset <= 3'b111;
		end else
			offset <= offset - 3'd1;
	end
	
	always @(Clk) begin
		if (Divider == 1'b0)
			Pixel <= {1'b0,pixelData[offset]};
		else
			case (offset[2:1])
				2'b11:
					Pixel <= pixelData[7:6];
				2'b10:
					Pixel <= pixelData[5:4];
				2'b01:
					Pixel <= pixelData[3:2];
				default:
					Pixel <= pixelData[1:0];
			endcase
	end
	
endmodule

module RawShift_testbench();

	reg Clk;
	reg [7:0] Data;
	reg Divider;
	reg Load;
	wire [1:0] Pixel;

	RawShift uut(
		.Clk(Clk),
		.Data(Data),
		.Divider(Divider),
		.Load(Load),
		.Pixel(Pixel)
	);
	
	initial begin
		Clk <= 1'b0;
		Data <= 8'b11100100;
		Divider <= 1'b0;
		Load <= 1'b0;
	end
	
	integer loadCounter;
	
	always begin
		Divider <= 1'b0;
		for (loadCounter = 0; loadCounter < 16; loadCounter = loadCounter + 1) begin
			#200 Clk <= ~Clk;
			if (loadCounter == 0)
				Load <= 1'b1;
			if (loadCounter == 2)
				Load <= 1'b0;
		end
		Divider <= 1'b1;
		for (loadCounter = 0; loadCounter < 16; loadCounter = loadCounter + 1) begin
			#200 Clk <= ~Clk;
			if (loadCounter == 0)
				Load <= 1'b1;
			if (loadCounter == 2)
				Load <= 1'b0;
		end
	end

endmodule
