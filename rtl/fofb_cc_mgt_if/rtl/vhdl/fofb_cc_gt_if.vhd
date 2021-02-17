----------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Filename     :
--  Purpose      : Virtex2Pro MGT interface
--  Responsible  : Isa S. Uzun
----------------------------------------------------------------------
--  Copyright (c) 2007 Diamond Light Source Ltd.
--  All rights reserved.
----------------------------------------------------------------------
--  Description: This is the top-level interface module that instantiates
--  MGT Tile and user logic to interface CC.
----------------------------------------------------------------------
--  Limitations & Assumptions:
----------------------------------------------------------------------
--  Known Errors: Please send any bug reports to isa.uzun@diamond.ac.uk
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.fofb_cc_pkg.all;

entity fofb_cc_gt_if is
    generic (
        DEVICE                  : device_t;
        -- CC Design selection parameters
        LaneCount               : integer := 4;
        TX_IDLE_NUM             : natural := 16;    --32767 cc
        RX_IDLE_NUM             : natural := 13;    --4095 cc
        SEND_ID_NUM             : natural := 14;    --8191 cc
        -- Simulation parameters
        SIM_GTPRESET_SPEEDUP    : integer := 0;     -- Not used
        -- Selection of transceiver reference clock input
        REFCLK_INPUT            : string := "REFCLK0"
    );
    port (
        -- Main clocks and resets
        refclk_i                : in  std_logic;
        mgtreset_i              : in  std_logic;

        -- Main clocks and resets (NOT USED for V2P MGT Interface)
        initclk_i               : in  std_logic;
        gtreset_i               : in  std_logic;
        userclk_i               : in  std_logic;
        userclk_2x_i            : in  std_logic;
        txoutclk_o              : out std_logic;
        plllkdet_o              : out std_logic;

        -- RocketIO
        rxn_i                   : in  std_logic_vector(LaneCount-1 downto 0);
        rxp_i                   : in  std_logic_vector(LaneCount-1 downto 0);
        txn_o                   : out std_logic_vector(LaneCount-1 downto 0);
        txp_o                   : out std_logic_vector(LaneCount-1 downto 0);

        -- time frame sync
        timeframe_start_i       : in  std_logic;
        timeframe_valid_i       : in  std_logic;
        timeframe_cntr_i        : in  std_logic_vector(15 downto 0);
        bpmid_i                 : in  std_logic_vector(9 downto 0);

        -- mgt configuration
        powerdown_i             : in  std_logic_vector(3 downto 0);
        loopback_i              : in  std_logic_vector(7 downto 0);
        rxpolarity_i            : in  std_logic_vector(LaneCount-1 downto 0);
        -- status information
        linksup_o               : out std_logic_vector(7 downto 0);
        frameerror_cnt_o        : inout std_logic_2d_16(3 downto 0);
        softerror_cnt_o         : inout std_logic_2d_16(3 downto 0);
        harderror_cnt_o         : inout std_logic_2d_16(3 downto 0);
        txpck_cnt_o             : out std_logic_2d_16(3 downto 0);
        rxpck_cnt_o             : out std_logic_2d_16(3 downto 0);
        fofb_err_clear          : in  std_logic;

        -- network information
        tfs_bit_o               : out std_logic_vector(3 downto 0);
        link_partner_o          : out std_logic_2d_10(3 downto 0);
        pmc_timeframe_val_o     : out std_logic_2d_16(3 downto 0);
        pmc_timestamp_val_o     : out std_logic_2d_32(3 downto 0);

        -- tx/rx state machine status for reset operation
        tx_sm_busy_o            : out std_logic_vector(LaneCount-1 downto 0);
        rx_sm_busy_o            : out std_logic_vector(LaneCount-1 downto 0);

        -- TX FIFO interface
        tx_dat_i                : in  std_logic_2d_16(LaneCount-1 downto 0);
        txf_empty_i             : in  std_logic_vector(LaneCount-1 downto 0);
        txf_rd_en_o             : out std_logic_vector(LaneCount-1 downto 0);

        -- RX FIFO interface
        rxf_full_i              : in  std_logic_vector(LaneCount-1 downto 0);
        rx_dat_o                : out std_logic_2d_16(LaneCount-1 downto 0);
        rx_dat_val_o            : out std_logic_vector(LaneCount-1 downto 0)
    );
end fofb_cc_gt_if;

architecture rtl of fofb_cc_gt_if is

signal txdata               : std_logic_2d_16(LaneCount-1 downto 0);
signal rxdata               : std_logic_2d_16(LaneCount-1 downto 0);
signal txcharisk            : std_logic_2d_2(LaneCount-1 downto 0);
signal rxcharisk            : std_logic_2d_2(LaneCount-1 downto 0);
signal encommaalign         : std_logic_vector(LaneCount-1 downto 0);
signal txkerr               : std_logic_2d_2(LaneCount-1 downto 0);
signal txbuferr             : std_logic_vector(LaneCount-1 downto 0);
signal rxbuferr             : std_logic_vector(LaneCount-1 downto 0);
signal rxrealign            : std_logic_vector(LaneCount-1 downto 0);
signal rxdisperr            : std_logic_2d_2(LaneCount-1 downto 0);
signal rxnotintable         : std_logic_2d_2(LaneCount-1 downto 0);
signal rxreset              : std_logic_vector(LaneCount-1 downto 0);
signal txreset              : std_logic_vector(LaneCount-1 downto 0);
signal rxcheckingcrc        : std_logic_vector(LaneCount-1 downto 0);
signal rxcrcerr             : std_logic_vector(LaneCount-1 downto 0);
signal refclksel            : std_logic;
signal txpolarity           : std_logic;
signal userclk              : std_logic;
signal linksup              : std_logic_vector(7 downto 0);
signal frameerror_cnt       : std_logic_2d_16(3 downto 0);
signal softerror_cnt        : std_logic_2d_16(3 downto 0);
signal harderror_cnt        : std_logic_2d_16(3 downto 0);
signal txpck_cnt            : std_logic_2d_16(3 downto 0);
signal rxpck_cnt            : std_logic_2d_16(3 downto 0);
signal tfs_bit              : std_logic_vector(3 downto 0);
signal link_partner         : std_logic_2d_10(3 downto 0);
signal pmc_timeframe_val    : std_logic_2d_16(3 downto 0);
signal pmc_timestamp_val    : std_logic_2d_32(3 downto 0);

begin

-- Unused outputs
txoutclk_o <= '0';
plllkdet_o <= '0';

-- 0=BREFCLK, 1=BREFCLK2
refclksel <= '1' when (DEVICE = PMCSFPEVR) else '0';

txpolarity <= '1' when (DEVICE = PMCEVR) else '0';

-- Internal signal assignments
linksup_o <= linksup;
frameerror_cnt_o<= frameerror_cnt;
softerror_cnt_o <= softerror_cnt;
harderror_cnt_o <= harderror_cnt;
txpck_cnt_o <= txpck_cnt;
rxpck_cnt_o <= rxpck_cnt;
tfs_bit_o <= tfs_bit;
link_partner_o <= link_partner;
pmc_timeframe_val_o <= pmc_timeframe_val;
pmc_timestamp_val_o <= pmc_timestamp_val;


MGT_IF_GEN: for N in 0 to (LaneCount-1) generate

MGT_LANES: entity work.fofb_cc_mgt_lane
    generic map(
        -- CC Design selection parameters
        TX_IDLE_NUM             => TX_IDLE_NUM,
        RX_IDLE_NUM             => RX_IDLE_NUM,
        SEND_ID_NUM             => SEND_ID_NUM
    )
    port map (
        userclk_i               => userclk_i,
        mgtreset_i              => mgtreset_i,
        rxreset_o               => rxreset(N),
        txreset_o               => txreset(N),
        powerdown_i             => powerdown_i(N),

        timeframe_valid_i       => timeframe_valid_i,
        timeframe_cntr_i        => timeframe_cntr_i,
        bpmid_i                 => bpmid_i,

        linksup_o               => linksup(2*N+1 downto 2*N),
        frameerror_cnt_o        => frameerror_cnt(N),
        softerror_cnt_o         => softerror_cnt(N),
        harderror_cnt_o         => harderror_cnt(N),
        txpck_cnt_o             => txpck_cnt(N),
        rxpck_cnt_o             => rxpck_cnt(N),
        fofb_err_clear          => fofb_err_clear,

        tfs_bit_o               => tfs_bit(N),
        link_partner_o          => link_partner(N),
        pmc_timeframe_val_o     => pmc_timeframe_val(N),
        timestamp_val_o         => pmc_timestamp_val(N),

        tx_sm_busy_o            => tx_sm_busy_o(N),
        rx_sm_busy_o            => rx_sm_busy_o(N),

        tx_dat_i                => tx_dat_i(N),
        txf_empty_i             => txf_empty_i(N),
        txf_rd_en_o             => txf_rd_en_o(N),

        rxf_full_i              => rxf_full_i(N),
        rx_dat_o                => rx_dat_o(N),
        rx_dat_val_o            => rx_dat_val_o(N),

        txdata_o                => txdata(N),
        txcharisk_o             => txcharisk(N),
        rxdata_i                => rxdata(N),
        rxcharisk_i             => rxcharisk(N),
        encommaalign_o          => encommaalign(N),
        txkerr_i                => txkerr(N),
        txbuferr_i              => txbuferr(N),
        rxbuferr_i              => rxbuferr(N),
        rxrealign_i             => rxrealign(N),
        rxdisperr_i             => rxdisperr(N),
        rxnotintable_i          => rxnotintable(N),
        rxcrcerr_i              => rxcrcerr(N),
        rxcheckingcrc_i         => rxcheckingcrc(N)
    );

MGT_TILES : entity work.fofb_cc_mgt_tile
    port map (
        brefclk_i               => refclk_i,
        refclksel_i             => refclksel,
        userclk_i               => userclk_i,
        encommaalign_i          => encommaalign(N),
        loopback_i              => loopback_i(2*N+1 downto 2*N),
        powerdown_i             => powerdown_i(N),
        rxn_i                   => rxn_i(N),
        rxp_i                   => rxp_i(N),
        rxreset_i               => rxreset(N),
        txcharisk_i             => txcharisk(N),
        txdata_i                => txdata(N),
        txreset_i               => txreset(N),
        txpolarity_i            => txpolarity,
        rxbufstatus_o           => rxbuferr(N),
        rxcharisk_o             => rxcharisk(N),
        rxcheckingcrc_o         => rxcheckingcrc(N),
        rxcrcerr_o              => rxcrcerr(N),
        rxdata_o                => rxdata(N),
        rxdisperr_o             => rxdisperr(N),
        rxnotintable_o          => rxnotintable(N),
        rxrealign_o             => rxrealign(N),
        txbuferr_o              => txbuferr(N),
        txkerr_o                => txkerr(N),
        txn_o                   => txn_o(N),
        txp_o                   => txp_o(N)
);

end generate;

end rtl;
