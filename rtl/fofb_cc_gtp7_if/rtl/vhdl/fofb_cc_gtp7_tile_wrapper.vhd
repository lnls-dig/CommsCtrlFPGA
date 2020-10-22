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
    GT_SIM_GTRESET_SPEEDUP                  : integer  := 0  -- Set to 1 to speed up sim reset
);
port (
    rst_in                                  : in   std_logic;
    ---------------------------- Channel - DRP Ports  --------------------------
    drpclk_in                               : in   std_logic;
    ------------------------ GTPE2_CHANNEL Clocking Ports ----------------------
    pll0clk_in                              : in   std_logic;
    pll0refclk_in                           : in   std_logic;
    pll1clk_in                              : in   std_logic;
    pll1refclk_in                           : in   std_logic;    
    ------------------------------- Loopback Ports -----------------------------
    loopback_in                             : in   std_logic_vector(2 downto 0);
    ------------------------------ Power-Down Ports ----------------------------
    rxpd_in                                 : in   std_logic_vector(1 downto 0);
    txpd_in                                 : in   std_logic_vector(1 downto 0);
    --------------------- RX Initialization and Reset Ports --------------------
    rxuserrdy_in                            : in   std_logic;
    ------------------ Receive Ports - FPGA RX Interface Ports -----------------
    rxdata_out                              : out  std_logic_vector(15 downto 0);
    rxusrclk2_in                            : in   std_logic;
    ------------------ Receive Ports - RX 8B/10B Decoder Ports -----------------
    rxcharisk_out                           : out  std_logic_vector(1 downto 0);
    rxdisperr_out                           : out  std_logic_vector(1 downto 0);
    rxnotintable_out                        : out  std_logic_vector(1 downto 0);
    ------------------------ Receive Ports - RX AFE Ports ----------------------
    gtprxn_in                               : in   std_logic;
    gtprxp_in                               : in   std_logic;
    ------------------- Receive Ports - RX Buffer Bypass Ports -----------------
    rxbufstatus_out                         : out  std_logic;
    -------------- Receive Ports - RX Byte and Word Alignment Ports ------------
    rxbyterealign_out                       : out  std_logic;
    rxmcommaalignen_in                      : in   std_logic;
    rxpcommaalignen_in                      : in   std_logic;
    ------------- Receive Ports - RX Initialization and Reset Ports ------------
    gtrxreset_in                            : in   std_logic;    
    ----------------- Receive Ports - RX Polarity Control Ports ----------------
    rxpolarity_in                           : in   std_logic;
    -------------- Receive Ports -RX Initialization and Reset Ports ------------
    rxresetdone_out                         : out  std_logic;
    --------------------- TX Initialization and Reset Ports --------------------
    gttxreset_in                            : in   std_logic;
    txuserrdy_in                            : in   std_logic;
    ------------------ Transmit Ports - FPGA TX Interface Ports ----------------
    txdata_in                               : in   std_logic_vector(15 downto 0);
    txusrclk2_in                            : in   std_logic;
    ------------------ Transmit Ports - TX 8B/10B Encoder Ports ----------------
    txcharisk_in                            : in   std_logic_vector(1 downto 0);
    --------------- Transmit Ports - TX Configurable Driver Ports --------------
    gtptxn_out                              : out  std_logic;
    gtptxp_out                              : out  std_logic;
    ------------------- Transmit Ports - TX Buffer Ports -----------------------
    txbufstatus_out                         : out  std_logic;
    ----------- Transmit Ports - TX Fabric Clock Output Control Ports ----------
    txoutclk_out                            : out  std_logic;
    ------------- Transmit Ports - TX Initialization and Reset Ports -----------
    txresetdone_out                         : out  std_logic
);
end FOFB_CC_GTP7_TILE_WRAPPER;

architecture RTL of FOFB_CC_GTP7_TILE_WRAPPER is

  -- ground and tied_to_vcc_i signals
  signal  tied_to_ground_i                : std_logic := '0';

  -- Buffer status signals
  signal rxbufstatus                      : std_logic_vector(2 downto 0);
  signal txbufstatus                      : std_logic_vector(1 downto 0);

  -- Convert integer to "TRUE" or "FALSE" string
  function int2boolstr(intval : integer := 0) return string is
    variable stringval : string := "FALSE";
  begin
    if intval = 0 then
      stringval := "FALSE";
    else
      stringval := "TRUE";
    end if;
    return stringval;
  end function;

begin
  gtp7_tile : entity work.fofb_cc_gtp7_tile
  generic map (
    -- simulation attributes
    GT_SIM_GTRESET_SPEEDUP      => int2boolstr(GT_SIM_GTRESET_SPEEDUP)
  )
  port map (
    rst_in                      =>  rst_in,
    drp_busy_out                =>  open,
    rxpmaresetdone              =>  open,
    txpmaresetdone              =>  open,
    drpaddr_in                  =>  "000000000",
    drpclk_in                   =>  drpclk_in,
    drpdi_in                    =>  x"0000",
    drpdo_out                   =>  open,
    drpen_in                    =>  tied_to_ground_i,
    drprdy_out                  =>  open,
    drpwe_in                    =>  tied_to_ground_i,
    pll0clk_in                  =>  pll0clk_in,
    pll0refclk_in               =>  pll0refclk_in,
    pll1clk_in                  =>  pll1clk_in,
    pll1refclk_in               =>  pll1refclk_in,
    loopback_in                 =>  loopback_in,
    rxpd_in                     =>  rxpd_in,
    txpd_in                     =>  txpd_in,
    eyescanreset_in             =>  tied_to_ground_i,
    rxuserrdy_in                =>  rxuserrdy_in,
    eyescandataerror_out        =>  open,
    eyescantrigger_in           =>  tied_to_ground_i,
    rxclkcorcnt_out             =>  open,
    rxdata_out                  =>  rxdata_out,
    rxusrclk_in                 =>  rxusrclk2_in,
    rxusrclk2_in                =>  rxusrclk2_in,
    rxcharisk_out               =>  rxcharisk_out,
    rxdisperr_out               =>  rxdisperr_out,
    rxnotintable_out            =>  rxnotintable_out,
    gtprxn_in                   =>  gtprxn_in,
    gtprxp_in                   =>  gtprxp_in,
    rxbufstatus_out             =>  rxbufstatus,
    rxbyterealign_out           =>  rxbyterealign_out,
    rxmcommaalignen_in          =>  rxmcommaalignen_in,
    rxpcommaalignen_in          =>  rxpcommaalignen_in,
    dmonitorout_out             =>  open,
    rxlpmhfhold_in              =>  tied_to_ground_i,
    rxlpmlfhold_in              =>  tied_to_ground_i,
    rxoutclk_out                =>  open,
    rxoutclkfabric_out          =>  open,
    gtrxreset_in                =>  gtrxreset_in,
    rxlpmreset_in               =>  tied_to_ground_i,
    rxpolarity_in               =>  rxpolarity_in,
    rxresetdone_out             =>  rxresetdone_out,
    gttxreset_in                =>  gttxreset_in,
    txuserrdy_in                =>  txuserrdy_in,
    txdata_in                   =>  txdata_in,
    txusrclk_in                 =>  txusrclk2_in,
    txusrclk2_in                =>  txusrclk2_in,
    txcharisk_in                =>  txcharisk_in,
    gtptxn_out                  =>  gtptxn_out,
    gtptxp_out                  =>  gtptxp_out,
    txbufstatus_out             =>  txbufstatus,
    txoutclk_out                =>  txoutclk_out,
    txoutclkfabric_out          =>  open,
    txoutclkpcs_out             =>  open,
    txresetdone_out             =>  txresetdone_out
  );

  txbufstatus_out <= txbufstatus(1);
  rxbufstatus_out <= rxbufstatus(2);

end RTL;
