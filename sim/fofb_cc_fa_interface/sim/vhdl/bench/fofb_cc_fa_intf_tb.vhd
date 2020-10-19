library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.ALL;

library work;
use work.fofb_cc_pkg.all;
use work.test_interface.all;

entity fofb_cc_fa_intf_tb IS
generic (
    BLK_DW                  : integer := 32;
    BLK_SIZE                : integer := 16;
    BPMS                    : integer := 4;
    DMUX                    : integer := 1
);
end fofb_cc_fa_intf_tb;

ARCHITECTURE behavior OF fofb_cc_fa_intf_tb IS 

signal mgt_clk              : std_logic := '0';
signal adc_clk              : std_logic := '0';
signal adc_rst              : std_logic := '1';
signal mgt_rst              : std_logic := '1';

signal fa_block_start       : std_logic;
signal fa_data_valid        : std_logic;
signal fa_dat               : std_logic_vector(BLK_DW-1 downto 0);

signal timeframe_start      : std_logic;
signal bpm_cc_xpos          : std_logic_2d_32(BPMS-1 downto 0);
signal bpm_cc_ypos          : std_logic_2d_32(BPMS-1 downto 0);

begin

mgt_clk <= not mgt_clk after 5 ns;
adc_clk <= not adc_clk after 4 ns;
mgt_rst <= '0' after 100 ns;
adc_rst <= '0' after 100 ns;

-- Instantiate the Unit Under Test (UUT)
uut: entity work.fofb_cc_fa_if
generic map (
    BLK_DW              => BLK_DW,
    BLK_SIZE            => BLK_SIZE,
    BPMS                => BPMS,
    DMUX                => DMUX
)
port map(
    mgtclk_i            => mgt_clk,
    mgtreset_i          => mgt_rst,
    adcclk_i            => adc_clk,
    adcreset_i          => adc_rst,

    fa_block_start_i    => fa_block_start,
    fa_data_valid_i     => fa_data_valid,
    fa_dat_i            => fa_dat,

    fa_x_psel_i         => X"7",
    fa_y_psel_i         => X"8",

    timeframe_start_o   => timeframe_start,
    bpm_cc_xpos_o       => bpm_cc_xpos,
    bpm_cc_ypos_o       => bpm_cc_ypos
);

stim_proc : process
begin
    fa_block_start <= '0';
    fa_data_valid <= '0';
    fa_dat <= (others=>'0');

    PROC_TX_CLK_EAT(100, adc_clk);

for N in 1 to 5 loop
    for I in 1 to (BLK_SIZE*BPMS*DMUX) loop
        fa_block_start <= '1';
        fa_data_valid <= '1';
        fa_dat <= std_logic_vector(to_unsigned(I+(100*N),BLK_DW));
        PROC_TX_CLK_EAT(1,adc_clk);
    end loop;

    fa_block_start <= '0';
    fa_data_valid <= '0';
    fa_dat <= (others=>'0');

    PROC_TX_CLK_EAT(1000, adc_clk);

end loop;

    wait;
end process;

end;

