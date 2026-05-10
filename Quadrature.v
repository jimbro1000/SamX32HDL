module quadrature(
	input OSC,
	input R,
	input VR,
	input Reset,
	input is_COMMON,
	input is_RAM,
	output VClk,
	output reg Q,
	output reg E,
	output reg ZCpu,
	output reg ZVideo,
	output reg VideoLoadClock,
	output reg nRAS0,
	output reg nCE
);

reg [3:0] State;
reg [3:0] NextState;
reg fast_cpu_cycle;
reg fast_video_cycle;
wire need_ram;

initial begin
	State <= 4'd15;
	NextState <= 4'd15;
	fast_cpu_cycle <= 1'b0;
	fast_video_cycle <= 1'b0;
	ZCpu <= 1'b0;
	ZVideo <= 1'b0;
	Q <= 1'b0;
	E <= 1'b0;
	nRAS0 <= 1'b1;
	nCE <= 1'b1;
end

assign need_ram = is_RAM | ZVideo;

always @(negedge OSC) begin
	// VLC is ZVideo inverted and delayed by one cycle
	VideoLoadClock <= ~ZVideo;
	// VRAM strobe from original SAMx spec - now incorrect and needs retiming
	if (fast_video_cycle == 1'b1 & (NextState == 4'd5 | NextState == 4'd13))
	  nRAS0 <= 1'b0;
	else if (fast_video_cycle == 1'b0 & NextState == 4'd13)
	  nRAS0 <= 1'b0;
	else
	  nRAS0 <= 1'b1;
//	if (fast_cpu_cycle == 1'b1)
//		if (State == 1'd0)
//			nRAS0 <= 1'b1;
//	else
//		case (State)
//			4'd1: nRAS0 <= 1'b1;
//			4'd2: nRAS0 <= 1'b1;
//			4'd3: nRAS0 <= 1'b1;
//			4'd4: nRAS0 <= 1'b1;
//			4'd5: nRAS0 <= 1'b1;
//			default: nRAS0 <= 1'b0;
//		endcase

	// RAM chip enable -- horrible logic and very wrong
	if (Reset == 1'b0)
		nCE <= 1'b1; // force chip disable
	else if (fast_cpu_cycle == 1'b1 & fast_video_cycle ==  1'b1) begin // both fast
	  if (need_ram & (NextState == 4'd3 | NextState == 4'd7 | NextState == 4'd11 | NextState == 4'd15))
    		nCE <= 1'b0; // enable for start of slice cycle
		else if (NextState == 4'd2 | NextState == 4'd6 | NextState == 4'd10 | NextState == 4'd14)
		  nCE <= 1'b1; // disable for end of slice cycle - 1 dead tick minimum between each cycle
	end else if (fast_cpu_cycle == 1'b1) begin // cpu only fast
	  if (need_ram & (NextState == 4'd7 | NextState == 4'd11 | NextState == 4'd15)) 
	    nCE <= 1'b0;
	  else if (NextState == 4'd6 | NextState == 4'd10 | NextState == 4'd14)
	    nCE <= 1'b1;
	end else if (fast_video_cycle == 1'b1) begin // video only fast
	  if (need_ram & (NextState == 4'd3 | NextState == 4'd11 | NextState == 4'd15))
    		nCE <= 1'b0;
		else if (NextState == 4'd2 | NextState == 4'd6 | NextState == 4'd14)
		  nCE <= 1'b1;
  end else // both slow
	  if (need_ram & (NextState == 4'd11 | NextState == 4'd15))
    		nCE <= 1'b0;
		else if (NextState == 4'd2 | NextState == 4'd14)
		  nCE <= 1'b1;
end

always @(negedge OSC) begin
	State <= NextState;
	case (State)
		4'd15: begin
			NextState <= 4'd0;
			if (fast_cpu_cycle == 1'b1)
				if (R == 1'b0)
					fast_cpu_cycle <= 1'b0;
				else
					Q <= Reset;
		end
		4'd0: begin
			NextState <= 4'd1;
		end
		4'd1: begin
			NextState <= 4'd2;
			if (fast_cpu_cycle == 1'b1)
				E <= Reset;
		end
		4'd2: begin
			NextState <= 4'd3;
			if (fast_cpu_cycle == 1'b1)
				ZCpu <= 1'b1;
			else
				Q <= Reset;
			ZVideo <= 1'b0;
		end
		4'd3: begin
			NextState <= 4'd4;
			if (fast_cpu_cycle == 1'b1)
				Q <= 1'b0;
		end
		4'd4: begin
			NextState <= 4'd5;
		end
		4'd5: begin
			NextState <= 4'd6;
			if (fast_cpu_cycle == 1'b1)
				E <= 1'b0;
			ZCpu <= 1'b0;
			if (fast_video_cycle == 1'b1)
				ZVideo <= 1'b1;
		end
		4'd6: begin
			NextState <= 4'd7;
			if (fast_cpu_cycle == 1'b0)
				E <= Reset;
		end
		4'd7: begin
			NextState <= 4'd8;
			if (fast_cpu_cycle == 1'b1)
				if (R == 1'b0)
					fast_cpu_cycle = 1'b0;
				else
					Q <= Reset;
		end
		4'd8: begin
			NextState <= 4'd9;
		end
		4'd9: begin
			NextState <= 4'd10;
			if (fast_cpu_cycle == 1'b1)
				E <= Reset;
		end
		4'd10: begin
			NextState <= 4'd11;
			if (fast_cpu_cycle == 1'b0)
				Q <= 1'b0;
			fast_video_cycle <= VR;
			ZCpu <= 1'b1;
			ZVideo <= 1'b0;
		end
		4'd11: begin
			NextState <= 4'd12;
			if (fast_cpu_cycle == 1'b1)
				Q <= 1'b0;
			else
				if (R == 1'b1)
					fast_cpu_cycle <= 1'b1;
		end
		4'd12: begin
			NextState <= 4'd13;
		end
		4'd13: begin
			NextState <= 4'd14;
			if (fast_cpu_cycle == 1'b1)
				E <= 1'b0;
		end
		4'd14: begin
			NextState <= 4'd15;
			E <= 1'b0;
			ZCpu <= 1'b0;
			ZVideo <= 1'b1;
		end
	endcase
end

assign VClk = OSC;

endmodule


module quadrature_testbench;

	reg OSC;
	reg R;
	reg VR;
	reg Reset;
	reg is_COMMON;
	reg is_RAM;
	wire VClk;
	wire Q;
	wire E;
	wire ZCpu;
	wire ZVideo;
	wire VideoLoadClock;
	wire nRAS0;
	wire nCE;
	
	parameter clockCycle = 34920;

	quadrature uut(
		.OSC(OSC),
		.R(R),
		.VR(VR),
		.Reset(Reset),
		.is_COMMON(is_COMMON),
		.is_RAM(is_RAM),
		.VClk(VClk),
		.Q(Q),
		.E(E),
		.ZCpu(ZCpu),
		.ZVideo(ZVideo),
		.VideoLoadClock(VideoLoadClock),
		.nRAS0(nRAS0),
		.nCE(nCE)
	);
	
	initial begin
		OSC = 1'b0;
		R = 1'b0;
		VR = 1'b0;
		is_COMMON = 1'b0;
		is_RAM = 1'b0;
		Reset = 1'b0;
		
		#(clockCycle * 8) Reset = 1'b1; // hold in reset
		#(clockCycle * 128) is_RAM = 1'b1; // select ram address space
		#(clockCycle * 256) R = 1'b1; // set to fast cpu cycle
   	#(clockCycle * 256) VR = 1'b1; R = 1'b0; // set to fast video cycle
		#(clockCycle * 256) R = 1'b1; // set to fast cpu and video cycle
	
	end
	
	always begin
	  #(clockCycle) OSC = ~OSC;
  end

endmodule
