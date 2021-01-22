----------------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Filename     : fofb_cc_fa_if_bram.vhd
--  Purpose      : Fast data acquision interface dual-port BRAM
--  Author       : Lucas Russo
----------------------------------------------------------------------------
--  Copyright (c) 2021 CNPEM.
--  All rights reserved.
----------------------------------------------------------------------------
--  Description: FA data acquision interface dual-port BRAM. This module is
--  used for clock domain crossing from ADC to MGT to read fa rate data
----------------------------------------------------------------------------
--  Limitations & Assumptions:
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-- synthesis translate_off
library unisim;
use unisim.all;
-- synthesis translate_on

-----------------------------------------------
--  Entity declaration
-----------------------------------------------
entity fofb_cc_fa_if_bram is
    generic (
        WR_AW       : integer := 0;
        RD_AW       : integer := 0;
        DMUX        : integer := 0
    );
    port (
        addra       : IN std_logic_vector(WR_AW-1 downto 0);
        addrb       : IN std_logic_vector(RD_AW-1 downto 0);
        ena         : in std_logic;
        enb         : in std_logic;
        clka        : IN std_logic;
        clkb        : IN std_logic;
        dina        : IN std_logic_vector(32/DMUX-1 downto 0);
        doutb       : OUT std_logic_vector(31 downto 0);
        wea         : IN std_logic
    );
end entity;

-----------------------------------------------
--  Architecture declaration
-----------------------------------------------
architecture rtl of fofb_cc_fa_if_bram is

-----------------------------------------------
-- Component declaration
-----------------------------------------------
component fofb_cc_fa_if_bram_16_to_32
    port (
        clka : in STD_LOGIC;
        ena : in STD_LOGIC;
        wea : in STD_LOGIC_VECTOR ( 0 to 0 );
        addra : in STD_LOGIC_VECTOR ( 9 downto 0 );
        dina : in STD_LOGIC_VECTOR ( 15 downto 0 );
        clkb : in STD_LOGIC;
        enb : in STD_LOGIC;
        addrb : in STD_LOGIC_VECTOR ( 8 downto 0 );
        doutb : out STD_LOGIC_VECTOR ( 31 downto 0 )
    );
end component;

component fofb_cc_fa_if_bram_32_to_32
    port (
        clka : in STD_LOGIC;
        ena : in STD_LOGIC;
        wea : in STD_LOGIC_VECTOR ( 0 to 0 );
        addra : in STD_LOGIC_VECTOR ( 8 downto 0 );
        dina : in STD_LOGIC_VECTOR ( 31 downto 0 );
        clkb : in STD_LOGIC;
        enb : in STD_LOGIC;
        addrb : in STD_LOGIC_VECTOR ( 8 downto 0 );
        doutb : out STD_LOGIC_VECTOR ( 31 downto 0 )
    );
end component;

-----------------------------------------------
-- Signal declaration
-----------------------------------------------
signal  addra_i : std_logic_vector(9 downto 0);
signal  addrb_i : std_logic_vector(9 downto 0);

begin

addra_i <= (addra_i'left downto WR_AW => '0') & addra;
addrb_i <= (addra_i'left downto RD_AW => '0') & addrb;

DMUX_2 : if (DMUX = 2) generate
    RAMB16_S18_S36_inst : fofb_cc_fa_if_bram_16_to_32
    port map (
        clka  => clka,
        clkb  => clkb,
        ena   => ena,
        enb   => enb,
        wea   => (others => wea),
        addra => addra_i(9 downto 0),
        addrb => addrb_i(8 downto 0),
        dina   => dina,
        doutb  => doutb
    );
end generate;

DMUX_1 : if (DMUX = 1) generate
    RAMB16_S36_S36_inst : fofb_cc_fa_if_bram_32_to_32
    port map (
        clka  => clka,
        clkb  => clkb,
        ena   => ena,
        enb   => enb,
        wea   => (others => wea),
        addra => addra_i(8 downto 0),
        addrb => addrb_i(8 downto 0),
        dina   => dina,
        doutb  => doutb
    );
end generate;

end;
