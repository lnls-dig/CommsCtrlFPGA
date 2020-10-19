library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity fofb_cc_gtx_crc32_tb is
end fofb_cc_gtx_crc32_tb;

architecture testbench of fofb_cc_gtx_crc32_tb is

procedure PROC_TX_CLK_EAT  (
    clock_count             : in integer;
    signal trn_clk          : in std_logic
);

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

signal  userclk             : std_logic := '0';
signal  mgtreset            : std_logic := '1';
signal  crcdatavalid        : std_logic;
signal  crcin               : unsigned(15 downto 0);
signal  crcin32             : unsigned(31 downto 0);
signal  crcout0             : std_logic_vector(31 downto 0);
signal  crcout1             : std_logic_vector(31 downto 0);
signal  crcreset            : std_logic;

constant data_width         : integer := 16;

begin

userclk <= not userclk after 5 ns;
mgtreset <= '0' after 100 ns;

crcin32 <= crcin & X"0000";

CRCIN_GEN : process
begin

    crcreset <= '0';
    crcin <= (others => '0');
    crcdatavalid <= '0';
    PROC_TX_CLK_EAT(100, userclk);

    for I in 0 to 9 loop
        if (I = 0) then
            crcreset <= '1';
        else
            crcreset <= '0';
        end if;
        crcdatavalid <= '1';
        crcin <= crcin + 1;
        PROC_TX_CLK_EAT(1, userclk);
    end loop;

    crcdatavalid <= '0';
    crcin <= (others => '0');
    PROC_TX_CLK_EAT(1000, userclk);

    wait;

end process;

--
-- Instantiate Virtex-5 CRC32 Macro
--
V5_CRC32_MACRO : CRC32
generic map(
    CRC_INIT        => X"FFFFFFFF"
)
port map (
    CRCOUT          => crcout0,
    CRCCLK          => userclk,
    CRCDATAVALID    => crcdatavalid,
    CRCDATAWIDTH    => "001",       -- 16-bit datawidth
    CRCIN           => std_logic_vector(crcin32),
    CRCRESET        => crcreset
);

V6_CRC_IMPL : entity work.fofb_cc_gtx_crc32
port map (
    CRCOUT          => crcout1,
    CRCCLK          => userclk,
    CRCDATAVALID    => crcdatavalid,
    CRCIN           => std_logic_vector(crcin),
    CRCRESET        => crcreset
);

end testbench;
