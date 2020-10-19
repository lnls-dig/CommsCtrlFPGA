----------------------------------------------------------------------------
--  Project      : Diamond Diamond FOFB Communication Controller
--  Filename     : fofb_cc_v5_clk_if.vhd
--  Purpose      : Clock and reset interface logic
--  Author       : Isa S. Uzun
----------------------------------------------------------------------------
--  Copyright (c) 2007 Diamond Light Source Ltd.
--  All rights reserved.
----------------------------------------------------------------------------
--  Description: This module receives differential input clock for
--  CC design, and generates user clk, and reset outputs for Virtex5
--  For more details on RocketIO clocking, please have a look at:
--      UG196 Virtex-5 FPGA RocketIO GTP Transceiver User Guide
----------------------------------------------------------------------------
--  Limitations & Assumptions:
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_cc_pkg.all;-- DLS FOFB package

library unisim;
use unisim.vcomponents.all;

-----------------------------------------------
--  Entity declaration
-----------------------------------------------
entity fofb_cc_v5_clk_if is
    port (
        -- Differential GT clock inputs
        refclk_n_i              : in  std_logic;
        refclk_p_i              : in  std_logic;
        -- System level clock and reset inputs
        txoutclk_i              : in  std_logic;
        plllkdet_i              : in  std_logic;
        -- System level clock and reset outputs
        refclk_o                : out std_logic;
        initclk_o               : out std_logic;
        userclk_o               : out std_logic;
        userclk_2x_o            : out std_logic;
        mgtreset_o              : out std_logic;
        gtreset_o               : out std_logic
    );
end fofb_cc_v5_clk_if;

architecture rtl of fofb_cc_v5_clk_if is

-----------------------------------------------
-- Signal declaration
-----------------------------------------------
signal refclk               : std_logic;
signal refclk_i             : std_logic;
signal dcm_reset            : std_logic;
signal txoutclk_to_dcm      : std_logic;
signal dcm_clkdiv1          : std_logic;
signal dcm_clkdiv2          : std_logic;
signal init_reset           : std_logic;
signal dcm_locked           : std_logic;
signal tied_to_ground       : std_logic;
signal tied_to_vcc          : std_logic;
signal clkfb                : std_logic;
signal clkdv                : std_logic;
signal clk0                 : std_logic;

begin

--  Static signal Assigments
tied_to_ground <= '0';
tied_to_vcc <= '1';

-- Output assignments
refclk_o     <= refclk;
userclk_o    <= dcm_clkdiv2;    -- 106.25MHz
userclk_2x_o <= dcm_clkdiv1;    -- 212.5 MHz
gtreset_o    <= not init_reset;
mgtreset_o   <= not dcm_locked;
initclk_o    <= '0';

-- Differential clock input for MGT/GTP
refclk_ibufds : IBUFGDS
port map (
    O   => refclk_i,
    I   => refclk_p_i,
    IB  => refclk_n_i
);

-- This buffer is required for CC GTPs becuase they are
-- not clocked by dedicated clocks
refclk_bufg : BUFG
port map (
    I   => refclk_i,
    O   => refclk
);

-- Debouncer for GT reset output
-- Initial reset to GTP using init_clk
SRL16_dcmreset : SRL16
port map    (
    Q                   => init_reset,
    A0                  => '1',
    A1                  => '1',
    A2                  => '1',
    A3                  => '1',
    CLK                 => refclk,
    D                   => '1'
);

-- Clock input to DCM comes from GTP_DUAL txoutclk
-- which is 2 x refclk (212.5MHz)
txoutclk_dcm0_bufg : BUFG
port map (
    I   => txoutclk_i,
    O   => txoutclk_to_dcm
);

-- DCM reset
dcm_reset <= not plllkdet_i;

-----------------------------------------------
-- Instantiate a DCM module to divide the reference clock.
-----------------------------------------------
i_clock_divider : DCM
generic map (
    CLKDV_DIVIDE            => 2.0,
    DFS_FREQUENCY_MODE      => "LOW",
    DLL_FREQUENCY_MODE      => "HIGH"
)
port map (
    CLK0                    => clk0,
    CLK180                  => open,
    CLK270                  => open,
    CLK2X                   => open,
    CLK2X180                => open,
    CLK90                   => open,
    CLKDV                   => clkdv,
    CLKFX                   => open,
    CLKFX180                => open,
    LOCKED                  => dcm_locked,
    PSDONE                  => open,
    STATUS                  => open,
    CLKFB                   => clkfb,
    CLKIN                   => txoutclk_to_dcm,
    DSSEN                   => '0',
    PSCLK                   => '0',
    PSEN                    => '0',
    PSINCDEC                => '0',
    RST                     => dcm_reset
);

dcm_1x_bufg_i : BUFG
port map (
    I                       => clk0,
    O                       => clkfb
);

dcm_clkdiv1  <=  clkfb;

dcm_div2_bufg_i : BUFG
port map (
    I                       => clkdv,
    O                       => dcm_clkdiv2
);

end rtl;
