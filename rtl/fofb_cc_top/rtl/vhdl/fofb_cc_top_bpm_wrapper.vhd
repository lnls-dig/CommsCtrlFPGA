library ieee;
use ieee.std_logic_1164.all;

library work;
use work.fofb_cc_pkg.all;

-----------------------------------------------
--  Entity declaration
-----------------------------------------------
entity fofb_cc_top_wrapper is
    port (
        -- differential MGT/GTP clock inputs
        refclk_p_i              : in  std_logic;
        refclk_n_i              : in  std_logic;
        -- clock and reset interface
        adcclk_i                : in  std_logic;
        adcreset_i              : in  std_logic;
        -- fast acquisition data interface
        fai_fa_block_start_i    : in  std_logic;
        fai_fa_data_valid_i     : in  std_logic;
        fai_fa_d_i              : in  std_logic_vector(15 downto 0);
        -- FOFB communication controller configuration interface
        fai_cfg_a_o             : out std_logic_vector(10 downto 0);
        fai_cfg_d_o             : out std_logic_vector(31 downto 0);
        fai_cfg_d_i             : in  std_logic_vector(31 downto 0);
        fai_cfg_we_o            : out std_logic;
        fai_cfg_clk_o           : out std_logic;
        fai_cfg_val_i           : in  std_logic_vector(31 downto 0);
        fai_psel_val_i          : in  std_logic_vector(31 downto 0);
        toa_rstb_i              : in  std_logic;
        toa_rden_i              : in  std_logic;
        toa_dat_o               : out std_logic_vector(31 downto 0);
        rcb_rstb_i              : in  std_logic;
        rcb_rden_i              : in  std_logic;
        rcb_dat_o               : out std_logic_vector(31 downto 0);
        fai_rxfifo_clear        : in  std_logic;
        fai_txfifo_clear        : in  std_logic;
        fofb_cc_enable_o        : out std_logic;
       -- serial I/Os for eight RocketIOs on the Libera
        fai_rio_rdp_i           : in  std_logic_vector(3 downto 0);
        fai_rio_rdn_i           : in  std_logic_vector(3 downto 0);
        fai_rio_tdp_o           : out std_logic_vector(3 downto 0);
        fai_rio_tdn_o           : out std_logic_vector(3 downto 0)
);
end fofb_cc_top_wrapper;

architecture structure of fofb_cc_top_wrapper is
begin

i_fofb_cc_top : entity work.fofb_cc_top
    port map (
        refclk_p_i              => refclk_p_i,
        refclk_n_i              => refclk_n_i,
        adcclk_i                => adcclk_i,
        adcreset_i              => adcreset_i,
        sysclk_i                => '0',
        sysreset_n_i            => '1',
        fai_fa_block_start_i    => fai_fa_block_start_i,
        fai_fa_data_valid_i     => fai_fa_data_valid_i,
        fai_fa_d_i              => fai_fa_d_i   ,
        fai_cfg_a_o             => fai_cfg_a_o  ,
        fai_cfg_d_o             => fai_cfg_d_o  ,
        fai_cfg_d_i             => fai_cfg_d_i  ,
        fai_cfg_we_o            => fai_cfg_we_o ,
        fai_cfg_clk_o           => fai_cfg_clk_o,
        fai_cfg_val_i           => fai_cfg_val_i,
        fai_psel_val_i          => fai_psel_val_i,
        toa_rstb_i              => toa_rstb_i,
        toa_rden_i              => toa_rden_i,
        toa_dat_o               => toa_dat_o,
        rcb_rstb_i              => rcb_rstb_i,
        rcb_rden_i              => rcb_rden_i,
        rcb_dat_o               => rcb_dat_o,
        fai_rxfifo_clear        => fai_rxfifo_clear,
        fai_txfifo_clear        => fai_txfifo_clear,
        fai_rio_rdp_i           => fai_rio_rdp_i,
        fai_rio_rdn_i           => fai_rio_rdn_i,
        fai_rio_tdp_o           => fai_rio_tdp_o,
        fai_rio_tdn_o           => fai_rio_tdn_o,
        fai_rio_tdis_o          => open,
        coeff_x_addr_i          => (others => '0'),
        coeff_x_dat_o           => open,
        coeff_y_addr_i          => (others => '0'),
        coeff_y_dat_o           => open,
        xy_buf_addr_i           => (others => '0'),
        xy_buf_dat_o            => open,
        xy_buf_rstb_i           => '0',
        timeframe_start_o       => open,
        timeframe_end_o         => open,
        fofb_watchdog_i         => (others => '0'),
        fofb_event_i            => (others => '0'),
        fofb_process_time_o     => open,
        fofb_bpm_count_o        => open,
        fofb_dma_ok_i           => '0',
        fofb_node_mask_o        => open,
        fofb_rxlink_up_o        => open,
        fofb_rxlink_partner_o   => open,
        fofb_timestamp_val_o    => open,
        fofb_cc_enable_o        => fofb_cc_enable_o,
        harderror_cnt_o         => open,
        softerror_cnt_o         => open,
        frameerror_cnt_o        => open,
        bpmid_i                 => (others => '0'),
        timeframe_length_i      => (others => '0'),
        pbpm_xpos_0_i           => (others => '0'),
        pbpm_ypos_0_i           => (others => '0'),
        pbpm_xpos_1_i           => (others => '0'),
        pbpm_ypos_1_i           => (others => '0')
    );
end structure;

