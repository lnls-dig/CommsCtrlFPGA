----------------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Filename     : fofb_cc_frame_cntrl.vhd
--  Purpose      : Frame start control module
--  Author       : Isa S. Uzun
----------------------------------------------------------------------------
--  Copyright (c) 2007 Diamond Light Source Ltd.
--  All rights reserved.
----------------------------------------------------------------------------
--  Description: This module accepts internal and external (extracted from
--  an incloming packet) time frame start pulses, and generates one user pulse
--  to be used in the CC.
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_cc_pkg.all;   -- DLS FOFB package

-----------------------------------------------
--  Entity declaration
-----------------------------------------------
entity fofb_cc_frame_cntrl is
    generic (
        DEVICE              : device_t := BPM;
        USE_EXT_CC_IF       : boolean := false;
        LaneCount           : natural := 4
    );
    port (
        mgtclk_i            : in  std_logic;
        mgtreset_i          : in  std_logic;
        -- Time frame start input
        tfs_bpm_i           : in  std_logic;
        tfs_pmc_i           : in  std_logic_vector(LaneCount-1 downto 0);
        tfs_td_if_i         : in  std_logic := '1';
        tfs_override_i      : in  std_logic := '0';
        -- Time frame control outputs
        timeframe_len_i     : in  std_logic_vector(15 downto 0);
        timeframe_start_o   : out std_logic;
        timeframe_end_o     : out std_logic;
        timeframe_valid_o   : out std_logic;
        -- Timeframe number and timestamp information from PMC
        pmc_timeframe_cntr_i: in  std_logic_2d_16(LaneCount-1 downto 0);
        pmc_timestamp_val_i : in  std_logic_2d_32(LaneCount-1 downto 0);
        -- Timeframe number from TD_IF
        td_if_timeframe_cntr_i : in std_logic_vector(15 downto 0) := (others => '0');
        td_if_timestamp_val_i : in std_logic_vector(31 downto 0) := (others => '0');
        -- System timeframe count and timestamp information
        timeframe_cntr_o    : out std_logic_vector(31 downto 0);
        timestamp_value_o   : out std_logic_vector(31 downto 0)
    );
end fofb_cc_frame_cntrl;

-----------------------------------------------
--  Architecture declaration
-----------------------------------------------
architecture rtl of fofb_cc_frame_cntrl is

-----------------------------------------------
--  Signal declaration
-----------------------------------------------
type timeframe_state_type is (idle, active, dead);

signal timeframe_state      : timeframe_state_type;
signal tfbit_mgt_ored       : std_logic;
signal timeframe_cntr       : unsigned(31 downto 0);
signal pmc_timeframe_val    : std_logic_vector(15 downto 0);
signal pmc_timestamp_val    : std_logic_vector(31 downto 0);
signal td_if_timeframe_val  : std_logic_vector(15 downto 0);
signal td_if_timestamp_val  : std_logic_vector(31 downto 0);
signal timeframe_start      : std_logic;
signal counter_16bit        : unsigned(15 downto 0);
signal counter_10bit        : unsigned(9 downto 0);
signal timeframe_valid      : std_logic;
signal timeframe_valid_prev : std_logic;


function onehot_decode(x : std_logic_vector; size : integer) return std_logic_vector is
begin
    for j in 0 to x'left loop
        if x(j) /= '0' then
            return std_logic_vector(to_unsigned(j, size));
        end if;
    end loop;  -- i
    return std_logic_vector(to_unsigned(0, size));
end onehot_decode;

begin

-- timeframe_start pulse is generated (1) from fai data interface on
-- Libera BPMs, (2) from incoming packets for PMC, PBP and SNIFFER
-- designs. However, BPM setting can be overriden should BPM wants
-- to be a slave
timeframe_start <= tfs_bpm_i when (DEVICE = BPM and tfs_override_i = '0') else tfbit_mgt_ored;

-- timeframe count value is (1) incremented with every frame on BPM design,
-- (2) extracted from tandem interface if DEVICE is a DISTRIBUTOR,
-- (3) extracted from first arriving primary BPM packet on others
timeframe_cntr_o <= std_logic_vector(timeframe_cntr) when (DEVICE = BPM and tfs_override_i = '0') else
                       (X"0000" & td_if_timeframe_val) when (DEVICE = DISTRIBUTOR and USE_EXT_CC_IF) else
                       (X"0000" & pmc_timeframe_val);

timestamp_value_o <= td_if_timestamp_val when (DEVICE = DISTRIBUTOR and USE_EXT_CC_IF) else
                     pmc_timestamp_val;

---------------------------------------------------
-- timeframe start bits extracted form RocketIO
-- channels are ORed together
---------------------------------------------------
TimeFrameStartBit_Gen: process(mgtclk_i, tfs_pmc_i)
    variable tmp: std_logic := '0';
begin
    tmp := tfs_pmc_i(0);

    OR_bits: for N IN 1 TO (LaneCount-1) loop
        tmp := tmp or tfs_pmc_i(N);
    end loop;

    if DEVICE = DISTRIBUTOR and USE_EXT_CC_IF then
        tmp := tmp or tfs_td_if_i;
    end if;

    tfbit_mgt_ored <= tmp;
end process;

--------------------------------------------------------------------------
-- Each MGT channel extracts the timeframe_start bit from incoming primary BPM
-- packets, also :
-- timeframe_val value is extracted from first arriving packet's HEADER (as 16-bits)
-- timestamp_val value is extracted from first arriving packet's TIMESTAMP field (32-bits).
-- Information arriving later in the same timeframe is ignored.
--------------------------------------------------------------------------
process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then
        if (mgtreset_i = '1') then
            pmc_timeframe_val  <= (others => '0');
            td_if_timeframe_val <= (others => '0');
        else
            if (timeframe_state = idle) then
                pmc_timeframe_val  <= pmc_timeframe_cntr_i(to_integer(unsigned(onehot_decode(tfs_pmc_i, tfs_pmc_i'length))));
                pmc_timestamp_val <= pmc_timestamp_val_i(to_integer(unsigned(onehot_decode(tfs_pmc_i, tfs_pmc_i'length))));

                td_if_timeframe_val <= td_if_timeframe_cntr_i;
                td_if_timestamp_val <= td_if_timestamp_val_i;
            end if;
        end if;
    end if;
end process;

--------------------------------------------
-- Time frame control logic
--------------------------------------------
timeframe_valid_o <= timeframe_valid;
timeframe_start_o <= timeframe_valid and not timeframe_valid_prev;
timeframe_end_o <= not timeframe_valid and timeframe_valid_prev;

process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then
        if (mgtreset_i = '1') then
            timeframe_valid      <= '0';
            timeframe_valid_prev <= '0';
            timeframe_cntr       <= (others => '0');
            counter_16bit        <= (others => '0');
            counter_10bit        <= (others => '0');
            timeframe_state      <= idle;
        else

            timeframe_valid_prev <= timeframe_valid;

            case (timeframe_state) is
                -- Wait for external timeframe_start pulse (BPM or extracted)
                -- and then generate internal timeframe_start pulse for the
                -- CC modules
                when idle =>
                    counter_16bit <= (others => '0');
                    counter_10bit  <= (others => '0');
                    if (timeframe_start = '1') then
                        timeframe_valid <= '1';
                        timeframe_cntr <= timeframe_cntr + 1;
                        timeframe_state <= active;
                    end if;

                -- Timeframe is active, wait until end which is defined by
                -- timeframe_len_i value
                when active =>
                    counter_16bit <= counter_16bit + 1;
                    if (counter_16bit = unsigned(timeframe_len_i)) then
                        timeframe_valid <= '0';
                        timeframe_state <= dead;
                    end if;

                -- Wait for time frame start pulse to count time frame
                -- There is a 256 clock cycles dead period to allow TX/TX fifo
                -- reset and latching node mask register to PMC/PCIE
                when dead =>
                    counter_10bit <= counter_10bit + 1;
                    if (counter_10bit(8) = '1') then
                        timeframe_state <= idle;
                    end if;

                when others =>

            end case;
        end if;
    end if;
end process;

end rtl;
