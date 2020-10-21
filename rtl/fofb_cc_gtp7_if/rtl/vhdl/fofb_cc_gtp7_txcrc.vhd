library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.vcomponents.all;

-----------------------------------------------
--  Entity declaration
-----------------------------------------------
entity fofb_cc_gtp7_txcrc is
port (
    -- clocks and resets
    mgtclk_i        : in  std_logic;
    mgtreset_i      : in  std_logic;
    -- input data interface
    tx_d_i          : in  std_logic_vector(15 downto 0);
    tx_d_val_i      : in  std_logic;
    -- output data interface
    tx_d_o          : out std_logic_vector(15 downto 0);
    tx_d_val_o      : out std_logic := '0'
);
end fofb_cc_gtp7_txcrc;

-----------------------------------------------
--  Architecture declaration
-----------------------------------------------
architecture rtl of fofb_cc_gtp7_txcrc is

-----------------------------------------------
-- Signal declaration
-----------------------------------------------
signal crc_tx_idat      : std_logic_vector(31 downto 0);
signal crc_tx_odat      : std_logic_vector(31 downto 0);
signal tx_d_1_r         : std_logic_vector(15 downto 0);
signal tx_d_2_r         : std_logic_vector(15 downto 0);
signal crc_tx_d_1_r     : std_logic_vector(31 downto 0);
signal crc_tx_d_2_r     : std_logic_vector(31 downto 0);
signal tx_eof           : std_logic;
signal tx_eof_1_r       : std_logic;
signal tx_eof_2_r       : std_logic;
signal tx_eof_3_r       : std_logic;
signal tx_sof           : std_logic;
signal tx_sof_1_r       : std_logic;
signal tx_d_val_r       : std_logic;
signal crc_rst          : std_logic;

begin

-- Datawidth for CRC32 block is set to 16-bits, so core processes bits tx_d_i[31:0]
crc_tx_idat <= tx_d_i & X"0000" ;

-- CRC reset assertion, this initializes the internal crc-reg with CRC_INIT value
tx_sof <= tx_d_val_i and not tx_d_val_r;
tx_eof <= not tx_d_val_i and tx_d_val_r;

process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        if (mgtreset_i = '1') then
            tx_d_val_r <= '0';
        else
            tx_d_val_r <= tx_d_val_i;
        end if;
    end if;
end process;

process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        if (mgtreset_i = '1') then
            tx_d_1_r <= X"0000"; 
            tx_d_2_r <= X"0000";
        else
            tx_d_1_r <= tx_d_i;
            tx_d_2_r <= tx_d_1_r;
        end if;
    end if;
end process;

process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        if (mgtreset_i = '1') then
            crc_tx_d_1_r <= (others => '0');
            crc_tx_d_2_r <= (others => '0');
        else
            crc_tx_d_1_r <= crc_tx_odat;
            crc_tx_d_2_r <= crc_tx_d_1_r;
        end if;
    end if;
end process;

process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        if (mgtreset_i = '1') then
            tx_sof_1_r <= '0'; 
            tx_eof_1_r <= '0'; 
            tx_eof_2_r <= '0'; 
            tx_eof_3_r <= '0'; 
        else
            tx_sof_1_r <= tx_sof;
            tx_eof_1_r <= tx_eof;
            tx_eof_2_r <= tx_eof_1_r;
            tx_eof_3_r <= tx_eof_2_r;
        end if;
    end if;
end process;

process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        if (mgtreset_i = '1') then
            tx_d_o <= X"0000";
        else
            if (tx_eof_1_r = '1') then
                tx_d_o <= crc_tx_odat(31 downto 16);
            elsif (tx_eof_2_r = '1') then
                tx_d_o <= crc_tx_d_1_r(15 downto 0);
            else
                tx_d_o <= tx_d_1_r;
            end if;
        end if;
    end if;
end process;

process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        if (mgtreset_i = '1') then
            tx_d_val_o <= '0';
        else
            if (tx_sof_1_r = '1') then
                tx_d_val_o <= '1';
            elsif (tx_eof_3_r = '1') then
                tx_d_val_o <= '0';
            end if;
        end if;
    end if;
end process;

crc_rst <= mgtreset_i or tx_sof;

tx_crc32 : entity work.fofb_cc_gtp7_crc32
port map (
    CRCOUT          => crc_tx_odat,
    CRCCLK          => mgtclk_i,
    CRCDATAVALID    => tx_d_val_i,
    CRCIN           => crc_tx_idat(31 downto 16),
    CRCRESET        => crc_rst
);

end rtl;