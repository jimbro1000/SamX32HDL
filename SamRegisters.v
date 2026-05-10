module SamRegisters(
	input clk,
	input [15:0] A,
	input [7:0] D,
	input RWn,
	input RSTn,
	input Q,
	output reg [2:0] V,
	output reg [18:5] F,
	output [18:3] FA,
	output wire VC,
	output MMU_EN,
	output reg R,
	output reg TY,
	output reg TASK,
	output reg [1:0] COMMON,
	output reg [15:0] Y,
	output [6:0] X,
	output [2:0] LPR,
	output [1:0] LPF,
	output [2:0] HRES,
	output [1:0] CRES,
	output reg [7:0] BRDR,
	output HVEN,
	output MOCH,
	output H50,
	output FMT,
	output BP,
	output BPI,
	output reg [7:0] page,
	output reg [127:0] PDEF
);

	wire is_FFxx;
	wire is_FF3x;
	wire is_FF9x;
	wire is_FFAx;
	wire is_FFBx;
	wire is_SAM_REG;
	
	reg [7:0] INIT0;
	reg [7:0] VMODE;
	reg [6:0] VRES;
	reg [7:0] HOR;
	reg [7:0] page_map_array [0:15];
	
	assign is_FFxx    = (A[15:8] == 8'd255) ? 1'b1 : 1'b0;
	assign is_FF3x    = (A[15:4] == 12'b111111110011) ? 1'b1 : 1'b0; // FF3x ONLY
	assign is_FF9x    = (A[15:4] == 12'b111111111001) ? 1'b1 : 1'b0; // FF9x ONLY
	assign is_FFAx    = (A[15:4] == 12'b111111111010) ? 1'b1 : 1'b0; // FFAx ONLY
	assign is_FFBx    = (A[15:4] == 12'b111111111011) ? 1'b1 : 1'b0; // FFBx ONLY
	assign is_SAM_REG = (A[15:5] == 11'b11111111110) ? 1'b1 : 1'b0;  // FFCx and FFDx
	
	assign VC = INIT0[7];
	assign MMU_EN = INIT0[6];
	assign FMT = ~H50;
	assign BP = VMODE[7];
	assign BPI = VMODE[5];
	assign MOCH = VMODE[4];
	assign H50 = VMODE[3];
	assign LPR = VMODE[2:0];
	assign LPF = VRES[6:5];
	assign HRES = VRES[4:2];
	assign CRES = VRES[1:0];
	assign HVEN = HOR[7];
	assign X = HOR[6:0];
	
	always @(negedge clk) begin
		if (MMU_EN == 1'b1)
			if (TASK == 1'b0)
				case (A[15:3])
					3'd7: page <= page_map_array[15];
					3'd6: page <= page_map_array[14];
					3'd5: page <= page_map_array[13];
					3'd4: page <= page_map_array[12];
					3'd3: page <= page_map_array[11];
					3'd2: page <= page_map_array[10];
					3'd1: page <= page_map_array[9];
					default: page <= page_map_array[8];
				endcase
			else
				case (A[15:3])
					3'd7: page <= page_map_array[7];
					3'd6: page <= page_map_array[6];
					3'd5: page <= page_map_array[5];
					3'd4: page <= page_map_array[4];
					3'd3: page <= page_map_array[3];
					3'd2: page <= page_map_array[2];
					3'd1: page <= page_map_array[1];
					default: page <= page_map_array[0];
				endcase
		else
			page <= {5'b00000,A[15:13]};
	end
	
	always @(negedge Q) begin
		if (RSTn == 1'b0) begin
			V <= 8'd0;
			F <= 14'd0;
			TASK <= 1'b0;
			R <= 1'b0;
			COMMON <= 2'b00;
			TY <= 1'b0;
			INIT0 <= 2'b00;
			VMODE <= 8'd0;
			HOR <= 8'd0;

			page_map_array[0] <= 8'd0;
			page_map_array[1] <= 8'd1;
			page_map_array[2] <= 8'd2;
			page_map_array[3] <= 8'd3;
			page_map_array[4] <= 8'd4;
			page_map_array[5] <= 8'd5;
			page_map_array[6] <= 8'd6;
			page_map_array[7] <= 8'd7;
			
			page_map_array[8] <= 8'd0;
			page_map_array[9] <= 8'd1;
			page_map_array[10] <= 8'd2;
			page_map_array[11] <= 8'd3;
			page_map_array[12] <= 8'd4;
			page_map_array[13] <= 8'd5;
			page_map_array[14] <= 8'd6;
			page_map_array[15] <= 8'd7;
		end else begin
			if (RWn == 1'b0) begin
				if (is_SAM_REG == 1'b1) begin
					if (VC == 1'b1) begin
						case (A[4:1])
							4'b0000: V[0] <= A[0];
							4'b0001: V[1] <= A[0];
							4'b0010: V[2] <= A[0];
							4'b0011: F[9] <= A[0];
							4'b0100: F[10] <= A[0];
							4'b0101: F[11] <= A[0];
							4'b0110: F[12] <= A[0];
							4'b0111: F[13] <= A[0];
							4'b1000: F[14] <= A[0];
							4'b1001: F[15] <= A[0];
							4'b1010: TASK <= A[0];
							4'b1011: R <= A[0];
							4'b1100: R <= A[0];
							4'b1111: TY <= A[0];
//							default: ;
						endcase
					end
					case (A[4:1])
						4'b1100: R <= A[0];
						4'b1101: R <= A[1];
//						default: ;
					endcase
				end else if (is_FFAx == 1'b1) begin
					case (A[3:0])
						4'b0000: page_map_array[0] <= D;
						4'b0001: page_map_array[1] <= D;
						4'b0010: page_map_array[2] <= D;
						4'b0011: page_map_array[3] <= D;
						4'b0100: page_map_array[4] <= D;
						4'b0101: page_map_array[5] <= D;
						4'b0110: page_map_array[6] <= D;
						4'b0111: page_map_array[7] <= D;
						4'b1000: page_map_array[8] <= D;
						4'b1001: page_map_array[9] <= D;
						4'b1010: page_map_array[10] <= D;
						4'b1011: page_map_array[11] <= D;
						4'b1100: page_map_array[12] <= D;
						4'b1101: page_map_array[13] <= D;
						4'b1110: page_map_array[14] <= D;
						4'b1111: page_map_array[15] <= D;
//						default: ;
					endcase
				end else if (is_FFBx == 1'b1) begin
					case (A[3:0])
						4'b0000: PDEF[7:0] <= D;
						4'b0001: PDEF[15:8] <= D;
						4'b0010: PDEF[23:16] <= D;
						4'b0011: PDEF[31:24] <= D;
						4'b0100: PDEF[39:32] <= D;
						4'b0101: PDEF[47:40] <= D;
						4'b0110: PDEF[55:48] <= D;
						4'b0111: PDEF[63:56] <= D;
						4'b1000: PDEF[71:64] <= D;
						4'b1001: PDEF[79:72] <= D;
						4'b1010: PDEF[87:80] <= D;
						4'b1011: PDEF[95:88] <= D;
						4'b1100: PDEF[103:96] <= D;
						4'b1101: PDEF[111:104] <= D;
						4'b1110: PDEF[119:112] <= D;
						4'b1111: PDEF[127:120] <= D;
//						default: ;
					endcase
				end else if (is_FF3x == 1'b1) begin
					case (A[3:0])
						4'b1000: F[18:13] <= D[5:0];
						4'b1001: F[12:5] <= D;
						4'b1111: COMMON <= D[1:0];
//						default: ;
					endcase
				end else if (is_FF9x == 1'b1) begin
					case (A[3:0])
						4'b0000: INIT0 <= D;
						4'b0001: TASK <= D[0];
						4'b1000: VMODE <= D;
						4'b1001: VRES <= D[6:0];
						4'b1010: BRDR <= D;
						4'b1101: Y[15:8] <= D;
						4'b1110: Y[7:0] <= D;
						4'b1111: HOR <= D;
//						default: ;
					endcase
				end
			end
		end
	end
	
endmodule

