----------------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Filename     : fofb_cc_dos.vhd
--  Purpose      : FA rate data interface
--  Author       : Lucas Russo
----------------------------------------------------------------------------
--  Copyright (c) 2021 CNPEM
--  All rights reserved.
----------------------------------------------------------------------------
--  Description: This module checks if the packet is within the current timeframe,
-- discards if it's not or stores in a async FWFT fifo if it is
----------------------------------------------------------------------------
--  Limitations & Assumptions:
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_cc_pkg.all;           -- Diamond FOFB package

-----------------------------------------------
--  Entity declaration
-----------------------------------------------
entity fofb_cc_dos is
    generic (
        FIFO_DATA_WIDTH              : natural;
        FIFO_SIZE                    : natural;
        FIFO_ALMOST_EMPTY_THRESHOLD  : integer;
        FIFO_ALMOST_FULL_THRESHOLD   : integer
    );
    port (
        ext_cc_clk_i                 : in  std_logic;
        ext_cc_rst_n_i               : in  std_logic;
        ext_cc_dat_i                 : in  std_logic_vector((32*PacketSize-1) downto 0);
        ext_cc_dat_val_i             : in  std_logic;

        timeframe_start_o            : out std_logic;

        dos_clk_i                    : in  std_logic;
        dos_rst_n_i                  : in  std_logic;
        dos_data_o                   : out std_logic_vector((32*PacketSize-1) downto 0);
        dos_valid_o                  : out std_logic;
        dos_en_i                     : in  std_logic;
        dos_empty_o                  : out std_logic
    );
end fofb_cc_dos;

-----------------------------------------------
--  Architecture declaration
-----------------------------------------------
architecture rtl of fofb_cc_dos is

signal dos_valid                    : std_logic;

begin

-- Async FIFO for both CDC and buffering data for ARBMUX which
-- is unbuffered
fofb_cc_rx_buffer_extra_lane: entity work.fofb_cc_async_fwft_fifo
generic map (
    g_data_width              => FIFO_DATA_WIDTH,
    g_size                    => FIFO_SIZE,
    g_almost_empty_threshold  => FIFO_ALMOST_EMPTY_THRESHOLD,
    g_almost_full_threshold   => FIFO_ALMOST_FULL_THRESHOLD
)
port map(
    -- write port
    wr_clk_i                  => ext_cc_clk_i,
    wr_rst_n_i                => ext_cc_rst_n_i,
    wr_data_i                 => ext_cc_dat_i,
    wr_en_i                   => ext_cc_dat_val_i,

    -- read port
    rd_clk_i                  => dos_clk_i,
    rd_rst_n_i                => dos_rst_n_i,
    rd_data_o                 => dos_data_o,
    rd_valid_o                => dos_valid,
    rd_en_i                   => dos_en_i,
    rd_empty_o                => dos_empty_o
);

dos_valid_o <= dos_valid;
-- it doesn't matter if this signal is not 1-cc long, nor that
-- we will possibly generate more than 1 in a timeframe. frame_cntrl
-- will only use the first timeframe_start signal detected
timeframe_start_o <= dos_valid;

end rtl;
