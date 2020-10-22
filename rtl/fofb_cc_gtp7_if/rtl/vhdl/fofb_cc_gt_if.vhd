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
        SIM_GTPRESET_SPEEDUP    : integer := 0
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
signal pll0refclksel        : std_logic;
signal pllrst               : std_logic;

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
    gtp7_tile_wrapper : entity work.fofb_cc_gtp7_tile_wrapper
        generic map (
            -- simulation attributes
            GT_SIM_GTRESET_SPEEDUP      => SIM_GTPRESET_SPEEDUP
        )
        port map (
            pll0clk_in                  => pll0clk;
            pll0refclk_in               => pll0refclk;
            pll1clk_in                  => pll1clk_in;
            pll1refclk_in               => pll1refclk;
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
            rst_in                      => '0', -- FIXME: placeholder code

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
        PLL1OUTCLK_OUT        => pll1clk_in,
        PLL1OUTREFCLK_OUT     => pll1refclk,
        GTREFCLK1_IN          => gtrefclk1,
        GTREFCLK0_IN          => gtrefclk0,
    );

refclk0_gen : if GTP7_IF_REFCLK = "REFCLK0" generate
    gtrefclk0     <= ref_clk;
    gtrefclk1     <= '0';
    pll0refclksel <= "001";
end generate;

refclk1_gen : if GTP7_IF_REFCLK = "REFCLK1" generate
    gtrefclk0     <= '0';
    gtrefclk1     <= ref_clk;
    pll0refclksel <= "010";
end generate;

--
-- GTP Quad PLL reset logic (AR #43482)
--
quad_pll_reset : entity work.gtpe7_common_reset is 
    generic map
    (
        STABLE_CLOCK_PERIOD   => 8
    );
    port map
    (    
        STABLE_CLOCK          => init_clk,
        SOFT_RESET            => '0',         -- FIXME: placeholder code
        COMMON_RESET          => pllrst
   );
end gtpe7_common_reset;

--
-- Conditional chipscope generation
--
CSCOPE_GEN : if (GTP7_IF_CSGEN = true) generate

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
data(151) <= plllkdet;
data(165 downto 156) <= link_partner_buffer(0);
data(175 downto 166) <= link_partner_buffer(2);

data(183 downto 176) <= linksup_buffer;

data(184)            <= timeframe_start_i;
data(185)            <= timeframe_valid_i;

data(189 downto 186) <= rxrealign;
data(193 downto 190) <= rxbuferr;

end generate;

end rtl;
