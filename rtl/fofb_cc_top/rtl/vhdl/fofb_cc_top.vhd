-----------------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Filename     : fofb_cc_top.vhd
--  Purpose      : FOFB Communication Controller (CC) top level file
--  Author       : Isa S. Uzun
-----------------------------------------------------------------------------
--  Copyright (c) 2007 Diamond Light Source Ltd.
--  All rights reserved.
-----------------------------------------------------------------------------
--  Description: Communication Controller top level module.
-----------------------------------------------------------------------------
--  Limitations & Assumptions:
-----------------------------------------------------------------------------
--  Known Errors: This design is still under test. Please send any bug
--reports to isa.uzun@diamond.ac.uk
-----------------------------------------------------------------------------
--  TO DO List:
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_cc_pkg.all;-- DLS FOFB package

-----------------------------------------------
--  Entity declaration
-----------------------------------------------
entity fofb_cc_top is
    generic (
        -- Default node ID 0-255
        ID                      : integer := 200;
        -- FPGA Device
        DEVICE                  : device_t := BPM;
        USE_DCM                 : boolean := true;
        SIM_GTPRESET_SPEEDUP    : integer := 0;
        INTERLEAVED             : boolean := false;
        -- Extended FAI interface for FOFB
        EXTENDED_CONF_BUF       : boolean := false;
        -- Absolute or Difference position data
        TX_BPM_POS_ABS          : boolean := true;
        -- MGT Interface Parameters
        LANE_COUNT              : integer := 4;
        TX_IDLE_NUM             : integer := 16;
        RX_IDLE_NUM             : integer := 8;
        SEND_ID_NUM             : integer := 14;
        -- BPM Data Interface Parameters
        BPMS                    : integer := 1;
        FAI_DW                  : integer := 16;
        DMUX                    : integer := 2;
        USE_CHIPSCOPE           : boolean := false

    );
    port (
        -- differential MGT/GTP clock inputs
        refclk_p_i              : in std_logic;
        refclk_n_i              : in std_logic;
        -- clock and reset interface
        adcclk_i                : in std_logic;
        adcreset_i              : in std_logic;
        sysclk_i                : in std_logic;
        sysreset_n_i            : in std_logic;
        -- fast acquisition data interface
        fai_fa_block_start_i    : in std_logic;
        fai_fa_data_valid_i     : in std_logic;
        fai_fa_d_i              : in std_logic_vector(FAI_DW-1 downto 0);
        -- FOFB communication controller configuration interface
        fai_cfg_a_o             : out std_logic_vector(10 downto 0);
        fai_cfg_d_o             : out std_logic_vector(31 downto 0);
        fai_cfg_d_i             : in  std_logic_vector(31 downto 0);
        fai_cfg_we_o            : out std_logic;
        fai_cfg_clk_o           : out std_logic;
        fai_cfg_val_i           : in  std_logic_vector(31 downto 0);
        toa_rstb_i              : in  std_logic;
        toa_rden_i              : in  std_logic;
        toa_dat_o               : out std_logic_vector(31 downto 0);
        rcb_rstb_i              : in  std_logic;
        rcb_rden_i              : in  std_logic;
        rcb_dat_o               : out std_logic_vector(31 downto 0);
        fai_rxfifo_clear        : in  std_logic;
        fai_txfifo_clear        : in  std_logic;
        -- serial I/Os for eight RocketIOs on the Libera
        fai_rio_rdp_i           : in  std_logic_vector(LANE_COUNT-1 downto 0);
        fai_rio_rdn_i           : in  std_logic_vector(LANE_COUNT-1 downto 0);
        fai_rio_tdp_o           : out std_logic_vector(LANE_COUNT-1 downto 0);
        fai_rio_tdn_o           : out std_logic_vector(LANE_COUNT-1 downto 0);
        fai_rio_tdis_o          : out std_logic_vector(LANE_COUNT-1 downto 0);
        -- inverse response matrix coefficient buffer i/o
        coeff_x_addr_i          : in  std_logic_vector(7 downto 0);
        coeff_x_dat_o           : out std_logic_vector(31 downto 0);
        coeff_y_addr_i          : in  std_logic_vector(7 downto 0);
        coeff_y_dat_o           : out std_logic_vector(31 downto 0);
        -- Higher-level integration interface (PMC, SNIFFER_V5)
        xy_buf_addr_i           : in  std_logic_vector(NodeW downto 0);
        xy_buf_dat_o            : out std_logic_vector(63 downto 0);
        xy_buf_rstb_i           : in  std_logic;
        timeframe_start_o       : out std_logic;
        timeframe_end_o         : out std_logic;
        fofb_watchdog_i         : in  std_logic_vector(31 downto 0);
        fofb_event_i            : in  std_logic_vector(31 downto 0);
        fofb_process_time_o     : out std_logic_vector(15 downto 0);
        fofb_bpm_count_o        : out std_logic_vector(7 downto 0);
        fofb_dma_ok_i           : in  std_logic;
        fofb_node_mask_o        : out std_logic_vector(NodeNum-1 downto 0);
        fofb_timestamp_val_o    : out std_logic_vector(31 downto 0);
        fofb_link_status_o      : out std_logic_vector(31 downto 0);
        fofb_fod_dat_o          : out std_logic_vector((32*PacketSize-1) downto 0);
        fofb_fod_dat_val_o      : out std_logic_vector(LANE_COUNT-1 downto 0)
);
end fofb_cc_top;

architecture structural of fofb_cc_top is

-----------------------------------------
-- Signal declarations

-- chipscope
signal control              : std_logic_vector(35 downto 0);
signal data                 : std_logic_vector(255 downto 0);
signal trig0                : std_logic_vector(7 downto 0);
--  tx fifo
signal txf_din              : std_logic_vector((32*PacketSize-1) downto 0);
signal txf_wr_en            : std_logic_vector(LANE_COUNT-1 downto 0);
signal txf_rd_en            : std_logic_vector(LANE_COUNT-1 downto 0);
signal txf_empty            : std_logic_vector(LANE_COUNT-1 downto 0);
signal txf_dout             : std_logic_2d_16(LANE_COUNT-1 downto 0);
signal txf_full             : std_logic_vector(LANE_COUNT-1 downto 0);
-- rx fifo
signal rxf_din              : std_logic_2d_16(LANE_COUNT-1 downto 0);
signal rxf_dout             : std_logic_2d_128(LANE_COUNT-1 downto 0);
signal rxf_wr_en            : std_logic_vector(LANE_COUNT-1 downto 0);
signal rxf_rd_en            : std_logic_vector(LANE_COUNT-1 downto 0);
signal rxf_empty            : std_logic_vector(LANE_COUNT-1 downto 0);
signal rxf_empty_n          : std_logic_vector(LANE_COUNT-1 downto 0);
signal rxf_full             : std_logic_vector(LANE_COUNT-1 downto 0);
-- frame status
signal timeframe_count      : std_logic_vector(31 downto 0) := (others=>'0');
signal link_partners        : std_logic_2d_10(3 downto 0);
signal timeframe_dly        : std_logic_vector(15 downto 0);
-- channel status signals
signal linkup               : std_logic_vector(7 downto 0);
signal rx_linkup            : std_logic_vector(3 downto 0);
signal tx_linkup            : std_logic_vector(3 downto 0);
-- system reset
signal rx_fifo_rst          : std_logic_vector(LANE_COUNT-1 downto 0);
signal tx_fifo_rst          : std_logic_vector(LANE_COUNT-1 downto 0);
-- arbmux module connections
signal arbmux_dout          : std_logic_vector((32*PacketSize-1) downto 0);
signal arbmux_dout_rdy      : std_logic;
-- configuration signals
signal mgt_powerdown        : std_logic_vector(3 downto 0);
signal mgt_loopback         : std_logic_vector(7 downto 0);
-- time frame start signals
signal int_timeframe_start  : std_logic := '0';
signal ext_timeframe_start  : std_logic_vector(3 downto 0);
signal timeframe_start      : std_logic := '0';
signal timeframe_end        : std_logic;
signal timeframe_valid      : std_logic;
-- own bpm position
signal bpm_cc_xpos          : std_logic_2d_32(BPMS-1 downto 0);
signal bpm_cc_ypos          : std_logic_2d_32(BPMS-1 downto 0);
-- status info
signal rx_max_data_count    : std_logic_2d_8(3 downto 0);
signal tx_max_data_count    : std_logic_2d_8(3 downto 0);
signal tx_fsm_busy          : std_logic_vector(LANE_COUNT-1 downto 0);
signal rx_fsm_busy          : std_logic_vector(LANE_COUNT-1 downto 0);
signal harderror_cnt        : std_logic_2d_16(3 downto 0);
signal softerror_cnt        : std_logic_2d_16(3 downto 0);
signal frameerror_cnt       : std_logic_2d_16(3 downto 0);
signal rxpck_count          : std_logic_2d_16(3 downto 0);
signal txpck_count          : std_logic_2d_16(3 downto 0);
signal bpm_count            : std_logic_vector(7 downto 0);
signal fodprocess_time      : std_logic_vector(15 downto 0);
signal link_up_i            : std_logic_vector(7 downto 0);
signal golden_orb_x         : std_logic_vector(31 downto 0);
signal golden_orb_y         : std_logic_vector(31 downto 0);
signal ext_timeframe_val    : std_logic_2d_16(3 downto 0);
signal ext_timestamp_val    : std_logic_2d_32(3 downto 0);
signal timestamp_val        : std_logic_vector(31 downto 0);
signal bpmid                : std_logic_vector(NodeW-1 downto 0);
signal timeframelen         : std_logic_vector(15 downto 0);

signal refclk               : std_logic;
signal sysreset             : std_logic;
signal adcreset             : std_logic;
signal txoutclk             : std_logic;
signal plllkdet             : std_logic;
signal userclk              : std_logic;
signal userclk_2x           : std_logic;
signal mgtreset             : std_logic;
signal gtreset              : std_logic;

signal fofb_tfs_override    : std_logic;
signal fai_cfg_act_part     : std_logic;
signal fofb_cc_enable       : std_logic;
signal fofb_err_clear       : std_logic;

signal initclk              : std_logic;
signal initreset            : std_logic;
signal rxpolarity           : std_logic_vector(3 downto 0);
signal fai_psel_val         : std_logic_vector(31 downto 0);
signal fofb_pos_datsel      : std_logic_vector(3 downto 0);

begin

----------------------------------------------
-- Link status information to higher-level
----------------------------------------------
fofb_process_time_o   <= fodprocess_time;
fofb_bpm_count_o      <= bpm_count;
fofb_timestamp_val_o  <= timestamp_val;
fofb_link_status_o <= X"00" & "000000"& link_partners(1) & "0000000" & rx_linkup(1);

fai_cfg_clk_o <= userclk;

----------------------------------------------
-- re-arrange rx and tx channel up outputs
----------------------------------------------
rx_linkup <= linkup(7) & linkup(5) & linkup(3) & linkup(1);
tx_linkup <= linkup(6) & linkup(4) & linkup(2) & linkup(0);
link_up_i <= tx_linkup & rx_linkup;

----------------------------------------------
-- enable all mgt transceivers on digital board
----------------------------------------------
fai_rio_tdis_o <= (others => '0');

----------------------------------------------------------------------
-- timeframe pulses to top level
----------------------------------------------------------------------
timeframe_start_o <= timeframe_start;
timeframe_end_o <= timeframe_end;

----------------------------------------------------------------------
-- reset signals: fai_cfg_val(3) from user is used as user reset
----------------------------------------------------------------------
fofb_tfs_override <= fai_cfg_val_i(4);
fofb_cc_enable <= fai_cfg_val_i(3);
fofb_err_clear <= fai_cfg_val_i(2);
fai_cfg_act_part <= fai_cfg_val_i(0);

sysreset <= mgtreset or not fofb_cc_enable;
adcreset <= adcreset_i;

----------------------------------------------------------------------
-- MGT reference clocks, user clocks and reset interface
----------------------------------------------------------------------
initreset <= not sysreset_n_i;

fofb_cc_clk_if : entity work.fofb_cc_clk_if
port map (
    refclk_n_i              => refclk_n_i,
    refclk_p_i              => refclk_p_i,

    gtreset_i               => initreset,
    txoutclk_i              => txoutclk,
    plllkdet_i              => plllkdet,

    initclk_o               => initclk,
    refclk_o                => refclk,
    mgtreset_o              => mgtreset,
    gtreset_o               => gtreset,

    userclk_o               => userclk,
    userclk_2x_o            => userclk_2x
);

----------------------------------------------------------------------
-- Generate LANE_COUNT Gigabit Transceiver Channels
-- This is an instantiation for wrapper component for various
-- Xilinx Devices support
-- This module reset is not tied to CC enable signal to initialise
-- links even CC is not running
----------------------------------------------------------------------
GT_IF: entity work.fofb_cc_gt_if
generic map (
    DEVICE                  => DEVICE,
    LaneCount               => LANE_COUNT,
    TX_IDLE_NUM             => TX_IDLE_NUM,
    RX_IDLE_NUM             => RX_IDLE_NUM,
    SEND_ID_NUM             => SEND_ID_NUM,
    SIM_GTPRESET_SPEEDUP    => SIM_GTPRESET_SPEEDUP
)
port map (
    refclk_i                => refclk,
    mgtreset_i              => mgtreset,
    initclk_i               => initclk,

    gtreset_i               => gtreset,
    txoutclk_o              => txoutclk,
    plllkdet_o              => plllkdet,
    userclk_i               => userclk,
    userclk_2x_i            => userclk_2x,
    rxpolarity_i            => rxpolarity(LANE_COUNT-1 downto 0),

    rxn_i                   => fai_rio_rdn_i,
    rxp_i                   => fai_rio_rdp_i,
    txn_o                   => fai_rio_tdn_o,
    txp_o                   => fai_rio_tdp_o,

    timeframe_start_i       => timeframe_start,
    timeframe_valid_i       => timeframe_valid,
    timeframe_cntr_i        => timeframe_count(15 downto 0),
    bpmid_i                 => bpmid,

    powerdown_i             => mgt_powerdown,
    loopback_i              => mgt_loopback,
    linksup_o               => linkup,
    harderror_cnt_o         => harderror_cnt,
    softerror_cnt_o         => softerror_cnt,
    frameerror_cnt_o        => frameerror_cnt,
    fofb_err_clear          => fofb_err_clear,

    tx_sm_busy_o            => tx_fsm_busy,
    rx_sm_busy_o            => rx_fsm_busy,

    tfs_bit_o               => ext_timeframe_start,
    link_partner_o          => link_partners,
    pmc_timeframe_val_o     => ext_timeframe_val,
    pmc_timestamp_val_o     => ext_timestamp_val,

    txpck_cnt_o             => txpck_count,
    rxpck_cnt_o             => rxpck_count,

    tx_dat_i                => txf_dout,
    txf_empty_i             => txf_empty,
    txf_rd_en_o             => txf_rd_en,

    rxf_full_i              => rxf_full,
    rx_dat_o                => rxf_din,
    rx_dat_val_o            => rxf_wr_en
);

----------------------------------------------
-- fifo reset module. fifos are flushed at the end
-- of each time rame.
----------------------------------------------
fifo_reset: for N in 0 to (LANE_COUNT - 1) generate
fofb_cc_fifo_rst : entity work.fofb_cc_fifo_rst
port map(
    mgtclk_i                => userclk,
    mgtreset_i              => sysreset,
    tx_linkup_i             => tx_linkup(N),
    rx_linkup_i             => rx_linkup(N),
    timeframe_end_i         => timeframe_end,
    tx_sm_busy_i            => tx_fsm_busy(N),
    rx_sm_busy_i            => rx_fsm_busy(N),
    txfifo_reset_o          => tx_fifo_rst(N),
    rxfifo_reset_o          => rx_fifo_rst(N)
);
end generate;

----------------------------------------------
-- asymetrical rx fifo generation for each mgt channel
-- 16-bit input/128-bit output
----------------------------------------------
RX_FIFO_GEN: for N in 0 to (LANE_COUNT - 1) generate
fofb_cc_rx_buffer_inst : entity work.fofb_cc_rx_buffer
port map (
    din                     => rxf_din(N),
    rd_clk                  => userclk,
    rd_en                   => rxf_rd_en(N),
    rst                     => rx_fifo_rst(N),
    wr_clk                  => userclk,
    wr_en                   => rxf_wr_en(N),
    dout                    => rxf_dout(N),
    empty                   => rxf_empty(N),
    full                    => rxf_full(N),
    reset                   => fai_rxfifo_clear,
    timeframe_valid_i       => timeframe_valid,
    max_data_count          => rx_max_data_count(N)
);
end generate;

----------------------------------------------
-- cc input buffer arbiter. inputs are connected to
-- rx fifo.
----------------------------------------------
fofb_cc_arbmux : entity work.fofb_cc_arbmux
generic map (
    LaneCount               => LANE_COUNT
)
port map (
    mgt_clk                 => userclk,
    mgt_rst                 => sysreset,
    data_in                 => rxf_dout,
    data_in_rdy             => rxf_empty_n,
    rx_fifo_rd_en           => rxf_rd_en,
    channel_up              => rx_linkup(LANE_COUNT-1 downto 0),
    data_out                => arbmux_dout,
    data_out_rdy            => arbmux_dout_rdy,
    timeframe_valid_i       => timeframe_valid
);

rxf_empty_n <= not rxf_empty;

-------------------------------------------------
-- CC forward or discard (fod) module
-------------------------------------------------
fofb_cc_fod : entity work.fofb_cc_fod
generic map (
    BPMS                    => BPMS,
    DEVICE                  => DEVICE,
    INTERLEAVED             => INTERLEAVED,
    LaneCount               => LANE_COUNT
)
port map (
    mgtclk_i                => userclk,
    sysclk_i                => sysclk_i,
    mgtreset_i              => sysreset,
    timeframe_valid_i       => timeframe_valid,
    timeframe_start_i       => timeframe_start,
    timeframe_end_i         => timeframe_end,
    timeframe_dly_i         => timeframe_dly,
    linksup_i               => tx_linkup(LANE_COUNT-1 downto 0),
    fod_dat_i               => arbmux_dout,
    fod_dat_val_i           => arbmux_dout_rdy,
    fod_dat_o               => txf_din,
    fod_dat_val_o           => txf_wr_en,
    timeframe_cntr_i        => timeframe_count,
    bpm_x_pos_i             => bpm_cc_xpos,
    bpm_y_pos_i             => bpm_cc_ypos,
    timestamp_val_i         => timestamp_val,
    pos_datsel_i            => fofb_pos_datsel(BPMS-1 downto 0),
    toa_rstb_i              => toa_rstb_i,
    toa_rden_i              => toa_rden_i,
    toa_dat_o               => toa_dat_o,
    rcb_rstb_i              => rcb_rstb_i,
    rcb_rden_i              => rcb_rden_i,
    rcb_dat_o               => rcb_dat_o,
    txf_full_i              => txf_full,
    bpmid_i                 => bpmid,
    xy_buf_dout_o           => xy_buf_dat_o,
    xy_buf_addr_i           => xy_buf_addr_i,
    xy_buf_rstb_i           => xy_buf_rstb_i,
    xy_buf_long_en_i        => '0',
    fodprocess_time_o       => fodprocess_time,
    bpm_count_o             => bpm_count,
    golden_orb_x_i          => golden_orb_x,
    golden_orb_y_i          => golden_orb_y,
    fofb_watchdog_i         => fofb_watchdog_i,
    fofb_event_i            => fofb_event_i,
    fofb_dma_ok_i           => fofb_dma_ok_i,
    fofb_node_mask_o        => fofb_node_mask_o
);

fofb_fod_dat_o <= txf_din;
fofb_fod_dat_val_o <= txf_wr_en;

-------------------------------------------------
-- tx fifo generation for each mgt channel
-- 128-bit input/16-bit output
-------------------------------------------------
TX_FIFO_GEN: for N in 0 to (LANE_COUNT - 1) generate
fofb_cc_tx_buffer_inst : entity work.fofb_cc_tx_buffer
port map (
    din                     => txf_din,
    wr_clk                  => userclk,
    rd_clk                  => userclk,
    rd_en                   => txf_rd_en(N),
    rst                     => tx_fifo_rst(N),
    wr_en                   => txf_wr_en(N),
    dout                    => txf_dout(N),
    empty                   => txf_empty(N),
    full                    => txf_full(N),
    reset                   => fai_txfifo_clear,
    timeframe_valid_i       => timeframe_valid,
    max_data_count          => tx_max_data_count(N)
);
end generate;

----------------------------------------------
-- Configuration interface module
----------------------------------------------
fofb_cc_cfg_if : entity work.fofb_cc_cfg_if
generic map (
    ID                      => ID,
    EXTENDED_CONF_BUF       => EXTENDED_CONF_BUF
)
port map(
    mgtclk_i                => userclk,
    mgtreset_i              => mgtreset,
    fai_cfg_act_part_i      => fai_cfg_act_part,
    fai_cfg_a_o             => fai_cfg_a_o,
    fai_cfg_do_o            => fai_cfg_d_o,
    fai_cfg_di_i            => fai_cfg_d_i,
    fai_cfg_we_o            => fai_cfg_we_o,
    bpmid_o                 => bpmid,
    timeframe_len_o         => timeframelen,
    powerdown_o             => mgt_powerdown,
    loopback_o              => mgt_loopback,
    timeframe_dly_o         => timeframe_dly,
    rxpolarity_o            => rxpolarity,
    fai_psel_val_o          => fai_psel_val,
    fofb_dat_sel_o          => fofb_pos_datsel,
    pmc_heart_beat_i        => X"00000000",
    link_partners_i         => link_partners,
    link_up_i               => link_up_i,
    timeframe_cnt_i         => timeframe_count(15 downto 0),
    harderror_cnt_i         => harderror_cnt,
    softerror_cnt_i         => softerror_cnt,
    frameerror_cnt_i        => frameerror_cnt,
    rxpck_cnt_i             => rxpck_count,
    txpck_cnt_i             => txpck_count,
    bpmcount_i              => bpm_count,
    fodprocess_time_i       => fodprocess_time,
    rx_max_data_count_i     => rx_max_data_count,
    tx_max_data_count_i     => tx_max_data_count,
    coeff_x_addr_i          => coeff_x_addr_i,
    coeff_x_dat_o           => coeff_x_dat_o,
    coeff_y_addr_i          => coeff_y_addr_i,
    coeff_y_dat_o           => coeff_y_dat_o,
    golden_x_orb_o          => golden_orb_x,
    golden_y_orb_o          => golden_orb_y,
    fai_cfg_val_i           => fai_cfg_val_i
);

----------------------------------------------
-- fa interface module, removed by synthesizer for PMC
----------------------------------------------
fofb_cc_fa_if : entity work.fofb_cc_fa_if
generic map (
    BLK_DW                  => FAI_DW,
    BPMS                    => BPMS,
    DMUX                    => DMUX
)
port map(
    mgtclk_i                => userclk,
    adcclk_i                => adcclk_i,
    adcreset_i              => adcreset,
    mgtreset_i              => sysreset,
    fa_block_start_i        => fai_fa_block_start_i,
    fa_data_valid_i         => fai_fa_data_valid_i,
    fa_dat_i                => fai_fa_d_i,
    fa_psel_i               => fai_psel_val,
    timeframe_start_o       => int_timeframe_start,
    bpm_cc_xpos_o           => bpm_cc_xpos,
    bpm_cc_ypos_o           => bpm_cc_ypos
);

----------------------------------------------
-- Control module for tfs inputs from libera and mgts
----------------------------------------------
fofb_cc_frame_cntrl : entity work.fofb_cc_frame_cntrl
generic map (
    DEVICE                  => DEVICE,
    LaneCount               => LANE_COUNT
)
port map(
    mgtclk_i                => userclk,
    mgtreset_i              => sysreset,
    tfs_bpm_i               => int_timeframe_start,
    tfs_pmc_i               => ext_timeframe_start,
    tfs_override_i          => fofb_tfs_override,
    timeframe_len_i         => timeframelen,
    timeframe_valid_o       => timeframe_valid,
    timeframe_start_o       => timeframe_start,
    timeframe_end_o         => timeframe_end,
    pmc_timeframe_cntr_i    => ext_timeframe_val,
    pmc_timestamp_val_i     => ext_timestamp_val,
    timeframe_cntr_o        => timeframe_count,
    timestamp_value_o       => timestamp_val
);

CSCOPE_GEN : if (USE_CHIPSCOPE = true) generate

ila_core_inst : entity work.ila_t8_d256_s16384
port map (
  clk             => userclk,
  probe0          => data,
  probe1          => trig0
);

trig0(0)          <= fai_fa_block_start_i;
trig0(1)          <= fai_fa_data_valid_i;
trig0(2)          <= timeframe_valid;
trig0(3)          <= timeframe_start;
trig0(4)          <= timeframe_end;
trig0(5)          <= txf_wr_en(0);
trig0(6)          <= int_timeframe_start;
trig0(7)          <= '0';

data(15 downto 0) <= fai_fa_d_i;
data(16)          <= fai_fa_block_start_i;
data(17)          <= fai_fa_data_valid_i;
data(18)          <= txf_wr_en(0);
data(19)          <= int_timeframe_start;

data(31 downto 20) <= (others => '0');

data(63 downto 32)   <= txf_din(31 downto 0);
data(95 downto 64)   <= txf_din(63 downto 32);
data(127 downto 96)  <= txf_din(95 downto 64);
data(159 downto 128) <= txf_din(127 downto 96);

data(191 downto 160) <= bpm_cc_xpos(0);
data(223 downto 192) <= bpm_cc_ypos(0);

data(255 downto 224) <= (others => '0');

end generate;

end structural;
