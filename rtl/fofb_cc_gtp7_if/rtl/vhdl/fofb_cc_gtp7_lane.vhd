----------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Purpose      : 2-byte lane interface to a single 7-series GTP
--  Author       : Daniel Tavares (CNPEM/Sirius)
----------------------------------------------------------------------
--  Based on code provided by Diamond Light Source Ltd. and made publicly
--  available at https://github.com/dls-controls/CommsCtrlFPGA
----------------------------------------------------------------------
--  Description: This module provides a full duplex 2-byte lane interface
--  to a single GTP. It instantiates RX and TX data path modules.
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_cc_pkg.all;

entity fofb_cc_gtp7_lane is
generic (
    TX_IDLE_NUM             : natural := 16;    --32767 cc
    RX_IDLE_NUM             : natural := 13;    --4095 cc
    SEND_ID_NUM             : natural := 14     --8191 cc
);
port (
    -- clocks and resets
    userclk_i               : in  std_logic;
    mgtreset_i              : in  std_logic;
    sysclk_i                : in  std_logic;
    gtp_resetdone_i         : in  std_logic;
    rxreset_o               : out std_logic;
    txreset_o               : out std_logic;
    powerdown_i             : in  std_logic;
    rxelecidlereset_i       : in  std_logic;

    -- time frame sync
    timeframe_start_i       : in  std_logic;
    timeframe_valid_i       : in std_logic;
    timeframe_cntr_i        : in  std_logic_vector(15 downto 0);
    bpmid_i                 : in  std_logic_vector(NodeW-1 downto 0);

    -- status information
    linksup_o               : out std_logic_vector(1 downto 0);
    frameerror_cnt_o        : out std_logic_vector(15 downto 0);
    softerror_cnt_o         : out std_logic_vector(15 downto 0);
    harderror_cnt_o         : out std_logic_vector(15 downto 0);
    txpck_cnt_o             : out std_logic_vector(15 downto 0);
    rxpck_cnt_o             : out std_logic_vector(15 downto 0);

    -- network information
    tfs_bit_o               : out std_logic;
    link_partner_o          : out std_logic_vector(9 downto 0);
    pmc_timeframe_val_o     : out std_logic_vector(15 downto 0);
    timestamp_val_o         : out std_logic_vector(31 downto 0);

    -- tx/rx state machine status for reset operation
    tx_sm_busy_o            : out std_logic;
    rx_sm_busy_o            : out std_logic;

    -- TX FIFO interface
    tx_dat_i                : in  std_logic_vector(15 downto 0);
    txf_empty_i             : in  std_logic;
    txf_rd_en_o             : out std_logic;

    -- RX FIFO interface
    rxf_full_i              : in  std_logic;
    rx_dat_o                : out std_logic_vector (15 downto 0);
    rx_dat_val_o            : out std_logic;

   tx_harderror_o           : out std_logic;

    -- GTP_DUAL Tile interface
    txdata_o                : out std_logic_vector(15 downto 0);
    txcharisk_o             : out std_logic_vector(1 downto 0);
    rxdata_i                : in  std_logic_vector(15 downto 0);
    rxcharisk_i             : in  std_logic_vector(1 downto 0);
    rxenmcommaalign_o       : out std_logic;
    rxenpcommaalign_o       : out std_logic;
    txkerr_i                : in  std_logic_vector(1 downto 0);
    txbuferr_i              : in  std_logic;
    rxbuferr_i              : in  std_logic;
    rxrealign_i             : in  std_logic;
    rxdisperr_i             : in  std_logic_vector(1 downto 0);
    rxnotintable_i          : in  std_logic_vector(1 downto 0)
);
end fofb_cc_gtp7_lane;

architecture rtl of fofb_cc_gtp7_lane is

signal txcharisk_buffer     : std_logic_vector(1 downto 0);
signal txdata_buffer        : std_logic_vector(15 downto 0);
signal rxcharisk_buffer     : std_logic_vector(1 downto 0);
signal rxdata_buffer        : std_logic_vector(15 downto 0);
signal txlink_up            : std_logic;
signal rxlink_up            : std_logic;
signal ena_comma_align      : std_logic;
signal rxdisperr_buffer     : std_logic_vector(1 downto 0);
signal rxnotintable_buffer  : std_logic_vector(1 downto 0);
signal frameerror           : std_logic;
signal frameerror_prev      : std_logic;
signal frameerror_rise      : std_logic;
signal softerror            : std_logic;
signal softerror_prev       : std_logic;
signal softerror_rise       : std_logic;
signal tx_harderror         : std_logic;
signal rx_harderror         : std_logic;
signal harderror_prev       : std_logic;
signal harderror_rise       : std_logic;
signal harderror            : std_logic;
signal frameerror_cnt_buf   : std_logic_vector(15 downto 0);
signal softerror_cnt_buf    : std_logic_vector(15 downto 0);
signal harderror_cnt_buf    : std_logic_vector(15 downto 0);

begin

linksup_o <= rxlink_up & txlink_up;
rxenmcommaalign_o <= ena_comma_align;
rxenpcommaalign_o <= ena_comma_align;

-- buffers for twisting data from prox --
-- gtp gtps order their data in the opposite direction from pro gtps. to reuse the
-- pro aurora logic, we twist the data to make it compatible.
txdata_o    <= txdata_buffer( 7 downto 0) & txdata_buffer(15 downto 8);
txcharisk_o <= txcharisk_buffer(0) & txcharisk_buffer(1);

rxdata_buffer    <= rxdata_i( 7 downto 0) & rxdata_i(15 downto 8);
rxcharisk_buffer <= rxcharisk_i(0) & rxcharisk_i(1);

rxdisperr_buffer    <= rxdisperr_i(0) & rxdisperr_i(1);
rxnotintable_buffer <= rxnotintable_i(0) & rxnotintable_i(1);

--
--
--
tx_ll : entity work.fofb_cc_gtp7_tx_ll
    generic map (
        TX_IDLE_NUM         => TX_IDLE_NUM,
        SEND_ID_NUM         => SEND_ID_NUM
    )
    port map (
        mgtclk_i            => userclk_i,
        mgtreset_i          => mgtreset_i,
        sysclk_i            => sysclk_i,
        gtp_resetdone_i     => gtp_resetdone_i,
        txreset_o           => txreset_o,
        powerdown_i         => powerdown_i,
        timeframe_start_i   => timeframe_start_i,
        timeframe_valid_i   => timeframe_valid_i,
        bpmid_i             => bpmid_i,
        tx_link_up_o        => txlink_up,
        txpck_cnt_o         => txpck_cnt_o,
        tx_sm_busy_o        => tx_sm_busy_o,
        txf_d_i             => tx_dat_i,
        txf_empty_i         => txf_empty_i,
        txf_rd_en_o         => txf_rd_en_o,
        tx_d_o              => txdata_buffer,
        txcharisk_o         => txcharisk_buffer,
        txkerr_i            => txkerr_i,
        txbuferr_i          => txbuferr_i,
        tx_harderror_o      => tx_harderror
    );

--
--
--
rx_ll : entity work.fofb_cc_gtp7_rx_ll
    generic map (
        RX_IDLE_NUM         => RX_IDLE_NUM
    )
    port map (
        mgtclk_i            => userclk_i,
        mgtreset_i          => mgtreset_i,
        sysclk_i            => sysclk_i,
        gtp_resetdone_i     => gtp_resetdone_i,
        rxreset_o           => rxreset_o,
        powerdown_i         => powerdown_i,
        rxelecidlereset_i   => rxelecidlereset_i,
        rx_link_up_o        => rxlink_up,
        rxpck_cnt_o         => rxpck_cnt_o,
        rx_sm_busy_o        => rx_sm_busy_o,
        rxf_d_o             => rx_dat_o,
        rxf_d_val_o         => rx_dat_val_o,
        rx_d_i              => rxdata_buffer,
        rxcharisk_i         => rxcharisk_buffer,
        tfs_bit_o           => tfs_bit_o,
        link_partner_o      => link_partner_o,
        pmc_timeframe_val_o => pmc_timeframe_val_o,
        timestamp_val_o     => timestamp_val_o,
        timeframe_start_i   => timeframe_start_i,
        timeframe_valid_i   => timeframe_valid_i,
        timeframe_cntr_i    => timeframe_cntr_i,
        comma_align_o       => ena_comma_align,
        rxf_full_i          => rxf_full_i,
        rxbuferr_i          => rxbuferr_i,
        rxrealign_i         => rxrealign_i,
        rx_harderror_o      => rx_harderror,
        rx_softerror_o      => softerror,
        rx_frameerror_o     => frameerror,
        rxdisperr_i         => rxdisperr_buffer,
        rxnotintable_i      => rxnotintable_buffer
    );

tx_harderror_o <= tx_harderror;

--
-- Error Counters
--
--harderror <= tx_harderror or rx_harderror;
harderror <= rx_harderror;
frameerror_rise <= frameerror and not frameerror_prev;
softerror_rise <= softerror and not softerror_prev;
harderror_rise <= harderror and not harderror_prev;

process (userclk_i)
begin
if (userclk_i'event and userclk_i = '1') then
    if (mgtreset_i = '1') then
        frameerror_cnt_buf <= (others => '0');
        softerror_cnt_buf <= (others => '0');
        harderror_cnt_buf <= (others => '0');
    else
        frameerror_prev <= frameerror;
        softerror_prev <= softerror;
        harderror_prev <= harderror;

        if (frameerror_rise = '1') then
            frameerror_cnt_buf <= std_logic_vector(unsigned(frameerror_cnt_buf) + 1);
        end if;

        if (softerror_rise = '1') then
            softerror_cnt_buf <= std_logic_vector(unsigned(softerror_cnt_buf) + 1);
        end if;

        if (harderror_rise = '1') then
            harderror_cnt_buf <= std_logic_vector(unsigned(harderror_cnt_buf) + 1);
        end if;
    end if;
end if;
end process;

frameerror_cnt_o <= frameerror_cnt_buf;
softerror_cnt_o <= softerror_cnt_buf;
harderror_cnt_o <= harderror_cnt_buf;

end rtl;
