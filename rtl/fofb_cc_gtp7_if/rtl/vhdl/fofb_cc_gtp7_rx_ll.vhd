----------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Purpose      : 7-series GTP RX interface
--  Author       : Daniel Tavares (CNPEM/Sirius)
----------------------------------------------------------------------
--  Based on code provided by Diamond Light Source Ltd. and made publicly
--  available at https://github.com/dls-controls/CommsCtrlFPGA
----------------------------------------------------------------------
--  Description: This module handles RX data flow from GTP to
--  CC interface. It is responsible from:
--      * RX link initialisation
--      * Data flow control from GTP to CC RX FIFO
--      * Error detection including CRC32
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fofb_cc_gtp7_rx_ll is
    generic (
        RX_IDLE_NUM         : natural := 13    --4095 cc
    );
    port (
        mgtclk_i            : in  std_logic;
        mgtreset_i          : in  std_logic;
        sysclk_i            : in  std_logic;
        gtp_resetdone_i     : in  std_logic;
        rxreset_o           : out std_logic;
        powerdown_i         : in  std_logic;
        rxelecidlereset_i   : in  std_logic;
        -- status information
        rx_link_up_o        : out std_logic; 
        rxpck_cnt_o         : out std_logic_vector(15 downto 0);
        -- tx/rx state machine status for reset operation
        rx_sm_busy_o        : out std_logic;
        -- RX FIFO interface
        rxf_d_o             : out std_logic_vector(15 downto 0);
        rxf_d_val_o         : out std_logic;
        --
        rx_d_i              : in  std_logic_vector(15 downto 0);
        rxcharisk_i         : in  std_logic_vector(1 downto 0);
        -- network information
        tfs_bit_o           : out std_logic;
        link_partner_o      : out std_logic_vector(9 downto 0);
        pmc_timeframe_val_o : out std_logic_vector(15 downto 0);
        timestamp_val_o     : out std_logic_vector(31 downto 0);
        --
        timeframe_start_i   : in  std_logic;
        timeframe_valid_i   : in std_logic;
        timeframe_cntr_i    : in  std_logic_vector(15 downto 0);
        comma_align_o       : out std_logic;
        rxf_full_i          : in  std_logic;
        --
        rx_harderror_o      : out std_logic;
        rx_softerror_o      : out std_logic;
        rx_frameerror_o     : out std_logic;
        --
        rxbuferr_i          : in  std_logic;
        rxrealign_i         : in  std_logic;
        rxdisperr_i         : in  std_logic_vector(1 downto 0);
        rxnotintable_i      : in  std_logic_vector(1 downto 0)
    );
end fofb_cc_gtp7_rx_ll;

-----------------------------------------------
--  Architecture declaration
-----------------------------------------------
architecture rtl of fofb_cc_gtp7_rx_ll is

-- RocketIO protocol symbols
constant IDLE           : std_logic_vector (15 downto 0) :=X"BC95"; --/K28.5
constant SOP            : std_logic_vector (15 downto 0) :=X"5CFB"; --/K28.2/K27.7/
constant EOP            : std_logic_vector (15 downto 0) :=X"FDFE"; --/K29.7/K30.7/ 
constant SENDID_L       : std_logic_vector (7 downto 0)  := X"F7";  --/K23.7/
constant SENDID_H       : std_logic_vector (7 downto 0)  := X"1C";  --/K28.0/

-- MGT protocol configuration constants
constant RX_DELAY_NUM   : natural := 4;
constant SOFT_ERR_NUM   : natural := 8;

type rx_state_type is (rx_rst, rx_wait_resetdone, rx_idle, rx_synced);
signal rx_state         : rx_state_type;

type rx_data_state_type is (rx_crc_wait, rx_wait_0, rx_wait_1, rx_write_data);
signal rx_data_state    : rx_data_state_type;

-- rx_data shift register
type std_logic_2d_16 is array (natural range <>) of std_logic_vector(15 downto 0);
signal rx_dl                    : std_logic_2d_16(RX_DELAY_NUM-1 downto 0) := (others => X"0000");

signal counter_idle_rx          : unsigned(RX_IDLE_NUM-1 downto 0);
signal counter_odd_word_rx      : unsigned(3 downto 0);
signal rx_link_up               : std_logic;
signal payload_word_cnt         : unsigned(4 downto 0);
signal rx_d_val                 : std_logic;
signal rx_crc_d_val             : std_logic;
signal rx_crc_d_val_reg         : std_logic;
signal rx_crc_d_val_rise        : std_logic;
signal rx_crc_d                 : std_logic_vector(15 downto 0);
signal rx_payload_cnt           : unsigned(2 downto 0);
signal error_detect_ena         : std_logic;
signal rx_crcerror              : std_logic;
signal counter4bit              : unsigned(3 downto 0);
signal rxpck_cnt                : unsigned(15 downto 0);
signal rx_harderror             : std_logic;
signal rx_softerror             : std_logic;
signal rx_softerror_r           : std_logic_vector(1 downto 0);
signal rx_frameerror            : std_logic;

signal count_r                  : std_logic_vector(0 to 1);
signal bucket_full_r            : std_logic;
signal good_count_r             : std_logic_vector(0 to 1);

signal timestamp_val_lt         : std_logic_vector(31 downto 0);
signal pmc_timeframe_val_lt     : std_logic_vector(15 downto 0);
signal tfs_bit_lt               : std_logic;
signal link_partner             : std_logic_vector(9 downto 0);

begin

-- Output assignements
rxpck_cnt_o <= std_logic_vector(rxpck_cnt);
rx_link_up_o <= rx_link_up;
rx_harderror_o <= rx_harderror; 
rx_softerror_o <= rx_softerror;
rx_frameerror_o<= rx_frameerror;
link_partner_o <= link_partner when (rx_link_up = '1') else (others => '0');

------------------------------------------------------------
-- RX Link initialisation
------------------------------------------------------------
rx_init : process(mgtclk_i)
begin
if (mgtclk_i'event and mgtclk_i = '1') then
    if (mgtreset_i = '1' or rx_harderror = '1' or powerdown_i = '1' 
            or rxelecidlereset_i = '1'
            or counter_odd_word_rx(3) = '1') then
        rx_link_up          <= '0';
        counter_idle_rx     <= (others => '0');
        counter_odd_word_rx <= (others => '0');
        rx_state            <=  rx_rst;
        comma_align_o       <= '0';
        error_detect_ena    <= '0';
        rxreset_o           <= '0';
        counter4bit         <= "0000";
    else
        case (rx_state) is

            -- RocketIO RX reset for 7 clock cycles
            when rx_rst =>
                rxreset_o <= '1';
                if (counter4bit(3) = '1') then
                    rx_state <= rx_wait_resetdone;
                    rxreset_o <= '0';
                end if;
                counter4bit  <= counter4bit + 1;

            when rx_wait_resetdone =>
                if (gtp_resetdone_i = '1') then
                    rx_state <= rx_idle;
                end if;

            -- Wait to receive certain number of IDLE characters
            when rx_idle    =>

                comma_align_o <= '1';

                if (counter_idle_rx(RX_IDLE_NUM-1) = '1') then
                    rx_state <= rx_synced;
                end if;

                -- Wait for IDLE characters for alignment
                if (rx_d_i = IDLE and rxcharisk_i = "10") then
                    counter_idle_rx <=  counter_idle_rx + 1;
                else
                    counter_idle_rx <=  (others => '0');
                end if;

                -- Apply reset when odd word alignment is established
                if (rx_d_i = X"95BC" and rxcharisk_i = "01") then
                    counter_odd_word_rx <= counter_odd_word_rx + 1;
                else
                    counter_odd_word_rx <=  (others => '0');
                end if;

            -- Stay in synced until RESET condition occurs
            when rx_synced    =>
                rx_link_up <= '1';
                comma_align_o <= '0';
                error_detect_ena <= '1';

            when others =>

        end case;
    end if;
end if;
end process;

------------------------------------------------------------
-- Link partners are detected in each time frame. X"3FF" 
-- indicates that there is no connection on this particular 
-- channel.
------------------------------------------------------------
process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then
        if (mgtreset_i = '1' or rx_link_up = '0') then
            link_partner <= (others => '1');
        else
                if (rx_d_i(15 downto 8) = SENDID_L and rxcharisk_i = "10") then
                    link_partner(7 downto 0) <= rx_d_i(7 downto 0);
                end if;
                if (rx_d_i(15 downto 8) = SENDID_H and rxcharisk_i = "10") then
                    link_partner(9 downto 8) <= rx_d_i(1 downto 0);
                end if;
        end if;
    end if;
end process;

------------------------------------------------------------
-- Detects Start of Packet, and asserts data valid signal
-- for 12 clock cycles to CRC module
------------------------------------------------------------
process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then
        if (mgtreset_i = '1' or rx_link_up = '0') then
            payload_word_cnt <= (others => '0');
            rx_d_val             <= '0';
            pmc_timeframe_val_lt <= X"0000";
            tfs_bit_lt           <= '0';
            timestamp_val_lt     <= X"00000000";
        else
            if (rx_d_i = SOP and rxcharisk_i = "11") then
                rx_d_val <= '1';
            elsif (payload_word_cnt = 11) then
                rx_d_val <= '0';
            end if;

            if (rx_d_val = '1') then
                payload_word_cnt <= payload_word_cnt + 1;
            else
                payload_word_cnt <= (others => '0');
            end if;

            -- latch timeframe value from payload byte 1
            if (rx_d_val = '1' and payload_word_cnt = "00000") then
                pmc_timeframe_val_lt <= rx_d_i;
            end if;

            if (rx_d_val = '1' and payload_word_cnt = "00001") then
                tfs_bit_lt <= rx_d_i(15);
            end if;

            -- latch 32-bit timestamp value from payload bytes 7/8
            if (rx_d_val = '1' and payload_word_cnt = "00110") then
                timestamp_val_lt(31 downto 16) <= rx_d_i;
            end if;
            if (rx_d_val = '1' and payload_word_cnt = "00111") then
                timestamp_val_lt(15 downto 0) <= rx_d_i;
            end if;
        end if;
    end if;
end process;

------------------------------------------------------------
-- CRC32 calculation, if CRC is not valid, data is not 
-- written to rx fifo.
------------------------------------------------------------
rx_crc : entity work.fofb_cc_gtp7_rxcrc
    port map (
        mgtclk_i       => mgtclk_i,
        mgtreset_i     => mgtreset_i,
        rx_d_i         => rx_d_i,
        rx_d_val_i     => rx_d_val,
        rx_d_o         => rx_crc_d,
        rx_d_val_o     => rx_crc_d_val,
        rx_crc_valid_o => open,
        rx_crc_fail_o  => rx_crcerror
    );

------------------------------------------
-- Delay line for rx_data by RX_DELAY_NUM
------------------------------------------
process (mgtclk_i)
begin
  if (mgtclk_i'event and mgtclk_i = '1') then
     for i in 0 to (RX_DELAY_NUM-2) loop
        rx_dl(i+1) <= rx_dl(i);
     end loop;
     rx_dl(0) <= rx_crc_d;
  end if;
end process;

------------------------------------------
-- RX state machine
------------------------------------------
rx_crc_d_val_rise <= rx_crc_d_val and not rx_crc_d_val_reg;

check_rx_frame : process(mgtclk_i)
begin
if (mgtclk_i'event and mgtclk_i = '1') then

    if (mgtreset_i = '1' or rx_link_up = '0') then
        rx_data_state    <=  rx_crc_wait;
        rx_crc_d_val_reg <= '0';
    else

        rx_crc_d_val_reg <= rx_crc_d_val;

        case rx_data_state is
            -- wait for CRC checking flag, this indicates a packet has been received
            -- successfully
            when rx_crc_wait  =>
                if (rx_crc_d_val_rise = '1') then
                    rx_data_state <= rx_wait_0;
                end if;

            when rx_wait_0 =>
                rx_data_state <= rx_wait_1;

            -- wait to 1 clock cycle for time frame count to be registered for PMC ops
            when rx_wait_1 =>
                -- Discard packet when time frame does not match and time frame is not ended
                -- and RX fifo is not full
                if (rx_dl(1) = timeframe_cntr_i and timeframe_valid_i = '1' and rxf_full_i = '0') then
                    rx_data_state <= rx_write_data;
                else
                    rx_data_state <= rx_crc_wait;
                end if;

            -- start writing payload into RX fifo
            when rx_write_data  =>
                if (rx_payload_cnt = "000") then
                    rx_data_state <= rx_crc_wait;
                end if;

            when others =>

        end case;
    end if;
end if;
end process;

------------------------------------------
-- Extract time frame count value, and time frame start bit from
-- received packet
------------------------------------------
process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then
        if (mgtreset_i = '1' or rx_link_up = '0') then
            pmc_timeframe_val_o <= X"0000";
            tfs_bit_o <= '0';
            timestamp_val_o <= X"00000000";
        else
            if (rx_crc_d_val_rise = '1') then
                pmc_timeframe_val_o <= pmc_timeframe_val_lt;
                timestamp_val_o <= timestamp_val_lt;
                tfs_bit_o <= tfs_bit_lt;
            else
                tfs_bit_o <= '0';
            end if;
        end if;
    end if;
end process;

--
-- Write px payload into fifo
--
rxf_d_o <= rx_dl(3);

process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then
        if (mgtreset_i = '1' or rx_link_up = '0') then
            rx_payload_cnt <= "111";
            rxpck_cnt <= X"0000";
            rx_sm_busy_o <= '0';
            rxf_d_val_o <= '0';
        else
            if (rx_data_state = rx_write_data) then
                rx_payload_cnt <= rx_payload_cnt - 1;
            elsif (rx_payload_cnt = "000") then
                rx_payload_cnt <= "111";
            end if;

            if (rx_data_state = rx_write_data) then
                rxf_d_val_o <= '1';
            else
                rxf_d_val_o <= '0';
            end if;

            -- Received packet counter is with every packet
            if (timeframe_start_i = '1') then
                rxpck_cnt <= X"0000";
            -- Delay state since timeframe_start_i is extracted from the first 
            -- packet in PMC design
            elsif (rx_data_state = rx_wait_1) then
                rxpck_cnt <= rxpck_cnt + 1;
            end if;

            -- RX state machine status info
            if (rx_data_state = rx_crc_wait) then
                if (rx_crc_d_val_rise = '1') then
                    rx_sm_busy_o <= '1';
                else
                    rx_sm_busy_o <= '0';
                end if;
            end if;

        end if;
    end if;
end process;


--------------------------------------------------------
-- Soft and Frame error detection
-- Soft Error  : Dispersion and symbol errors
-- Frame Error : frame encapsulation or CRC errors
--------------------------------------------------------
process (mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then

        if (mgtreset_i = '1') then
            rx_frameerror  <= '0';
        else
            if (error_detect_ena = '1') then
                if (rx_crcerror = '1') then
                    rx_frameerror <= '1';
                else
                    rx_frameerror <= '0';
                end if;
            else
                rx_frameerror <= '0';
            end if;
        end if;
    end if;
end process;

-- Detect Soft Errors
process (mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then
        if (mgtreset_i = '1') then
            rx_softerror_r(0) <= '0';
            rx_softerror_r(1) <= '0';
            rx_softerror <= '0';
        else
            if (error_detect_ena = '1') then
                rx_softerror_r(0) <= rxdisperr_i(1) or rxnotintable_i(1);
                rx_softerror_r(1) <= rxdisperr_i(0) or rxnotintable_i(0);
            else
                rx_softerror_r(0) <= '0';
                rx_softerror_r(1) <= '0';
            end if;

            rx_softerror <= rx_softerror_r(0) or rx_softerror_r(1);

        end if;
    end if;
end process;

-- Detect Hard Errors
process (mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then

        if (mgtreset_i = '1') then
            rx_harderror   <= '0';
        else
            if (error_detect_ena = '1') then
                rx_harderror <= rxbuferr_i or rxrealign_i or bucket_full_r;
            else
                rx_harderror <= '0';
            end if;
        end if;
    end if;
end process;


-- Leaky Bucket --

-- Good cycle counter: it takes 2 consecutive good cycles to remove
-- a demerit from the leaky bucket.
process (mgtclk_i)
    variable err_vec : std_logic_vector(3 downto 0);
begin
    if (mgtclk_i 'event and mgtclk_i = '1') then
        if (error_detect_ena = '0') then
            good_count_r <= "01";
        else
            err_vec := rx_softerror_r & good_count_r;

            case err_vec is
                when "0000" => good_count_r <= "01";
                when "0001" => good_count_r <= "10";
                when "0010" => good_count_r <= "01";
                when "0011" => good_count_r <= "01";
                when others => good_count_r <= "00";
            end case;
        end if;
    end if;
end process;


-- Perform the leaky bucket algorithm using an up/down counter.  A drop is
-- added to the bucket whenever a soft error occurs and is allowed to leak
-- out whenever the good cycles counter reaches 2.  Once the bucket fills
-- (3 drops) it stays full until it is reset by disabling and then enabling
-- the error detection circuit.

process (mgtclk_i)
    variable leaky_bucket : std_logic_vector(4 downto 0);
begin

    if (mgtclk_i 'event and mgtclk_i = '1') then
        if (error_detect_ena = '0') then
            count_r <= "00";
        else

            leaky_bucket := rx_softerror_r & good_count_r(0) & count_r;
            case leaky_bucket is

                when "00000" => count_r <= count_r;
                when "00001" => count_r <= count_r;
                when "00010" => count_r <= count_r;
                when "00011" => count_r <= count_r;

                when "00100" => count_r <= "00";
                when "00101" => count_r <= "00";
                when "00110" => count_r <= "01";
                when "00111" => count_r <= "11";

                when "01000" => count_r <= "01";
                when "01001" => count_r <= "10";
                when "01010" => count_r <= "11";
                when "01011" => count_r <= "11";

                when "01100" => count_r <= "01";
                when "01101" => count_r <= "10";
                when "01110" => count_r <= "11";
                when "01111" => count_r <= "11";

                when "10000" => count_r <= "01";
                when "10001" => count_r <= "10";
                when "10010" => count_r <= "11";
                when "10011" => count_r <= "11";

                when "10100" => count_r <= "01";
                when "10101" => count_r <= "10";
                when "10110" => count_r <= "11";
                when "10111" => count_r <= "11";

                when "11000" => count_r <= "10";
                when "11001" => count_r <= "11";
                when "11010" => count_r <= "11";
                when "11011" => count_r <= "11";

                when "11100" => count_r <= "10";
                when "11101" => count_r <= "11";
                when "11110" => count_r <= "11";
                when "11111" => count_r <= "11";

                when others  => count_r <= "XX";
            end case;
        end if;
    end if;
end process;

-- Detect when the bucket is full and register the signal.
process (mgtclk_i)
begin
    if (mgtclk_i 'event and mgtclk_i = '1') then
        if (count_r = "11") then
            bucket_full_r <= '1';
        else
            bucket_full_r <= '0';
        end if;
    end if;
end process;

end rtl;
