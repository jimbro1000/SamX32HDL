module vdiv3(
	input clk,
   input rst,
   output q
);

	wire d0;
	reg q0;
	reg q1;
	reg q2;
	
	initial begin
		q0 <= 1'b0;
		q1 <= 1'b0;
		q2 <= 1'b0;
	end

	always @(posedge clk) begin
		if (rst == 1'b1) begin
			q0 <= 1'b0;
			q1 <= 1'b0;
		end else begin
			q0 <= d0;
			q1 <= q0;
		end
	end
	
	always @(negedge clk) begin
		if (rst == 1'b1)
			q2 <= 1'b0;
		else
			q2 <= q1;
	end
	
	assign d0 = ~(q0 | q1);
	assign q = q2 | q1;
	
endmodule

module vdiv3_testbench();

	reg clk;
	reg rst;
	wire q;
	
	initial begin
		rst <= 1'b1;
		clk <= 1'b0;
		
		#(300) rst <= 1'b0;
	end
	
	vdiv3 uut(
		.clk(clk),
		.rst(rst),
		.q(q)
	);
	
	always begin
		#(100) clk <= ~clk;
	end
	
endmodule
