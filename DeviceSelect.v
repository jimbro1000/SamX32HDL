module DeviceSelect(
	input clk,
	input [15:0] A,
	input TY,
	input [1:0] COMMON,
	output reg [2:0] S
);

	wire is_FFxx;
	wire is_IO0;
	wire is_IO1;
	wire is_IO2;
	wire is_ROM0;
	wire is_ROM1;
	wire is_ROM2;
//	wire is_SAM;
	wire is_IRQ;
	wire is_COMMON0;
	wire is_COMMON1;
	wire is_COMMON;
	
	assign is_FFxx = A[15:8] == 8'd255;
	assign is_IO0 = (is_FFxx & A[7:5] == 3'b000);
	assign is_IO1 = (is_FFxx & A[7:4] == 4'b0010);
	assign is_IO2 = (is_FFxx & A[7:5] == 3'b010);
//	assign is_SAM = (is_FFxx & A[7:5] == 3'b110);
	assign is_IRQ = (is_FFxx & A[7:4] == 4'b1111);
	assign is_COMMON0 = (COMMON[0] == 1'b1 & A[15:12] == 4'b1111);
	assign is_COMMON1 = (COMMON[1] == 1'b1 & A[15:12] == 4'b1110);
	assign is_COMMON = ((is_COMMON0 | is_COMMON1) & (is_IRQ | ~is_FFxx));
	assign is_ROM0 = (~TY & A[15:13] == 3'b100);
	assign is_ROM1 = (~TY & A[15:13] == 3'b101);
	assign is_ROM2 = (~TY & A[15:14] == 2'b11 & ~is_FFxx);

	always @(negedge clk) begin
		if (is_IO0)
			S <= 3'b100;
		else if (is_IO1)
			S <= 3'b101;
		else if (is_IO2)
			S <= 3'b110;
		else if (is_COMMON)
			S <= 3'b000;
		else if (is_IRQ)
			S <= 3'b010;
		else if (is_FFxx) //is_SAM
			S <= 3'b111;
		else if (is_ROM0)
			S <= 3'b001;
		else if (is_ROM1)
			S <= 3'b010;
		else if (is_ROM2)
			S <= 3'b011;
		else
			S <= 3'b000;
	end

endmodule

module DeviceSelect_testbench();

	reg clk;
	reg [15:0] A;
	reg TY;
	reg [1:0] COMMON;
	wire [2:0] S;
	
	integer i;

	DeviceSelect uut (
		.clk(clk),
		.A(A),
		.TY(TY),
		.COMMON(COMMON),
		.S(S)
	);
	
	initial begin
		TY <= 1'b0;
		clk <= 1'b0;
		COMMON <= 2'b00;
		A <= 16'd65535;
		
		for (i = 0; i < 4; i = i + 1) begin
		
		#100 TY <= 1'b0; A <= 16'b0000000000000000; // start lower ram
		#100 A <= 16'b0111111111111111; // end lower ram
		#100 A <= 16'b1000000000000000; // rom 0
		#100 A <= 16'b1001111111111111; // end rom 0
		#100 A <= 16'b1010000000000000; // rom 1
		#100 A <= 16'b1011111111111111; // end rom 1
		#100 A <= 16'b1100000000000000; // rom 2
		#100 A <= 16'hfeff; // end rom 2
		#100 A <= 16'hff00; // io 0
		#100 A <= 16'hff1f; // end io 0
		#100 A <= 16'hff20; // io 1
		#100 A <= 16'hff3f; // end io 1
		#100 A <= 16'hff40; // io 2
		#100 A <= 16'hff5f; // end io 2
		#100 A <= 16'hff60; // sam
		#100 A <= 16'hffef; // end sam
		#100 A <= 16'hfff0; // irq
		#100 A <= 16'hffff; // end irq
		
		#100 TY <= 1'b1; A <= 16'b0000000000000000; // start lower ram
		#100 A <= 16'b0111111111111111; // end lower ram
		#100 A <= 16'b1000000000000000; // rom 0
		#100 A <= 16'b1001111111111111; // end rom 0
		#100 A <= 16'b1010000000000000; // rom 1
		#100 A <= 16'b1011111111111111; // end rom 1
		#100 A <= 16'b1100000000000000; // rom 2
		#100 A <= 16'hfeff; // end rom 2
		#100 A <= 16'hff00; // io 0
		#100 A <= 16'hff1f; // end io 0
		#100 A <= 16'hff20; // io 1
		#100 A <= 16'hff3f; // end io 1
		#100 A <= 16'hff40; // io 2
		#100 A <= 16'hff5f; // end io 2
		#100 A <= 16'hff60; // sam
		#100 A <= 16'hffef; // end sam
		#100 A <= 16'hfff0; // irq
		#100 A <= 16'hffff; // end irq
		
		#50 COMMON <= COMMON + 2'b01;
		end
	end
	
	always begin
		#50 clk <= ~clk;
	end

endmodule
