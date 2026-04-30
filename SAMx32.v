`timescale 1ns / 1ps

module SAMx32(
	input [15:0] A,
	input RWn,
	input OSCin,
	input RSTn,
	//input [2:0] GM,
	//input CSS,
	//input AnG,
	input [7:0] CD,
	
	input [7:0] RD,
	
	output [11:0] RGBout,
	output Format,
	output [19:0] Z,
	output Z0n,
	output CE1n,
	output CE2n,
	output WEn,
	output [2:0] S,
	output Q,
	output E,
	output [6:0] CC,
	output [3:0] CR,
	output HSn,
	output FSn
);

	wire [20:0] ZI;
	wire RAS0;
	wire RAMCEn;
	wire GEn;
	wire GDIR;
	wire VClk;
	wire DA0;
	wire RFormat;
	wire PaletteRegEnable;
	wire AnG;
	wire CSS;
	wire [2:0] GM;
	
	reg [7:0] VD;
	
	ControlSignalCapture shadowPIA (
		.Clk (E),
		.S (S),
		.A (A[1:0]),
		.D (RD[7:3]),
		.AnG (AnG),
		.GM (GM),
		.CSS (CSS)
	);
	
	samx	SAM (
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
		.PREN (PaletteRegEnable)
	);
	
	assign CE1n = RAMCEn | ZI[20];
	assign CE2n = RAMCEn | ~ZI[20];
	assign Z = ZI[19:0];

	ProtoVDG VDG (
		.Q (Q),
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
		.RGB (RGBout)
	);
	
endmodule
