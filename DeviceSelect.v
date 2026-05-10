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
	wire is_SAM;
	wire is_IRQ;
	
	assign is_FFxx = A[15:8] == 8'd255;
	assign is_IO0 = (is_FFxx & A[7:5] == 3'b000);
	assign is_IO1 = (is_FFxx & A[7:4] == 4'b0010);
	assign is_IO2 = (is_FFxx & A[7:5] == 3'b010);
	assign is_SAM = (is_FFxx & A[7:5] == 3'b110);
	assign is_IRQ = (is_FFxx & A[7:5] == 3'b111);

	always @(negedge clk) begin
		if (is_IO0)
			S <= 3'b100;
		else if (is_IO1)
			S <= 3'b101;
		else if (is_IO2)
			S <= 3'b110;
	end


//	-- Upper 32K
//	is_COMMON0 <= COMMON(0) = '1' and A(15 downto 12) = "1111";
//	is_COMMON1 <= COMMON(1) = '1' and A(15 downto 12) = "1110";
//	is_COMMON  <= (is_COMMON0 or is_COMMON1) and (is_IRQ_VEC or not is_FFxx);
//	is_ROM0 <= TY = '0' and A(15 downto 13) = "100";
//	is_ROM1 <= TY = '0' and A(15 downto 13) = "101";
//	is_ROM2 <= TY = '0' and A(15 downto 14) = "11" and not is_FFxx;
//
//	-- RAM
//	is_RAM  <= A(15) = '0' or (TY = '1' and not is_FFxx);
//	
//	S <= -- IO, SAM registers, IRQ vectors
//	     "100" when is_IO0 else
//	     "101" when is_IO1 else
//	     "110" when is_IO2 else
//	     -- RAM for COMMON:
//	     "000" when is_COMMON else
//	     -- ROM1 for IRQ vectors:
//	     "010" when is_IRQ_VEC else
//	     "111" when is_FFxx else
//	     -- Upper 32K in map type 0:
//	     "001" when is_ROM0 else
//	     "010" when is_ROM1 else
//	     "011" when is_ROM2 else
//	     -- RAM
//	     "000";

endmodule
