module ControlSignalCapture(
	input Clk,
	input [2:0] S,
	input [1:0] A,
	input [4:0] D,
	output reg AnG,
	output reg CSS,
	output reg [2:0] GM
);

	// keep a shadow copy of writes to the second register
	// of PIA1 (IO1)
	// consciously ignoring the matter of whether a write is
	// to the data direction register or the io register
	// for the purposes of use in a Dragon the relevant writes
	// will always be correct during normal operation

	initial begin
		AnG <= 1'b0;
		CSS <= 1'b0;
		GM <= 3'b000;
	end

	always @(negedge Clk) begin
		if (S == 3'b101 & A == 2'b10) begin
			{AnG, GM[2:0], CSS} <= D;
		end
	end

endmodule
