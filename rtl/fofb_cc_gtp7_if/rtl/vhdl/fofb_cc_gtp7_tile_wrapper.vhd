----------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Purpose      : 7-series GTPE_CHANNEL
--  Author       : Daniel Tavares (CNPEM/Sirius)
----------------------------------------------------------------------
--  Based on code provided by Diamond Light Source Ltd. and made publicly
--  available at https://github.com/dls-controls/CommsCtrlFPGA
----------------------------------------------------------------------
--  Description: 7-Series GTPE2_CHANNEL component instantiation with
--  required configuration (Wrapper).
----------------------------------------------------------------------

library ieee;
use IEEE.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity FOFB_CC_GTP7_TILE_WRAPPER is
generic (
    -- Simulation attributes
    GTX_SIM_GTXRESET_SPEEDUP    : integer    := 0  -- Set to 1 to speed up sim reset
);
port (
    ------------------------ Loopback and Powerdown Ports ----------------------
    LOOPBACK_IN                             : in   std_logic_vector(2 downto 0);
    RXPOWERDOWN_IN                          : in   std_logic_vector(1 downto 0);
    TXPOWERDOWN_IN                          : in   std_logic_vector(1 downto 0);
    ----------------------- Receive Ports - 8b10b Decoder ----------------------
    RXCHARISK_OUT                           : out  std_logic_vector(1 downto 0);
    RXDISPERR_OUT                           : out  std_logic_vector(1 downto 0);
    RXNOTINTABLE_OUT                        : out  std_logic_vector(1 downto 0);
    --------------- Receive Ports - Comma Detection and Alignment --------------
    RXBYTEREALIGN_OUT                       : out  std_logic;
    RXENMCOMMAALIGN_IN                      : in   std_logic;
    RXENPCOMMAALIGN_IN                      : in   std_logic;
    ------------------- Receive Ports - RX Data Path interface -----------------
    RXDATA_OUT                              : out  std_logic_vector(15 downto 0);
    RXRESET_IN                              : in   std_logic;
    RXUSRCLK2_IN                            : in   std_logic;
    ------- Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR ------
    RXN_IN                                  : in   std_logic;
    RXP_IN                                  : in   std_logic;
    -------- Receive Ports - RX Elastic Buffer and Phase Alignment Ports -------
    RXBUFSTATUS_OUT                         : out  std_logic;
    ------------------------ Receive Ports - RX PLL Ports ----------------------
    GTXRXRESET_IN                           : in   std_logic;
    MGTREFCLKRX_IN                          : in   std_logic_vector(1 downto 0);
    PLLRXRESET_IN                           : in   std_logic;
    RXPLLLKDET_OUT                          : out  std_logic;
    RXRESETDONE_OUT                         : out  std_logic;
    ----------------- Receive Ports - RX Polarity Control Ports --------------···--
    RXPOLARITY_IN                           : in   std_logic;
    ---------------- Transmit Ports - 8b10b Encoder Control Ports --------------
    TXCHARISK_IN                            : in   std_logic_vector(1 downto 0);
    TXKERR_OUT                              : out  std_logic_vector(1 downto 0);
    ------------------ Transmit Ports - TX Data Path interface -----------------
    TXDATA_IN                               : in   std_logic_vector(15 downto 0);
    TXOUTCLK_OUT                            : out  std_logic;
    TXRESET_IN                              : in   std_logic;
    TXUSRCLK2_IN                            : in   std_logic;
    ---------------- Transmit Ports - TX Driver and OOB signaling --------------
    TXN_OUT                                 : out  std_logic;
    TXP_OUT                                 : out  std_logic;
    ----------- Transmit Ports - TX Elastic Buffer and Phase Alignment ---------
    TXBUFSTATUS_OUT                         : out  std_logic;
    ----------------------- Transmit Ports - TX PLL Ports ----------------------
    GTXTXRESET_IN                           : in   std_logic;
    MGTREFCLKTX_IN                          : in   std_logic_vector(1 downto 0);
    PLLTXRESET_IN                           : in   std_logic;
    TXPLLLKDET_OUT                          : out  std_logic;
    TXRESETDONE_OUT                         : out  std_logic;
    -- Board clock to drive AR #35681 workaround logic
    -- This saves one BUFG instead of driving with GT REFCLK
    INIT_CLK_IN                             : in  std_logic;
    LINK_RESET_IN                           : in  std_logic_vector(1 downto 0)
);
end FOFB_CC_GTP7_TILE_WRAPPER;

architecture RTL of FOFB_CC_GTP7_TILE_WRAPPER is

-- ground and tied_to_vcc_i signals
signal  tied_to_ground_i                : std_logic;
signal  tied_to_ground_vec_i            : std_logic_vector(63 downto 0);
signal  tied_to_vcc_i                   : std_logic;

-- RX Datapath signals
signal rxdata_i                         : std_logic_vector(31 downto 0);
signal rxchariscomma_float_i            : std_logic_vector(1 downto 0);
signal rxcharisk_float_i                : std_logic_vector(1 downto 0);
signal rxdisperr_float_i                : std_logic_vector(1 downto 0);
signal rxnotintable_float_i             : std_logic_vector(1 downto 0);
signal rxrundisp_float_i                : std_logic_vector(1 downto 0);

-- TX Datapath signals
signal txdata_i                         : std_logic_vector(31 downto 0);
signal txkerr_float_i                   : std_logic_vector(1 downto 0);
signal txrundisp_float_i                : std_logic_vector(1 downto 0);

signal RXRESET_IN_BUF                   : std_logic;
signal RXPLLLKDET_BUF                   : std_logic;
signal count_for_reset                  : std_logic_vector(10 downto 0);
signal gtx_test1                        : std_logic;
signal gtxtest_w                        : std_logic_vector(12 downto 0);

signal RXBUFSTATUS                      : std_logic_vector(2 downto 0);
signal TXBUFSTATUS                      : std_logic_vector(1 downto 0);

begin

RXRESET_IN_BUF <= RXRESET_IN OR LINK_RESET_IN(1);

------------------- FIX for TX/RXPLL_DIVSEL_OUT = 2 or 4 ----------------------
-- Refer AR #35681 - Virtex-6 GTX Transceiver - MMCM fails to lock and
-- TX/RXRESETDONE fails to assert
RXPLLLKDET_OUT <= RXPLLLKDET_BUF;

process(INIT_CLK_IN)
begin
    if rising_edge(INIT_CLK_IN) then
        if(RXPLLLKDET_BUF = '1') then
            count_for_reset <= count_for_reset + 1;
            if(count_for_reset = "11100000000") then
                count_for_reset <= count_for_reset;
            end if;
        else
            count_for_reset <= "00000000000";
        end if;
    end if;
end process;

gtx_test1 <= '1' when ((count_for_reset > "10000000000") and (count_for_reset < "10100000000")) else
             '0' when ((count_for_reset > "10100000000") and (count_for_reset < "11000000000")) else
             '1' when ((count_for_reset > "11000000000") and (count_for_reset < "11100000000")) else
             '0';

gtxtest_w <= "1000000" & link_reset_in(0) & link_reset_in(0) & link_reset_in(0) & '0' & gtx_test1 & '0';

GTP7_TILE : entity work.FOFB_CC_GTP7_TILE
generic map (
    GTX_SIM_GTXRESET_SPEEDUP    => GTX_SIM_GTXRESET_SPEEDUP,
    GTX_TX_CLK_SOURCE           => "RXPLL",
    GTX_POWER_SAVE              => "0000110100"
)
port map (
    GTXTEST_IN                  => gtxtest_w,

    LOOPBACK_IN                 => LOOPBACK_IN,
    RXPOWERDOWN_IN              => RXPOWERDOWN_IN,
    TXPOWERDOWN_IN              => TXPOWERDOWN_IN,

    RXCHARISK_OUT               => RXCHARISK_OUT,
    RXDISPERR_OUT               => RXDISPERR_OUT,
    RXNOTINTABLE_OUT            => RXNOTINTABLE_OUT,

    RXBYTEREALIGN_OUT           => RXBYTEREALIGN_OUT,
    RXENMCOMMAALIGN_IN          => RXENMCOMMAALIGN_IN,
    RXENPCOMMAALIGN_IN          => RXENPCOMMAALIGN_IN,

    RXDATA_OUT                  => RXDATA_OUT,
    RXRESET_IN                  => RXRESET_IN_BUF,
    RXUSRCLK2_IN                => RXUSRCLK2_IN,

    RXN_IN                      => RXN_IN,
    RXP_IN                      => RXP_IN,

    RXBUFSTATUS_OUT             => RXBUFSTATUS,

    GTXRXRESET_IN               => GTXRXRESET_IN,
    MGTREFCLKRX_IN              => MGTREFCLKRX_IN,
    PLLRXRESET_IN               => PLLRXRESET_IN,
    RXPLLLKDET_OUT              => RXPLLLKDET_BUF,
    RXRESETDONE_OUT             => RXRESETDONE_OUT,

    RXPOLARITY_IN               => RXPOLARITY_IN,

    TXCHARISK_IN                => TXCHARISK_IN,
    TXKERR_OUT                  => TXKERR_OUT,

    TXDATA_IN                   => TXDATA_IN,
    TXOUTCLK_OUT                => TXOUTCLK_OUT,
    TXRESET_IN                  => TXRESET_IN,
    TXUSRCLK2_IN                => TXUSRCLK2_IN,

    TXN_OUT                     => TXN_OUT,
    TXP_OUT                     => TXP_OUT,

    TXBUFSTATUS_OUT             => TXBUFSTATUS,

    GTXTXRESET_IN               => GTXTXRESET_IN,
    MGTREFCLKTX_IN              => MGTREFCLKTX_IN,
    PLLTXRESET_IN               => PLLTXRESET_IN,
    TXPLLLKDET_OUT              => TXPLLLKDET_OUT,
    TXRESETDONE_OUT             => TXRESETDONE_OUT
);

TXBUFSTATUS_OUT <= TXBUFSTATUS(1);
RXBUFSTATUS_OUT <= RXBUFSTATUS(2);

end RTL;