module ProtoVDG(
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
	BRDR,
	VideoLoadClock,
	VR
);

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
	input [1:0] CRES;
	input [1:0] LPF;
	input BP;
	input [2:0] HRES;
	input [7:0] BRDR;
	input VideoLoadClock;
	output [3:0] AlphaRow;
	output [6:0] AlphaCode;
	output DA0;
	output FSn;
	output HSn;
	output OutputFormat;
	output [11:0] RGB;
	output VR;

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
	wire [3:0] EnhancedColour;
	wire viewportActive;
	wire blank;

	parameter forceMode = 1'b0;
	parameter forceAlpha = 1'b1;
	parameter forceGM = 3'd6;
	parameter forceCSS = 1'b0;
	parameter forceSG = 1'b0;
	parameter forceFormat = 1'b0;
	parameter forceInv = 1'b0;
	parameter forceData = 8'd65; //8'h1E; // 4 colours in bitmap mode

	wire useAlpha;
	wire [2:0] useGM;
	wire useCSS;
	wire useAnS;
	wire useFormat;
//	wire useInv;
	wire [7:0] useData;

	reg [7:0] testcode;

	assign useAlpha = forceMode ? forceAlpha : AnG;
	assign useGM = forceMode ? forceGM : GM;
	assign useCSS = forceMode ? forceCSS : Css;
	assign useAnS = useData[7]; //forceMode ? forceSG : useData[7];
//	assign useInv = useData[6]; //forceMode ? forceInv : Inv;
	assign useFormat = forceFormat; //forceMode ? forceFormat : Format;
	assign useData = testcode; //forceMode ? forceData : Data;
	
	assign AlphaCode = useData[6:0];
	
	reg [3:0] frmCount;
	
	initial begin
		testcode <= 8'd112;
		frmCount <= 4'd0;
	end
	
	always @(negedge FSn) begin // or negedge VideoLoadClock) begin
		frmCount <= frmCount + 4'd1;
		if (frmCount == 0)
			testcode <= testcode + 8'd1; //8'd112;
	end

	// Multiplexer - pick colour clock timing based on Format signal
	FormatSelect	FrmtSel (
							.Clk(Clk), 
							.Format(useFormat), 
							.FSn(FSn), 
							.FrameFormat(OutputFormat)
						);
				
	wire [8:0] LeftMargin;
	wire [8:0] RightMargin;
	wire [8:0] TopMargin;
	wire [8:0] BottomMargin;
					
	FormatProfiler FmtProfile (
							.clk(Clk),
							.format(useFormat),
							.GM(useGM),
							.AnG(useAlpha),
							.VC_EN(VC_EN),
							.BP(BP),
							.HRES(HRES),
							.LPF(LPF),
							.LeftMargin(LeftMargin),
							.RightMargin(RightMargin),
							.TopMargin(TopMargin),
							.BottomMargin(BottomMargin),
							.fast_video(VR)
	);
	// Frame timing generator - orchestrate sync, data pre-load
	FormatTiming	FmtTiming (
							.AnG(useAlpha), 
							.Clk(Clk), 
							.VC_EN(VC_EN),
							.BP(BP),
							.HRES(HRES),
							.LeftBorderMargin(LeftMargin),
							.RightBorderMargin(RightMargin),
							.TopMargin(TopMargin),
							.BottomMargin(BottomMargin),
							.CRES(CRES),
							.FrameFormat(OutputFormat), 
							.VideoLoadClock(VideoLoadClock),
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
//	AlphaSwitch  	AlphaSw (
//							.Data(AlphaRowData),
//							.Inv(useInv),
//							.AData(AlphaData)
//							);
	// alpha data shift register
   RawShift			AlphaSf (
							.Clk(PClk),
                     .Data(AlphaRowData),
//                     .Data(useData),
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
						
	EnhancedRawShift EnhancedBitmapSf (
							.Clk(PClk),
							.Data(useData),
							.Divider({VR, CRES}),
							.Load(Load),
							.Pixel(EnhancedColour)
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
							.Colour5(EnhancedColour),
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

module ProtoVDG_testbench();

	reg AnG;
	wire AnS;
	reg Clk;
	reg Css;
	reg [7:0] Data;
	reg [7:0] AlphaRowData;
	reg Format;
	reg [2:0] GM;
	wire Inv;
	reg VC_EN;
	reg [1:0] CRES;
	reg [1:0] LPF;
	reg BP;
	reg [2:0] HRES;
	reg [7:0] BRDR;
	reg VideoLoadClock;

	assign AnS = Data[7];
	assign Inv = Data[6];

	wire [3:0] AlphaRow;
	wire [6:0] AlphaCode;
	wire DA0;
	wire FSn;
	wire HSn;
	wire OutputFormat;
	wire [11:0] RGB;
	wire VR;
	
	parameter clockperiod = 6948;
	parameter halfclock = 3474;
	
	ProtoVDG uut (
		.AnG (AnG),
		.AnS (AnS),
		.Clk (Clk),
		.Css (Css),
		.Data (Data),
		.AlphaRowData (AlphaRowData),
		.Format (Format),
		.GM (GM),
		.Inv (Inv),
		.VC_EN (VC_EN),
		.CRES (CRES),
		.LPF (LPF),
		.BP (BP),
		.HRES (HRES),
		.BRDR (BRDR),
		.VideoLoadClock (VideoLoadClock),

		.AlphaRow (AlphaRow),
		.AlphaCode (AlphaCode),
		.DA0 (DA0),
		.FSn (FSn),
		.HSn (HSn),
		.OutputFormat (OutputFormat),
		.RGB (RGB),
		.VR(VR)
	);
	
	initial begin
		Css <= 1'b0;
		AnG <= 1'b1;
		GM <= 3'd6;
		Clk <= 1'b0;
		Data <= 8'd65;
		AlphaRowData <= 8'hFF;
		Format <= 1'b1;
		VideoLoadClock <= 1'b1;
		VC_EN <= 1'b1;
	end
	
	// video pixel clock generator
	always begin
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk; VideoLoadClock <= 1'b0;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk;
		#(halfclock) Clk = ~Clk; VideoLoadClock <= 1'b1;		
	end
endmodule
