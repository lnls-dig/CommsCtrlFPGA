library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity fofb_cc_fai_fa_gen is
    generic (
        FAI_DW                : integer := 16;
        -- Number of cycles to keep valid_o asserted
        FAI_VALID_CYCLES      : integer := 32
    );
    port (
        -- Fast acquisition data interface
        adcclk_i                : in  std_logic;
        adcreset_i              : in  std_logic;
        data_sel_i              : in  std_logic_vector(3 downto 0);
        -- Fast acquisition data interface
        fai_fa_block_start_o    : out std_logic;
        fai_fa_data_valid_o     : out std_logic;
        fai_fa_d_o              : out std_logic_vector(FAI_DW-1 downto 0);
        -- Flags
        fai_enable_i            : in  std_logic;
        fai_trigger_i           : in  std_logic;
        -- keep signal to '1' to keep generating internal 10 kHz trigger
        fai_trigger_internal_i  : in  std_logic := '0';
        fai_armed_o             : out std_logic
);
end fofb_cc_fai_fa_gen;

architecture rtl of fofb_cc_fai_fa_gen is

constant COUNTER_WIDTH          : integer := integer(ceil(log2(real(FAI_VALID_CYCLES))));

signal counter_10kHz            : integer;
signal puls_10kHz               : std_logic;
-- 1 bit more than necessary to detect end of count.
signal counter                  : unsigned(COUNTER_WIDTH downto 0);
signal counter_ena              : std_logic;
signal counter_fai_dw           : unsigned(FAI_DW-1 downto 0);
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
        if (adcreset_i = '1') then
            counter_10kHz <= 0;
            puls_10kHz <= '0';
        else
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
    end if;
end process;


process(adcclk_i)
begin
    if rising_edge(adcclk_i) then
        if (adcreset_i = '1') then
            fai_trigger <= '0';
            fai_trigger_rise <= '0';
            fai_armed <= '0';
            counter_ena <= '0';
            counter <= to_unsigned(0, counter'length);
            counter_fai_dw <= to_unsigned(0, counter_fai_dw'length);
        else
            -- External trigger to be used for synchronus trigger
            fai_trigger <= fai_trigger_i;
            fai_trigger_rise <= fai_trigger_i and not fai_trigger;

            if (fai_trigger_rise = '1' or fai_trigger_internal_i = '1') then
                fai_armed <= '1';
            elsif (fai_enable_i = '0') then
                fai_armed <= '0';
            end if;

            -- Strech 10kHz FA clock to 16 clock cycles
            if (puls_10kHz = '1') then
                counter_ena <= '1';
            elsif (counter(counter'left) = '1') then
                counter_ena <= '0';
            end if;

            if (counter_ena = '1') then
                counter <= counter + 1;
            else
                counter <= to_unsigned(0, counter'length);
            end if;

            if (puls_10kHz = '1') then
                counter_fai_dw <= counter_fai_dw + 1;
            end if;
        end if;
    end if;
end process;

fai_fa_block_start_o <= counter_ena;
fai_fa_data_valid_o <= counter_ena;
fai_fa_d_o <= std_logic_vector(SHIFT_LEFT(counter_fai_dw, to_integer(unsigned(data_sel_i))));

end rtl;
