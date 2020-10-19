----------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Filename     :
--  Purpose      : Virtex5 GTP interface
--  Responsible  : Isa S. Uzun
----------------------------------------------------------------------
--  Copyright (c) 2007 Diamond Light Source Ltd.
--  All rights reserved.
----------------------------------------------------------------------
--  Description: This is the top-level interface module that instantiates
--  GTP Tile and user logic to interface CC.
--  This module implement only one GTP_DUAL which provides 2 RocketIO 
--  channels to CC.
----------------------------------------------------------------------
--  Limitations & Assumptions:
----------------------------------------------------------------------
--  Known Errors: Please send any bug reports to isa.uzun@diamond.ac.uk
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.fofb_cc_pkg.all;

entity fofb_cc_gtp_if is
generic (
    -- CC Design selection parameters
    LaneCount               : integer := 2;
    TX_IDLE_NUM             : natural := 16;    --32767 cc
    RX_IDLE_NUM             : natural := 13;    --4095 cc
    SEND_ID_NUM             : natural := 14;    --8191 cc
    -- Simulation parameters
    SIM_GTPRESET_SPEEDUP    : integer   := 0
);
port (
    -- clocks and resets
    refclk_i                : in  std_logic;
    mgtreset_i              : in  std_logic;
    initclk_i               : in  std_logic;

    -- system interface
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

    -- status information
    linksup_o               : out std_logic_vector(7 downto 0);
    frameerror_cnt_o        : inout std_logic_2d_16(3 downto 0); 
    softerror_cnt_o         : inout std_logic_2d_16(3 downto 0); 
    harderror_cnt_o         : inout std_logic_2d_16(3 downto 0); 
    txpck_cnt_o             : out std_logic_2d_16(3 downto 0);
    rxpck_cnt_o             : out std_logic_2d_16(3 downto 0);

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
end fofb_cc_gtp_if;

architecture rtl of fofb_cc_gtp_if is

-- GTP_DUAL 0 & 1
signal rxusrclk0            : std_logic := '0';
signal rxusrclk1            : std_logic := '0';
signal rxusrclk20           : std_logic := '0';
signal rxusrclk21           : std_logic := '0';
signal clkin                : std_logic := '0';
signal txusrclk0            : std_logic := '0';
signal txusrclk1            : std_logic := '0';
signal txusrclk20           : std_logic := '0';
signal txusrclk21           : std_logic := '0';
signal plllkdet             : std_logic;
signal refclkout            : std_logic;
signal txoutclk0            : std_logic;
signal open_rxbufstatus0    : std_logic_vector(1 downto 0);
signal open_rxbufstatus1    : std_logic_vector(1 downto 0);
signal open_txbufstatus0    : std_logic;
signal open_txbufstatus1    : std_logic;
signal rxelecidlereset      : std_logic_vector(3 downto 0);

--
signal loopback             : std_logic_2d_3(3 downto 0);
signal powerdown            : std_logic_2d_2(3 downto 0);
signal txdata               : std_logic_2d_16(3 downto 0);
signal rxdata               : std_logic_2d_16(3 downto 0);
signal txcharisk            : std_logic_2d_2(3 downto 0);
signal rxcharisk            : std_logic_2d_2(3 downto 0);
signal rxenmcommaalign      : std_logic_vector(3 downto 0);
signal rxenpcommaalign      : std_logic_vector(3 downto 0);
signal userclk              : std_logic;
signal resetdone            : std_logic_vector(3 downto 0);
signal txkerr               : std_logic_2d_2(3 downto 0);
signal txbuferr             : std_logic_vector(3 downto 0);
signal rxbuferr             : std_logic_vector(3 downto 0);
signal rxrealign            : std_logic_vector(3 downto 0);
signal rxdisperr            : std_logic_2d_2(3 downto 0);
signal rxnotintable         : std_logic_2d_2(3 downto 0);
signal rxreset              : std_logic_vector(3 downto 0);
signal txreset              : std_logic_vector(3 downto 0);
signal rxn                  : std_logic_vector(3 downto 0);
signal rxp                  : std_logic_vector(3 downto 0);
signal txn                  : std_logic_vector(3 downto 0);
signal txp                  : std_logic_vector(3 downto 0);

signal rx_dat_buffer        : std_logic_2d_16(LaneCount-1 downto 0);
signal linksup_buffer       : std_logic_vector(7 downto 0);

begin

-- connect the txoutclk of lane 0 to txoutclk
txoutclk_o <= txoutclk0;

-- assign outputs
rx_dat_o <= rx_dat_buffer;
linksup_o(3 downto 0) <= linksup_buffer(3 downto 0);

-- connect tx_lock to tx_lock_i from lane 0
process(refclkout)
begin
    if rising_edge(refclkout) then
        plllkdet_o <= plllkdet;
    end if;
end process;

userclk <= userclk_i;

--
--
--
GTP_LANE : for N in 0 to LaneCount-1 generate

-- Back compatibility with V2Pro loopback. Supports
-- parallel and serial loopback modes
loopback(N) <= '0' & loopback_i(2*N+1 downto 2*N);
powerdown(N) <= '0' & powerdown_i(N);

-- Output ports
--
rxn(N) <= rxn_i(N);
rxp(N) <= rxp_i(N);
txn_o(N) <= txn(N);
txp_o(N) <= txp(N);

end generate;


--
-- GTP User Logic instantiation
--
GTP_LANE_GEN: for N in 0 to (LaneCount-1) generate
    LANES: entity work.fofb_cc_gtp_lane
        generic map(
            -- CC Design selection parameters
            TX_IDLE_NUM             => TX_IDLE_NUM,
            RX_IDLE_NUM             => RX_IDLE_NUM,
            SEND_ID_NUM             => SEND_ID_NUM
        )
        port map (
            userclk_i               => userclk,
            mgtreset_i              => mgtreset_i,
            gtp_resetdone_i         => resetdone(N),
            rxreset_o               => rxreset(N),
            txreset_o               => txreset(N),
            powerdown_i             => powerdown_i(N),
            rxelecidlereset_i       => rxelecidlereset(N),

            timeframe_start_i       => timeframe_start_i,
            timeframe_valid_i       => timeframe_valid_i,
            timeframe_cntr_i        => timeframe_cntr_i,
            bpmid_i                 => bpmid_i,

            linksup_o               => linksup_buffer(2*N+1 downto 2*N),
            frameerror_cnt_o        => frameerror_cnt_o(N),
            softerror_cnt_o         => softerror_cnt_o(N),
            harderror_cnt_o         => harderror_cnt_o(N),
            txpck_cnt_o             => txpck_cnt_o(N),
            rxpck_cnt_o             => rxpck_cnt_o(N),

            tfs_bit_o               => tfs_bit_o(N),
            link_partner_o          => link_partner_o(N),
            pmc_timeframe_val_o     => pmc_timeframe_val_o(N),
            timestamp_val_o         => pmc_timestamp_val_o(N),

            tx_sm_busy_o            => tx_sm_busy_o(N),
            rx_sm_busy_o            => rx_sm_busy_o(N),

            tx_dat_i                => tx_dat_i(N),
            txf_empty_i             => txf_empty_i(N),
            txf_rd_en_o             => txf_rd_en_o(N),

            rxf_full_i              => rxf_full_i(N),
            rx_dat_o                => rx_dat_buffer(N),
            rx_dat_val_o            => rx_dat_val_o(N),

            txdata_o                => txdata(N),
            txcharisk_o             => txcharisk(N),
            rxdata_i                => rxdata(N),
            rxcharisk_i             => rxcharisk(N),
            rxenmcommaalign_o       => rxenmcommaalign(N),
            rxenpcommaalign_o       => rxenpcommaalign(N),
            txkerr_i                => txkerr(N),
            txbuferr_i              => txbuferr(N),
            rxbuferr_i              => rxbuferr(N),
            rxrealign_i             => rxrealign(N),
            rxdisperr_i             => rxdisperr(N),
            rxnotintable_i          => rxnotintable(N)
        );
end generate;

--
-- GTP Tile instantiation
--
GTP_INST : entity work.fofb_cc_gtp_tile
    generic map (
        -- simulation attributes
        TILE_SIM_GTPRESET_SPEEDUP   => SIM_GTPRESET_SPEEDUP
    )
    port map (
        loopback0_in                => loopback(0),
        loopback1_in                => loopback(1),
        rxpowerdown0_in             => powerdown(0),
        rxpowerdown1_in             => powerdown(1),
        txpowerdown0_in             => powerdown(0),
        txpowerdown1_in             => powerdown(1),
        rxcharisk0_out              => rxcharisk(0),
        rxcharisk1_out              => rxcharisk(1),
        rxdisperr0_out              => rxdisperr(0),
        rxdisperr1_out              => rxdisperr(1),
        rxnotintable0_out           => rxnotintable(0),
        rxnotintable1_out           => rxnotintable(1),
        rxbyterealign0_out          => rxrealign(0),
        rxbyterealign1_out          => rxrealign(1),
        rxenmcommaalign0_in         => rxenmcommaalign(0),
        rxenmcommaalign1_in         => rxenmcommaalign(1),
        rxenpcommaalign0_in         => rxenpcommaalign(0),
        rxenpcommaalign1_in         => rxenpcommaalign(1),
        rxdata0_out                 => rxdata(0),
        rxdata1_out                 => rxdata(1),
        rxreset0_in                 => rxreset(0),
        rxreset1_in                 => rxreset(1),
        rxusrclk0_in                => userclk_2x_i,
        rxusrclk1_in                => userclk_2x_i,
        rxusrclk20_in               => userclk_i,
        rxusrclk21_in               => userclk_i,
        rxn0_in                     => rxn(0),
        rxn1_in                     => rxn(1),
        rxp0_in                     => rxp(0),
        rxp1_in                     => rxp(1),
        rxbufstatus0_out(2)         => rxbuferr(0),
        rxbufstatus0_out(1 downto 0)=> open_rxbufstatus0(1 downto 0),
        rxbufstatus1_out(2)         => rxbuferr(1),
        rxbufstatus1_out(1 downto 0)=> open_rxbufstatus1(1 downto 0),
        clkin_in                    => refclk_i,
        gtpreset_in                 => gtreset_i,
        plllkdet_out                => plllkdet,
        refclkout_out               => refclkout,
        resetdone0_out              => resetdone(0),
        resetdone1_out              => resetdone(1),
        rxelecidlereset0_out        => rxelecidlereset(0),
        rxelecidlereset1_out        => rxelecidlereset(1),
        txcharisk0_in               => txcharisk(0),
        txcharisk1_in               => txcharisk(1),
        txkerr0_out                 => txkerr(0),
        txkerr1_out                 => txkerr(1),
        txbufstatus0_out(1)         => txbuferr(0),
        txbufstatus0_out(0)         => open_txbufstatus0,
        txbufstatus1_out(1)         => txbuferr(1),
        txbufstatus1_out(0)         => open_txbufstatus1,
        txdata0_in                  => txdata(0),
        txdata1_in                  => txdata(1),
        txoutclk0_out               => txoutclk0,
        txoutclk1_out               => open,
        txreset0_in                 => txreset(0),
        txreset1_in                 => txreset(1),
        txusrclk0_in                => userclk_2x_i,
        txusrclk1_in                => userclk_2x_i,
        txusrclk20_in               => userclk_i,
        txusrclk21_in               => userclk_i,
        txn0_out                    => txn(0),
        txn1_out                    => txn(1),
        txp0_out                    => txp(0),
        txp1_out                    => txp(1) 
    );

end rtl;
