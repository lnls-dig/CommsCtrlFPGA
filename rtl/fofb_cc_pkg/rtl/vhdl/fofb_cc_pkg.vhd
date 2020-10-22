----------------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller              
--  Filename     : fofb_cc_pkg.vhd                                    
--  Purpose      : CC parameters                         
--  Author       : Isa S. Uzun                                       
----------------------------------------------------------------------------
--  Copyright (c) 2007-2009 Diamond Light Source Ltd.                      
--  All rights reserved.                                              
----------------------------------------------------------------------------
--  Description: CC parameters                              
----------------------------------------------------------------------------
--  Limitations & Assumptions:                                        
----------------------------------------------------------------------------
--  Known Errors: This design is still under test. Please send any bug
--  reports to isa.uzun@diamond.ac.uk                       
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_cc_version.all;

package fofb_cc_pkg is

-- Functions
function vectorise(s: std_logic) return std_logic_vector;
function zeros(N: integer) return std_logic_vector;
-- Function to transpose CRC & Data
function transpose_data(inp : std_logic_vector) return std_logic_vector;
function tostd(inp : boolean) return std_logic;
-- Type definitions
-- 2D arrays
type std_logic_2d       is array (natural range <>) of std_logic_vector(31 downto 0);
type std_logic_2d_2     is array (natural range <>) of std_logic_vector(1 downto 0);
type std_logic_2d_3     is array (natural range <>) of std_logic_vector(2 downto 0);
type std_logic_2d_8     is array (natural range <>) of std_logic_vector(7 downto 0);
type std_logic_2d_9     is array (natural range <>) of std_logic_vector(8 downto 0);
type std_logic_2d_10    is array (natural range <>) of std_logic_vector(9 downto 0);
type std_logic_2d_16    is array (natural range <>) of std_logic_vector(15 downto 0);
type std_logic_2d_19    is array (natural range <>) of std_logic_vector(0 to 19);
type std_logic_2d_32    is array (natural range <>) of std_logic_vector(31 downto 0);
type std_logic_2d_128   is array (natural range <>) of std_logic_vector(127 downto 0);
type sys_state_type is (disabled, idle, enabled);

type device_t is (BPM, PMC, PMCEVR, PMCSFPEVR, SNIFFER, PBPM);

--------------------------- BPM Firmware Version -----------------------------
constant BPMFirmwareVersion : std_logic_vector(31 downto 0) := FPGAFirmwareVersion;
------------------------------------------------------------------------------

---------------------------------------------------
-- Default parameter values
---------------------------------------------------
-- default time frame length in cc
constant def_TimeFrameLength    : std_logic_vector(15 downto 0) := X"1D4C";
-- packet size in terms of fields (each field is 32-bit)
constant def_PacketSize         : integer := 4;
-- packet size in terms of  2-byte words (4x2 byte for packet, 2 byte dummy, 2 byte for CRC)
constant def_LinkLayerWordSize  : integer := 12;
-- default bpm id
constant def_BpmId              : std_logic_vector(9 downto 0):= (others => '1');
-- default node (including PMCs) count on the network
constant def_bpm_count          : std_logic_vector(9 downto 0):= "0000000111";
-- default timeframe start delay in cc
constant def_TimeFrameDelay    : std_logic_vector(15 downto 0) := X"0000";

constant PacketSize             : integer := def_PacketSize;
constant LinkLayerWordSize      : integer := def_LinkLayerWordSize;
--constant RioCount               : integer  := 4;      -- number of Rocketio channels

constant Status                 : boolean := true;    -- Include status info logic
constant SourceType             : std_logic_vector(2 downto 0) := "000";

-- Number of BPMs + PMCs on the network
-- Used in Forward and Discard module. It has to be power of 2.
-- Adjusting this parameter reduces logic
constant NodeNum                : integer := 512;   -- # of nodes
constant NodeW                  : integer := 9;     -- log2(NodeNum)

----------------------------------------------------------------------
-- ADDRESS SPACE
----------------------------------------------------------------------
-- CC Configuration Registers
----------------------------------------------------------------------
constant cc_cmd_bpm_id              : unsigned(7 downto 0)  := X"00";
constant cc_cmd_time_frame_len      : unsigned(7 downto 0)  := X"01";
constant cc_cmd_mgt_powerdown       : unsigned(7 downto 0)  := X"02";
constant cc_cmd_mgt_loopback        : unsigned(7 downto 0)  := X"03";
constant cc_cmd_time_frame_dly      : unsigned(7 downto 0)  := X"04";
constant cc_cmd_golden_orb_x        : unsigned(7 downto 0)  := X"05";
constant cc_cmd_golden_orb_y        : unsigned(7 downto 0)  := X"06";
constant cc_cmd_cust_feature        : unsigned(7 downto 0)  := X"07";
constant cc_cmd_rxpolarity          : unsigned(7 downto 0)  := X"08";
constant cc_cmd_payloadsel          : unsigned(7 downto 0)  := X"09";
constant cc_cmd_fofbdatasel         : unsigned(7 downto 0)  := X"0A";

----------------------------------------------------------------------
-- CC Status Registers
----------------------------------------------------------------------
constant cc_cmd_firmware_ver        : unsigned(7 downto 0)  := X"FF";
constant cc_cmd_sys_status          : unsigned(7 downto 0)  := X"00";
constant cc_cmd_link_partner_1      : unsigned(7 downto 0)  := X"01";
constant cc_cmd_link_partner_2      : unsigned(7 downto 0)  := X"02";
constant cc_cmd_link_partner_3      : unsigned(7 downto 0)  := X"03";
constant cc_cmd_link_partner_4      : unsigned(7 downto 0)  := X"04";
constant cc_cmd_link_up             : unsigned(7 downto 0)  := X"05";
constant cc_cmd_time_frame_count    : unsigned(7 downto 0)  := X"06";
constant cc_cmd_hard_err_cnt_1      : unsigned(7 downto 0)  := X"07";
constant cc_cmd_hard_err_cnt_2      : unsigned(7 downto 0)  := X"08";
constant cc_cmd_hard_err_cnt_3      : unsigned(7 downto 0)  := X"09";
constant cc_cmd_hard_err_cnt_4      : unsigned(7 downto 0)  := X"0A";
constant cc_cmd_soft_err_cnt_1      : unsigned(7 downto 0)  := X"0B";
constant cc_cmd_soft_err_cnt_2      : unsigned(7 downto 0)  := X"0C";
constant cc_cmd_soft_err_cnt_3      : unsigned(7 downto 0)  := X"0D";
constant cc_cmd_soft_err_cnt_4      : unsigned(7 downto 0)  := X"0E";
constant cc_cmd_frame_err_cnt_1     : unsigned(7 downto 0)  := X"0F";
constant cc_cmd_frame_err_cnt_2     : unsigned(7 downto 0)  := X"10";
constant cc_cmd_frame_err_cnt_3     : unsigned(7 downto 0)  := X"11";
constant cc_cmd_frame_err_cnt_4     : unsigned(7 downto 0)  := X"12";
constant cc_cmd_rx_pck_cnt_1        : unsigned(7 downto 0)  := X"13";
constant cc_cmd_rx_pck_cnt_2        : unsigned(7 downto 0)  := X"14";
constant cc_cmd_rx_pck_cnt_3        : unsigned(7 downto 0)  := X"15";
constant cc_cmd_rx_pck_cnt_4        : unsigned(7 downto 0)  := X"16";
constant cc_cmd_tx_pck_cnt_1        : unsigned(7 downto 0)  := X"17";
constant cc_cmd_tx_pck_cnt_2        : unsigned(7 downto 0)  := X"18";
constant cc_cmd_tx_pck_cnt_3        : unsigned(7 downto 0)  := X"19";
constant cc_cmd_tx_pck_cnt_4        : unsigned(7 downto 0)  := X"1A";
constant cc_cmd_fod_process_time    : unsigned(7 downto 0)  := X"1B";
constant cc_cmd_bpm_count           : unsigned(7 downto 0)  := X"1C";
constant cc_cmd_bpm_id_rdback       : unsigned(7 downto 0)  := X"1D";
constant cc_cmd_tf_length_rdback    : unsigned(7 downto 0)  := X"1E";
constant cc_cmd_powerdown_rdback    : unsigned(7 downto 0)  := X"1F";
constant cc_cmd_loopback_rdback     : unsigned(7 downto 0)  := X"20";
constant cc_cmd_faival_rdback       : unsigned(7 downto 0)  := X"21";
constant cc_cmd_feature_rdback      : unsigned(7 downto 0)  := X"22";
constant cc_cmd_rx_maxcount         : unsigned(7 downto 0)  := X"23";
constant cc_cmd_tx_maxcount         : unsigned(7 downto 0)  := X"24";

--
-- Global component declarations
--
component icon
    port (
        control0    : out std_logic_vector(35 downto 0)
    );
end component;

component ila
    port (
        control     : in  std_logic_vector(35 downto 0);
        clk         : in  std_logic;
        data        : in  std_logic_vector(63 downto 0);
        trig0       : in  std_logic_vector(7 downto 0)
     );
end component;

component ila_t16_d256_s1024
    port (
        control     : in  std_logic_vector(35 downto 0);
        clk         : in  std_logic;
        data        : in  std_logic_vector(255 downto 0);
        trig0       : in  std_logic_vector(15 downto 0)
     );
end component;

component ila_t8_d64_s16384
    port (
        control     : in  std_logic_vector(35 downto 0);
        clk         : in  std_logic;
        data        : in  std_logic_vector(63 downto 0);
        trig0       : in  std_logic_vector(7 downto 0)
     );
end component;

component ila_t8_d128_s8192
    port (
        control     : in  std_logic_vector(35 downto 0);
        clk         : in  std_logic;
        data        : in  std_logic_vector(127 downto 0);
        trig0       : in  std_logic_vector(7 downto 0)
     );
end component;

--
-- Conditional Chipscope generation defines
--
constant GTP7_IF_CSGEN      : boolean := FALSE;
constant GTX_IF_CSGEN       : boolean := FALSE;
constant GTPA_IF_CSGEN      : boolean := FALSE;

--
-- Selection of transceiver reference clock input
--
constant GTP7_IF_REFCLK     : string := "REFCLK0";

end fofb_cc_pkg;

-----------------------------------------------------------------------------------
--  Package Body
-----------------------------------------------------------------------------------
package body fofb_cc_pkg is

----------------------------------------------------------------------
-- Function for Transposing
----------------------------------------------------------------------
function vectorise(s: std_logic) return std_logic_vector is
    variable v: std_logic_vector(0 downto 0);
begin
    v(0) := s;
    return v;
end vectorise;

----------------------------------------------------------------------
-- Function for Transposing
----------------------------------------------------------------------
function zeros(N: integer) return std_logic_vector is
    variable v: std_logic_vector(N-1 downto 0);
begin
    v := (others => '0');
    return v;
end zeros;

----------------------------------------------------------------------
-- Function for Transposing
----------------------------------------------------------------------
function transpose_data (inp: std_logic_vector) return std_logic_vector is
    constant width       : integer := inp'length;
    variable transpose   : std_logic_vector(width - 1 downto 0);
begin
    for n in 0 to ((width/8) - 1) loop
        for l in 0 to 7 loop
            transpose((8*n) + 7 - l) := inp((n*8) + l);
        end loop;
    end loop;
    return(transpose);
end transpose_data;


function tostd(inp : boolean) return std_logic is
begin
    if inp then
        return('1');
    else
        return('0');
    end if;
end tostd;

end fofb_cc_pkg;
