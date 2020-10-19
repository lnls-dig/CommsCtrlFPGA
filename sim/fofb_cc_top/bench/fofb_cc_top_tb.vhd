----------------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Filename     : fofb_cc_top_tb.vhd
--  Purpose      : FOFB CC top level testbench file
--  Author        : Isa S. Uzun
----------------------------------------------------------------------------
--  Copyright (c) 2006 Diamond Light Source Ltd.
--  All rights reserved.
----------------------------------------------------------------------------
--  Description: Testbech file for top-level FOFB CC design
----------------------------------------------------------------------------
--  Limitations & Assumptions:
----------------------------------------------------------------------------
--  Known Errors: This design is still under test. Please send any bug
--   reports to isa.uzun@diamond.ac.uk
----------------------------------------------------------------------------
--  History Of Change:
----------------------------------------------------------------------------
--  Version | Date     | Author              | Remarks
--  0.1     | 17.02.05 | I.S. Uzun           | File created
--  1.0    | 22.03.06 | I.S. Uzun            | First release
----------------------------------------------------------------------------
--  Libraries
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- synthesis translate_off
library unisim;
use unisim.all;
-- synthesis translate_on

library modelsim_lib;
use modelsim_lib.util.all;

-- DLS FOFB packages
library work;
use work.fofb_cc_pkg.all;
use work.test_interface.all;

entity fofb_cc_top_tb IS
    generic (
        test_selector       : in string  := String'("fofb_cc_smoke_test");
        -- Configure CC design under test
        DEVICE              : device_t := BPM;
        LANE_COUNT          : natural := 1;      -- Can be only 2 for V5 design
        TX_IDLE_NUM         : natural := 10;
        RX_IDLE_NUM         : natural := 8;
        SEND_ID_NUM         : natural := 14;

        BPMS                : integer:= 4;
        FAI_DW              : integer := 32;
        DMUX                : integer := 1;
        --
        TEST_DURATION       : integer := 5        -- # of time frames to be simulated
    );
end fofb_cc_top_tb;

ARCHITECTURE behavior OF fofb_cc_top_tb IS 

signal sysclk               : std_logic :='0';
signal adcclk               : std_logic :='0';
signal refclk_n             : std_logic :='1';
signal refclk_p             : std_logic :='0';
signal refclk2x             : std_logic :='0';
signal adcreset             : std_logic :='1';
signal fai_fa_block_start   : std_logic :='0';
signal fai_fa_data_valid    : std_logic :='0';
signal fai_fa_d             : std_logic_vector(FAI_DW-1 downto 0);
signal fai_cfg_a            : std_logic_vector(10 downto 0);
signal fai_cfg_do           : std_logic_vector(31 downto 0);
signal fai_cfg_di           : std_logic_vector(31 downto 0);
signal fai_cfg_we           : std_logic :='0';
signal fai_cfg_clk          : std_logic :='0';
signal fai_cfg_val          : std_logic_vector(31 downto 0) := (others => '0');
signal fai_rio_rdp          : std_logic_vector(LANE_COUNT-1 downto 0);
signal fai_rio_rdn          : std_logic_vector(LANE_COUNT-1 downto 0);
signal fai_rio_tdp          : std_logic_vector(LANE_COUNT-1 downto 0);
signal fai_rio_tdn          : std_logic_vector(LANE_COUNT-1 downto 0);
signal fai_rio_rdp1         : std_logic_vector(LANE_COUNT-1 downto 0);
signal fai_rio_rdn1         : std_logic_vector(LANE_COUNT-1 downto 0);
signal fai_rio_tdp1         : std_logic_vector(LANE_COUNT-1 downto 0);
signal fai_rio_tdn1         : std_logic_vector(LANE_COUNT-1 downto 0);
signal fai_rio_tdis         : std_logic_vector(LANE_COUNT-1 downto 0);
signal ext_trig_in          : std_logic :='0';
signal coeff_x_addr         : std_logic_vector(7 downto 0);
signal coeff_x_out          : std_logic_vector(31 downto 0);
signal coeff_y_addr         : std_logic_vector(7 downto 0);
signal coeff_y_out          : std_logic_vector(31 downto 0);
signal fofb_process_time    : std_logic_vector(15 downto 0);
signal fofb_bpm_count       : std_logic_vector(7 downto 0);
signal rxp                  : std_logic;
signal rxn                  : std_logic;
signal txp                  : std_logic;
signal txn                  : std_logic;
signal mgtreset             : std_logic;
signal powerdown            : std_logic := '0';
signal refclk               : std_logic;
signal userclk              : std_logic;
signal userclk_2x           : std_logic;
signal gtreset              : std_logic;
signal txoutclk             : std_logic;
signal plllkdet             : std_logic;
signal timeframe_start      : std_logic;
signal timeframe_end        : std_logic;
signal xy_buf_dat           : std_logic_vector(63 downto 0);
signal xy_buf_addr          : std_logic_vector(NodeW downto 0);
signal xy_buf_rstb          : std_logic;
signal sysreset_n           : std_logic := '0';

begin

sysreset_n <= '1' after 10 us;

---------------------------------------------------------------------
-- Clocks and resets
---------------------------------------------------------------------
sysclk <= not sysclk after 5 ns;

adcclk <= not adcclk after 4 ns;
adcreset <= '0' after 100 ns;

refclk_p <= not refclk_p after 4.705 ns;
refclk_n <= not refclk_p;

i_fofb_cc_top : entity work.fofb_cc_top
    generic map (
        SIM_GTPRESET_SPEEDUP    => 1,
        --
        DEVICE                  => DEVICE,
        --
        LANE_COUNT              => LANE_COUNT,
        BPMS                    => BPMS,
        FAI_DW                  => FAI_DW,
        DMUX                    => DMUX,
        --
        TX_IDLE_NUM             => TX_IDLE_NUM,
        RX_IDLE_NUM             => RX_IDLE_NUM,
        SEND_ID_NUM             => SEND_ID_NUM
    )
    port map(
        refclk_p_i              => refclk_p,
        refclk_n_i              => refclk_n,

        adcclk_i                => adcclk,
        adcreset_i              => adcreset,
        sysclk_i                => sysclk,
        sysreset_n_i            => sysreset_n,

        fai_fa_block_start_i    => fai_fa_block_start,
        fai_fa_data_valid_i     => fai_fa_data_valid,
        fai_fa_d_i              => fai_fa_d,

        fai_cfg_a_o             => fai_cfg_a,
        fai_cfg_d_o             => fai_cfg_do,
        fai_cfg_d_i             => fai_cfg_di,
        fai_cfg_we_o            => fai_cfg_we,
        fai_cfg_clk_o           => fai_cfg_clk,
        fai_cfg_val_i           => fai_cfg_val,

        toa_rstb_i              => '0',
        toa_rden_i              => '0',
        toa_dat_o               => open,
        rcb_rstb_i              => '0',
        rcb_rden_i              => '0',
        rcb_dat_o               => open,
        fai_rxfifo_clear        => '0',
        fai_txfifo_clear        => '0',

        fai_rio_rdp_i           => fai_rio_rdp,
        fai_rio_rdn_i           => fai_rio_rdn,
        fai_rio_tdp_o           => fai_rio_tdp,
        fai_rio_tdn_o           => fai_rio_tdn,
        fai_rio_tdis_o          => fai_rio_tdis,

        coeff_x_addr_i          => coeff_x_addr,
        coeff_x_dat_o           => coeff_x_out,
        coeff_y_addr_i          => coeff_y_addr,
        coeff_y_dat_o           => coeff_y_out,

        xy_buf_addr_i           => xy_buf_addr,
        xy_buf_dat_o            => xy_buf_dat,
        xy_buf_rstb_i           => xy_buf_rstb,
        timeframe_start_o       => timeframe_start,
        timeframe_end_o         => timeframe_end,
        fofb_watchdog_i         => (others => '0'),
        fofb_event_i            => (others => '0'),
        fofb_process_time_o     => fofb_process_time,
        fofb_bpm_count_o        => fofb_bpm_count,
        fofb_dma_ok_i           => '1',
        fofb_node_mask_o        => open,
        fofb_timestamp_val_o    => open
);

tester : entity work.fofb_cc_top_tester
    generic map (
        test_selector           => test_selector,
        --
        DEVICE                  => DEVICE,
        BPMS                    => BPMS,
        FAI_DW                  => FAI_DW,
        DMUX                    => DMUX,
        --
        TX_IDLE_NUM             => TX_IDLE_NUM,
        RX_IDLE_NUM             => RX_IDLE_NUM,
        SEND_ID_NUM             => SEND_ID_NUM,
        --
        TEST_DURATION           => TEST_DURATION
    )
    port map (
        refclk_i                => refclk,
        sysclk_i                => sysclk,

        userclk_i               => userclk,
        userclk_2x_i            => userclk_2x,

        gtreset_i               => gtreset,
        mgtreset_i              => mgtreset,
        adcclk_i                => adcclk,

        txoutclk_o              => txoutclk,
        plllkdet_o              => plllkdet,

        fai_cfg_a_i             => fai_cfg_a,
        fai_cfg_do_i            => fai_cfg_do,
        fai_cfg_di_o            => fai_cfg_di,
        fai_cfg_we_i            => fai_cfg_we,
        fai_cfg_clk_i           => fai_cfg_clk,
        fai_cfg_val_o           => fai_cfg_val,

        fai_fa_block_start_o    => fai_fa_block_start,
        fai_fa_data_valid_o     => fai_fa_data_valid,
        fai_fa_d_o              => fai_fa_d,

        xy_buf_dat_i            => xy_buf_dat,
        xy_buf_addr_o           => xy_buf_addr,
        xy_buf_rstb_o           => xy_buf_rstb,
        timeframe_start_i       => timeframe_start,
        timeframe_end_i         => timeframe_end,

        rxn_i                   => rxn,
        rxp_i                   => rxp,
        txn_o                   => txn,
        txp_o                   => txp
    );

tester_clkgen : entity work.fofb_cc_v5_clk_if
port map (
    refclk_n_i              => refclk_n,
    refclk_p_i              => refclk_p,

    txoutclk_i              => txoutclk,
    plllkdet_i              => plllkdet,

    refclk_o                => refclk,
    initclk_o               => open,
    userclk_o               => userclk,
    userclk_2x_o            => userclk_2x,
    mgtreset_o              => mgtreset,
    gtreset_o               => gtreset
);

fai_rio_rdp(0) <= txp when (powerdown = '0')  else '1';
fai_rio_rdn(0) <= txn when (powerdown = '0')  else '0';

rxp <= fai_rio_tdp(0);
rxn <= fai_rio_tdn(0);

end;
