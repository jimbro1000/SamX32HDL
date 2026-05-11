//-- SAMx MMU
//
//-- (C) 2023-2025 Ciaran Anscomb
//--
//-- Released under the Creative Commons Attribution-ShareAlike 4.0
//-- International License (CC BY-SA 4.0).  Full text in the LICENSE file.
//
//-- A small MMU intended to be combined with fast SRAM and replace the SN74LS783
//-- Synchronous Address Multiplexer + DRAM in a Dragon 64.
//
//-- Primary reference is the datasheet for the SN74LS783.
//
//-- SAMx8 MMU changes the following functionality of the SAMx4:
//--
//--  - No DRAM support (refresh, muxed addresses, organisation).
//--  - Only SLOW and FAST CPU rates supported.
//--  - Video still supported in FAST mode.
//--  - VDG address "glitch" support removed.
//--  - Page bit repurposed as TASK selector.
//--  - Two sets (per-task) of 4 * 16K arbitrary page mapping.
//--  - Lower RAM size bit repurposed to enable common 4K/8K at top of RAM.
//--  - D0--D7 connected for writes to extra registers.
//
//-- Page registers accept 5-bit values 0-31, identifying a 16K page within the
//-- 512K SRAM.
//
//-- Address	Function			Default
//-- $FF30	Page for $0000--$3FFF, TASK 0	0
//-- $FF31	Page for $4000--$7FFF, TASK 0	1
//-- $FF32	Page for $8000--$BFFF, TASK 0	2
//-- $FF33	Page for $C000--$FEFF, TASK 0	3
//-- $FF34	Page for $0000--$3FFF, TASK 1	2
//-- $FF35	Page for $4000--$7FFF, TASK 1	3
//-- $FF36	Page for $8000--$BFFF, TASK 1	2
//-- $FF37	Page for $C000--$FEFF, TASK 1	3
//-- $FF38	F13--F18 (6 bits of VRAM base)	0
//-- $FF39	F5--F12 (8 bits of VRAM base)	0
//-- $FF3F	COMMON (bits 0--1)		0
//
//-- Setting bit 0 of COMMON forces the top 4K ($F000--$FEFF and the vector area
//-- $FFE0--$FFFF) to be mapped to page 31 whatever other configuration is in
//-- place.  Setting bit 1 does the same for the next 4K down ($E000--$EFFF).
//-- The vector area is still read-only and in map type 0, so is the rest,
//-- however modifications can be made by mapping 31 elsewhere.
//
//-- GIME registers of interest
//-- $FF90 (76) Compatible Mode | MMU Enabled
//-- $FF91 (0) MMU Task
//-- $FF98 VMODE (7543210) A/G | Invert Artifacts | Monochrome | H50 50/60Hz | lines per row [2..0]
//-- LPR 00x = one line per row
//--     010 = two lines per row
//--     011 = eight lines per row
//--     100 = nine lines per row
//--     101 = ten lines per row
//--     110 = eleven lines per row
//--     111 = one line per screen (infinite lines per row)
//-- $FF99 VRES (654321) lines per field [6..5] | horizontal res [4..2] | colour res [1..0]
//-- LPF 00 = 192 scan lines on screen
//--     01 = 200 scan lines on screen
//--     10 = undefined (zero/infinite)
//--     11 = 225 scan lines on screen
//-- HRES (graphics) 000 = 16 bytes per row
//--                 001 = 20 bytes per row
//--                 010 = 32 bytes per row
//--                 011 = 40 bytes per row
//--                 100 = 64 bytes per row
//--                 101 = 80 bytes per row
//--                 110 = 128 bytes per row
//--                 111 = 160 bytes per row
//-- HRES (text) 0x0 = 32 bytes per row
//--             0x1 = 40 bytes per row
//--             1x0 = 64 bytes per row
//--             1x1 = 80 bytes per row
//-- CRES (graphics) 00 = 2 colours (8 pixels per byte)
//--                 01 = 4 colours (4 pixels per byte)
//--                 10 = 16 colours (2 pixels per byte)
//--                 11 = undefines (should be 1 pixel per byte)
//-- CRES (text) x0 = no colour attributes
//--             x1 = colour attributes enabled
//-- $FF9A BRDER (543210) border colour (6 bit RGB) non-compatible mode only
//-- $FF9B (10) VBANK - not required
//-- $FF9C (3210) vertical scroll register
//-- $FF9D vertical offset MSB (location * 2048) limits to lower 512KB
//-- $FF9E vertical offset LSB (location * 8)
//-- $FF9F horizontal offset HVEN [7] | X offset (location * 2) [6..0]
//-- HVEN 0 = HRES used
//--      1 = 256 byte virtual screen width
//-- X applies only when HVEN = 1
//-- $FFA0-A7 MMU1 bank registers
//-- $FFA8-AF MMU2 bank registers
//-- $FFB0-BF palette registers (543210) high RGB [5..3] | low RGB [2..0] (note 2 bits per channel)
//-- note - expand to use full 8 bits to add extra bit to Red and Green
//-- $FFD8-D9 CPU clock rate D8 = slow, D9 = fast
//-- $FFDE-DF Memory Map type DE = mixed | DF = ram
//
//-- SAM original
//-- $FFC0-C5 V reg
//-- $FFC6-D3 F reg
//-- $FFD4-D5 P1 reg
//-- $FFD6-D7 CPU clock rate
//
//-- nZ0 is simply Z[0] inverted.  Convenient if using 16 bit SRAM.
//
//-- SLOW cycles
//
//-- OSCin	_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\
//-- OSCout	‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/
//-- Time		 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
//-- E		_____________________________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\__
//-- Q		_____________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\__________________
//--
//-- A*, RnW	XXXXXXXXX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀X
//--
//-- S0-2		XXXXXXXXXX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀
//--
//-- DA0		🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀XXXXXXXXX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀
//--
//-- VClk		____/‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾\___
//--
//-- Z0-18	XX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀X🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀
//--
//-- RAS0#	_________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________________________________
//-- GE#		‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________________________/‾‾
//-- CE#		‾‾‾‾‾\_______/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________/‾‾
//-- WE#		‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________/‾‾
//-- Time		 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
//
//-- FAST cycles
//
//-- OSCin	_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\
//-- OSCout	‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/
//-- Time		 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
//-- E		_________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\______
//-- Q		_/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\______________
//--
//-- A*, RnW      🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀XXXXX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀XXXXX
//--
//-- S0-2         X🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀XXXXX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀XXXX
//--
//-- DA0		🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀XXXXXXXXX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀
//--
//-- VClk		____/‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾\___
//--
//-- Z0-18	🮀🮀🮀🮀🮀🮀X🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀XXXXX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀X🮀🮀
//--
//-- RAS0#	_____/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\______________________________________
//-- GE#		‾‾‾‾‾‾‾‾‾\_______________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________/‾‾‾‾‾‾
//-- CE#		‾\____/‾‾‾‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾
//-- WE#		‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾
//-- Time		 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
//
//-- One machine cycle comprises 16 oscillator cycles (T0--TF), during which
//-- there is a video RAM fetch and one or two CPU cycles (depending on
//-- configured CPU rate).  Most operation is synchronous with the oscillator,
//-- but changes in A13--A15 are immediately reflected in S0--S2.
//
//-- The MC6809E datasheet documents the ``Address Delay Time'' (tAD) in the BUS
//-- TIMING CHARACTERISTICS table.  This tells us that the next address from the
//-- CPU should be available 3 (2.8) oscillator periods after E falls during
//-- a slow cycle or 2 (1.44) periods during a fast cycle.  Transition points
//-- between SLOW and FAST mode should be chosen with care:
//
//-- In a SLOW cycle, video memory access is between T1 and T3, with nRAS0 rising
//-- at T2 to latch the data.  CPU memory access is between TC and TF.  Any
//-- decision to transition to FAST cycles is taken at TC, which results in
//-- truncating E by one cycle.
//
//-- In a FAST cycle, video memory access is between TF and T1, with nRAS0 rising
//-- at T1 to latch the data.  CPU memory accesses are between T4 and T6, and
//-- between TC and TE.  Decisions to transition from FAST to SLOW taken at T0
//-- and T8, with either delaying CPU access until next machine cycle.
//
//-- This does not provide for the ``Read Data Hold Time'' (tDHR) mentioned in
//-- the MC6809E datasheet.  It does not appear to be necessary, and things are
//-- an awful lot simpler this way.
//
//-- If DA0 transitions outside the window TA--TC, VClk is stopped until TB to
//-- resynchronise the VDG. (see below)
//
//-- TODO:
//-- 1) Increase VClk frequency to double speed - allows video clocking to operate
//-- only on a single edge (done)
//-- 2) Disable vclk sync error as it shouldn't be needed any more (done)
//-- 3) Provide positive sync signal to vdg so that vclk sync is no longer needed (done)
//-- 4) Extend F register to include upper 1.5MB
//-- 5) Optional - extend V register to provide alternative operation modes, no need
//-- to increase pixel clock but a double data rate would allow more colours per mode
//-- this may require a more complex IO mechanism to ensure CPU only sees CPU data
//-- 6) Optional - address space allocation for palette registers (now 12 bit RGB)
//-- 7) Disable RAS0 signal (no longer required due to vertical integration) or
//-- repurpose to operate a latch for CPU data...


module vsamx(
	input OscOut,
	output E,
	output Q,

	input [15:0] A,
	input [7:0] D,
	input RnW,

	output reg [7:0] VD,
	output [2:0] S,
	output [20:0] Z, 		// SAM address
	output nZ0,  			// inverted Z0
	output nRAS0,  		// VRAM latch (rising edge)
	output nCE,  			// SRAM chip enable
	output nWE, 			// SRAM write enable

// RAM to CPU data bus control
	output nGE, 			// CPU data gate enable
	output GDIR, 			// CPU data gate direction

// VClk being held low for 8 cycles of OscOut implies
// external reset. - not required giben the presence of board reset signal
	output VClk, 			// 100Ω to nER
	input nER, 				//external reset
	input DA0,				// 10K pullup, probably not needed
	input nHS,				
			  
// Video Control
	output VC_EN,			// video compatible (1=std)
	output [127:0] PDEF, // palette definition 16 x 8 bit RGB entries
	output [1:0] CRES,	// colour resolution = bits per pixel
	output [2:0] LPR,		// lines per row
	output [1:0] LPF,		// lines per field
	output FMT,				// video format
	output BP,				// bitmap mode
	output [2:0] HRES,	// horizontal resolution
	output [7:0] BRDR,	// border colour
	output VideoLoadClock,
	input VR					// video speed rate (0=std, 1=fast)
);

//	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//	-- -- Registers
//
//	-- V: VDG addressing mode
//	-- Mode		    Division	Bits cleared on HS#
//	-- V2 V1 V0		 X   Y
//	--  0  0  0     1  12           B1-B4
//	--  0  0  1     3   1           B1-B3
//	--  0  1  0     1   3           B1-B4
//	--  0  1  1     2   1           B1-B3
//	--  1  0  0     1   2           B1-B4
//	--  1  0  1     1   1           B1-B3
//	--  1  1  0     1   1           B1-B4
//	--  1  1  1     1   1           None (DMA MODE)
//	
//	-- alternatively use the GIME style registers to define video behaviour and ignore
//	-- the V register values when compatibility mode is disabled
	
	wire [2:0] V;

//	-- F: VDG address offset.  Extends the 7 bits of the original to 14
//	-- bits, allowing a base address anywhere in the 512K in multiples of
//	-- 32 bytes.
	wire [18:3] F;
	
	wire VC;
	
	wire MMU_EN;

//	-- R: CPU rate.
	wire R;

//	-- TY: Map type.  0 selects 32K RAM, 32K ROM.  1 selects 64K RAM.
	wire TY;
	
// Selected mpu page (managed by SamRegisters)
	wire [7:0] mpu_page;

//	-- Task register.
	wire TASK;

//	-- Fixed 4K areas at top of RAM (second half of page 31).  Bit
//	-- 0 controls $F000--$FEFF (and vector area), bit 1 controls
//	-- $E000--$EFFF.
	wire [1:0] COMMON;
	
//	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//	-- -- Timing

	wire BOSC;	// buffered clock input

//	-- Internal port signals
	wire E_i;
	wire Q_i;
	wire [20:0] Z_i;

//	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//	-- -- Address multiplexer

	wire z_cpu;
	wire z_video;
	
//	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//	-- -- Reset

	wire VClk_BOSC_div2_d;
	wire VClk_BOSC_div2_q;
	wire VClk_BOSC_div4_d;
	wire VClk_BOSC_div4_q;
	wire IR;
	wire ER;
	wire IER;
	wire HR;  // Horizontal Reset
	reg DA0_nq;
	wire IER_or_VP;  // Vertical Pre-load
	
//	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//	-- -- VDG

//	-- Video address counter
	wire [18:1] B;
	wire [15:0] Y;
	wire [6:0] X;
	wire [6:0] VRES;
	wire HVEN;
	wire MOCH;
	wire H50;
	wire BPI;
	
//	-- Counters, dividers

	wire is_DMA;

	wire use_xdiv3;
	wire use_xdiv2;
	wire use_xdiv1;
	wire xdiv3_out;
	wire xdiv2_out;
	reg clock_b4;

	wire use_ydiv12;
	wire use_ydiv3;
	wire use_ydiv2;
	wire use_ydiv1;
	wire ydiv12_out;
	wire ydiv3_out;
	wire ydiv2_out;
	reg clock_b5;
	
//	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//	-- -- Address decoding

//	-- IO, SAM registers, IRQ vectors
	assign is_FFxx = A[15:8] == 8'b11111111;
	assign is_IRQ = is_FFxx & A[7:4] == 3'b1111;
	assign is_COMMON = (((COMMON[0] == 1'b1 & A[15:12] == 4'b1111) | (COMMON[1] == 1'b1 & A[15:12] == 4'b1110)) & (is_IRQ | ~is_FFxx));

//	-- RAM
	assign is_RAM = A[15] == 1'b0 | (TY == 1'b1 & ~is_FFxx);

			  
	DeviceSelect devices (
		.clk(BOSC),
		.TY(TY),
		.A(A),
		.COMMON(COMMON),
		.S(S)
	);

//	-- ADVANCED SAM FEATURES (based on CoCo3 GIME)

//	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//	-- -- Registers
	
	SamRegisters registers (
		.clk(BOSC),
		.A(A),
		.D(D),
		.RWn(RnW),
		.RSTn(IER),
		.Q(Q_i),
		.V(V),
		.F(F),
		.VC(VC),
		.MMU_EN(MMU_EN),
		.R(R),
		.TY(TY),
		.TASK(TASK),
		.COMMON(COMMON),
		.Y(Y),
		.X(X),
		.LPR(LPR),
		.LPF(LPF),
		.HRES(HRES),
		.CRES(CRES),
		.BRDR(BRDR),
		.HVEN(HVEN),
		.MOCH(MOCH),
		.H50(H50),
		.FMT(FMT),
		.BP(BP),
		.BPI(BPI),
		.page(mpu_page),
		.PDEF(PDEF)
	);
	
//	-- Latching register writes on the falling edge of Q makes other timing a lot simpler.  In particular, when to open the CPU data gate.

//	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//	-- -- Timing

//	-- Buffered Oscillator - used for all internal timing references
	assign BOSC = OscOut;

//	-- Buffered outputs
	assign E = E_i;
	assign Q = Q_i;

//	-- Pass through RnW to RAM (on nWE) for latter half of E high (CPU
//	-- cycle) only for RAM accesses.  This is still in plenty of time for
//	-- our SRAM.
	assign nWE = (E_i == 1'b1 & is_RAM == 1'b1) ? RnW : 1'b1;
	
//	-- CPU data bus gate.  Only enable for writes or while reading from RAM.
	assign nGE = (IER == 1'b1) ? 1'b1 : (~z_cpu) ? 1'b1 : (is_IRQ & RnW == 1'b0) ? 1'b1 : (E_i == 1'b1 & RnW == 1'b0) ? 1'b0 : (E_i == 1'b1 & (is_RAM | is_COMMON)) ? 1'b0 : 1'b1;

//	-- CPU data bus gate direction (inverted RnW)
	assign GDIR = ~RnW;
	
//	-- This is the main state machine, advanced by BOSC falling edge.
//	-- E and Q timings remain as they are in the original SAM (including
//	-- during transition between SLOW and FAST CPU rate).  However, as fast
//	-- SRAM is now assumed, RAM fetch timings are shortened, and a video
//	-- RAM fetch is performed even during fast cycles.
//	--
//	-- Remember that the NEW state set at each clock transition is what you
//	-- should use when cross-referencing with the datasheet.
//
//	-- Provide video clock signal to synchronise timing
//	-- VideoLoadClock <= '1' when z_video else '0';

	quadrature qclock (
		.OSC(BOSC),
		.R(R),
		.VR(VR),
		.Reset(IER),
		.is_COMMON(is_COMMON),
		.is_RAM(is_RAM),
		.VClk(VClk),
		.Q(Q_i),
		.E(E_i),
		.ZCpu(z_cpu),
		.ZVideo(z_video),
		.VideoLoadClock(VideoLoadClock),
		.nRAS0(nRAS0),
		.nCE(nCE)
	);
	
//	-- differentiate video data from cpu data
//	-- latch on each cycle where z addressing is dedicated to VDG
	always @(BOSC) begin
		if (z_video)
			VD <= D;
	end

//	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//	-- -- Address multiplexer

	assign Z_i[20:13] = (z_video) ? {2'b00, B[18:13]} : (z_cpu & ~MMU_EN & ~is_COMMON) ? {5'd0, A[15:13]} : (z_cpu & ~is_COMMON) ? mpu_page : 8'b11111111;

	assign Z_i[12:0] = (z_cpu) ? A[12:0] : (z_video) ? {B[12:1], DA0} : 13'b1111111111111;

	assign Z = Z_i;
	assign nZ0 = ~Z_i[0];
	
//	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//	-- -- Reset

//	assign VClk_BOSC_div2_d = (BOSC) ? 1'b0 : 1'b1;
//
//	vdiv2 VClk_BOSC_div2 (
//		.clk(VClk_BOSC_div2_d),
//		.q(VClk_BOSC_div2_q),
//		.rst(IER)
//	);
//
//	assign VClk_BOSC_div4_d = ~VClk_BOSC_div2_q;
//
//	vdiv2 VClk_BOSC_div4 (
//		.clk(VClk_BOSC_div4_d),
//		.q(VClk_BOSC_div4_q),
//		.rst(1'b0)
//	);
	
//	-- Note: IR defaults to '1' and is permanently set to '0' halfway
//	-- through a machine cycle.
	assign ER = ~nER; // (nER == 1'b0 & VClk_BOSC_div2_q == 1'b0 & VClk_BOSC_div4_q == 1'b0) ? 1'b1 : 1'b0;
	assign IER = IR | ER;

//	-- Horizontal Reset (HR)

	assign HR = IER | ~nHS;
	
//	-- Vertical Pre-load (VP)

	always @(negedge HR) begin
		DA0_nq <= ~DA0;
	end

//	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//	-- -- VDG

	VCAddressCounter BCounter (
		.DA0(DA0),
		.HR(HR),
		.IER_or_VP(IER_or_VP),
		.V(V),
		.F(F),
		.B(B)
	);
	
	endmodule
