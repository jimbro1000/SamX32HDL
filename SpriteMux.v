module SpriteMux(
	input clk,
	input	HRn,
	input [10:0] px,
	input	[8:0] py,
	input	[2047:0] bitmaps,
	input	[1023:0] instances,
	output [11:0] RGB,
	output active
);

	wire startAX;
	wire startAY;
	wire enableA;
	wire maskA;
	wire [2:0] pixelA;
	
	wire [10:0] posAX;
	wire [8:0] posAY;
	wire [1:0] scaleAX;
	wire [1:0] scaleAY;
	wire mirrorAX;
	wire mirrorAY;
	wire [1:0] rotateA;
	integer instanceA;
	wire [95:0] paletteA;
	wire [1:0] priorityA;
	
	//assign instanceA = instances[6:0] * 256;		// 7 bits << 8
	assign posAX = instances[17:7];		// 11 bits
	assign posAY = instances[26:18];		// 9 bits
	assign mirrorAX = instances[28];
	assign mirrorAY = instances[29];
	assign rotateA = instances[31:30];	// 2 bits
	assign scaleAX = instances[33:32];	// 2 bits
	assign scaleAY = instances[35:34];	// 2 bits
	assign priorityA = instances[37:36];// 2 bits
	assign paletteA = instances[133:38];// 96 bits

	SpritePosition spritePosA(				// identify if sprite is active for current display pixel
		.clk(clk),
		.X(px),
		.Y(py),
		.posX(posAX),
		.posY(posAY),
		.scaleX(scaleAX),
		.scaleY(scaleAY),
		.spriteEnable(enableA),
		.startX(startAX),
		.startY(startAY)
	);
	
	SpriteRenderer spriteA(					// produce pixel mask and colour index
		.clk(clk),
		.HRn(HRn),
		.active(enableA),
		.bitmap(bitmaps[instanceA+:256]),
		.scaleX(scaleAX),
		.scaleY(scaleAY),
		.rotate(rotateA),
		.mirrorX(mirrorAX),
		.mirrorY(mirrorAY),
		.startX(startAX),
		.startY(startAY),
		.mask(maskA),
		.pixel(pixelA)
	);

	wire startBX;
	wire startBY;
	wire enableB;
	wire maskB;
	wire [2:0] pixelB;
	
	wire [10:0] posBX;
	wire [8:0] posBY;
	wire [1:0] scaleBX;
	wire [1:0] scaleBY;
	wire mirrorBX;
	wire mirrorBY;
	wire [1:0] rotateB;
	integer instanceB;
	wire [95:0] paletteB;
	wire [1:0] priorityB;
	
	assign posBX = instances[274:263];		// 11 bits
	assign posBY = instances[282:274];		// 9 bits
	assign mirrorBX = instances[284];
	assign mirrorBY = instances[285];
	assign rotateB = instances[287:286];	// 2 bits
	assign scaleBX = instances[289:288];	// 2 bits
	assign scaleBY = instances[291:290];	// 2 bits
	assign priorityB = instances[293:292];	// 2 bits
	assign paletteB = instances[389:294];	// 96 bits

	SpritePosition spritePosB(				// identify if sprite is active for current display pixel
		.clk(clk),
		.X(px),
		.Y(py),
		.posX(posBX),
		.posY(posBY),
		.scaleX(scaleBX),
		.scaleY(scaleBY),
		.spriteEnable(enableB),
		.startX(startBX),
		.startY(startBY)
	);
	
	SpriteRenderer spriteB(					// produce pixel mask and colour index
		.clk(clk),
		.HRn(HRn),
		.active(enableB),
		.bitmap(bitmaps[instanceB+:256]),
		.scaleX(scaleBX),
		.scaleY(scaleBY),
		.rotate(rotateB),
		.mirrorX(mirrorBX),
		.mirrorY(mirrorBY),
		.startX(startBX),
		.startY(startBY),
		.mask(maskB),
		.pixel(pixelB)
	);
	
	wire startCX;
	wire startCY;
	wire enableC;
	wire maskC;
	wire [2:0] pixelC;
	
	wire [10:0] posCX;
	wire [8:0] posCY;
	wire [1:0] scaleCX;
	wire [1:0] scaleCY;
	wire mirrorCX;
	wire mirrorCY;
	wire [1:0] rotateC;
	integer instanceC;
	wire [95:0] paletteC;
	wire [1:0] priorityC;
	
	assign posCX = instances[529:519];		// 11 bits
	assign posCY = instances[538:530];		// 9 bits
	assign mirrorCX = instances[540];
	assign mirrorCY = instances[541];
	assign rotateC = instances[543:542];	// 2 bits
	assign scaleCX = instances[545:544];	// 2 bits
	assign scaleCY = instances[547:546];	// 2 bits
	assign priorityC = instances[549:548];	// 2 bits
	assign paletteC = instances[645:550];	// 96 bits

	SpritePosition spritePosC(				// identify if sprite is active for current display pixel
		.clk(clk),
		.X(px),
		.Y(py),
		.posX(posCX),
		.posY(posCY),
		.scaleX(scaleCX),
		.scaleY(scaleCY),
		.spriteEnable(enableC),
		.startX(startCX),
		.startY(startCY)
	);
	
	SpriteRenderer spriteC(					// produce pixel mask and colour index
		.clk(clk),
		.HRn(HRn),
		.active(enableC),
		.bitmap(bitmaps[instanceC+:256]),
		.scaleX(scaleCX),
		.scaleY(scaleCY),
		.rotate(rotateC),
		.mirrorX(mirrorCX),
		.mirrorY(mirrorCY),
		.startX(startCX),
		.startY(startCY),
		.mask(maskC),
		.pixel(pixelC)
	);
	
	wire startDX;
	wire startDY;
	wire enableD;
	wire maskD;
	wire [2:0] pixelD;
	
	wire [10:0] posDX;
	wire [8:0] posDY;
	wire [1:0] scaleDX;
	wire [1:0] scaleDY;
	wire mirrorDX;
	wire mirrorDY;
	wire [1:0] rotateD;
	integer instanceD;
	wire [95:0] paletteD;
	wire [1:0] priorityD;
	
	assign posDX = instances[785:775];		// 11 bits
	assign posDY = instances[794:786];		// 9 bits
	assign mirrorDX = instances[796];
	assign mirrorDY = instances[797];
	assign rotateD = instances[799:798];	// 2 bits
	assign scaleDX = instances[801:800];	// 2 bits
	assign scaleDY = instances[803:802];	// 2 bits
	assign priorityD = instances[805:804];	// 2 bits
	assign paletteD = instances[901:806];	// 96 bits

	SpritePosition spritePosD(				// identify if sprite is active for current display pixel
		.clk(clk),
		.X(px),
		.Y(py),
		.posX(posDX),
		.posY(posDY),
		.scaleX(scaleDX),
		.scaleY(scaleDY),
		.spriteEnable(enableD),
		.startX(startDX),
		.startY(startDY)
	);
	
	SpriteRenderer spriteD(					// produce pixel mask and colour index
		.clk(clk),
		.HRn(HRn),
		.active(enableD),
		.bitmap(bitmaps[instanceD+:256]),
		.scaleX(scaleDX),
		.scaleY(scaleDY),
		.rotate(rotateD),
		.mirrorX(mirrorDX),
		.mirrorY(mirrorDY),
		.startX(startDX),
		.startY(startDY),
		.mask(maskD),
		.pixel(pixelD)
	);
	
	always @(clk) begin
		instanceA = instances[6:0] * 256;			// 7 bits << 8
		instanceB = instances[262:256] * 256;		// 7 bits << 8
		instanceC = instances[518:512] * 256;		// 7 bits << 8
		instanceD = instances[774:768] * 256;		// 7 bits << 8
	end
	
	assign active = maskA | maskB | maskC | maskD;
	

endmodule
