	module SpritePriorityMux(
		input [11:0] rgbA,
		input [11:0] rgbB,
		input [11:0] rgbC,
		input [11:0] rgbD,
		input [1:0] priorityA,
		input [1:0] priorityB,
		input [1:0] priorityC,
		input [1:0] priorityD,
		input maskA,
		input maskB,
		input maskC,
		input maskD,
		output [11:0] rgbOut
	);
	
	// horrible method but if it works...
	assign rgbOut =	(maskA && priorityA == 3'd3) ? rgbA :
							(maskB && priorityB == 3'd3) ? rgbB :
							(maskC && priorityC == 3'd3) ? rgbC :
							(maskD && priorityD == 3'd3) ? rgbD :
							(maskA && priorityA == 3'd2) ? rgbA :
							(maskB && priorityB == 3'd2) ? rgbB :
							(maskC && priorityC == 3'd2) ? rgbC :
							(maskD && priorityD == 3'd2) ? rgbD :
							(maskA && priorityA == 3'd1) ? rgbA :
							(maskB && priorityB == 3'd1) ? rgbB :
							(maskC && priorityC == 3'd1) ? rgbC :
							(maskD && priorityD == 3'd1) ? rgbD :
							(maskA) ? rgbA :
							(maskB) ? rgbB :
							(maskC) ? rgbC :
							(maskD) ? rgbD :
							12'd0;
	
	endmodule
	