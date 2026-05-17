module VCAddressCounter(
	input [2:0] V,
	input DA0,
	input [18:3] F,
	input HR,
	input IER_or_VP,
	output reg [18:1] B
);

	initial begin
		B <= 18'd0;
	end
	
	// VDG address modifier

	//  Mode        Division    Bits cleared
	//  V2 V1 V0    X   Y       by HS# (low)
	//  ---------------------------------------
	//   0  0  0    1   12      B1-B4
	//   0  0  1    3    1      B1-B3
	//  ---------------------------------------
	//   0  1  0    1    3      B1-B4
	//   0  1  1    2    1      B1-B3
	//  ---------------------------------------
	//   1  0  0    1    2      B1-B4
	//   1  0  1    1    1      B1-B3
	//  ---------------------------------------
	//   1  1  0    1    1      B1-B4
	//   1  1  1    1    1      None (DMA MODE)
	
	wire use_ydiv12;
	wire use_ydiv3;
	wire use_ydiv2;
	wire use_ydiv1;
	wire use_xdiv3;
	wire use_xdiv2;
	wire use_xdiv1;
	wire is_DMA;
	wire clock_b5;
	wire clock_b4;
	wire xdiv2_out;
	wire xdiv3_out;
	wire ydiv2_out;
	wire ydiv3_out;
	wire ydiv12_out;

	assign use_ydiv12 = (V == 3'd0) ? 1'b1 : 1'b0;
	assign use_ydiv3 = (V == 3'd2) ? 1'b1 : 1'b0;
	assign use_ydiv2 = (V == 3'd4) ? 1'b1 : 1'b0;
	assign use_ydiv1 = (V[2:1] == 2'd3 | V[0] == 1'b1) ? 1'b1 : 1'b0;
	
	assign use_xdiv3 = (V == 3'd1) ? 1'b1 : 1'b0;
	assign use_xdiv2 = (V == 3'd3) ? 1'b1 : 1'b0;
	assign use_xdiv1 = (V[2] == 1'b1 | V[0] == 1'b0) ? 1'b1 : 1'b0;

	assign is_DMA = (V == 3'd7);

	assign clock_b5 = (use_ydiv12 & ydiv12_out) | (use_ydiv3 & ydiv3_out) | (use_ydiv2 & ydiv2_out) | (use_ydiv1 & B[4]);
	assign clock_b4 = (use_xdiv3 & xdiv3_out) | (use_xdiv2 & xdiv2_out) | (use_xdiv1 & B[3]);

	vdiv3 xdiv3 (
		.clk(B[3]),
		.q(xdiv3_out),
		.rst(IER_or_VP)
	);

	vdiv2 xdiv2 (
		.clk(B[2]),
		.q(xdiv2_out),
		.rst(IER_or_VP)
	);

	always @(negedge DA0) begin
		if (IER_or_VP == 1'b1 | (HR == 1'b1 & ~is_DMA))
			B[3:1] <= 3'd0;
		else
			B[3:1] <= (B[3:1] + 3'b1);
	end
	
	always @(negedge clock_b4) begin
		if (IER_or_VP == 1'b1 | (HR == 1'b1 & V[0] == 1'b0))
			B[4] <= 1'b0;
		else
			B[4] <= ~B[4];
	end

	vdiv3 ydiv12(
		.clk(ydiv3_out),
		.q(ydiv12_out),
		.rst(IER_or_VP)
	);

	vdiv3 ydiv3(
		.clk(B[4]),
		.q(ydiv3_out),
		.rst(IER_or_VP)
	);
	
	vdiv2 ydiv2(
		.clk(B[4]),
		.q(ydiv2_out),
		.rst(IER_or_VP)
	);
	
	always @(negedge clock_b5) begin
		if (IER_or_VP == 1'b1)
			B[18:5] <= F[18:5];
		else
			B[18:5] <= (B[18:5] + 14'd1);
	end
	
endmodule

module VCAddressCounter_Testbench();
	
	reg [2:0] V;
	reg DA0;
	reg [18:5] F;
	reg HR;
	reg IER_or_VP;
	wire [18:1] B;

	VCAddressCounter uut (
		.V(V),
		.DA0(DA0),
		.F(F),
		.HR(HR),
		.IER_or_VP(IER_or_VP),
		.B(B)
	);

	initial begin
		V <= 3'd6;
		DA0 <= 1'b0;
		F <= 14'd0;
		IER_or_VP <= 1'b1;
		HR <= 1'b0;
		
		#(200) IER_or_VP <= 1'b0;
	end
	
	always begin
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) DA0 <= ~DA0;
		#(100) HR <= 1'b1;
		#(200) HR <= 1'b0;
	end
	
endmodule
