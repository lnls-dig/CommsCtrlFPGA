----------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Purpose      : 7-series GTP interface
--  Author       : Daniel Tavares (CNPEM/Sirius)
----------------------------------------------------------------------
--  Based on code provided by Diamond Light Source Ltd. and made publicly
--  available at https://github.com/dls-controls/CommsCtrlFPGA
----------------------------------------------------------------------
--  Description: This is the top-level interface module that instantiates
--  GTPE2_CHANNEL Tile and user logic to interface CC.
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
        sysclk_i                : in  std_logic;

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

signal clkin                : std_logic := '0';
signal plllkdet             : std_logic;
signal refclkout            : std_logic;
signal txoutclk             : std_logic_vector(3 downto 0);

signal gtrefclk0            : std_logic;
signal gtrefclk1            : std_logic;
signal gteastrefclk0        : std_logic;
signal gteastrefclk1        : std_logic;
signal gtwestrefclk0        : std_logic;
signal gtwestrefclk1        : std_logic;
signal pll0refclksel        : std_logic_vector(2 downto 0);
signal pllrst               : std_logic;

signal pll0clk              : std_logic;
signal pll0refclk           : std_logic;
signal pll1clk              : std_logic;
signal pll1refclk           : std_logic;

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
signal tx_harderror         : std_logic_vector(3 downto 0);
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

plllkdet_o <= plllkdet;

userclk <= userclk_i;
resetdone <= rxresetdone and txresetdone;

--
-- GTP User Logic instantiation
--
gtp7_if_gen : for N in 0 to (LaneCount-1) generate

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


    gtp7_lane : entity work.fofb_cc_gtp7_lane
        generic map(
            -- CC Design selection parameters
            TX_IDLE_NUM             => TX_IDLE_NUM,
            RX_IDLE_NUM             => RX_IDLE_NUM,
            SEND_ID_NUM             => SEND_ID_NUM
        )
        port map (
            userclk_i               => userclk,
            mgtreset_i              => mgtreset_i,
            sysclk_i                => sysclk_i,
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

            tx_harderror_o          => tx_harderror(N),

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
    gtp7_tile_wrapper : entity work.fofb_cc_gtp7_tile_wrapper
        generic map (
            -- simulation attributes
            GT_SIM_GTRESET_SPEEDUP      => SIM_GTPRESET_SPEEDUP,
            PHYSICAL_INTERFACE          => PHYSICAL_INTERFACE
        )
        port map (
            pll0clk_in                  => pll0clk,
            pll0refclk_in               => pll0refclk,
            pll1clk_in                  => pll1clk,
            pll1refclk_in               => pll1refclk,
            rxuserrdy_in                => plllkdet,
            loopback_in                 => loopback(N),
            rxpd_in                     => powerdown(N),
            txpd_in                     => powerdown(N),

            rxcharisk_out               => rxcharisk(N),
            rxdisperr_out               => rxdisperr(N),
            rxnotintable_out            => rxnotintable(N),
            rxbyterealign_out           => rxrealign(N),
            rxmcommaalignen_in          => rxenmcommaalign(N),
            rxpcommaalignen_in          => rxenpcommaalign(N),
            rxdata_out                  => rxdata(N),
            gtrxreset_in                => rxreset(N),
            rxusrclk2_in                => userclk_2x_i,
            gtprxn_in                   => rxn(N),
            gtprxp_in                   => rxp(N),
            rxbufstatus_out             => rxbuferr(N),
            rxresetdone_out             => rxresetdone(N),
            rxpolarity_in               => rxpolarity_i(N),

            txresetdone_out             => txresetdone(n),
            drpclk_in                   => initclk_i,
            rst_in                      => gtreset_i,

            txuserrdy_in                => plllkdet,
            txcharisk_in                => txcharisk(N),
            txbufstatus_out             => txbuferr(N),
            txdata_in                   => txdata(N),
            txoutclk_out                => txoutclk(N),
            gttxreset_in                => txreset(N),
            txusrclk2_in                => userclk_2x_i,
            gtptxn_out                  => txn(N),
            gtptxp_out                  => txp(N)
    );

    txkerr(N) <= "00";
end generate;

--
-- GTP Quad PLL instantiation
--
quad_pll : entity work.gtpe7_common
    generic map
    (
        WRAPPER_SIM_GTRESET_SPEEDUP => "FALSE"
    )
    port map
    (
        PLL0OUTCLK_OUT        => pll0clk,
        PLL0OUTREFCLK_OUT     => pll0refclk,
        PLL0LOCK_OUT          => plllkdet,
        PLL0LOCKDETCLK_IN     => '0',
        PLL0REFCLKLOST_OUT    => open,
        PLL0RESET_IN          => pllrst,
        PLL0REFCLKSEL_IN      => pll0refclksel,
        PLL0PD_IN             => '0',
        PLL1OUTCLK_OUT        => pll1clk,
        PLL1OUTREFCLK_OUT     => pll1refclk,
        GTREFCLK1_IN          => gtrefclk1,
        GTREFCLK0_IN          => gtrefclk0,
        GTEASTREFCLK0_IN      => gteastrefclk0,
        GTEASTREFCLK1_IN      => gteastrefclk1,
        GTWESTREFCLK0_IN      => gtwestrefclk0,
        GTWESTREFCLK1_IN      => gtwestrefclk1
    );

assert (REFCLK_INPUT = "REFCLK0" or REFCLK_INPUT = "REFCLK1" or
    REFCLK_INPUT = "EASTREFCLK0" or REFCLK_INPUT = "EASTREFCLK1" or
    REFCLK_INPUT = "WESTREFCLK0" or REFCLK_INPUT = "WESTREFCLK1")
    report "[fofb_cc_gtp7_if/fofb_cc_gt_if]: Invalid REFCLK_INPUT(" & REFCLK_INPUT & ") selection." &
        "Must be one of REFCLK0, REFCLK1, EASTREFCLK0, EASTREFCLK1, WESTREFCLK0 or WESTREFCLK1"
    severity failure;

refclk0_gen : if REFCLK_INPUT = "REFCLK0" generate
    gtrefclk0     <= refclk_i;
    gtrefclk1     <= '0';
    gteastrefclk0 <= '0';
    gteastrefclk1 <= '0';
    gtwestrefclk0 <= '0';
    gtwestrefclk1 <= '0';
    pll0refclksel <= "001";
end generate;

refclk1_gen : if REFCLK_INPUT = "REFCLK1" generate
    gtrefclk0     <= '0';
    gtrefclk1     <= refclk_i;
    gteastrefclk0 <= '0';
    gteastrefclk1 <= '0';
    gtwestrefclk0 <= '0';
    gtwestrefclk1 <= '0';
    pll0refclksel <= "010";
end generate;

eastrefclk0_gen : if REFCLK_INPUT = "EASTREFCLK0" generate
    gtrefclk0     <= '0';
    gtrefclk1     <= '0';
    gteastrefclk0 <= refclk_i;
    gteastrefclk1 <= '0';
    gtwestrefclk0 <= '0';
    gtwestrefclk1 <= '0';
    pll0refclksel <= "011";
end generate;

eastrefclk1_gen : if REFCLK_INPUT = "EASTREFCLK1" generate
    gtrefclk0     <= '0';
    gtrefclk1     <= '0';
    gteastrefclk0 <= '0';
    gteastrefclk1 <= refclk_i;
    gtwestrefclk0 <= '0';
    gtwestrefclk1 <= '0';
    pll0refclksel <= "100";
end generate;

westrefclk0_gen : if REFCLK_INPUT = "WESTREFCLK0" generate
    gtrefclk0     <= '0';
    gtrefclk1     <= '0';
    gteastrefclk0 <= '0';
    gteastrefclk1 <= '0';
    gtwestrefclk0 <= refclk_i;
    gtwestrefclk1 <= '0';
    pll0refclksel <= "101";
end generate;

westrefclk1_gen : if REFCLK_INPUT = "WESTREFCLK1" generate
    gtrefclk0     <= '0';
    gtrefclk1     <= '0';
    gteastrefclk0 <= '0';
    gteastrefclk1 <= '0';
    gtwestrefclk0 <= '0';
    gtwestrefclk1 <= refclk_i;
    pll0refclksel <= "110";
end generate;

--
-- GTP Quad PLL reset logic (AR #43482)
--
quad_pll_reset : entity work.gtpe7_common_reset
    generic map
    (
        STABLE_CLOCK_PERIOD   => 6
    )
    port map
    (
        STABLE_CLOCK          => initclk_i,
        SOFT_RESET            => gtreset_i,
        COMMON_RESET          => pllrst
   );

--
-- Conditional chipscope generation
--
CSCOPE_GEN : if (GTP7_IF_CSGEN = true) generate

ila_core_inst : entity work.ila_fofb_cc_t8_d256_s8192_cap
    port map (
        clk             => userclk,
        probe0          => data,
        probe1          => trig0
     );

trig0(0)           <= timeframe_start_i;
trig0(1)           <= timeframe_valid_i;
trig0(3 downto 2)  <= rxcharisk(1);
trig0(5 downto 4)  <= rxcharisk(2);
trig0(6)           <= gtreset_i;
trig0(7)           <= mgtreset_i;

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
data(150 downto 148) <= (others => '0');
data(151)            <= plllkdet;
data(161 downto 152) <= link_partner_buffer(0);
data(171 downto 162) <= link_partner_buffer(2);

data(179 downto 172) <= linksup_buffer;

data(180)            <= timeframe_start_i;
data(181)            <= timeframe_valid_i;

data(185 downto 182) <= rxrealign;
data(189 downto 186) <= rxbuferr;

data(190)             <= gtreset_i;
data(191)             <= mgtreset_i;
data(192)             <= pllrst;
data(208 downto 193)  <= timeframe_cntr_i;

data(210 downto 209)  <= rxdisperr(0);
data(212 downto 211)  <= rxnotintable(0);
data(213)             <= rxrealign(0);
data(214)             <= rxenmcommaalign(0);
data(215)             <= rxenpcommaalign(0);
data(216)             <= rxbuferr(0);
data(217)             <= rxresetdone(0);
data(218)             <= rxpolarity_i(0);

data(220 downto 219)  <= rxdisperr(1);
data(222 downto 221)  <= rxnotintable(1);
data(223)             <= rxrealign(1);
data(224)             <= rxenmcommaalign(1);
data(225)             <= rxenpcommaalign(1);
data(226)             <= rxbuferr(1);
data(227)             <= rxresetdone(1);
data(228)             <= rxpolarity_i(1);

data(230 downto 229)  <= rxdisperr(2);
data(232 downto 231)  <= rxnotintable(2);
data(233)             <= rxrealign(2);
data(234)             <= rxenmcommaalign(2);
data(235)             <= rxenpcommaalign(2);
data(236)             <= rxbuferr(2);
data(237)             <= rxresetdone(2);
data(238)             <= rxpolarity_i(2);

data(240 downto 239)  <= rxdisperr(3);
data(242 downto 241)  <= rxnotintable(3);
data(243)             <= rxrealign(3);
data(244)             <= rxenmcommaalign(3);
data(245)             <= rxenpcommaalign(3);
data(246)             <= rxbuferr(3);
data(247)             <= rxresetdone(3);
data(248)             <= rxpolarity_i(3);

data(255 downto 249)  <= (others => '0');

end generate;

end rtl;
