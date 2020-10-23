library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

-----------------------------------------------
--  Entity declaration
-----------------------------------------------
entity fofb_cc_gtp7_rxcrc is
port (
    -- clocks and resets
    mgtclk_i        : in  std_logic;
    mgtreset_i      : in  std_logic;
    -- input data interface
    rx_d_i          : in  std_logic_vector(15 downto 0);
    rx_d_val_i      : in  std_logic;
    -- output data interface
    rx_d_o          : out std_logic_vector(15 downto 0);
    rx_d_val_o      : out std_logic;
    -- status outputs
    rx_crc_valid_o  : out std_logic;
    rx_crc_fail_o   : out std_logic
);
end fofb_cc_gtp7_rxcrc;

-----------------------------------------------
--  Architecture declaration
-----------------------------------------------
architecture rtl of fofb_cc_gtp7_rxcrc is

-----------------------------------------------
--  Signal declaration
-----------------------------------------------
type std_logic_2d_16bit is array (natural range <>) of std_logic_vector(15 downto 0);

constant RX_D_DEPTH     : integer := 13;

signal crc_rx_idat      : std_logic_vector(31 downto 0);
signal crc_rx_odat      : std_logic_vector(31 downto 0);
signal rx_d_val_r       : std_logic;
signal rx_d_line        : std_logic_2d_16bit(RX_D_DEPTH-1 downto 0);
signal rx_sof           : std_logic;
signal rx_eof           : std_logic;
signal rx_d_cnt         : unsigned(3 downto 0);
signal crc_rx_ival      : std_logic;
signal rx_sof_1_r       : std_logic;
signal rx_crc           : std_logic_vector(31 downto 0);
signal rx_odat_cnt      : unsigned(2 downto 0);
signal rx_odat_cnt_en   : std_logic;
signal crc_rst          : std_logic;

begin

-- Datawidth for CRC32 block is set to 16-bits, so core processes bits rx_d_i[31:0]
crc_rx_idat <= rx_d_line(0) & X"0000" ;

-- CRC reset assertion, this initializes the internal crc-reg with CRC_INIT value
rx_sof <= rx_d_val_i and not rx_d_val_r;
rx_eof <= not rx_d_val_i and rx_d_val_r;

process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        if (mgtreset_i = '1') then
            rx_d_val_r <= '0';
            rx_sof_1_r <= '0';
        else
            rx_d_val_r <= rx_d_val_i;
            rx_sof_1_r <= rx_sof;
        end if;
    end if;
end process;

process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        if (mgtreset_i = '1') then
            rx_d_cnt <= (others => '0');
        else
            if (rx_d_val_i = '1') then
                rx_d_cnt <= rx_d_cnt + 1;
            else
                rx_d_cnt <= (others => '0');
            end if;
        end if;
    end if;
end process;

-- Input data delay line
process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        for i in 0 to (RX_D_DEPTH-2) loop
            rx_d_line(i+1) <= rx_d_line(i);
        end loop;

        rx_d_line(0) <= rx_d_i;
    end if;
end process;

process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        if (mgtreset_i = '1') then
            crc_rx_ival <= '0';
        else
            if (rx_sof = '1') then
                crc_rx_ival <= '1';
            elsif (rx_d_cnt = "1010") then
                crc_rx_ival <= '0';
            end if;
        end if;
    end if;
end process;

rx_crc <= rx_d_line(1) & rx_d_line(0);

process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        if (mgtreset_i = '1') then
            rx_odat_cnt_en <= '0';
            rx_odat_cnt    <= "111";
        else
            if (rx_eof = '1' and crc_rx_odat =  rx_crc) then
                rx_odat_cnt_en <= '1';
            elsif (rx_odat_cnt = "000") then
                rx_odat_cnt_en <= '0';
            end if;

            if (rx_odat_cnt_en = '1') then
                rx_odat_cnt <= rx_odat_cnt - 1;
            else
                rx_odat_cnt <= "111";
            end if;
        end if;
    end if;
end process;

rx_d_o <= rx_d_line(12);
rx_d_val_o <= rx_odat_cnt_en;

-- Status information outputs, each 1 clock cycle pulse
process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        if (mgtreset_i = '1') then
            rx_crc_valid_o <= '0';
            rx_crc_fail_o <= '0';
        else
            if (rx_eof = '1') then
                if (crc_rx_odat =  rx_crc) then
                    rx_crc_valid_o <= '1';
                else
                    rx_crc_fail_o <= '1';
                end if;
            else
                rx_crc_valid_o <= '0';
                rx_crc_fail_o <= '0';
            end if;
        end if;
    end if;
end process;

-- Virtex-5 CRC32 block instantiation
crc_rst <= mgtreset_i or rx_sof_1_r;

rx_crc32 : entity work.fofb_cc_gtp7_crc32
port map (
    CRCOUT          => crc_rx_odat,
    CRCCLK          => mgtclk_i,
    CRCDATAVALID    => crc_rx_ival,
    CRCIN           => crc_rx_idat(31 downto 16),
    CRCRESET        => rx_sof_1_r
);

end rtl;