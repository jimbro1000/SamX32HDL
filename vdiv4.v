module vdiv4(
	input clk,
   input rst,
   output q
);

	wire q0;
	
	vdiv2 div2_0(
		.clk(clk),
		.rst(rst),
		.q(q0)
	);
	
	vdiv2 div2_1(
		.clk(q0),
		.rst(rst),
		.q(q)
	);

endmodule

module vdiv4_testbench();

	reg clk;
	reg rst;
	wire q;
	
	initial begin
		rst <= 1'b1;
		clk <= 1'b0;
		
		#(300) rst <= 1'b0;
	end
	
	vdiv4 uut(
		.clk(clk),
		.rst(rst),
		.q(q)
	);
	
	always begin
		#(100) clk <= ~clk;
	end
	
endmodule