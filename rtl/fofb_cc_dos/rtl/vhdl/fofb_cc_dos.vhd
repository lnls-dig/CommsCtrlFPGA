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

        timeframe_start_i            : in std_logic;
        timeframe_valid_i            : in std_logic;
        timeframe_count_i            : in std_logic_vector(15 downto 0);

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

signal ext_cc_dat_d1                : std_logic_vector((32*PacketSize-1) downto 0);
signal ext_cc_dat_val_d1            : std_logic;

begin

-- Check if packet is within a valid timeframe and if the
-- packet timestamp belongs in the current timeframe.
p_discard_or_store : process(ext_cc_clk_i)
begin
    if rising_edge(ext_cc_clk_i) then
        if ext_cc_rst_n_i = '0' then
            ext_cc_dat_d1 <= (others => '0');
            ext_cc_dat_val_d1 <= '0';
        else
            if (ext_cc_dat_i(def_PacketTimeframeCntr16MSB downto
                             def_PacketTimeframeCntr16MSB) = timeframe_count_i and
                    timeframe_valid_i = '1') then
                ext_cc_dat_d1 <= ext_cc_dat_i;
                ext_cc_dat_val_d1 <= ext_cc_dat_val_i;
            else
                ext_cc_dat_val_d1 <= '0';
            end if;
        end if;
    end if;
end process;

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
    wr_data_i                 => ext_cc_dat_d1,
    wr_en_i                   => ext_cc_dat_val_d1,

    -- read port
    rd_clk_i                  => dos_clk_i,
    rd_rst_n_i                => dos_rst_n_i,
    rd_data_o                 => dos_data_o,
    rd_valid_o                => dos_valid_o,
    rd_en_i                   => dos_en_i,
    rd_empty_o                => dos_empty_o
);

end rtl;
