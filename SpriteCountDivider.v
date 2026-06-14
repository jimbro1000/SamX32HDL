module SpriteCountDivider(
	input clk,
	input [1:0] divide,
	input rst,
	output clkOut
);

	reg [2:0] counter;
	
	initial begin
		counter <= 1;
	end
	
	always @(negedge clk) begin
		if (rst == 1'b0)
			counter <= 3'd0;
		else
			counter <= counter + 3'd1;
	end

	assign clkOut = divide == 2'd0 ? clk : divide == 2'd1 ? counter[0] : divide == 3'd2 ? counter[1] : counter[2];

endmodule

module SpriteCountDivider_testbench();

	reg clk;
	reg [1:0] divide;
	reg rst;
	wire clkOut;
	
	SpriteCountDivider uut (
		.clk(clk),
		.divide(divide),
		.rst(rst),
		.clkOut(clkOut)
	);
	
	initial begin
		clk <= 1'b0;
		divide <= 2'd0;
		rst <= 1'b1;
		
		#80 divide <= 2'd1;
		#160 divide <= 2'd2;
		#320 divide <= 2'd3;
	end
	
	always begin
		#20 clk <= ~clk;
	end
endmodule

/* 
vsim rtl_work.SpriteCountDivider_testbench -voptargs="+acc"
add wave -position end  sim:/SpriteCountDivider_testbench/clk
add wave -position end  sim:/SpriteCountDivider_testbench/rst
add wave -position end  sim:/SpriteCountDivider_testbench/divide
add wave -position end  sim:/SpriteCountDivider_testbench/clkOut
add wave -position end  sim:/SpriteCountDivider_testbench/uut/counter
*/

