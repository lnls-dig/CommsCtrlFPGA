------------------------------------------------------------------------------
-- Title      : BPM FWFT FIFO conversion
------------------------------------------------------------------------------
-- Author     : Lucas Maziero Russo
-- Company    : CNPEM LNLS-DIG
-- Created    : 2013-22-10
-- Platform   : FPGA-generic
-------------------------------------------------------------------------------
-- Description: Module for converting a standard FIFO into a FWFT (First word
--                fall through) FIFO
-------------------------------------------------------------------------------
-- Copyright (c) 2013 CNPEM
-- Licensed under GNU Lesser General Public License (LGPL) v3.0
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2014-12-09  1.0      lucas.russo        Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fofb_cc_pkg.all;

entity fofb_cc_async_fwft_fifo is
generic
(
  g_data_width                              : natural;
  g_size                                    : natural;

  g_with_rd_empty                           : boolean := true;
  g_with_rd_full                            : boolean := false;
  g_with_rd_almost_empty                    : boolean := false;
  g_with_rd_almost_full                     : boolean := false;
  g_with_rd_count                           : boolean := false;

  g_with_wr_empty                           : boolean := false;
  g_with_wr_full                            : boolean := true;
  g_with_wr_almost_empty                    : boolean := false;
  g_with_wr_almost_full                     : boolean := false;
  g_with_wr_count                           : boolean := false;

  g_almost_empty_threshold                  : integer;
  g_almost_full_threshold                   : integer
);
port
(
  -- Write clock
  wr_clk_i                                  : in  std_logic;
  wr_rst_n_i                                : in  std_logic;

  wr_data_i                                 : in  std_logic_vector(g_data_width-1 downto 0);
  wr_en_i                                   : in  std_logic;
  wr_full_o                                 : out std_logic;
  wr_count_o                                : out std_logic_vector(log2_size(g_size)-1 downto 0);
  wr_almost_empty_o                         : out std_logic;
  wr_almost_full_o                          : out std_logic;

  -- Read clock
  rd_clk_i                                  : in  std_logic;
  rd_rst_n_i                                : in  std_logic;

  rd_data_o                                 : out std_logic_vector(g_data_width-1 downto 0);
  rd_valid_o                                : out std_logic;
  rd_en_i                                   : in  std_logic;
  rd_empty_o                                : out std_logic;
  rd_count_o                                : out std_logic_vector(log2_size(g_size)-1 downto 0);
  rd_almost_empty_o                         : out std_logic;
  rd_almost_full_o                          : out std_logic
);
end fofb_cc_async_fwft_fifo;

architecture rtl of fofb_cc_async_fwft_fifo is

  -- Signals
  signal rst_n                              : std_logic;

  signal fwft_rd_en                         : std_logic;
  signal fwft_rd_valid                      : std_logic;
  signal fwft_rd_empty                      : std_logic;

  signal fifo_count_int                     : std_logic_vector(log2_size(g_size)-1 downto 0);
  signal fifo_almost_empty_int              : std_logic;
  signal fifo_almost_full_int               : std_logic;

begin

  cmp_fwft_async_fifo : entity work.fofb_cc_async_fifo
  generic map (
    g_data_width                            => g_data_width,
    g_size                                  => g_size,

    g_with_rd_empty                         => g_with_rd_empty,
    g_with_rd_full                          => g_with_rd_full,
    g_with_rd_almost_empty                  => g_with_rd_almost_empty,
    g_with_rd_almost_full                   => g_with_rd_almost_full,
    g_with_rd_count                         => g_with_rd_count,

    g_with_wr_empty                         => g_with_wr_empty,
    g_with_wr_full                          => g_with_wr_full,
    g_with_wr_almost_empty                  => g_with_wr_almost_empty,
    g_with_wr_almost_full                   => g_with_wr_almost_full,
    g_with_wr_count                         => g_with_wr_count,

    g_almost_empty_threshold                => g_almost_empty_threshold,
    g_almost_full_threshold                 => g_almost_full_threshold
  )
  port map(
    rst_n_i                                 => rst_n,

    clk_wr_i                                => wr_clk_i,
    d_i                                     => wr_data_i,
    we_i                                    => wr_en_i,
    wr_count_o                              => wr_count_o,
    wr_almost_empty_o                       => wr_almost_empty_o,
    wr_almost_full_o                        => wr_almost_full_o,

    clk_rd_i                                => rd_clk_i,
    q_o                                     => rd_data_o,
    rd_i                                    => fwft_rd_en,
    rd_count_o                              => rd_count_o,
    rd_almost_empty_o                       => rd_almost_empty_o,
    rd_almost_full_o                        => rd_almost_full_o,

    rd_empty_o                              => fwft_rd_empty,
    wr_full_o                               => wr_full_o
  );

  rst_n <= wr_rst_n_i and rd_rst_n_i;

  -- First Word Fall Through (FWFT) implementation
  fwft_rd_en <= not(fwft_rd_empty) and (not(fwft_rd_valid) or rd_en_i);

  p_fwft_rd_valid : process (rd_clk_i) is
  begin
    if rising_edge(rd_clk_i) then
      if rd_rst_n_i = '0' then
         fwft_rd_valid <= '0';
      else
        if fwft_rd_en = '1' then
           fwft_rd_valid <= '1';
        elsif rd_en_i = '1' then
           fwft_rd_valid <= '0';
        end if;
      end if;
    end if;
  end process;

  -- This is the actual valid flag for this FIFO
  rd_valid_o <= fwft_rd_valid;

  -- Output assignments
  rd_empty_o <= fwft_rd_empty;

end rtl;
