module vdiv2(
	input clk,
   input rst,
   output q
);

	reg q0;

	initial begin
		q0 <= 1'b0;
	end

	always @(negedge clk) begin
		if (rst == 1'b1)
			q0 <= 1'b0;
		else
			q0 <= ~q0;
	end
	
	assign q = q0;

endmodule

module vdiv2_testbench();

	reg clk;
	reg rst;
	wire q;
	
	initial begin
		rst <= 1'b1;
		clk <= 1'b0;
		
		#(300) rst <= 1'b0;
	end
	
	vdiv2 uut(
		.clk(clk),
		.rst(rst),
		.q(q)
	);
	
	always begin
		#(100) clk <= ~clk;
	end
endmodule
