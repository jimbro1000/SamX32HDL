`timescale 1ps / 1ps

module SAMx32(
	input [15:0] A, 		// CPU 16-bit address bus
	input RWn,				// Read / Write signal
	input OSCin,			// Main clock
	input RSTn,				// Reset
	input [2:0] GM,		// Graphic mode
	input CSS,				// Colour set select
	input AnG,				// Alpha / Graphic mode
	input [7:0] RD,		// CPU 8-bit data bus
	input [7:0] CD,		// Character data 8-bit
	output [11:0] RGBout,// Video output R[4]G[4]B[4]
	output VCLK,			// Video pixel clock
	output Format,			// Video frame timing PAL/NTSC
	output [3:0] CR,		// Character row
	output reg [3:0] CS,	// Character set select
	output [6:0] CC,		// Character code
	output [19:0] Z,		// Expanded RAM address bus
	output Z0n,				// Inverted bit 0 of expanded RAM address bus
	output CE1n,			// RAM chip enable 1
	output CE2n,			// RAM chip enable 2
	output WEn,				// RAM write enable
	output [2:0] S,		// SAM device select
	output Q,				// Quadrature clock Q
	output E,				// Quadrature clock E
	output HSn,				// Horizontal video sync
	output FSn				// Vertical video sync
);

	wire [20:0] ZI;   // SRAM address bus (internal)
	wire RAS0;	      // Ram access strobe (was row address select)
	wire RAMCEn;	   // SRAM chip enable
	wire GEn;
	wire GDIR;
	wire VClk;			// Video clock
	wire DA0;			// Video data access read
	wire RFormat;     // Requested video format (redundant?)
//	wire AnG;         // Alpha/Graphic mode select
//	wire CSS;         // Colour set select
//	wire [2:0] GM;    // Graphic mode selector
	wire VCE;         // Video Compatible Mode Enable
	wire [127:0] Palette; // 16x8 palette table
	wire [1:0] CRES;  // Bits per pixel (1/2/4/8)
	wire [2:0] LPR;   // Lines per row
	wire [1:0] LPF;   // Lines per field
	wire BP;			   // Bitmap Mode (gated by VCE)
	wire [2:0] HRES;  // Horizontal Resolution
	wire [7:0] BRDR;  // Border Colour
	wire VR;				// Request fast video
	wire VLC;	      // video load clock
	
	wire [7:0] VD;     // Video data buffer
	
//	ControlSignalCapture shadowPIA (
//		.Clk (E),
//		.S (S),
//		.A (A[1:0]),
//		.D (RD[7:3]),
//		.AnG (AnG),
//		.GM (GM),
//		.CSS (CSS)
//	);

//	assign AnG = 1'b0;
//	assign GM = 3'b000;
//	assign CSS = 1'b0;

	initial begin
		CS <= 4'd0;
	end
		
	vsamx	SAM (
		.OscOut (OSCin),
		.E (E),
		.Q (Q),
		.A (A),
		.D (RD),
		.VD (VD),
		.RnW (RWn),
		.S (S),
		.Z (ZI),
		.nZ0 (Z0n),
		.nRAS0 (RAS0),
		.nCE (RAMCEn),
		.nWE (WEn),
		.nGE (GEn),
		.GDIR (GDIR),
      .VClk (VClk),
		.nER (RSTn),
		.DA0 (DA0),
		.nHS (HSn),
		.VC_EN (VCE),
		.PDEF (Palette),
		.CRES (CRES),
		.LPR (LPR),
		.LPF (LPF),
		.FMT (RFormat),
		.BP (BP),
		.HRES (HRES),
		.BRDR (BRDR),
		.VideoLoadClock (VLC),
		.VR(VR)
	);
			  
	assign CE1n = RAMCEn | ZI[20];
	assign CE2n = RAMCEn | ~ZI[20];
	assign Z = ZI[19:0];

	ProtoVDG VDG (
		.AnG (AnG),
		.AnS (RD[7]),
		.Clk (VClk),
		.Css (CSS),
		.Data (VD),
		.AlphaRowData (CD),
		.AlphaCode (CC),
		.Format (RFormat),
		.GM (GM),
		.Inv (RD[6]),
		.AlphaRow (CR),
		.DA0 (DA0),
		.FSn (FSn),
		.HSn (HSn),
		.OutputFormat (Format),
		.RGB (RGBout),
		.VC_EN (VCE),
		.CRES (CRES),
		.LPF (LPF),
		.BP (BP),
		.HRES (HRES),
		.BRDR (BRDR),
		.PaletteDef (Palette),
		.VideoLoadClock (VLC),
		.VR(VR)
	);

endmodule

module SAMx32_testbench();

	reg [15:0] A;
	reg RWn;
	reg OSCin;
	reg RSTn;
	reg [2:0] GM;
	reg CSS;
	reg AnG;
	reg [7:0] CD;
	reg [7:0] RD;
	wire [11:0] RGBout;
	wire Format;
	wire [19:0] Z;
	wire Z0n;
	wire CE1n;
	wire CE2n;
	wire WEn;
	wire [2:0] S;
	wire Q;
	wire E;
	wire [6:0] CC;
	wire [3:0] CR;
	wire HSn;
	wire FSn;
	wire [3:0] CS;
	
	parameter clockCycle = 3492;

	SAMx32 uut (
		.A(A),
		.RWn(RWn),
		.OSCin(OSCin),
		.RSTn(RSTn),
		.GM(GM),
		.CSS(CSS),
		.AnG(AnG),
		.CD(CD),
		.RD(RD),
		.RGBout(RGBout),
		.Format(Format),
		.Z(Z),
		.Z0n(Z0n),
		.CE1n(CE1n),
		.CE2n(CE2n),
		.WEn(WEn),
		.S(S),
		.Q(Q),
		.E(E),
		.CC(CC),
		.CR(CR),
		.CS(CS),
		.HSn(HSn),
		.FSn(FSn)
	);

	initial begin
		A <= 16'd65535;
		RWn <= 1'b1;
		RSTn <= 1'b0;
		OSCin <= 1'b1;
		GM <= 3'b110;
		CSS <= 1'b0;
		AnG <= 1'b0;
		CD <= 8'b00011011;
		RD <= 8'd0;
		
	end
	
	always begin
	  #(clockCycle) OSCin <= 1'b1;
	  #(clockCycle) OSCin <= 1'b0;
	end

endmodule
