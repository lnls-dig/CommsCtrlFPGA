----------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Purpose      : 7-series GTP TX interface
--  Author       : Daniel Tavares (CNPEM/Sirius)
----------------------------------------------------------------------
--  Based on code provided by Diamond Light Source Ltd. and made publicly
--  available at https://github.com/dls-controls/CommsCtrlFPGA
----------------------------------------------------------------------
--  Description: This module handles TX data flow from CC interface to
--  GTP. It is responsible from:
--      * TX link initialisation
--      * Data flow control from CC TX FIFO to GTP
--      * Error detection including CRC32
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_cc_pkg.all;
-----------------------------------------------
--  Entity declaration
-----------------------------------------------
entity fofb_cc_gtp7_tx_ll is
    generic (
        TX_IDLE_NUM             : natural := 16;    --32767 cc
        SEND_ID_NUM             : natural := 14     --8191 cc
    );
    port (
        mgtclk_i                : in  std_logic;
        mgtreset_i              : in  std_logic;
        sysclk_i                : in  std_logic;
        gtp_resetdone_i         : in  std_logic;
        txreset_o               : out std_logic;
        powerdown_i             : in  std_logic;
        -- time frame sync
        timeframe_start_i       : in std_logic;
        timeframe_valid_i       : in std_logic;
        bpmid_i                 : in  std_logic_vector(NodeW-1 downto 0);
        -- status information
        tx_link_up_o            : out std_logic; 
        txpck_cnt_o             : out std_logic_vector(15 downto 0);
        -- tx/rx state machine status for reset operation
        tx_sm_busy_o            : out std_logic;
        -- TX FIFO interface
        txf_d_i                 : in  std_logic_vector(15 downto 0);
        txf_empty_i             : in  std_logic;
        txf_rd_en_o             : out std_logic;
        --
        tx_d_o                  : out std_logic_vector(15 downto 0);
        txcharisk_o             : out std_logic_vector(1 downto 0);
        --
        txkerr_i                : in  std_logic_vector(1 downto 0);
        txbuferr_i              : in  std_logic;
        --
        tx_harderror_o          : out std_logic
    );
end fofb_cc_gtp7_tx_ll;

-----------------------------------------------
--  Architecture declaration
-----------------------------------------------
architecture rtl of fofb_cc_gtp7_tx_ll is

-----------------------------------------------
--  Signal declaration
-----------------------------------------------
-- RocketIO protocol symbols
constant IDLE           : std_logic_vector (15 downto 0) :=X"BC95"; --/K28.5
constant SOP            : std_logic_vector (15 downto 0) :=X"5CFB"; --/K28.2/K27.7/
constant EOP            : std_logic_vector (15 downto 0) :=X"FDFE"; --/K29.7/K30.7/ 
constant SENDID_L       : std_logic_vector (7 downto 0)  := X"F7";   --/K23.7/
constant SENDID_H       : std_logic_vector (7 downto 0)  := X"1C";   --/K28.0/

-- state machine declarations
type tx_state_type is (tx_wait_resetdone, tx_sync, tx_idle, tx_sop, tx_payload, tx_eop);
signal tx_state                 : tx_state_type;

signal txf_rd_en                : std_logic;
signal txf_rd_cnt               : unsigned(2 downto 0);
signal tx_d_eof                 : std_logic;
signal tx_d_eof_1_r             : std_logic;
signal tx_d_val                 : std_logic;
signal tx_d_val_r               : std_logic;
signal tx_d                     : std_logic_vector(15 downto 0);
signal tx_d_1_r                 : std_logic_vector(15 downto 0);
signal tx_d_2_r                 : std_logic_vector(15 downto 0);
signal counter_idle_tx          : unsigned(TX_IDLE_NUM-1 downto 0);
signal send_id_cnt              : unsigned(SEND_ID_NUM-1 downto 0);
signal tx_crc_din_val_r         : std_logic;
signal tx_crc_din_val           : std_logic;
signal tx_crc_din_val_cnt       : unsigned(3 downto 0);
signal error_detect_ena         : std_logic;
signal counter4bit              : unsigned(3 downto 0);
signal txpck_cnt                : unsigned(15 downto 0);
signal tx_harderror             : std_logic;
signal send_id                  : std_logic;
signal send_id_prev             : std_logic;
signal mgtreset_sysclk_sync     : std_logic;
signal tx_harderror_sysclk_sync : std_logic;
signal powerdown_sysclk_sync    : std_logic;
signal txreset_req_done         : std_logic;
signal txreset_req_done_sync_mgtclk  : std_logic;

begin

txf_rd_en_o  <= txf_rd_en;
tx_harderror_o <= tx_harderror;
txpck_cnt_o <= std_logic_vector(txpck_cnt);


-- If TX_FIFO has packets, start...
-- TX_FIFO_EMPTY is set to '1' during FIFO reset.
process (mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then

        if (mgtreset_i = '1') then
            txf_rd_en <= '0';
            txf_rd_cnt <= "111";
            tx_crc_din_val <= '0';
            tx_crc_din_val_r <= '0';
            tx_crc_din_val_cnt <= "1001";
        else
            -- Read 8x16-bit words from tx fifo
            if (txf_empty_i = '0' and timeframe_valid_i = '1' and
                    txf_rd_en = '0' and tx_state = tx_idle) then
                txf_rd_en <= '1';
            elsif (txf_rd_cnt = "000") then
                txf_rd_en <= '0';
            end if;

            if (txf_rd_en = '1') then
                txf_rd_cnt <= txf_rd_cnt - 1;
            end if;

            -- Data train to CRC32 block is 10x16-bit in length. Therefore, we need a
            -- seperate counter
            if (txf_empty_i = '0' and timeframe_valid_i = '1' and
                    tx_crc_din_val = '0' and tx_state = tx_idle) then
                tx_crc_din_val <= '1';
            elsif (tx_crc_din_val_cnt = "0000") then
                tx_crc_din_val <= '0';
            end if;

            if (tx_crc_din_val = '1') then
                tx_crc_din_val_cnt <= tx_crc_din_val_cnt - 1;
            else
                tx_crc_din_val_cnt <= "1001";
            end if;

            tx_crc_din_val_r <= tx_crc_din_val;
        end if;
    end if;
end process;

-- CRC32 block computed CRC on incoming data from TX Fifo, and appends it
-- at the end of the data
tx_crc : entity work.fofb_cc_gtp7_txcrc
port map (
      mgtclk_i      => mgtclk_i,
      mgtreset_i    => mgtreset_i,
      tx_d_i        => txf_d_i,
      tx_d_val_i    => tx_crc_din_val_r,
      tx_d_o        => tx_d,
      tx_d_val_o    => tx_d_val
    );

tx_d_eof <= not tx_d_val and tx_d_val_r;

process (mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then
        if (mgtreset_i = '1') then
            tx_d_val_r <= '0';
            tx_d_eof_1_r <= '0';
            tx_d_1_r <= X"0000";
            tx_d_2_r <= X"0000";
        else
            tx_d_val_r <= tx_d_val;
            tx_d_eof_1_r <= tx_d_eof;
            tx_d_1_r    <= tx_d;
            tx_d_2_r    <= tx_d_1_r;
        end if;
    end if;
end process;

process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then
        if (mgtreset_i = '1') then
            txpck_cnt <= X"0000";
        else
            if (timeframe_start_i = '1') then
                txpck_cnt <= X"0000";
            elsif (tx_state = tx_eop) then
                txpck_cnt <= txpck_cnt + 1;
            end if;
        end if;
    end if;
end process;

------------------------------------------
-- TX reset
------------------------------------------

-- Sync signals from mgtclk_i to sysclk_i. These are "long" (>5 src clock periods)
-- pulses and the clocks are not "too" different in frequeneyc (<50%) so we
-- shouldn't experience problems with simple 2FF synchronizers.
sync_mgtreset : entity work.fofb_cc_syncff
    port map (
        clk_i       => sysclk_i,
        dat_i       => mgtreset_i,
        dat_o       => mgtreset_sysclk_sync
    );

sync_tx_harderror : entity work.fofb_cc_syncff
    port map (
        clk_i       => sysclk_i,
        dat_i       => tx_harderror,
        dat_o       => tx_harderror_sysclk_sync
    );

sync_powerdown : entity work.fofb_cc_syncff
    port map (
        clk_i       => sysclk_i,
        dat_i       => powerdown_i,
        dat_o       => powerdown_sysclk_sync
    );

gen_tx_reset : process(sysclk_i)
begin
    if (sysclk_i'event and sysclk_i = '1') then

        if (mgtreset_sysclk_sync = '1' or tx_harderror_sysclk_sync = '1' or
            powerdown_sysclk_sync = '1') then
            counter4bit         <= "0000";
            txreset_o           <= '0';
            txreset_req_done    <= '0';
        else
            -- RocketIO TX reset for 7 clock cycles
            if (counter4bit(3) = '1') then
                txreset_req_done <= '1';
                txreset_o <= '0';
            else
                counter4bit <= counter4bit + 1;
                txreset_o <= '1';
            end if;
        end if;
    end if;
end process;

sync_txreset_req : entity work.fofb_cc_syncff
    port map (
        clk_i       => mgtclk_i,
        dat_i       => txreset_req_done,
        dat_o       => txreset_req_done_sync_mgtclk
    );

------------------------------------------
-- TX state machine
------------------------------------------
gen_tx_data : process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then

        if (mgtreset_i = '1' or tx_harderror = '1' or powerdown_i = '1') then
            tx_state            <= tx_wait_resetdone;
            tx_d_o              <= X"0000";
            txcharisk_o         <= "00";
            tx_link_up_o        <= '0';
            counter_idle_tx     <= (others => '0');
            send_id_cnt         <=  (others => '0');
            tx_sm_busy_o        <= '0';
            error_detect_ena    <= '0';
        else

            case tx_state is

                -- Wait for GTP resetdone signal
                when tx_wait_resetdone  =>
                    if (gtp_resetdone_i = '1') then
                        tx_state <= tx_sync;
                    end if;

                -- send IDLE characters for synchronisation
                when tx_sync    =>
                    tx_d_o          <= IDLE;
                    txcharisk_o     <= "10";
                    counter_idle_tx <= counter_idle_tx + 1;

                    if (counter_idle_tx(TX_IDLE_NUM-1) = '1') then
                        tx_state        <= tx_idle;
                    end if;

                -- start TX operation
                when tx_idle  =>
                    if (tx_d_val = '1') then
                        tx_state         <= tx_sop;
                        tx_sm_busy_o     <= '1';
                    else
                        tx_state         <= tx_idle;
                        tx_sm_busy_o     <= '0';
                    end if;

                    -- Inject owm BPM ID periodically only in tx_idle state
                    send_id <= send_id_cnt(SEND_ID_NUM-1) and not timeframe_valid_i;
                    send_id_prev <= send_id;

                    if (send_id = '1') then
                        send_id_cnt <= (others => '0');
                    else
                        send_id_cnt <= send_id_cnt + 1;
                    end if;

                    if (send_id = '1') then
                        tx_d_o <= SENDID_L &
                                  bpmid_i(7 downto 0);
                    elsif (send_id_prev = '1') then
                        tx_d_o <= SENDID_H &
                                  (7 downto (NodeW-8) => '0') &
                                  bpmid_i(NodeW-1 downto 8);
                    else
                        tx_d_o <= IDLE;
                    end if;

                    error_detect_ena <= '1';
                    txcharisk_o      <= "10";
                    tx_link_up_o     <= '1';

                -- Start packet encapsulation
                when tx_sop =>
                    tx_d_o      <= SOP;
                    tx_state    <= tx_payload;
                    txcharisk_o <= "11";

                -- Inject payload
                when tx_payload =>

                    tx_d_o   <= tx_d_2_r;
                    txcharisk_o <= "00";

                    if (tx_d_eof_1_r = '1') then
                        tx_state       <= tx_eop;
                    else
                        tx_state       <= tx_payload;
                    end if;

                -- Stop encapsulation
                when tx_eop =>
                    tx_d_o       <= EOP;
                    txcharisk_o  <= "11";
                    tx_state     <= tx_idle;

                when others =>
                    tx_d_o   <= IDLE;
                    txcharisk_o <= "10";
                    tx_state        <= tx_idle;
            end case;
        end if;
    end if;
end process;

-------------------------------------------------------
-- TX error handling
--------------------------------------------------------
process (mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then

        if (mgtreset_i = '1') then
            tx_harderror   <= '0';
        else
            -- Detect hard error, asserted for 1 cc.
            if (error_detect_ena = '1') then
                if (txkerr_i /= "00" or txbuferr_i = '1') then
                    tx_harderror <= '1';
                end if;
            else
                tx_harderror <= '0';
            end if;

        end if;
    end if;
end process;


end rtl;
