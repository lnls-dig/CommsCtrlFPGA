library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fofb_cc_fai_fa_gen is
    port (
        -- Fast acquisition data interface
        adcclk_i                : in  std_logic;
        adcreset_i              : in  std_logic;
        data_sel_i              : in  std_logic_vector(3 downto 0);
        -- Fast acquisition data interface
        fai_fa_block_start_o    : out std_logic;
        fai_fa_data_valid_o     : out std_logic;
        fai_fa_d_o              : out std_logic_vector(31 downto 0);
        -- Flags
        fai_enable_i            : in  std_logic;
        fai_trigger_i           : in  std_logic;
        fai_armed_o             : out std_logic
);
end fofb_cc_fai_fa_gen;

architecture rtl of fofb_cc_fai_fa_gen is

signal counter_10kHz            : integer;
signal puls_10kHz               : std_logic;
signal counter5bit              : unsigned(4 downto 0);
signal counter5bit_ena          : std_logic;
signal counter32bit             : unsigned(31 downto 0);
signal fai_trigger              : std_logic;
signal fai_trigger_rise         : std_logic;
signal fai_armed                : std_logic;

begin

fai_armed_o <= fai_armed;

--
-- Generate 10kHz clock for Synthetic BPM data generation
--
process(adcclk_i)
begin
    if rising_edge(adcclk_i) then
        if (fai_armed = '1') then
            if (counter_10kHz = 12500) then
                counter_10kHz <= 0;
                puls_10kHz <= '1';
            else
                counter_10kHz <= counter_10kHz + 1;
                puls_10kHz <= '0';
            end if;
        else
            counter_10kHz <= 0;
            puls_10kHz <= '0';
        end if;
    end if;
end process;


process(adcclk_i)
begin
    if rising_edge(adcclk_i) then
        -- External trigger to be used for synchronus trigger
        fai_trigger <= fai_trigger_i;
        fai_trigger_rise <= fai_trigger_i and not fai_trigger;

        if (fai_trigger_rise = '1') then
            fai_armed <= '1';
        elsif (fai_enable_i = '0') then
            fai_armed <= '0';
        end if;

        -- Strech 10kHz FA clock to 16 clock cycles
        if (puls_10kHz = '1') then
            counter5bit_ena <= '1';
        elsif (counter5bit(4) = '1') then
            counter5bit_ena <= '0';
        end if;

        if (counter5bit_ena = '1') then
            counter5bit <= counter5bit + 1;
        else
            counter5bit <= "00000";
        end if;

        if (puls_10kHz = '1') then
            counter32bit <= counter32bit + 1;
        end if;
    end if;
end process;

fai_fa_block_start_o <= counter5bit_ena;
fai_fa_data_valid_o <= counter5bit_ena;
fai_fa_d_o <= std_logic_vector(SHIFT_LEFT(counter32bit, to_integer(unsigned(data_sel_i))));

end rtl;
