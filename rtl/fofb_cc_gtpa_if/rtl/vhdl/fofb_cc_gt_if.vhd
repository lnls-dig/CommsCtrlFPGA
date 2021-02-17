----------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Filename     :
--  Purpose      : Spartan6 GTPA interface
--  Responsible  : Isa S. Uzun
----------------------------------------------------------------------
--  Copyright (c) 2007 Diamond Light Source Ltd.
--  All rights reserved.
----------------------------------------------------------------------
--  Description: This is the top-level interface module that instantiates
--  GTPA Tile and user logic to interface CC.
--  This module implement one GTP_DUAL which provides 2 RocketIO
--  channels to CC.
----------------------------------------------------------------------
--  Limitations & Assumptions: This design modules uses GCLK inputs
--  to the GTPA tile. This is hardware specific for SPEC FMC Carrier
--  board.
----------------------------------------------------------------------
--  Known Errors: Please send any bug reports to isa.uzun@diamond.ac.uk
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.fofb_cc_pkg.all;

entity fofb_cc_gt_if is
generic (
    DEVICE                  : device_t := BPM;
    -- CC Design selection parameters
    LaneCount               : integer := 1;
    TX_IDLE_NUM             : integer := 16;    --32767 cc
    RX_IDLE_NUM             : integer := 13;    --4095 cc
    SEND_ID_NUM             : integer := 14;    --8191 cc
    -- Simulation parameters
    SIM_GTPRESET_SPEEDUP    : integer := 0;
    -- Custom FPGA Device parameters
    REF_GTPA                : integer := 1;
    -- Selection of transceiver reference clock input
    REFCLK_INPUT            : string := "REFCLK0"
);
port (
    -- Main clocks and resets
    refclk_i                : in  std_logic;
    mgtreset_i              : in  std_logic;

    -- Main clocks and resets (NOT USED for V2P MGT Interface)
    initclk_i               : in  std_logic;
    sysclk_i                : in  std_logic := '0';
    gtreset_i               : in  std_logic;

    userclk_i               : in  std_logic;
    userclk_2x_i            : in  std_logic;
    txoutclk_o              : out std_logic;
    plllkdet_o              : out std_logic;
    rxpolarity_i            : in  std_logic_vector(LaneCount-1 downto 0);

    -- RocketIO
    rxn_i                   : in  std_logic_vector(LaneCount-1 downto 0);
    rxp_i                   : in  std_logic_vector(LaneCount-1 downto 0);
    txn_o                   : out std_logic_vector(LaneCount-1 downto 0);
    txp_o                   : out std_logic_vector(LaneCount-1 downto 0);

    -- time frame sync
    timeframe_start_i       : in  std_logic;
    timeframe_valid_i       : in  std_logic;
    timeframe_cntr_i        : in  std_logic_vector(15 downto 0);
    bpmid_i                 : in  std_logic_vector(NodeW-1 downto 0);

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
signal plllkdet             : std_logic_vector(1 downto 0);
signal gtpclkout            : std_logic_2d_2(1 downto 0);
signal open_rxbufstatus0    : std_logic_vector(1 downto 0);
signal open_rxbufstatus1    : std_logic_vector(1 downto 0);
signal open_txbufstatus0    : std_logic;
signal open_txbufstatus1    : std_logic;

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
signal link_partner_buffer  : std_logic_2d_10(3 downto 0);

signal control              : std_logic_vector(35 downto 0);
signal data                 : std_logic_vector(63 downto 0);
signal trig0                : std_logic_vector(7 downto 0);

begin

-- Connect the txoutclk to REF GTPA's gtpclkout port
txoutclk_o <= gtpclkout(REF_GTPA)(0);

-- assign outputs
rx_dat_o <= rx_dat_buffer;
linksup_o(3 downto 0) <= linksup_buffer(3 downto 0);
link_partner_o <= link_partner_buffer;

-- connect tx_lock to tx_lock_i from lane 0
plllkdet_o <= plllkdet(REF_GTPA);

userclk <= userclk_i;

GTPA_LANE : for N in 0 to LaneCount-1 generate

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
GTPA_LANE_GEN: for N in 0 to (LaneCount-1) generate
    LANES: entity work.fofb_cc_gtpa_lane
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
            rxelecidlereset_i       => '0',

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
            link_partner_o          => link_partner_buffer(N),
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
GTPA_TILE : entity work.fofb_cc_gtpa_tile
    generic map (
        -- simulation attributes
        TILE_SIM_GTPRESET_SPEEDUP   => SIM_GTPRESET_SPEEDUP
    )
    port map (
        -- Loopback and Powerdown Ports
        loopback0_in                => loopback(0),
        loopback1_in                => loopback(1),
        rxpowerdown0_in             => powerdown(0),
        rxpowerdown1_in             => powerdown(1),
        txpowerdown0_in             => powerdown(0),
        txpowerdown1_in             => powerdown(1),
        polarity0                   => rxpolarity_i(0),
        polarity1                   => rxpolarity_i(1),
        -- Receive Ports - 8b10b Decoder
        rxcharisk0_out              => rxcharisk(0),
        rxcharisk1_out              => rxcharisk(1),
        rxdisperr0_out              => rxdisperr(0),
        rxdisperr1_out              => rxdisperr(1),
        rxnotintable0_out           => rxnotintable(0),
        rxnotintable1_out           => rxnotintable(1),
        -- Receive Ports - Comma Detection and Alignment
        rxbyterealign0_out          => rxrealign(0),
        rxbyterealign1_out          => rxrealign(1),
        rxenmcommaalign0_in         => rxenmcommaalign(0),
        rxenmcommaalign1_in         => rxenmcommaalign(1),
        rxenpcommaalign0_in         => rxenpcommaalign(0),
        rxenpcommaalign1_in         => rxenpcommaalign(1),
        -- Receive Ports - RX Data Path interface
        rxdata0_out                 => rxdata(0),
        rxdata1_out                 => rxdata(1),
        rxreset0_in                 => rxreset(0),
        rxreset1_in                 => rxreset(1),
        rxusrclk0_in                => userclk_2x_i,
        rxusrclk1_in                => userclk_2x_i,
        rxusrclk20_in               => userclk_i,
        rxusrclk21_in               => userclk_i,
        -- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR
        rxn0_in                     => rxn(0),
        rxn1_in                     => rxn(1),
        rxp0_in                     => rxp(0),
        rxp1_in                     => rxp(1),
        -- Receive Ports - RX Elastic Buffer and Phase Alignment Ports
        rxbufstatus0_out(2)         => rxbuferr(0),
        rxbufstatus0_out(1 downto 0)=> open_rxbufstatus0(1 downto 0),
        rxbufstatus1_out(2)         => rxbuferr(1),
        rxbufstatus1_out(1 downto 0)=> open_rxbufstatus1(1 downto 0),
        txbufstatus0_out(1)         => txbuferr(0),
        txbufstatus0_out(0)         => open_txbufstatus0,
        txbufstatus1_out(1)         => txbuferr(1),
        txbufstatus1_out(0)         => open_txbufstatus1,
        -- Shared Ports - Tile and PLL Ports
        clk00_in                    => '0',
        clk01_in                    => '0',
        gclk00_in                   => refclk_i,
        gclk01_in                   => refclk_i,
        gclk10_in                   => '0',
        gclk11_in                   => '0',
        gtpreset0_in                => gtreset_i,
        gtpreset1_in                => gtreset_i,
        plllkdet0_out               => plllkdet(0),
        plllkdet1_out               => plllkdet(1),
        resetdone0_out              => resetdone(0),
        resetdone1_out              => resetdone(1),
        -- Transmit Ports - 8b10b Encoder Control Ports
        txcharisk0_in               => txcharisk(0),
        txcharisk1_in               => txcharisk(1),
        -- Transmit Ports - TX Data Path interface
        txdata0_in                  => txdata(0),
        txdata1_in                  => txdata(1),
        gtpclkout0_out              => gtpclkout(0),
        gtpclkout1_out              => gtpclkout(1),
        txreset0_in                 => txreset(0),
        txreset1_in                 => txreset(1),
        txusrclk0_in                => userclk_2x_i,
        txusrclk1_in                => userclk_2x_i,
        txusrclk20_in               => userclk_i,
        txusrclk21_in               => userclk_i,
        -- -- Transmit Ports - 8b10b Encoder Control
        txkerr0_out                 => txkerr(0),
        txkerr1_out                 => txkerr(1),
        -- Transmit Ports - TX Driver and OOB signalling
        txn0_out                    => txn(0),
        txn1_out                    => txn(1),
        txp0_out                    => txp(0),
        txp1_out                    => txp(1)
    );

--
-- Conditional chipscope generation
--
CSCOPE_GEN : if (GTPA_IF_CSGEN = true) generate

icon_inst : icon
    port map (
        control0        => control
    );

ila_inst : ila_t8_d64_s16384
    port map (
        control         => control,
        clk             => userclk,
        data            => data,
        trig0           => trig0
     );

trig0(0)           <= rxbuferr(1);
trig0(1)           <= rxrealign(1);
trig0(7 downto 2)  <= (others => '0');

data(15 downto 0)  <= rxdata(0);
data(31 downto 16) <= rxdata(1);
data(33 downto 32) <= plllkdet;
data(43 downto 34) <= link_partner_buffer(0);
data(53 downto 44) <= link_partner_buffer(1);
data(63 downto 54) <= (others => '0');

end generate;

end rtl;
