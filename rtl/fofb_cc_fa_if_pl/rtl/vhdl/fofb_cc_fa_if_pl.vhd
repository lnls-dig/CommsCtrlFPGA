----------------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Filename     : fofb_cc_fa_if_pl.vhd
--  Purpose      : FA rate data interface
--  Author       : Lucas Russo
----------------------------------------------------------------------------
--  Copyright (c) 2021 CNPEM
--  All rights reserved.
----------------------------------------------------------------------------
--  Description: This module handles Fast Acquisition interface from
--  a parallel interface. An independent clock FIFO is used for CDC.
-- Data is written into FIFO at ADC clock rate and read by CC at mgt clock
----------------------------------------------------------------------------
--  Limitations & Assumptions:
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.fofb_cc_pkg.all;

-----------------------------------------------
--  Entity declaration
-----------------------------------------------
entity fofb_cc_fa_if_pl is
    generic (
        -- Number of BPMS
        BPMS                    : integer := 1
    );
    port (
        mgtclk_i                : in  std_logic;
        mgtreset_i              : in  std_logic;
        adcclk_i                : in  std_logic;
        adcreset_i              : in  std_logic;

        fa_data_valid_i         : in  std_logic;
        fa_dat_x_i              : in  std_logic_2d_32(BPMS-1 downto 0);
        fa_dat_y_i              : in  std_logic_2d_32(BPMS-1 downto 0);

        timeframe_start_o       : out std_logic;
        bpm_cc_xpos_o           : out std_logic_2d_32(BPMS-1 downto 0);
        bpm_cc_ypos_o           : out std_logic_2d_32(BPMS-1 downto 0)
    );
end fofb_cc_fa_if_pl;

-----------------------------------------------
--  Architecture declaration
-----------------------------------------------
architecture rtl of fofb_cc_fa_if_pl is

constant FIFO_WIDTH         : natural := 64*BPMS;
constant FIFO_SIZE          : natural := 4;
constant FIFO_ALMOST_FULL   : natural := 3;
constant FIFO_ALMOST_EMPTY  : natural := 1;

-----------------------------------------------
-- Signal declaration
-----------------------------------------------
signal adcreset_n           : std_logic;
signal mgtreset_n           : std_logic;

signal bpm_xy_pos_in_fifo   : std_logic_vector(FIFO_WIDTH-1 downto 0);
signal bpm_xy_pos_we        : std_logic;
signal bpm_xy_pos_wr_full   : std_logic;

signal bpm_xy_pos_out_fifo  : std_logic_vector(FIFO_WIDTH-1 downto 0);
signal bpm_xy_pos_out_valid : std_logic;
signal bpm_xy_pos_rd        : std_logic;
signal bpm_xy_pos_rd_empty  : std_logic;

signal bpm_xy_pos_in_flat   : std_logic_vector(FIFO_WIDTH-1 downto 0);
signal bpm_xy_pos_out_flat  : std_logic_vector(FIFO_WIDTH-1 downto 0);

signal bpm_xy_pos_in        : std_logic_2d_64(BPMS-1 downto 0);
signal bpm_xy_pos_out       : std_logic_2d_64(BPMS-1 downto 0);

signal bpm_xpos_out         : std_logic_2d_32(BPMS-1 downto 0);
signal bpm_ypos_out         : std_logic_2d_32(BPMS-1 downto 0);

signal bpm_cc_xpos          : std_logic_2d_32(BPMS-1 downto 0);
signal bpm_cc_ypos          : std_logic_2d_32(BPMS-1 downto 0);

begin

---------------------------------------------------
-- FIFO is used to handle CDC between ADC clock rate
-- and CC clock rate.
---------------------------------------------------

GEN_MERGE_XY_IN : for i in 0 to BPMS-1 generate

bpm_xy_pos_in(i) <= fa_dat_x_i(i) & fa_dat_y_i(i);

end generate;

GEN_FLAT_XY_IN : for i in 0 to BPMS-1 generate

bpm_xy_pos_in_flat(64*(i+1)-1 downto 64*i) <= bpm_xy_pos_in(i);

end generate;

bpm_xy_pos_in_fifo <= bpm_xy_pos_in_flat;
bpm_xy_pos_we <= fa_data_valid_i;

adcreset_n <= not adcreset_i;
mgtreset_n <= not mgtreset_i;

i_fofb_cc_fa_if_pl_fifo: entity work.fofb_cc_async_fwft_fifo
generic map (
    g_data_width              => FIFO_WIDTH,
    g_size                    => FIFO_SIZE,
    g_almost_empty_threshold  => FIFO_ALMOST_EMPTY,
    g_almost_full_threshold   => FIFO_ALMOST_FULL
)
port map(
    -- write port
    wr_clk_i     => adcclk_i,
    wr_rst_n_i   => adcreset_n,
    wr_data_i    => bpm_xy_pos_in_fifo,
    wr_en_i      => bpm_xy_pos_we,
    wr_full_o    => bpm_xy_pos_wr_full,

    -- read port
    rd_clk_i     => mgtclk_i,
    rd_rst_n_i   => mgtreset_n,
    rd_data_o    => bpm_xy_pos_out_fifo,
    rd_valid_o   => bpm_xy_pos_out_valid,
    rd_en_i      => bpm_xy_pos_rd,
    rd_empty_o   => bpm_xy_pos_rd_empty
);

bpm_xy_pos_rd <= '1';
bpm_xy_pos_out_flat <= bpm_xy_pos_out_fifo;

GEN_FLAT_XY_OUT : for i in 0 to BPMS-1 generate

bpm_xy_pos_out(i) <= bpm_xy_pos_out_flat(64*(i+1)-1 downto 64*i);

end generate;

GEN_MERGE_XY_OUT : for i in 0 to BPMS-1 generate

bpm_xpos_out(i) <= bpm_xy_pos_out(i)(63 downto 32);
bpm_ypos_out(i) <= bpm_xy_pos_out(i)(31 downto 0);

end generate;

timeframe_start_o <= bpm_xy_pos_out_valid;
bpm_cc_xpos_o     <= bpm_xpos_out;
bpm_cc_ypos_o     <= bpm_ypos_out;

end rtl;
