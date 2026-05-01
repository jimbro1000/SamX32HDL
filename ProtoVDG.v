module ProtoVDG(
	Q,
	GClk,
	AnG,
	AnS,
	Clk,
	Css,
	Data,
	AlphaRowData,
	Format,
	GM,
	Inv,
	PaletteDef,
	AlphaRow,
	AlphaCode,
	DA0,
	FSn,
	HSn,
	OutputFormat,
	RGB,
	VC_EN,
	CRES,
	LPF,
	BP,
	HRES,
	BRDR
);

	input Q;
	input GClk;
	input AnG;
	input AnS;
	input Clk;
	input Css;
	input [7:0] Data;
	input [7:0] AlphaRowData;
	input Format;
	input [2:0] GM;
	input Inv;
	input [127:0] PaletteDef;
	input VC_EN;
	input [2:0] CRES;
	input [2:0] LPF;
	input BP;
	input [2:0] HRES;
	input [7:0] BRDR;
	output [3:0] AlphaRow;
	output [6:0] AlphaCode;
	output DA0;
	output FSn;
	output HSn;
	output OutputFormat;
	output [11:0] RGB;

	wire Divider;
	wire Load;
	wire PClk;
	wire Sel1;
	wire Sel2;
	wire [7:0] AlphaData;
	wire [1:0] AlphaPixel;
	wire [1:0] GraphPixel;
	wire [7:0] SData;
	wire [3:0] SColour;
	wire [3:0] GraphColour;
	wire [3:0] AlphaColour;
	wire [3:0] SemiColour;
	wire [3:0] BorderColour;
	wire viewportActive;
	wire blank;

	parameter forceMode = 1'b0;
	parameter forceAlpha = 1'b0;
	parameter forceGM = 3'd6;
	parameter forceCSS = 1'b1;
	parameter forceSG = 1'b0;
	parameter forceFormat = 1'b0;
	parameter forceInv = 1'b0;
	parameter forceData = 8'd33;

	wire useAlpha;
	wire [2:0] useGM;
	wire useCSS;
	wire useAnS;
	wire useFormat;
	wire useInv;
	wire [7:0] useData;

	assign useAlpha = forceMode ? forceAlpha : AnG;
	assign useGM = forceMode ? forceGM : GM;
	assign useCSS = forceMode ? forceCSS : Css;
	assign useAnS = forceMode ? forceSG : AnS; //useData[7];
	assign useInv = forceMode ? forceInv : Inv;
	assign useFormat = forceMode ? forceFormat : Format;
	assign useData = forceMode ? forceData : Data;
	
	assign AlphaCode = useData[6:0];

	// Multiplexer - pick colour clock timing based on Format signal
	FormatSelect	FrmtSel (
							.Clk(Clk), 
							.Format(useFormat), 
							.FSn(FSn), 
							.FrameFormat(OutputFormat)
						);
				
	wire [6:0] BPR;
	wire [8:0] LeftMargin;
	wire [8:0] RightMargin;
	wire [8:0] AllRows;
	wire [8:0] TopBlank;
	wire [8:0] TopMargin;
	wire [8:0] BottomMargin;
	wire [2:0] BPP;
					
	FormatProfiler FmtProfile (
		.clk(Clk),
		.format(useFormat),
		.GM(useGM),
		.AnG(useAlpha),
		.VC_EN(VC_EN),
		.BP(BP),
		.HRES(HRES),
		.CRES(CRES),
		.LPF(LPF),
		.BytesPerRow(BPR),
		.LeftMargin(LeftMargin),
		.RightMargin(RightMargin),
		.AllRows(AllRows),
		.TopBlank(TopBlank),
		.TopMargin(TopMargin),
		.BottomMargin(BottomMargin),
		.BPP(BPP)
	);
	// Frame timing generator - orchestrate sync, data pre-load
	FormatTiming	FmtTiming (
							.Q(Q),
							.AnG(useAlpha), 
							.Clk(Clk), 
							.FrameFormat(OutputFormat), 
							.GMode(useGM), 
							.alphaRow(AlphaRow), 
							.DA0(DA0), 
							.FSn(FSn), 
							.HSn(HSn), 
							.BackPorch(blank),
							.active(viewportActive),
							.Load(Load), 
							.PixelClk(PClk)
						);
	// Multiplexer - pick pixel generator format, define timing divider, select lines for colour mux
	DataSelectPath	DataSel (
							.AnG(useAlpha), 
							.AnS(useAnS), 
							.GM(useGM), 
							.Divider(Divider), 
							.selAlpha(Sel2), 
							.selSemi(Sel1)
						);
	// Lookup Semi4 data to pixel
	Semi4Rom			S4Rom (
							.Clk(Clk),
							.Data(useData),
                     .Row(AlphaRow),
                     .SColour(SColour),
                     .SData(SData)
						);
	// Apply inverse mode if required
	AlphaSwitch  	AlphaSw (
							.Data(AlphaRowData),
							.Inv(useInv),
							.AData(AlphaData)
							);
	// alpha data shift register
   RawShift			AlphaSf (
							.Clk(PClk),
                     .Data(AlphaData),
                     .Divider(Divider),
                     .Load(Load),
                     .Pixel(AlphaPixel[1:0])
						);
	// graphic data shift register
	RawShift			GraphSf (
							.Clk(PClk),
                     .Data(useData),
                     .Divider(Divider),
                     .Load(Load),
                     .Pixel(GraphPixel[1:0])
						);
	// semigraphic data register
   SemiShift  		SemiSf (
							.Clk(PClk), 
                     .Data(SData), 
                     .Load(Load), 
                     .SColour(SColour), 
                     .Colour(SemiColour[3:0])
						);
	// alpha pixel data to colour 
   ColourMap  		AlphaMap (
							.AnG(useAlpha), 
                     .Css(useCSS), 
                     .Mode(GM), 
                     .Pixel(AlphaPixel[1:0]), 
                     .Colour(AlphaColour[3:0])
						);
	// graphic pixel data to colour
   ColourMap  		GraphMap (
							.AnG(useAlpha), 
                     .Css(useCSS), 
                     .Mode(useGM), 
                     .Pixel(GraphPixel[1:0]), 
                     .Colour(GraphColour[3:0])
						);
	// border colour selector
	BorderSelect	Border (
							.AnG(useAlpha),
							.CSS(useCSS),
							.GM(useGM),
							.Colour(BorderColour)
						);
	// multiplexer - pick pixel colour channel from display mode
   ColourMux  		Palette (
							.clk(Clk),
							.Colour1(SemiColour), 
                     .Colour2(AlphaColour[3:0]), 
                     .Colour3(GraphColour[3:0]), 
							.Colour4(BorderColour),
                     .Sel1(Sel1), 
                     .Sel2(Sel2), 
							.VC(VC_EN),
							.backporch(blank),
							.viewportActive(viewportActive),
							.PaletteDef(PaletteDef),
							.Border(BRDR),
                     .RGB(RGB)
						);
endmodule
