----------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Purpose      : CRC32 computation module
--  Author       : Daniel Tavares (CNPEM/Sirius)
----------------------------------------------------------------------
--  Based on code provided by Diamond Light Source Ltd. and made publicly
--  available at https://github.com/dls-controls/CommsCtrlFPGA
----------------------------------------------------------------------
--  Description: This module is used to compute CRC32 using 16-bit data
--  input interface for the payload.
--
--  CRC module for data(15:0)
--   lfsr(31:0)=1+x^1+x^2+x^4+x^5+x^7+x^8+x^10+x^11+x^12+x^16+x^22+x^23+x^26+x^32;
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.fofb_cc_pkg.all;

entity fofb_cc_gtp7_crc32 is
  port (
    CRCIN           : in std_logic_vector (15 downto 0);
    CRCDATAVALID    : in std_logic;
    CRCRESET        : in std_logic;
    CRCCLK          : in std_logic;
    CRCOUT          : out std_logic_vector (31 downto 0)
);
end fofb_cc_gtp7_crc32;

architecture rtl of fofb_cc_gtp7_crc32 is

signal lfsr_q               : std_logic_vector (31 downto 0);
signal lfsr_c               : std_logic_vector (31 downto 0);
signal CRCDATAVALID_PREV    : std_logic;
signal CRCIN_PREV           : std_logic_vector (15 downto 0);

begin

-- To complie with existing Virtex2Pro and Virtex5 hardcore CRC32 IPs
-- 1./ Input data needs to be byte reversed
-- 2./ Outdata needs to be byte reversed and bit inverted

process(CRCCLK)
begin
    if rising_edge(CRCCLK) then
        CRCIN_PREV <= transpose_data(CRCIN);
        CRCDATAVALID_PREV <= CRCDATAVALID;
    end if;
end process;

CRCOUT <= not transpose_data(lfsr_q);

    lfsr_c(0) <= lfsr_q(16) xor lfsr_q(22) xor lfsr_q(25) xor lfsr_q(26) xor lfsr_q(28) xor CRCIN_PREV(0) xor CRCIN_PREV(6) xor CRCIN_PREV(9) xor CRCIN_PREV(10) xor CRCIN_PREV(12);
    lfsr_c(1) <= lfsr_q(16) xor lfsr_q(17) xor lfsr_q(22) xor lfsr_q(23) xor lfsr_q(25) xor lfsr_q(27) xor lfsr_q(28) xor lfsr_q(29) xor CRCIN_PREV(0) xor CRCIN_PREV(1) xor CRCIN_PREV(6) xor CRCIN_PREV(7) xor CRCIN_PREV(9) xor CRCIN_PREV(11) xor CRCIN_PREV(12) xor CRCIN_PREV(13);
    lfsr_c(2) <= lfsr_q(16) xor lfsr_q(17) xor lfsr_q(18) xor lfsr_q(22) xor lfsr_q(23) xor lfsr_q(24) xor lfsr_q(25) xor lfsr_q(29) xor lfsr_q(30) xor CRCIN_PREV(0) xor CRCIN_PREV(1) xor CRCIN_PREV(2) xor CRCIN_PREV(6) xor CRCIN_PREV(7) xor CRCIN_PREV(8) xor CRCIN_PREV(9) xor CRCIN_PREV(13) xor CRCIN_PREV(14);
    lfsr_c(3) <= lfsr_q(17) xor lfsr_q(18) xor lfsr_q(19) xor lfsr_q(23) xor lfsr_q(24) xor lfsr_q(25) xor lfsr_q(26) xor lfsr_q(30) xor lfsr_q(31) xor CRCIN_PREV(1) xor CRCIN_PREV(2) xor CRCIN_PREV(3) xor CRCIN_PREV(7) xor CRCIN_PREV(8) xor CRCIN_PREV(9) xor CRCIN_PREV(10) xor CRCIN_PREV(14) xor CRCIN_PREV(15);
    lfsr_c(4) <= lfsr_q(16) xor lfsr_q(18) xor lfsr_q(19) xor lfsr_q(20) xor lfsr_q(22) xor lfsr_q(24) xor lfsr_q(27) xor lfsr_q(28) xor lfsr_q(31) xor CRCIN_PREV(0) xor CRCIN_PREV(2) xor CRCIN_PREV(3) xor CRCIN_PREV(4) xor CRCIN_PREV(6) xor CRCIN_PREV(8) xor CRCIN_PREV(11) xor CRCIN_PREV(12) xor CRCIN_PREV(15);
    lfsr_c(5) <= lfsr_q(16) xor lfsr_q(17) xor lfsr_q(19) xor lfsr_q(20) xor lfsr_q(21) xor lfsr_q(22) xor lfsr_q(23) xor lfsr_q(26) xor lfsr_q(29) xor CRCIN_PREV(0) xor CRCIN_PREV(1) xor CRCIN_PREV(3) xor CRCIN_PREV(4) xor CRCIN_PREV(5) xor CRCIN_PREV(6) xor CRCIN_PREV(7) xor CRCIN_PREV(10) xor CRCIN_PREV(13);
    lfsr_c(6) <= lfsr_q(17) xor lfsr_q(18) xor lfsr_q(20) xor lfsr_q(21) xor lfsr_q(22) xor lfsr_q(23) xor lfsr_q(24) xor lfsr_q(27) xor lfsr_q(30) xor CRCIN_PREV(1) xor CRCIN_PREV(2) xor CRCIN_PREV(4) xor CRCIN_PREV(5) xor CRCIN_PREV(6) xor CRCIN_PREV(7) xor CRCIN_PREV(8) xor CRCIN_PREV(11) xor CRCIN_PREV(14);
    lfsr_c(7) <= lfsr_q(16) xor lfsr_q(18) xor lfsr_q(19) xor lfsr_q(21) xor lfsr_q(23) xor lfsr_q(24) xor lfsr_q(26) xor lfsr_q(31) xor CRCIN_PREV(0) xor CRCIN_PREV(2) xor CRCIN_PREV(3) xor CRCIN_PREV(5) xor CRCIN_PREV(7) xor CRCIN_PREV(8) xor CRCIN_PREV(10) xor CRCIN_PREV(15);
    lfsr_c(8) <= lfsr_q(16) xor lfsr_q(17) xor lfsr_q(19) xor lfsr_q(20) xor lfsr_q(24) xor lfsr_q(26) xor lfsr_q(27) xor lfsr_q(28) xor CRCIN_PREV(0) xor CRCIN_PREV(1) xor CRCIN_PREV(3) xor CRCIN_PREV(4) xor CRCIN_PREV(8) xor CRCIN_PREV(10) xor CRCIN_PREV(11) xor CRCIN_PREV(12);
    lfsr_c(9) <= lfsr_q(17) xor lfsr_q(18) xor lfsr_q(20) xor lfsr_q(21) xor lfsr_q(25) xor lfsr_q(27) xor lfsr_q(28) xor lfsr_q(29) xor CRCIN_PREV(1) xor CRCIN_PREV(2) xor CRCIN_PREV(4) xor CRCIN_PREV(5) xor CRCIN_PREV(9) xor CRCIN_PREV(11) xor CRCIN_PREV(12) xor CRCIN_PREV(13);
    lfsr_c(10) <= lfsr_q(16) xor lfsr_q(18) xor lfsr_q(19) xor lfsr_q(21) xor lfsr_q(25) xor lfsr_q(29) xor lfsr_q(30) xor CRCIN_PREV(0) xor CRCIN_PREV(2) xor CRCIN_PREV(3) xor CRCIN_PREV(5) xor CRCIN_PREV(9) xor CRCIN_PREV(13) xor CRCIN_PREV(14);
    lfsr_c(11) <= lfsr_q(16) xor lfsr_q(17) xor lfsr_q(19) xor lfsr_q(20) xor lfsr_q(25) xor lfsr_q(28) xor lfsr_q(30) xor lfsr_q(31) xor CRCIN_PREV(0) xor CRCIN_PREV(1) xor CRCIN_PREV(3) xor CRCIN_PREV(4) xor CRCIN_PREV(9) xor CRCIN_PREV(12) xor CRCIN_PREV(14) xor CRCIN_PREV(15);
    lfsr_c(12) <= lfsr_q(16) xor lfsr_q(17) xor lfsr_q(18) xor lfsr_q(20) xor lfsr_q(21) xor lfsr_q(22) xor lfsr_q(25) xor lfsr_q(28) xor lfsr_q(29) xor lfsr_q(31) xor CRCIN_PREV(0) xor CRCIN_PREV(1) xor CRCIN_PREV(2) xor CRCIN_PREV(4) xor CRCIN_PREV(5) xor CRCIN_PREV(6) xor CRCIN_PREV(9) xor CRCIN_PREV(12) xor CRCIN_PREV(13) xor CRCIN_PREV(15);
    lfsr_c(13) <= lfsr_q(17) xor lfsr_q(18) xor lfsr_q(19) xor lfsr_q(21) xor lfsr_q(22) xor lfsr_q(23) xor lfsr_q(26) xor lfsr_q(29) xor lfsr_q(30) xor CRCIN_PREV(1) xor CRCIN_PREV(2) xor CRCIN_PREV(3) xor CRCIN_PREV(5) xor CRCIN_PREV(6) xor CRCIN_PREV(7) xor CRCIN_PREV(10) xor CRCIN_PREV(13) xor CRCIN_PREV(14);
    lfsr_c(14) <= lfsr_q(18) xor lfsr_q(19) xor lfsr_q(20) xor lfsr_q(22) xor lfsr_q(23) xor lfsr_q(24) xor lfsr_q(27) xor lfsr_q(30) xor lfsr_q(31) xor CRCIN_PREV(2) xor CRCIN_PREV(3) xor CRCIN_PREV(4) xor CRCIN_PREV(6) xor CRCIN_PREV(7) xor CRCIN_PREV(8) xor CRCIN_PREV(11) xor CRCIN_PREV(14) xor CRCIN_PREV(15);
    lfsr_c(15) <= lfsr_q(19) xor lfsr_q(20) xor lfsr_q(21) xor lfsr_q(23) xor lfsr_q(24) xor lfsr_q(25) xor lfsr_q(28) xor lfsr_q(31) xor CRCIN_PREV(3) xor CRCIN_PREV(4) xor CRCIN_PREV(5) xor CRCIN_PREV(7) xor CRCIN_PREV(8) xor CRCIN_PREV(9) xor CRCIN_PREV(12) xor CRCIN_PREV(15);
    lfsr_c(16) <= lfsr_q(0) xor lfsr_q(16) xor lfsr_q(20) xor lfsr_q(21) xor lfsr_q(24) xor lfsr_q(28) xor lfsr_q(29) xor CRCIN_PREV(0) xor CRCIN_PREV(4) xor CRCIN_PREV(5) xor CRCIN_PREV(8) xor CRCIN_PREV(12) xor CRCIN_PREV(13);
    lfsr_c(17) <= lfsr_q(1) xor lfsr_q(17) xor lfsr_q(21) xor lfsr_q(22) xor lfsr_q(25) xor lfsr_q(29) xor lfsr_q(30) xor CRCIN_PREV(1) xor CRCIN_PREV(5) xor CRCIN_PREV(6) xor CRCIN_PREV(9) xor CRCIN_PREV(13) xor CRCIN_PREV(14);
    lfsr_c(18) <= lfsr_q(2) xor lfsr_q(18) xor lfsr_q(22) xor lfsr_q(23) xor lfsr_q(26) xor lfsr_q(30) xor lfsr_q(31) xor CRCIN_PREV(2) xor CRCIN_PREV(6) xor CRCIN_PREV(7) xor CRCIN_PREV(10) xor CRCIN_PREV(14) xor CRCIN_PREV(15);
    lfsr_c(19) <= lfsr_q(3) xor lfsr_q(19) xor lfsr_q(23) xor lfsr_q(24) xor lfsr_q(27) xor lfsr_q(31) xor CRCIN_PREV(3) xor CRCIN_PREV(7) xor CRCIN_PREV(8) xor CRCIN_PREV(11) xor CRCIN_PREV(15);
    lfsr_c(20) <= lfsr_q(4) xor lfsr_q(20) xor lfsr_q(24) xor lfsr_q(25) xor lfsr_q(28) xor CRCIN_PREV(4) xor CRCIN_PREV(8) xor CRCIN_PREV(9) xor CRCIN_PREV(12);
    lfsr_c(21) <= lfsr_q(5) xor lfsr_q(21) xor lfsr_q(25) xor lfsr_q(26) xor lfsr_q(29) xor CRCIN_PREV(5) xor CRCIN_PREV(9) xor CRCIN_PREV(10) xor CRCIN_PREV(13);
    lfsr_c(22) <= lfsr_q(6) xor lfsr_q(16) xor lfsr_q(25) xor lfsr_q(27) xor lfsr_q(28) xor lfsr_q(30) xor CRCIN_PREV(0) xor CRCIN_PREV(9) xor CRCIN_PREV(11) xor CRCIN_PREV(12) xor CRCIN_PREV(14);
    lfsr_c(23) <= lfsr_q(7) xor lfsr_q(16) xor lfsr_q(17) xor lfsr_q(22) xor lfsr_q(25) xor lfsr_q(29) xor lfsr_q(31) xor CRCIN_PREV(0) xor CRCIN_PREV(1) xor CRCIN_PREV(6) xor CRCIN_PREV(9) xor CRCIN_PREV(13) xor CRCIN_PREV(15);
    lfsr_c(24) <= lfsr_q(8) xor lfsr_q(17) xor lfsr_q(18) xor lfsr_q(23) xor lfsr_q(26) xor lfsr_q(30) xor CRCIN_PREV(1) xor CRCIN_PREV(2) xor CRCIN_PREV(7) xor CRCIN_PREV(10) xor CRCIN_PREV(14);
    lfsr_c(25) <= lfsr_q(9) xor lfsr_q(18) xor lfsr_q(19) xor lfsr_q(24) xor lfsr_q(27) xor lfsr_q(31) xor CRCIN_PREV(2) xor CRCIN_PREV(3) xor CRCIN_PREV(8) xor CRCIN_PREV(11) xor CRCIN_PREV(15);
    lfsr_c(26) <= lfsr_q(10) xor lfsr_q(16) xor lfsr_q(19) xor lfsr_q(20) xor lfsr_q(22) xor lfsr_q(26) xor CRCIN_PREV(0) xor CRCIN_PREV(3) xor CRCIN_PREV(4) xor CRCIN_PREV(6) xor CRCIN_PREV(10);
    lfsr_c(27) <= lfsr_q(11) xor lfsr_q(17) xor lfsr_q(20) xor lfsr_q(21) xor lfsr_q(23) xor lfsr_q(27) xor CRCIN_PREV(1) xor CRCIN_PREV(4) xor CRCIN_PREV(5) xor CRCIN_PREV(7) xor CRCIN_PREV(11);
    lfsr_c(28) <= lfsr_q(12) xor lfsr_q(18) xor lfsr_q(21) xor lfsr_q(22) xor lfsr_q(24) xor lfsr_q(28) xor CRCIN_PREV(2) xor CRCIN_PREV(5) xor CRCIN_PREV(6) xor CRCIN_PREV(8) xor CRCIN_PREV(12);
    lfsr_c(29) <= lfsr_q(13) xor lfsr_q(19) xor lfsr_q(22) xor lfsr_q(23) xor lfsr_q(25) xor lfsr_q(29) xor CRCIN_PREV(3) xor CRCIN_PREV(6) xor CRCIN_PREV(7) xor CRCIN_PREV(9) xor CRCIN_PREV(13);
    lfsr_c(30) <= lfsr_q(14) xor lfsr_q(20) xor lfsr_q(23) xor lfsr_q(24) xor lfsr_q(26) xor lfsr_q(30) xor CRCIN_PREV(4) xor CRCIN_PREV(7) xor CRCIN_PREV(8) xor CRCIN_PREV(10) xor CRCIN_PREV(14);
    lfsr_c(31) <= lfsr_q(15) xor lfsr_q(21) xor lfsr_q(24) xor lfsr_q(25) xor lfsr_q(27) xor lfsr_q(31) xor CRCIN_PREV(5) xor CRCIN_PREV(8) xor CRCIN_PREV(9) xor CRCIN_PREV(11) xor CRCIN_PREV(15);

process (CRCCLK,CRCRESET) begin
if (CRCCLK'EVENT and CRCCLK = '1') then
        if (CRCRESET = '1') then
        lfsr_q <= X"FFFFFFFF";
    else
        if (CRCDATAVALID_PREV = '1') then
            lfsr_q <= lfsr_c;
        end if;
    end if;
end if;
end process;

end architecture rtl; 