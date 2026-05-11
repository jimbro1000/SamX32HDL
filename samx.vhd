-- SAMx MMU

-- (C) 2023-2025 Ciaran Anscomb
--
-- Released under the Creative Commons Attribution-ShareAlike 4.0
-- International License (CC BY-SA 4.0).  Full text in the LICENSE file.

-- A small MMU intended to be combined with fast SRAM and replace the SN74LS783
-- Synchronous Address Multiplexer + DRAM in a Dragon 64.

-- Primary reference is the datasheet for the SN74LS783.

-- SAMx8 MMU changes the following functionality of the SAMx4:
--
--  - No DRAM support (refresh, muxed addresses, organisation).
--  - Only SLOW and FAST CPU rates supported.
--  - Video still supported in FAST mode.
--  - VDG address "glitch" support removed.
--  - Page bit repurposed as TASK selector.
--  - Two sets (per-task) of 4 * 16K arbitrary page mapping.
--  - Lower RAM size bit repurposed to enable common 4K/8K at top of RAM.
--  - D0--D7 connected for writes to extra registers.

-- Page registers accept 5-bit values 0-31, identifying a 16K page within the
-- 512K SRAM.

-- Address	Function			Default
-- $FF30	Page for $0000--$3FFF, TASK 0	0
-- $FF31	Page for $4000--$7FFF, TASK 0	1
-- $FF32	Page for $8000--$BFFF, TASK 0	2
-- $FF33	Page for $C000--$FEFF, TASK 0	3
-- $FF34	Page for $0000--$3FFF, TASK 1	2
-- $FF35	Page for $4000--$7FFF, TASK 1	3
-- $FF36	Page for $8000--$BFFF, TASK 1	2
-- $FF37	Page for $C000--$FEFF, TASK 1	3
-- $FF38	F13--F18 (6 bits of VRAM base)	0
-- $FF39	F5--F12 (8 bits of VRAM base)	0
-- $FF3F	COMMON (bits 0--1)		0

-- Setting bit 0 of COMMON forces the top 4K ($F000--$FEFF and the vector area
-- $FFE0--$FFFF) to be mapped to page 31 whatever other configuration is in
-- place.  Setting bit 1 does the same for the next 4K down ($E000--$EFFF).
-- The vector area is still read-only and in map type 0, so is the rest,
-- however modifications can be made by mapping 31 elsewhere.

-- GIME registers of interest
-- $FF90 (76) Compatible Mode | MMU Enabled
-- $FF91 (0) MMU Task
-- $FF98 VMODE (7543210) A/G | Invert Artifacts | Monochrome | H50 50/60Hz | lines per row [2..0]
-- LPR 00x = one line per row
--     010 = two lines per row
--     011 = eight lines per row
--     100 = nine lines per row
--     101 = ten lines per row
--     110 = eleven lines per row
--     111 = one line per screen (infinite lines per row)
-- $FF99 VRES (654321) lines per field [6..5] | horizontal res [4..2] | colour res [1..0]
-- LPF 00 = 192 scan lines on screen
--     01 = 200 scan lines on screen
--     10 = undefined (zero/infinite)
--     11 = 225 scan lines on screen
-- HRES (graphics) 000 = 16 bytes per row
--                 001 = 20 bytes per row
--                 010 = 32 bytes per row
--                 011 = 40 bytes per row
--                 100 = 64 bytes per row
--                 101 = 80 bytes per row
--                 110 = 128 bytes per row
--                 111 = 160 bytes per row
-- HRES (text) 0x0 = 32 bytes per row
--             0x1 = 40 bytes per row
--             1x0 = 64 bytes per row
--             1x1 = 80 bytes per row
-- CRES (graphics) 00 = 2 colours (8 pixels per byte)
--                 01 = 4 colours (4 pixels per byte)
--                 10 = 16 colours (2 pixels per byte)
--                 11 = undefines (should be 1 pixel per byte)
-- CRES (text) x0 = no colour attributes
--             x1 = colour attributes enabled
-- $FF9A BRDER (543210) border colour (6 bit RGB) non-compatible mode only
-- $FF9B (10) VBANK - not required
-- $FF9C (3210) vertical scroll register
-- $FF9D vertical offset MSB (location * 2048) limits to lower 512KB
-- $FF9E vertical offset LSB (location * 8)
-- $FF9F horizontal offset HVEN [7] | X offset (location * 2) [6..0]
-- HVEN 0 = HRES used
--      1 = 256 byte virtual screen width
-- X applies only when HVEN = 1
-- $FFA0-A7 MMU1 bank registers
-- $FFA8-AF MMU2 bank registers
-- $FFB0-BF palette registers (543210) high RGB [5..3] | low RGB [2..0] (note 2 bits per channel)
-- note - expand to use full 8 bits to add extra bit to Red and Green
-- $FFD8-D9 CPU clock rate D8 = slow, D9 = fast
-- $FFDE-DF Memory Map type DE = mixed | DF = ram

-- SAM original
-- $FFC0-C5 V reg
-- $FFC6-D3 F reg
-- $FFD4-D5 P1 reg
-- $FFD6-D7 CPU clock rate

-- nZ0 is simply Z[0] inverted.  Convenient if using 16 bit SRAM.

-- SLOW cycles

-- OSCin	_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\
-- OSCout	‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/
-- Time		 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
-- E		_____________________________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\__
-- Q		_____________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\__________________
--
-- A*, RnW	XXXXXXXXX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀X
--
-- S0-2		XXXXXXXXXX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀
--
-- DA0		🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀XXXXXXXXX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀
--
-- VClk		____/‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾\___
--
-- Z0-18	XX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀X🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀
--
-- RAS0#	_________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________________________________
-- GE#		‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________________________/‾‾
-- CE#		‾‾‾‾‾\_______/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________/‾‾
-- WE#		‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________/‾‾
-- Time		 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F

-- FAST cycles

-- OSCin	_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\
-- OSCout	‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/
-- Time		 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
-- E		_________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\______
-- Q		_/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\______________
--
-- A*, RnW      🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀XXXXX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀XXXXX
--
-- S0-2         X🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀XXXXX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀XXXX
--
-- DA0		🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀XXXXXXXXX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀
--
-- VClk		____/‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾\___
--
-- Z0-18	🮀🮀🮀🮀🮀🮀X🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀XXXXX🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀🮀X🮀🮀
--
-- RAS0#	_____/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\______________________________________
-- GE#		‾‾‾‾‾‾‾‾‾\_______________/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______________/‾‾‾‾‾‾
-- CE#		‾\____/‾‾‾‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾
-- WE#		‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\_______/‾‾‾‾‾‾
-- Time		 0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F

-- One machine cycle comprises 16 oscillator cycles (T0--TF), during which
-- there is a video RAM fetch and one or two CPU cycles (depending on
-- configured CPU rate).  Most operation is synchronous with the oscillator,
-- but changes in A13--A15 are immediately reflected in S0--S2.

-- The MC6809E datasheet documents the ``Address Delay Time'' (tAD) in the BUS
-- TIMING CHARACTERISTICS table.  This tells us that the next address from the
-- CPU should be available 3 (2.8) oscillator periods after E falls during
-- a slow cycle or 2 (1.44) periods during a fast cycle.  Transition points
-- between SLOW and FAST mode should be chosen with care:

-- In a SLOW cycle, video memory access is between T1 and T3, with nRAS0 rising
-- at T2 to latch the data.  CPU memory access is between TC and TF.  Any
-- decision to transition to FAST cycles is taken at TC, which results in
-- truncating E by one cycle.

-- In a FAST cycle, video memory access is between TF and T1, with nRAS0 rising
-- at T1 to latch the data.  CPU memory accesses are between T4 and T6, and
-- between TC and TE.  Decisions to transition from FAST to SLOW taken at T0
-- and T8, with either delaying CPU access until next machine cycle.

-- This does not provide for the ``Read Data Hold Time'' (tDHR) mentioned in
-- the MC6809E datasheet.  It does not appear to be necessary, and things are
-- an awful lot simpler this way.

-- If DA0 transitions outside the window TA--TC, VClk is stopped until TB to
-- resynchronise the VDG. (see below)

-- TODO:
-- 1) Increase VClk frequency to double speed - allows video clocking to operate
-- only on a single edge
-- 2) Disable vclk sync error as it shouldn't be needed any more (done)
-- 3) Provide positive sync signal to vdg so that vclk sync is no longer needed (done)
-- 4) Extend F register to include upper 1.5MB
-- 5) Optional - extend V register to provide alternative operation modes, no need
-- to increase pixel clock but a double data rate would allow more colours per mode
-- this may require a more complex IO mechanism to ensure CPU only sees CPU data
-- 6) Optional - address space allocation for palette registers (now 12 bit RGB)
-- 7) Disable RAS0 signal (no longer required due to vertical integration) or
-- repurpose to operate a latch for CPU data...

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity samx is
	port (
		     -- No OscIn pin: if a crystal is to be used, the circuit
		     -- to present it as a nice square clock should be
		     -- external.
		     OscOut : in std_logic;
		     E : out std_logic;
		     Q : out std_logic;

		     A : in std_logic_vector(15 downto 0);
		     D : in std_logic_vector(7 downto 0);
		     RnW : in std_logic;

			  VD : out std_logic_vector(7 downto 0);
		     S : out std_logic_vector(2 downto 0);
		     Z : out std_logic_vector(20 downto 0);  -- SRAM address
		     nZ0: out std_logic;  -- inverted Z(0)
		     nRAS0 : out std_logic;  -- VRAM latch (rising edge)
		     nCE : out std_logic;  -- SRAM chip enable
		     nWE : out std_logic;  -- SRAM write enable

		     -- RAM to CPU data bus control
		     nGE : out std_logic;  -- CPU data gate enable
		     GDIR : out std_logic;  -- CPU data gate direction

		     -- VClk being held low for 8 cycles of OscOut implies
		     -- external reset.
		     VClk : out std_logic;  -- 100Ω to nER
		     nER : in std_logic;  -- external reset
		     DA0 : in std_logic;  -- 10K pullup, probably not needed
		     nHS : in std_logic;
			  
			  -- Video Control
			  VC_EN : out std_logic; -- video compatible (1=std)
			  PDEF : out std_logic_vector (127 downto 0); -- palette def
			  CRES : out std_logic_vector (1 downto 0); -- bits per pixel
			  LPR : out std_logic_vector (2 downto 0); -- lines per row
			  LPF : out std_logic_vector (1 downto 0); -- lines per field
			  FMT : out std_logic; -- video format
			  BP : out std_logic; -- bitmap mode
			  HRES : out std_logic_vector (2 downto 0); -- horizontal res
			  BRDR : out std_logic_vector (7 downto 0); -- border colour
			  VideoLoadClock : out std_logic;
			  VR : in std_logic -- video speed request
	     );
end;

architecture rtl of samx is

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Address decoding

	-- IO, SAM registers, IRQ vectors
	signal is_FFxx : boolean;
	signal is_IO0 : boolean;
	signal is_IO1 : boolean;
	signal is_IO2 : boolean;
	signal is_FF3x : boolean;
	signal is_FF9x : boolean;
	signal is_FFAx : boolean;
	signal is_FFBx : boolean;
	--signal is_FFDx : boolean;
	signal is_SAM_REG : boolean;
	signal is_IRQ_VEC : boolean;

	-- Upper 32K, excluding IO, etc.
	signal is_COMMON0 : boolean;
	signal is_COMMON1 : boolean;
	signal is_COMMON : boolean;
	signal is_ROM0 : boolean;
	signal is_ROM1 : boolean;
	signal is_ROM2 : boolean;

	-- RAM, including upper 32K in map type 1
	signal is_RAM : boolean;

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Registers

	-- V: VDG addressing mode
	-- Mode		    Division	Bits cleared on HS#
	-- V2 V1 V0		 X   Y
	--  0  0  0     1  12           B1-B4
	--  0  0  1     3   1           B1-B3
	--  0  1  0     1   3           B1-B4
	--  0  1  1     2   1           B1-B3
	--  1  0  0     1   2           B1-B4
	--  1  0  1     1   1           B1-B3
	--  1  1  0     1   1           B1-B4
	--  1  1  1     1   1           None (DMA MODE)
	
	-- assume V extended to 4 bits for custom modes
	-- V3 V2 V1 V0  X   Y
	--  1  0  0  0  1   8			  B1-B4 (custom 8 row text mode)
	--  1  0  0  1  3   1			  B1-B4 (double data rate for VDG)
	--  1  0  1  0  1   3			  B1-B5 (")
	--  1  0  1  1  2   1           B1-B4
	--  1  1  0  0  1   2           B1-B5
	--  1  1  0  1  1   1           B1-B4
	--  1  1  1  0  1   1           B1-B5
	--  1  1  1  1  1   1           None (double data rate dma mode)
	
	-- alternatively use the GIME style registers to define video behaviour and ignore
	-- the V register values when compatibility mode is disabled
	
	signal V : std_logic_vector(2 downto 0); -- := (others => '0');

	-- F: VDG address offset.  Extends the 7 bits of the original to 14
	-- bits, allowing a base address anywhere in the 512K in multiples of
	-- 32 bytes.
	signal F : std_logic_vector(18 downto 5); -- := (others => '0');
	signal FA : std_logic_vector(18 downto 3); -- := (others => '0');
	signal VC : std_logic; -- := '1';
	signal MMU_EN : std_logic; -- := '0';
--	signal INIT0 : std_logic_vector(7 downto 0) := "11000000";

	-- R: CPU rate.
	signal R : std_logic; -- := '0';

	-- TY: Map type.  0 selects 32K RAM, 32K ROM.  1 selects 64K RAM.
	signal TY : std_logic; -- := '0';

	-- DAT registers

	-- Page select.  Which of 32 × 16K sections of RAM is mapped into each
	-- of 8 × 8K CPU address regions (× 2 TASKs).
--	type page_map_array is array (0 to 15) of std_logic_vector(7 downto 0);
--	constant INIT_PAGE_MAP : page_map_array := (
--		"00000000", "00000001", "00000010", "00000011",
--		"00000100", "00000101", "00000110", "00000111",
--		"00000000", "00000001", "00000010", "00000011",
--		"00000100", "00000101", "00000110", "00000111"
--	);
--	signal page_map : page_map_array := INIT_PAGE_MAP;

--	signal mpu_page : integer range 0 to 15;
	signal mpu_page : std_logic_vector(7 downto 0);

	-- Task register.
	signal TASK : std_logic := '0';

	-- Fixed 4K areas at top of RAM (second half of page 31).  Bit
	-- 0 controls $F000--$FEFF (and vector area), bit 1 controls
	-- $E000--$EFFF.
	signal COMMON : std_logic_vector(1 downto 0); -- := (others => '0');

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Timing

	-- Reference time
	--type time_ref is (T0, T1, T2, T3, T4, T5, T6, T7, T8, T9, TA, TB, TC, TD, TE, TF);
	signal BOSC : std_logic;
	--signal T : time_ref := T7;
	--signal fast_cycle : boolean := false;
	--signal fast_video : boolean := false;

	-- Internal port signals
	signal E_i : std_logic := '0';
	signal Q_i : std_logic := '0';
	signal Z_i : std_logic_vector(20 downto 0);

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Address multiplexer

	signal z_cpu : boolean := false;
	signal z_video : boolean := true;

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Reset

	signal VClk_BOSC_div2_d : std_logic;
	signal VClk_BOSC_div2_q : std_logic;
	signal VClk_BOSC_div4_d : std_logic;
	signal VClk_BOSC_div4_q : std_logic;
	signal IR : std_logic := '1';
	signal ER : std_logic;
	signal IER : std_logic;
	signal HR : std_logic;  -- Horizontal Reset
	signal DA0_nq : std_logic := '0';
	signal IER_or_VP : std_logic;  -- Vertical Pre-load

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- VDG

	-- Video address counter
	signal B : std_logic_vector(18 downto 1) := (others => '0');
	signal Y : std_logic_vector(15 downto 0); -- := (others => '0');
	signal X : std_logic_vector(6 downto 0); -- := (others => '0');
	--signal VMODE : std_logic_vector(7 downto 0) := (others => '0');
	signal VRES : std_logic_vector(6 downto 0); -- := (others => '0');
	--signal HOR : std_logic_vector(7 downto 0) := (others => '0');
	signal HVEN : std_logic := '0';
	signal MOCH : std_logic := '0';
	signal H50 : std_logic := '0';
	signal BPI : std_logic := '0';
	
	-- Synchronisation
	--signal vdg_da0_window : boolean;
	--signal vdg_start : boolean;
	--signal vdg_sync_error : boolean := false;

	-- Counters, dividers

	signal is_DMA       : boolean;

	signal use_xdiv3    : std_logic;
	signal use_xdiv2    : std_logic;
	signal use_xdiv1    : std_logic;
	signal xdiv3_out    : std_logic;
	signal xdiv2_out    : std_logic;
	signal clock_b4     : std_logic := '0';

	signal use_ydiv12   : std_logic;
	signal use_ydiv3    : std_logic;
	signal use_ydiv2    : std_logic;
	signal use_ydiv1    : std_logic;
	signal ydiv12_out   : std_logic;
	signal ydiv3_out    : std_logic;
	signal ydiv2_out    : std_logic;
	signal clock_b5     : std_logic := '0';
	
	COMPONENT Quadrature
	PORT (
		OSC : IN STD_LOGIC;
		R : IN STD_LOGIC;
		VR : IN STD_LOGIC;
		Reset : IN STD_LOGIC;
		is_COMMON : IN boolean;
		is_RAM : IN boolean;
		VClk : OUT STD_LOGIC;
		Q : OUT STD_LOGIC;
		E : OUT STD_LOGIC;
		ZCpu : OUT boolean;
		ZVideo : OUT boolean;
		VideoLoadClock : OUT STD_LOGIC;
		nRAS0 : OUT STD_LOGIC;
		nCE : OUT STD_LOGIC
	);
	END COMPONENT;
	
	COMPONENT SamRegisters
	PORT (
		clk : IN STD_LOGIC;
		A : IN STD_LOGIC_VECTOR(15 downto 0);
		D : IN STD_LOGIC_VECTOR(7 downto 0);
		RWn : IN STD_LOGIC;
		RSTn : IN STD_LOGIC;
		Q : IN STD_LOGIC;
		
		V : OUT STD_LOGIC_VECTOR(2 downto 0);
		F : OUT STD_LOGIC_VECTOR(18 downto 5);
		FA : OUT STD_LOGIC_VECTOR(18 downto 3);
		VC : OUT STD_LOGIC;
		MMU_EN : OUT STD_LOGIC;
		R : OUT STD_LOGIC;
		TY : OUT STD_LOGIC;
		TASK : OUT STD_LOGIC;
		COMMON : OUT STD_LOGIC_VECTOR(1 downto 0);
		Y : OUT STD_LOGIC_VECTOR(15 downto 0);
		X : OUT STD_LOGIC_VECTOR(6 downto 0);
		LPR : OUT STD_LOGIC_VECTOR(2 downto 0);
		LPF : OUT STD_LOGIC_VECTOR(1 downto 0);
		HRES : OUT STD_LOGIC_VECTOR(2 downto 0);
		CRES : OUT STD_LOGIC_VECTOR(1 downto 0);
		BRDR : OUT STD_LOGIC_VECTOR(7 downto 0);
		HVEN : OUT STD_LOGIC;
		MOCH : OUT STD_LOGIC;
		H50 : OUT STD_LOGIC;
		FMT : OUT STD_LOGIC;
		BP : OUT STD_LOGIC;
		BPI : OUT STD_LOGIC;
		page : OUT STD_LOGIC_VECTOR(7 downto 0);
		PDEF : OUT STD_LOGIC_VECTOR(127 downto 0)
	);
	END COMPONENT;
	
	COMPONENT vdiv2
	PORT (
		clk : IN STD_LOGIC;
		rst : IN STD_LOGIC;
		q : OUT STD_LOGIC
	);
	END COMPONENT;

	COMPONENT vdiv3
	PORT (
		clk : IN STD_LOGIC;
		rst : IN STD_LOGIC;
		q : OUT STD_LOGIC
	);
	END COMPONENT;

	COMPONENT vdiv4
	PORT (
		clk : IN STD_LOGIC;
		rst : IN STD_LOGIC;
		q : OUT STD_LOGIC
	);
	END COMPONENT;

	COMPONENT VCAddressCounter
	PORT (
		DA0 : IN STD_LOGIC;
		HR : IN STD_LOGIC;
		IER_or_VP : IN STD_LOGIC;
		V : IN STD_LOGIC_VECTOR(2 downto 0);
		F : IN STD_LOGIC_VECTOR(18 downto 5);
		B : OUT STD_LOGIC_VECTOR(18 downto 1)
	);
	END COMPONENT;
	
	COMPONENT DeviceSelect
	PORT (
		clk : IN STD_LOGIC;
		TY : IN STD_LOGIC;
		A : IN STD_LOGIC_VECTOR(15 downto 0);
		COMMON : IN STD_LOGIC_VECTOR(1 downto 0);
		S : OUT STD_LOGIC_VECTOR(2 downto 0)
	);
	END COMPONENT;
	
begin

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Address decoding

	-- IO, SAM registers, IRQ vectors
	is_FFxx    <= A(15 downto 8) = "11111111";
--	is_IO0     <= is_FFxx and A(7 downto 5) = "000";   -- FF0x and FF1x
--	is_IO1     <= is_FFxx and A(7 downto 4) = "0010";  -- FF2x ONLY
--	is_FF3x    <= is_FFxx and A(7 downto 4) = "0011";  -- FF3x ONLY
--	is_IO2     <= is_FFxx and A(7 downto 5) = "010";   -- FF4x and FF5x
--	is_FF9x    <= is_FFxx and A(7 downto 4) = "1001";  -- FF9x ONLY
--	is_FFAx    <= is_FFxx and A(7 downto 4) = "1010";  -- FFAx ONLY
--	is_FFBx    <= is_FFxx and A(7 downto 4) = "1011";  -- FFBx ONLY
	--is_FFDx    <= is_FFxx and A(7 downto 4) = "1101";  -- FFDx ONLY
--	is_SAM_REG <= is_FFxx and A(7 downto 5) = "110";   -- FFCx and FFDx
--	is_IRQ_VEC <= is_FFxx and A(7 downto 5) = "111";   -- FFEx and FFFx

--	-- Upper 32K
--	is_COMMON0 <= COMMON(0) = '1' and A(15 downto 12) = "1111";
--	is_COMMON1 <= COMMON(1) = '1' and A(15 downto 12) = "1110";
--	is_COMMON  <= (is_COMMON0 or is_COMMON1) and (is_IRQ_VEC or not is_FFxx);
--	is_ROM0 <= TY = '0' and A(15 downto 13) = "100";
--	is_ROM1 <= TY = '0' and A(15 downto 13) = "101";
--	is_ROM2 <= TY = '0' and A(15 downto 14) = "11" and not is_FFxx;

	-- RAM
	is_RAM  <= A(15) = '0' or (TY = '1' and not is_FFxx);
	
--	S <= -- IO, SAM registers, IRQ vectors
--	     "100" when is_IO0 else
--	     "101" when is_IO1 else
--	     "110" when is_IO2 else
--	     -- RAM for COMMON:
--	     "000" when is_COMMON else
--	     -- ROM1 for IRQ vectors:
--	     "010" when is_IRQ_VEC else
--	     "111" when is_FFxx else
--	     -- Upper 32K in map type 0:
--	     "001" when is_ROM0 else
--	     "010" when is_ROM1 else
--	     "011" when is_ROM2 else
--	     -- RAM
--	     "000";
		  
	devices : DeviceSelect
	port map (
		clk => BOSC,
		TY => TY,
		A => A,
		COMMON => COMMON,
		S => S
	);

	-- ADVANCED SAM FEATURES (based on CoCo3 GIME)

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Registers
	
	registers : SamRegisters
	port map (
		clk => BOSC,
		A => A,
		D => D,
		RWn => RnW,
		RSTn => IER,
		Q => Q_i,
		V => V,
		F => F,
		FA => FA,
		VC => VC,
		MMU_EN => MMU_EN,
		R => R,
		TY => TY,
		TASK => TASK,
		COMMON => COMMON,
		Y => Y,
		X => X,
		LPR => LPR,
		LPF => LPF,
		HRES => HRES,
		CRES => CRES,
		BRDR => BRDR,
		HVEN => HVEN,
		MOCH => MOCH,
		H50 => H50,
		FMT => FMT,
		BP => BP,
		BPI => BPI,
		page => mpu_page,
		PDEF => PDEF
	);

	-- Latching register writes on the falling edge of Q makes other timing a lot simpler.  In particular, when to open the CPU data gate.

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Timing

	-- Buffered Oscillator - used for all internal timing references
	BOSC <= OscOut;

	-- Buffered outputs
	E <= E_i;
	Q <= Q_i;

	-- Pass through RnW to RAM (on nWE) for latter half of E high (CPU
	-- cycle) only for RAM accesses.  This is still in plenty of time for
	-- our SRAM.
	nWE <= RnW when E_i = '1' and is_RAM else '1';

	-- VRAM strobe.  Latches data slightly earlier in fast cycles.
	--nRAS0 <= '1' when fast_cycle and T = T0 else
	--	 '1' when T = T1 or T = T2 or T = T3 or T = T4 or T = T5 else
	--	 '0';

	-- CE# timing.  VRAM fetch and one (SLOW) or two (FAST) CPU accesses
	-- per machine cycle.
	--nCE <= '1' when IER = '1' else
	--       '0' when fast_cycle and (T = TF or T = T0) else
	--       '0' when not fast_cycle and (T = T0 or T = T1) else
	--       '1' when not is_RAM and not is_COMMON else
	--       not (E_i and not Q_i);

	-- CPU data bus gate.  Only enable for writes or while reading from RAM.
	nGE <= '1' when IER = '1' else
	       '1' when not z_cpu else
	       '1' when is_IRQ_VEC and RnW = '0' else
	       '0' when E_i = '1' and RnW = '0' else
	       '0' when E_i = '1' and (is_RAM or is_COMMON) else
	       '1';

	-- CPU data bus gate direction (inverted RnW)
	GDIR <= not RnW;

	-- VDG DA0 transition window open for these states.
	-- vdg_da0_window <= true when T = TA or T = TB else false;

	-- Restart VDG, if stopped
	-- vdg_start <= true when T = TB else false;
	
	-- Provide video clock signal to synchronise timing
	-- VideoLoadClock <= '1' when z_video else '0';

	-- This is the main state machine, advanced by BOSC falling edge.
	-- E and Q timings remain as they are in the original SAM (including
	-- during transition between SLOW and FAST CPU rate).  However, as fast
	-- SRAM is now assumed, RAM fetch timings are shortened, and a video
	-- RAM fetch is performed even during fast cycles.
	--
	-- Remember that the NEW state set at each clock transition is what you
	-- should use when cross-referencing with the datasheet.

	qclock : Quadrature
	port map (
		OSC => BOSC,
		R => R,
		VR => VR,
		Reset => IER,
		is_COMMON => is_COMMON,
		is_RAM => is_RAM,
		VClk => VClk,
		Q => Q_i,
		E => E_i,
		ZCpu => z_cpu,
		ZVideo => z_video,
		VideoLoadClock => VideoLoadClock,
		nRAS0 => nRAS0,
		nCE => nCE
	);
	
	-- differentiate video data from cpu data
	-- latch on each cycle where z addressing is dedicated to VDG
	VD <= D when z_video = true; 

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Address multiplexer

	--mpu_page <= to_integer(unsigned(TASK & A(15 downto 13)));

	Z_i(20 downto 13) <=
		-- VDG
		"00" & B(18 downto 13) when z_video else
		-- MMU disabled
		"00000" & A(15 downto 13) when z_cpu and MMU_EN = '0' and is_COMMON = false else
		-- CPU
		mpu_page when z_cpu and is_COMMON = false else
		-- DEFAULT
		"11111111";

	Z_i(12 downto 0) <=
		-- CPU
		A(12 downto 0) when z_cpu else
		-- VDG
		B(12 downto 1) & DA0 when z_video else
		-- DEFAULT
		"1111111111111";

	Z <= Z_i;
	nZ0 <= not Z_i(0);

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- Reset

	--VClk_BOSC_div2_d <= '0' when not vdg_sync_error and BOSC = '1' else '1';
	VClk_BOSC_div2_d <= '0' when BOSC = '1' else '1';

	VClk_BOSC_div2 : vdiv2
	port map (
			 clk => VClk_BOSC_div2_d,
			 q => VClk_BOSC_div2_q,
			 rst => IER
		 );

	VClk_BOSC_div4_d <= not VClk_BOSC_div2_q;

	VClk_BOSC_div4 : vdiv2
	port map (
			 clk => VClk_BOSC_div4_d,
			 q => VClk_BOSC_div4_q,
			 rst => '0'
		 );

	-- Run pixel clock at full oscillator speed, up to VDG to divide this down, not SAM
	-- suspend for reset only
	-- VClk <= '0' when IER = '0' else BOSC;

	-- Note: IR defaults to '1' and is permanently set to '0' halfway
	-- through a machine cycle.
	ER <= '1' when nER = '0' and VClk_BOSC_div2_q = '0' and VClk_BOSC_div4_q = '0' else '0';
	IER <= IR or ER;

	-- Horizontal Reset (HR)

	HR <= IER or not nHS;

	-- Vertical Pre-load (VP)

	process (HR)
	begin
		if falling_edge(HR) then
			DA0_nq <= not DA0;
		end if;
	end process;

	IER_or_VP <= IER or (HR nor DA0_nq);

	-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
	-- -- VDG

	BCounter : VCAddressCounter
	port map (
		DA0 => DA0,
		HR => HR,
		IER_or_VP => IER_or_VP,
		V => V,
		F => F,
		B => B
	);

end rtl;
