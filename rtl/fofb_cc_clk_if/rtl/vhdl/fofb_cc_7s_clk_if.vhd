----------------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Filename     : fofb_cc_7s_clk_if.vhd
--  Purpose      : Clock and reset interface logic
--  Author       : Daniel Tavares (CNPEM/Sirius)
----------------------------------------------------------------------------
--  Based on code provided by Diamond Light Source Ltd. and made publicly
--  available at https://github.com/dls-controls/CommsCtrlFPGA
----------------------------------------------------------------------------
--  Description: This module receives differential input clock for
--  CC design, and generates user clk, and reset outputs for 7-Series
--  FPGA family.
--  For more details on RocketIO clocking, please have a look at:
--      UG482 7 Series FPGAs GTP Transceivers User Guide
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
entity fofb_cc_clk_if is
    generic (
        -- FPGA Device
        DEVICE                  : device_t := BPM;
        USE_DCM                 : boolean := true
    );
    port (
        refclk_n_i              : in  std_logic;
        refclk_p_i              : in  std_logic;
        -- system interface
        gtreset_i               : in  std_logic;
        txoutclk_i              : in  std_logic;
        plllkdet_i              : in  std_logic;
        -- clocks and resets
        initclk_o               : out std_logic;
        refclk_o                : out std_logic;
        mgtreset_o              : out std_logic;
        gtreset_o               : out std_logic;
        -- user clocks
        userclk_o               : out std_logic;
        userclk_2x_o            : out std_logic
    );
end fofb_cc_clk_if;

architecture rtl of fofb_cc_clk_if is

-----------------------------------------------
-- Signal declaration
-----------------------------------------------
signal refclk               : std_logic;
signal userclk              : std_logic;
signal tied_to_ground       : std_logic;
signal mgtreset             : std_logic;

begin

--  Static signal Assigments
tied_to_ground <= '0';

----------------------
-- 7-series Interface
----------------------

-- Output assignments
refclk_o     <= refclk;
userclk_o    <= userclk;        -- 156.25MHz
userclk_2x_o <= userclk;        -- 156.25MHz
initclk_o    <= tied_to_ground;
gtreset_o    <= tied_to_ground;
mgtreset_o   <= mgtreset;

-- Differential clock input for 7-series GTP
refclk_ibufds : IBUFDS_GTE2
    port map (
        O   => refclk,
        I   => refclk_p_i,
        IB  => refclk_n_i
        ODIV2   => open,
        CEB     => '0',
    );

user_clock_bufg : BUFG
    port map (
        I => txoutclk_i,  -- UG482 (v1.9) pag. 79 - Fig. 3-3: Multiple Lanes — TXOUTCLK Drives TXUSRCLK2 (2-Byte Mode)
        O => userclk
    );

-- Initial reset is based on external reset
process(gtreset_i, userclk)
    variable cnt    : unsigned(4 downto 0) := "00000";
begin
    if (gtreset_i = '1') then
        mgtreset <= '1';
--    elsif rising_edge(refclk) then
    elsif rising_edge(userclk) then
        if (cnt(4) = '1') then
            mgtreset <= '0';
        else
            cnt := cnt + 1;
            mgtreset <= '1';
        end if;
    end if;
end process;



end rtl;
