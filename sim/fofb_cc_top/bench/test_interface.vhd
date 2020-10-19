library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.textio.all;

-- Package Declaration

package test_interface is

subtype bpmid_range is integer range 9 downto 0;
subtype reserved_range is integer range 14 downto 10;
subtype tfstart_range is integer range 15 downto 15;
subtype timeframe_range is integer range 31 downto 16;

constant IDLE           : std_logic_vector (15 downto 0) :=X"BC95";
constant SOP            : std_logic_vector (15 downto 0) :=X"5CFB";
constant EOP            : std_logic_vector (15 downto 0) :=X"FDFE";
constant SENDID         : std_logic_vector (7 downto 0)  :=X"F7";
-- MGT protocol configuration constants

type intarray is array (INTEGER range <>) of integer;

shared variable bpmsent        : integer;
shared variable bpmrepeated    : integer := 0;
shared variable bpmreceived    : integer := 0;
shared variable bpmarray       : intarray(168 downto 0);

type cc_packet is
    record
        id          : std_logic_vector(7 downto 0);
        x_pos       : std_logic_vector(31 downto 0);
        y_pos       : std_logic_vector(31 downto 0);
end record;

type packets_array is array (natural range <>) of cc_packet;

shared variable sent_packets        : packets_array(255 downto 0);
shared variable received_packets    : packets_array(255 downto 0);

function vectorise (
    s: std_logic
) return std_logic_vector;

procedure writeNowToScreen (
    text_string             : in string
);

procedure writeNowWithDataToScreen (
    text_string             : in string;
    decValue                : in integer
);

procedure writeHexToScreen (
  text_string               : in string;
  hexValue                  : in std_logic_vector
);

procedure writeDecToScreen (
  text_string               : in string;
  decValue                  : in integer
);

procedure FINISH;

procedure FINISH_FAILURE;

procedure PROC_TX_CLK_EAT  (
    clock_count             : in integer;
    signal trn_clk          : in std_logic
);

procedure PROC_TX_CC_CFG_WRITE  (
    signal cc_cfg_clk       : in  std_logic;
    signal cc_cfg_addr      : out std_logic_vector(10 downto 0);
    signal cc_cfg_dat       : out std_logic_vector(31 downto 0);
    signal cc_cfg_wen       : out std_logic;
    addr                    : integer;
    val                     : integer
);

procedure PROC_TX_CONFIGURE_CC  (
    signal cc_cfg_clk       : in  std_logic;
    signal cc_cfg_addr      : out std_logic_vector(10 downto 0);
    signal cc_cfg_dat       : out std_logic_vector(31 downto 0);
    signal cc_cfg_wen       : out std_logic;
    signal fai_cfg_val      : out std_logic_vector(31 downto 0);
    id                      : integer;
    framelen                : integer;
    powerdown               : integer;
    loopback                : integer;
    payload                 : integer
);

procedure PROC_TX_ENABLE_CC  (
    signal fai_cfg_val      : out std_logic_vector(31 downto 0)
);

procedure PROC_TX_TFSOVERRIDE  (
    signal fai_cfg_val      : out std_logic_vector(31 downto 0)
);

procedure PROC_TX_SEND_PACKET  (
    signal mgtclk_i         : in  std_logic;
    signal tx_dat           : out std_logic_vector(127 downto 0);
    signal tx_dat_val       : out std_logic;
    timeframe_val           : in  integer;
    packet                  : in  cc_packet
);

end package test_interface;

-- Package Body
package body test_interface is

--************************************************************
--     Proc : writeNowToScreen
--     Inputs : Text String
--     Outputs : None
--     Description : Displays current simulation time and text string to
--          standard output.
--   *************************************************************

procedure writeNowToScreen (

  text_string                 : in string

) is

  variable L      : line;

begin

  write (L, String'("[ "));
  write (L, now);
  write (L, String'(" ] : "));
  write (L, text_string);
  writeline (output, L);

end writeNowToScreen;

--************************************************************
--     Proc : writeNowToScreen
--     Inputs : Text String
--     Outputs : None
--     Description : Displays current simulation time and text string to
--          standard output.
--   *************************************************************

procedure writeNowWithDataToScreen (

    text_string               : in string;
    decValue                  : in integer

) is

  variable L      : line;

begin

  write (L, String'("[ "));
  write (L, now);
  write (L, String'("] : "));
  write (L, text_string);
  write(L, decValue);
  writeline (output, L);

end writeNowWithDataToScreen;


--************************************************************
--     Proc : writeHexToRx
--     Inputs : hex value with bit width that is multiple of 4
--     Outputs : None
--     Description : Displays nibble aligned hex value to Rx file
--
--   *************************************************************

procedure writeHexToScreen (

  text_string               : in string;
  hexValue                  : in std_logic_vector

) is

  variable L      : line;

begin

  write (L, text_string);
  hwrite(L, hexValue);
  writeline (output, L);

end writeHexToScreen;


--************************************************************
--     Proc : writeHexToRx
--     Inputs : hex value with bit width that is multiple of 4
--     Outputs : None
--     Description : Displays nibble aligned hex value to Rx file
--
--   *************************************************************

procedure writeDecToScreen (

  text_string               : in string;
  decValue                  : in integer

) is

  variable L      : line;

begin

  write (L, text_string);
  write(L, decValue);
  writeline (output, L);

end writeDecToScreen;


--************************************************************
--  Proc : FINISH
--  Inputs : None
--  Outputs : None
--  Description : Ends simulation with successful message
--*************************************************************/

procedure FINISH is

  variable  L : line;

begin

  assert (false)
    report "Simulation Stopped."
    severity failure;

end FINISH;


--************************************************************
--  Proc : FINISH_FAILURE
--  Inputs : None
--  Outputs : None
--  Description : Ends simulation with failure message
--*************************************************************/

procedure FINISH_FAILURE is

  variable  L : line;

begin

  assert (false)
    report "Simulation Ended With 1 or more failures"
    severity failure;

end FINISH_FAILURE;


--************************************************************
--     Proc : 
--     Inputs : 
--     Outputs : 
--     Description : 
--
--*************************************************************
function vectorise (
    s: std_logic
) return std_logic_vector is

    variable v: std_logic_vector(0 downto 0);

begin

    v(0) := s;
    return v;

end vectorise;

--************************************************************
--    Proc : PROC_TX_CLK_EAT
--    Inputs : None
--    Outputs : None
--    Description : Consume clocks.
--*************************************************************/

procedure PROC_TX_CLK_EAT  (
    clock_count             : in integer;
    signal trn_clk          : in std_logic
) is

    variable i  : integer;

begin

  for i in 0 to (clock_count - 1) loop

    wait until (trn_clk'event and trn_clk = '1');

  end loop;

end PROC_TX_CLK_EAT;


--************************************************************
--    Proc : PROC_TX_CC_CFG_WRITE
--    Inputs :
--    Outputs :
--    Description : Write to CC configuration memory
--*************************************************************/
procedure PROC_TX_CC_CFG_WRITE  (
    signal cc_cfg_clk       : in  std_logic;
    signal cc_cfg_addr      : out std_logic_vector(10 downto 0);
    signal cc_cfg_dat       : out std_logic_vector(31 downto 0);
    signal cc_cfg_wen       : out std_logic;
    addr                    : in  integer;
    val                     : in  integer
) is

begin

    cc_cfg_addr <= std_logic_vector(to_unsigned(addr, 11));
    cc_cfg_dat <= std_logic_vector(to_unsigned(val, 32));
    cc_cfg_wen <= '1';

    PROC_TX_CLK_EAT (1, cc_cfg_clk);

    cc_cfg_addr <= (others => '0');
    cc_cfg_dat <= (others => '0');
    cc_cfg_wen <= '0';

    PROC_TX_CLK_EAT (1, cc_cfg_clk);

end PROC_TX_CC_CFG_WRITE;

--************************************************************
--    Proc : PROC_TX_CC_CFG_WRITE
--    Inputs : 
--    Outputs : 
--    Description : Configure Communication Controller
--*************************************************************/
procedure PROC_TX_CONFIGURE_CC  (
    signal cc_cfg_clk       : in  std_logic;
    signal cc_cfg_addr      : out std_logic_vector(10 downto 0);
    signal cc_cfg_dat       : out std_logic_vector(31 downto 0);
    signal cc_cfg_wen       : out std_logic;
    signal fai_cfg_val      : out std_logic_vector(31 downto 0);
    id                      : in integer;
    framelen                : in integer;
    powerdown               : in integer;
    loopback                : in integer;
    payload                 : in integer
) is

begin
    PROC_TX_CC_CFG_WRITE(cc_cfg_clk, cc_cfg_addr, cc_cfg_dat, cc_cfg_wen, 0, id);
    PROC_TX_CC_CFG_WRITE(cc_cfg_clk, cc_cfg_addr, cc_cfg_dat, cc_cfg_wen, 1, framelen);
    PROC_TX_CC_CFG_WRITE(cc_cfg_clk, cc_cfg_addr, cc_cfg_dat, cc_cfg_wen, 2, powerdown);
    PROC_TX_CC_CFG_WRITE(cc_cfg_clk, cc_cfg_addr, cc_cfg_dat, cc_cfg_wen, 3, loopback);
    PROC_TX_CC_CFG_WRITE(cc_cfg_clk, cc_cfg_addr, cc_cfg_dat, cc_cfg_wen, 9, payload);

    -- wait a bit
    PROC_TX_CLK_EAT (10, cc_cfg_clk);

    -- assert cfg_val flag
    fai_cfg_val(0) <= '0';
    PROC_TX_CLK_EAT (1, cc_cfg_clk);
    fai_cfg_val(0) <= '1';
    PROC_TX_CLK_EAT (1, cc_cfg_clk);
    fai_cfg_val(0) <= '0';

end PROC_TX_CONFIGURE_CC;

--************************************************************
--    Proc : PROC_TX_ENABLE_CC
--    Inputs : 
--    Outputs : 
--    Description : Enable Communication Controller
--*************************************************************/
procedure PROC_TX_ENABLE_CC  (
    signal fai_cfg_val  : out std_logic_vector(31 downto 0)
) is

begin

    fai_cfg_val(3) <= '1';

end PROC_TX_ENABLE_CC;

procedure PROC_TX_TFSOVERRIDE  (
    signal fai_cfg_val  : out std_logic_vector(31 downto 0)
) is

begin

    fai_cfg_val(4) <= '1';

end PROC_TX_TFSOVERRIDE;

--************************************************************
--    Proc : PROC_TX_SEND_PACKET
--    Inputs : 
--    Outputs : 
--    Description : Enable Communication Controller
--*************************************************************/
procedure PROC_TX_SEND_PACKET  (
    signal mgtclk_i         : in  std_logic;
    signal tx_dat           : out std_logic_vector(127 downto 0);
    signal tx_dat_val       : out std_logic;
    timeframe_val           : in  integer;
    packet                  : in  cc_packet
) is
    variable header         : std_logic_vector(31 downto 0);
    variable timestamp      : std_logic_vector(31 downto 0);
begin

    header := std_logic_vector(to_unsigned(timeframe_val, 16)) & '1' & "0000000" & packet.id;
    timestamp := std_logic_vector(to_unsigned(timeframe_val, 32));
    tx_dat <= header & packet.x_pos & packet.y_pos & timestamp;
    tx_dat_val <= '1';
    PROC_TX_CLK_EAT (1, mgtclk_i);
    tx_dat_val <= '0';
    PROC_TX_CLK_EAT (10, mgtclk_i);

end PROC_TX_SEND_PACKET;


end package body test_interface;
