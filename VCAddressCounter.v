module VCAddressCounter(
	input [2:0] V,
	input DA0,
	input [18:5] F,
	input HR,
	input IER_or_VP,
	input VC,
	input [6:0] HO,
	input [15:0] VO,
	input [2:0] LPR,
	input HVEN,
	output reg [20:1] B
);

	initial begin
		B <= 20'd0;
	end
	
	// VDG address modifier VC=1

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
	
	// VDG address modifier VC = 0
	// Bits cleared is irrelevant in this mode due to HRES
	
	//  LPR			Division
	//  L2 L1 L0   Y
	//   0  0  0   1
	//   0  0  1   1
	//  -------------------
	//   0  1  0   2
	//   0  1  1   8
	//   1  0  0   9
	//   1  0  1   10
	//   1  1  0   11
	//   1  1  1   halt vertical division counter
	
	// VDG bytes per row VC = 0
	
	//  BP HRES       Bytes
	//		 H2 H1 H0   BPR
	//   0  0  x  0   32
	//   0  0  x  1   40
	//   0  1  x  0   64
	//   0  1  x  1   80
	//  --------------------
	//   1  0  0  0   16
	//   1  0  0  1   20
	//   1  0  1  0   32
	//   1  0  1  1   40
	//   1  1  0  0   64
	//   1  1  0  1   80
	//   1  1  1  0   128
	//   1  1  1  1   160
	//  HVEN = 1 => 256 bytes per row
	
	// Video Base Address [18..0] = {VO[15..0],3'b000}
	// (note this is raw memory address - not paged,
	// gives a 512K address space for video plus the 
	// size of the video frame)
	
	// B needs to be expanded to [19..0] to handle addressing
	
	// Maximum frame size is 256 x 225 == 57,600 bytes
	
	// Base Address is further offset by HO[6..0]
	// Effectively {VO[18..5],HO[6..0],0}
	// Technically VO[4..0] should be added to HO[6..2]
	// but for simplicity assume VO[4..0] is always 00000
	
	// on HSn reduce row counter:
	// if LPR == 111 always subtract BPR (set row counter to 1)
	// else if not zero subtract BPR bytes from
	// B
	// else on zero reset row counter to LPR (lookup)
	
	wire [20:1] vc_base;
	reg [3:0] vc_row_counter;
	reg [3:0] vc_row_max;
	reg [20:1] repeat_address;
	
	assign vc_base = {VO[15:5], (VO[4:0] | HO[6:2]), HO[1:0]};

	initial begin
		vc_row_max <= 4'd1;
		vc_row_counter <= 4'd0;
	end

	always @(posedge HR) begin
	  if (VC == 1'b0 & LPR == 3'd7)
	    vc_row_max <= 4'd0;
	  else if (VC == 1'b1 & V == 3'd0)
	    vc_row_max <= 4'd12;
	  else if (VC == 1'b0 & LPR == 3'd6)
	    vc_row_max <= 4'd11;
	  else if (VC == 1'b0 & LPR == 3'd5)
	    vc_row_max <= 4'd10;
	  else if (VC == 1'b0 & LPR == 3'd4)
	    vc_row_max <= 4'd9;
	  else if (VC == 1'b0 & LPR == 3'd3)
	    vc_row_max <= 4'd8;
	  else if (VC == 1'b1 & V == 3'd2)
	    vc_row_max <= 4'd3;
	  else if ((VC == 1'b1 & V == 3'd4) | (VC == 1'b0 & LPR == 3'd2))
	    vc_row_max <= 4'd2;
	  else
	    vc_row_max <= 4'd1;
	end
	
   always @(negedge DA0) begin
		if (IER_or_VP == 1'b1) begin // vertical sync reset address to base address in register
			if (VC == 1'b1) begin // compatibility mode use F
				repeat_address <= F;
				B <= F;
			end else begin // enhanced mode use VO + HO
				repeat_address <= vc_base;
				B <= vc_base;
			end
			vc_row_counter <= vc_row_max - 4'd1; // reset row repeat counter
		end else if (HR == 1'b1) begin // horizontal sync
			if (vc_row_max == 4'd0) // special case - just repeat the same row indefinitely
				B <= repeat_address;
			else begin
				if (vc_row_counter == 4'd0) begin // row repeat counter at zero, move to next row
					vc_row_counter <= vc_row_max - 4'd1;
					if (~VC & HVEN) begin // special case for 256 byte wide field with viewport window
						repeat_address <= repeat_address + 20'd256;
						B <= repeat_address + 20'd256;
					end else begin // progress normally onto next contiguous address
						repeat_address <= (B + 20'd1);
						B <= B + 20'd1;
					end
				end else begin // repeat row
					vc_row_counter <= vc_row_counter - 4'd1;
					B <= repeat_address;
				end
			end
		end else
			B <= B + 20'd1;
  end
	
endmodule

module VCAddressCounter_Testbench();
	
	reg [2:0] V;
	reg DA0;
	reg [18:5] F;
	reg HR;
	reg IER_or_VP;
	wire [20:1] B;
	reg VC;
	reg BP;
	reg [6:0] HO;
	reg [15:0] VO;
	reg [2:0] LPR;
	reg HVEN;
	
	integer counter;
	integer vcounter;
	
	VCAddressCounter uut (
		.V(V),
		.DA0(DA0),
		.F(F),
		.HR(HR),
		.IER_or_VP(IER_or_VP),
		.VC(VC),
		.HO(HO),
		.VO(VO),
		.LPR(LPR),
		.HVEN(HVEN),
		.B(B)
	);
	
	//vc_base = {VO[15:5], (VO[4:0] | HO[6:2]), HO[1:0]};
	// VO = 32768 & HO = 0 == 10000000 000 (00000 | 00000) 00
	// == 10000000 00000000 00 (131072 in decimal)
	// effective address (with DA)
	// == 0100 00000000 00000000 (262144 in decimal)
	
	initial begin
		DA0 <= 1'b0;
		F <= 14'd0;
		VC <= 1'b1;
		BP <= 1'b0;
		HO <= 7'b0;
		VO <= 16'd32768;
		LPR <= 3'b0;
		HVEN <= 1'b0;
		// V = 6/7 (PMODE 3/4) 192 lines
		V <= 3'd6;
		IER_or_VP <= 1'b1;
		#(100) HR <= 1'b1;
		#(100) HR <= 1'b0;
		#(200) IER_or_VP <= 1'b0; // start page
		for (vcounter = 0; vcounter < 192; vcounter = vcounter + 1) begin
	   	for (counter = 0; counter < 31; counter = counter + 1) begin
				#(100) DA0 <= ~DA0;
			end
			#(100) HR <= 1'b1;
			#(100) DA0 <= ~DA0;
		end
		// V = 4 (PMODE 2/1) 96 lines
		V <= 3'd4;
		IER_or_VP <= 1'b1;
		#(100) HR <= 1'b1;
		#(200) IER_or_VP <= 1'b0; // start page
		for (vcounter = 0; vcounter < 192; vcounter = vcounter + 1) begin
			#(200) HR <= 1'b0;		
	   	for (counter = 0; counter < 31; counter = counter + 1) begin
				#(100) DA0 <= ~DA0;
			end
			#(100) HR <= 1'b1;
			#(100) DA0 <= ~DA0;
		end
	   // V = 2 64 lines
	   V <= 3'd2;
	   #(100) DA0 <= 1'b1;
	   #(100) HR <= 1'b0;
	   #(100) IER_or_VP <= 1'b1;
	   #(100) HR <= 1'b1;
	   #(100) DA0 <= ~DA0;
		#(100) IER_or_VP <= 1'b0; // start page
	   for (vcounter = 0; vcounter < 192; vcounter = vcounter + 1) begin
		   #(200) HR <= 1'b0;		
	   	for (counter = 0; counter < 31; counter = counter + 1) begin
				#(100) DA0 <= ~DA0;
  		   end
		   #(100) HR <= 1'b1;
		   #(100) DA0 <= ~DA0;
		end
	   // V = 0 16 lines
	   V <= 3'd0;
	   #(100) DA0 <= 1'b1;
	   #(100) HR <= 1'b0;
	   #(100) IER_or_VP <= 1'b1;
	   #(100) HR <= 1'b1;
	   #(100) DA0 <= ~DA0;
		#(100) IER_or_VP <= 1'b0; // start page
	   for (vcounter = 0; vcounter < 192; vcounter = vcounter + 1) begin
		   #(200) HR <= 1'b0;		
	   	for (counter = 0; counter < 31; counter = counter + 1) begin
				#(100) DA0 <= ~DA0;
  		   end
		   #(100) HR <= 1'b1;
		   #(100) DA0 <= ~DA0;
		end
		#(100) VC <= 1'b0;
		// LPR = 7 1 line
		#(100) LPR <= 3'd7;
	   #(100) DA0 <= 1'b1;
	   #(100) HR <= 1'b0;
	   #(100) IER_or_VP <= 1'b1;
	   #(100) HR <= 1'b1;
	   #(100) DA0 <= ~DA0;
		#(100) IER_or_VP <= 1'b0; // start page
		for (vcounter = 0; vcounter < 192; vcounter = vcounter + 1) begin
			#(200) HR <= 1'b0;		
	   	for (counter = 0; counter < 31; counter = counter + 1) begin
				#(100) DA0 <= ~DA0;
			end
			#(100) HR <= 1'b1;
			#(100) DA0 <= ~DA0;
		end
		// LPR = 6 11 line
		#(100) LPR <= 3'd6;
		#(100) DA0 <= 1'b1;
		#(100) HR <= 1'b0;
		#(100) IER_or_VP <= 1'b1;
		#(100) HR <= 1'b1;
		#(100) DA0 <= ~DA0;
		#(100) IER_or_VP <= 1'b0; // start page
		for (vcounter = 0; vcounter < 198; vcounter = vcounter + 1) begin
			#(200) HR <= 1'b0;		
			for (counter = 0; counter < 31; counter = counter + 1) begin
				#(100) DA0 <= ~DA0;
			end
			#(100) HR <= 1'b1;
			#(100) DA0 <= ~DA0;
		end
		// LPR = 5 10 line
		#(100) LPR <= 3'd5;
		#(100) DA0 <= 1'b1;
		#(100) HR <= 1'b0;
		#(100) IER_or_VP <= 1'b1;
		#(100) HR <= 1'b1;
		#(100) DA0 <= ~DA0;
		#(100) IER_or_VP <= 1'b0; // start page
		for (vcounter = 0; vcounter < 198; vcounter = vcounter + 1) begin
			#(200) HR <= 1'b0;		
			for (counter = 0; counter < 31; counter = counter + 1) begin
				#(100) DA0 <= ~DA0;
			end
			#(100) HR <= 1'b1;
			#(100) DA0 <= ~DA0;
		end
		// LPR = 4 9 line
		#(100) LPR <= 3'd4;
		#(100) DA0 <= 1'b1;
		#(100) HR <= 1'b0;
		#(100) IER_or_VP <= 1'b1;
		#(100) HR <= 1'b1;
		#(100) DA0 <= ~DA0;
		#(100) IER_or_VP <= 1'b0; // start page
		for (vcounter = 0; vcounter < 198; vcounter = vcounter + 1) begin
			#(200) HR <= 1'b0;		
			for (counter = 0; counter < 31; counter = counter + 1) begin
				#(100) DA0 <= ~DA0;
			end
			#(100) HR <= 1'b1;
			#(100) DA0 <= ~DA0;
		end
		// LPR = 3 8 line
		#(100) LPR <= 3'd3;
		#(100) DA0 <= 1'b1;
		#(100) HR <= 1'b0;
		#(100) IER_or_VP <= 1'b1;
		#(100) HR <= 1'b1;
		#(100) DA0 <= ~DA0;
		#(100) IER_or_VP <= 1'b0; // start page
		for (vcounter = 0; vcounter < 198; vcounter = vcounter + 1) begin
			#(200) HR <= 1'b0;		
			for (counter = 0; counter < 31; counter = counter + 1) begin
				#(100) DA0 <= ~DA0;
			end
			#(100) HR <= 1'b1;
			#(100) DA0 <= ~DA0;
		end
		// LPR = 2 2 line
		#(100) LPR <= 3'd2;
		#(100) DA0 <= 1'b1;
		#(100) HR <= 1'b0;
		#(100) IER_or_VP <= 1'b1;
		#(100) HR <= 1'b1;
		#(100) DA0 <= ~DA0;
		#(100) IER_or_VP <= 1'b0; // start page
		for (vcounter = 0; vcounter < 198; vcounter = vcounter + 1) begin
			#(200) HR <= 1'b0;		
			for (counter = 0; counter < 31; counter = counter + 1) begin
				#(100) DA0 <= ~DA0;
			end
			#(100) HR <= 1'b1;
			#(100) DA0 <= ~DA0;
		end
		// LPR = 1 1 line
		#(100) LPR <= 3'd1;
		#(100) DA0 <= 1'b1;
		#(100) HR <= 1'b0;
		#(100) IER_or_VP <= 1'b1;
		#(100) HR <= 1'b1;
		#(100) DA0 <= ~DA0;
		#(100) IER_or_VP <= 1'b0; // start page
		for (vcounter = 0; vcounter < 198; vcounter = vcounter + 1) begin
			#(200) HR <= 1'b0;		
			for (counter = 0; counter < 31; counter = counter + 1) begin
				#(100) DA0 <= ~DA0;
			end
			#(100) HR <= 1'b1;
			#(100) DA0 <= ~DA0;
		end
		// LPR = 1 1 line
		// HVEN = 1
		#(100) LPR <= 3'd1; HVEN <= 1'b1; VC <= 1'b0;
		#(100) DA0 <= 1'b1;
		#(100) HR <= 1'b0;
		#(100) IER_or_VP <= 1'b1;
		#(100) HR <= 1'b1;
		#(100) DA0 <= ~DA0;
		#(100) IER_or_VP <= 1'b0; // start page
		for (vcounter = 0; vcounter < 198; vcounter = vcounter + 1) begin
			#(200) HR <= 1'b0;		
			for (counter = 0; counter < 31; counter = counter + 1) begin
				#(100) DA0 <= ~DA0;
			end
			#(100) HR <= 1'b1;
			#(100) DA0 <= ~DA0;
		end
	end
	
endmodule
