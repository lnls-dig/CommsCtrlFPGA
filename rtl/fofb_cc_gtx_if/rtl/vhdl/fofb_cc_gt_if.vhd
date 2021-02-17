----------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Filename     :
--  Purpose      : Virtex6 GTX interface
--  Responsible  : Isa S. Uzun
----------------------------------------------------------------------
--  Copyright (c) 2007 Diamond Light Source Ltd.
--  All rights reserved.
----------------------------------------------------------------------
--  Description: This is the top-level interface module that instantiates
--  GTX Tile and user logic to interface CC.
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
        DEVICE                  : device_t := BPM;
        -- CC Design selection parameters
        LaneCount               : integer := 1;
        TX_IDLE_NUM             : integer := 16;    --32767 cc
        RX_IDLE_NUM             : integer := 13;    --4095 cc
        SEND_ID_NUM             : integer := 14;    --8191 cc
        -- Simulation parameters
        SIM_GTPRESET_SPEEDUP    : integer := 0;
        PHYSICAL_INTERFACE      : string  := "SFP";
        -- Selection of transceiver reference clock input
        REFCLK_INPUT            : string := "REFCLK0"
    );
    port (
        -- clocks and resets
        refclk_i                : in  std_logic;
        mgtreset_i              : in  std_logic;
        initclk_i               : in  std_logic;
        sysclk_i                : in  std_logic := '0';

        -- system interface
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
        frameerror_cnt_o        : out std_logic_2d_16(3 downto 0);
        softerror_cnt_o         : out std_logic_2d_16(3 downto 0);
        harderror_cnt_o         : out std_logic_2d_16(3 downto 0);
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
signal plllkdet             : std_logic;
signal rxplllkdet           : std_logic_vector(3 downto 0);
signal txplllkdet           : std_logic_vector(3 downto 0);
signal refclkout            : std_logic;
signal txoutclk             : std_logic_vector(3 downto 0);
signal open_rxbufstatus     : std_logic_vector(1 downto 0);
signal open_txbufstatus     : std_logic;
signal rxelecidlereset      : std_logic_vector(3 downto 0);

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
signal rxresetdone          : std_logic_vector(3 downto 0);
signal txresetdone          : std_logic_vector(3 downto 0);
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
signal rx_dat_val_buffer    : std_logic_vector(LaneCount-1 downto 0);
signal linksup_buffer       : std_logic_vector(7 downto 0);
signal link_partner_buffer  : std_logic_2d_10(3 downto 0);

signal tied_to_ground       : std_logic;
signal tied_to_vcc          : std_logic;

signal control              : std_logic_vector(35 downto 0);
signal data                 : std_logic_vector(255 downto 0);
signal trig0                : std_logic_vector(7 downto 0);

begin

-- Static signal Assignments
tied_to_ground <= '0';
tied_to_vcc    <= '1';

-- connect the txoutclk of lane 1 to txoutclk
txoutclk_o <= txoutclk(0);

-- assign outputs
rx_dat_o <= rx_dat_buffer;
rx_dat_val_o <= rx_dat_val_buffer;
linksup_o <= linksup_buffer;
link_partner_o <= link_partner_buffer;

-- connect tx_lock to tx_lock_i from lane 0
plllkdet_o <= rxplllkdet(0);

userclk <= userclk_i;
resetdone <= rxresetdone and txresetdone;

--
-- GTP User Logic instantiation
--
gtx_if_gen : for N in 0 to (LaneCount-1) generate

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


    gtx_lane : entity work.fofb_cc_gtx_lane
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
            rxelecidlereset_i       => tied_to_ground,

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
            rx_dat_val_o            => rx_dat_val_buffer(N),

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
--
-- GTP Tile instantiation
--
    gtx_tile_wrapper : entity work.fofb_cc_gtx_tile_wrapper
        generic map (
            -- simulation attributes
            GTX_SIM_GTXRESET_SPEEDUP    => SIM_GTPRESET_SPEEDUP
        )
        port map (
            loopback_in                 => loopback(N),
            rxpowerdown_in              => powerdown(N),
            txpowerdown_in              => powerdown(N),
            rxcharisk_out               => rxcharisk(N),
            rxdisperr_out               => rxdisperr(N),
            rxnotintable_out            => rxnotintable(N),
            rxbyterealign_out           => rxrealign(N),
            rxenmcommaalign_in          => rxenmcommaalign(N),
            rxenpcommaalign_in          => rxenpcommaalign(N),
            rxdata_out                  => rxdata(N),
            rxreset_in                  => rxreset(N),
            rxusrclk2_in                => userclk_2x_i,
            rxn_in                      => rxn(N),
            rxp_in                      => rxp(N),
            rxbufstatus_out             => rxbuferr(N),
            gtxrxreset_in               => gtreset_i,
            mgtrefclkrx_in(0)           => refclk_i,
            mgtrefclkrx_in(1)           => tied_to_ground,
            pllrxreset_in               => tied_to_ground,
            rxplllkdet_out              => rxplllkdet(N),
            rxresetdone_out             => rxresetdone(N),
            rxpolarity_in               => rxpolarity_i(N),

            gtxtxreset_in               => gtreset_i,
            mgtrefclktx_in(0)           => refclk_i,
            mgtrefclktx_in(1)           => tied_to_ground,
            plltxreset_in               => tied_to_ground,
            txplllkdet_out              => txplllkdet(n),
            txresetdone_out             => txresetdone(n),
            init_clk_in                 => initclk_i,
            link_reset_in               => "00",

            txcharisk_in                => txcharisk(N),
            txkerr_out                  => txkerr(N),
            txbufstatus_out             => txbuferr(N),
            txdata_in                   => txdata(N),
            txoutclk_out                => txoutclk(N),
            txreset_in                  => txreset(N),
            txusrclk2_in                => userclk_2x_i,
            txn_out                     => txn(N),
            txp_out                     => txp(N)
        );
end generate;

--
-- Conditional chipscope generation
--
CSCOPE_GEN : if (GTX_IF_CSGEN = true) generate

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

trig0(0)           <= timeframe_start_i;
trig0(1)           <= rxreset(0);
trig0(2)           <= txreset(0);
trig0(3)           <= rxbuferr(0);
trig0(7 downto 4)  <= (others => '0');


data(15 downto 0)  <= rxdata(0);
data(31 downto 16) <= rxdata(1);
data(47 downto 32) <= rxdata(2);
data(63 downto 48) <= rxdata(3);

data(79 downto 64)   <= txdata(0);
data(95 downto 80)   <= txdata(1);
data(111 downto 96)  <= txdata(2);
data(127 downto 112) <= txdata(3);

data(129 downto 128) <= rxcharisk(0);
data(131 downto 130) <= rxcharisk(1);
data(133 downto 132) <= rxcharisk(2);
data(135 downto 134) <= rxcharisk(3);

data(137 downto 136) <= txcharisk(0);
data(139 downto 138) <= txcharisk(1);
data(141 downto 140) <= txcharisk(2);
data(143 downto 142) <= txcharisk(3);

data(147 downto 144) <= resetdone;
data(151 downto 148) <= txplllkdet;
data(155 downto 152) <= rxplllkdet;
data(165 downto 156) <= link_partner_buffer(0);
data(175 downto 166) <= link_partner_buffer(2);

data(183 downto 176) <= linksup_buffer;

data(184)            <= timeframe_start_i;
data(185)            <= timeframe_valid_i;

data(189 downto 186) <= rxrealign;
data(193 downto 190) <= rxbuferr;

end generate;

end rtl;
