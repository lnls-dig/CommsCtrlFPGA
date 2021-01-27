----------------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Filename     : fofb_cc_cfg_if.vhd
--  Purpose      : FFA configuration interface
--  Author       : Isa S. Uzun
----------------------------------------------------------------------------
--  Copyright (c) 2007 Diamond Light Source Ltd.
--  All rights reserved.
----------------------------------------------------------------------------
--  Description: This module handles fai_cfg interface from libera.
--  A state machine controls cfg read and status write operations
--  ack_part input indicates the availability of configuration data.
----------------------------------------------------------------------------
--  Limitations & Assumptions:
----------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fofb_cc_pkg.all;       -- Diamond FOFB package

entity fofb_cc_cfg_if is
    generic (
        ID                      : integer := 255;
        EXTENDED_CONF_BUF       : boolean := false
    );
    port (
        -- Clocks and resets
        mgtclk_i                : in std_logic;
        mgtreset_i              : in std_logic;
        -- Config interface to libera
        fai_cfg_act_part_i      : in  std_logic;
        fai_cfg_a_o             : out std_logic_vector(10 downto 0);
        fai_cfg_do_o            : out std_logic_vector(31 downto 0);
        fai_cfg_di_i            : in  std_logic_vector(31 downto 0);
        fai_cfg_we_o            : out std_logic;
        -- Configuration data read from config bram
        bpmid_o                 : out std_logic_vector(NodeW-1 downto 0);
        timeframe_len_o         : out std_logic_vector(15 downto 0);
        powerdown_o             : out std_logic_vector(3 downto 0);
        loopback_o              : out std_logic_vector(7 downto 0);
        timeframe_dly_o         : out std_logic_vector(15 downto 0);
        rxpolarity_o            : out std_logic_vector(3 downto 0);
        fai_psel_val_o          : out std_logic_vector(31 downto 0);
        fofb_dat_sel_o          : out std_logic_vector(3 downto 0);
        -- Configuration data written to config bram
        pmc_heart_beat_i        : in  std_logic_vector(31 downto 0);
        link_partners_i         : in std_logic_2d_10(3 downto 0);
        link_up_i               : in std_logic_vector(7 downto 0);
        timeframe_cnt_i         : in std_logic_vector(15 downto 0);
        harderror_cnt_i         : in std_logic_2d_16(3 downto 0);
        softerror_cnt_i         : in std_logic_2d_16(3 downto 0);
        frameerror_cnt_i        : in std_logic_2d_16(3 downto 0);
        rxpck_cnt_i             : in std_logic_2d_16(3 downto 0);
        txpck_cnt_i             : in std_logic_2d_16(3 downto 0);
        bpmcount_i              : in std_logic_vector(7 downto 0);
        fodprocess_time_i       : in std_logic_vector(15 downto 0);
        rx_max_data_count_i     : in std_logic_2d_8(3 downto 0);
        tx_max_data_count_i     : in std_logic_2d_8(3 downto 0);
        -- feedback algorithm interface
        coeff_x_addr_i          : in  std_logic_vector(7 downto 0);
        coeff_x_dat_o           : out std_logic_vector(31 downto 0);
        coeff_y_addr_i          : in  std_logic_vector(7 downto 0);
        coeff_y_dat_o           : out std_logic_vector(31 downto 0);
        golden_x_orb_o          : out std_logic_vector(31 downto 0);
        golden_y_orb_o          : out std_logic_vector(31 downto 0);
        --
        fai_cfg_val_i           : in  std_logic_vector(31 downto 0)
     );
end fofb_cc_cfg_if;

-----------------------------------------------
--  Architecture Declaration
-----------------------------------------------
architecture rtl of fofb_cc_cfg_if is

-----------------------------------------------
--  Signal declarations
-----------------------------------------------
-- Configuration read address space
constant    cfg_read_start_addr     : unsigned(9 downto 0) := "0000000000";
constant    cfg_read_end_addr       : unsigned(9 downto 0) := "1011111111";
-- Status write address space
constant    sta_write_start_addr    : unsigned(9 downto 0) := "1100000000";
constant    sta_write_end_addr      : unsigned(9 downto 0) := "1111111111";
-- State machine
type state_type is (st1_idle, st2_read, st3_write);
signal state : state_type := st1_idle;

signal cfg_ack_prev                 : std_logic;
signal cfg_ack_rise                 : std_logic;
signal cfg_addr                     : unsigned(9 downto 0);
signal cfg_addr_prev                : unsigned(9 downto 0);
-- Following signals are related to mode of operation where feedback algorithm runs
-- on the FPGA
signal coef_x_wr                    : std_logic;
signal coef_y_wr                    : std_logic;

begin

fai_cfg_a_o <= '0' & std_logic_vector(cfg_addr_prev);

-- Register address input
cfg_ack_rise <= fai_cfg_act_part_i and (not cfg_ack_prev);

process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i='1') then
        cfg_addr_prev <= cfg_addr;
        cfg_ack_prev <= fai_cfg_act_part_i;
    end if;
end process;

------------------------------------------------------
-- State machine controlling read and write operations
------------------------------------------------------
ConfigRead: process (mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then
        if (mgtreset_i = '1') then
            state <= st1_idle;
            cfg_addr <= (others => '0');
        else
            case (state) is
                -- Wait for cfg_ack rising edge from CSPI indicating that
                -- config data has been written
                when st1_idle =>
                    if (cfg_ack_rise = '1') then
                        state <= st2_read;
                        cfg_addr <= cfg_read_start_addr;
                    end if;

                -- Read configuration data from cfg_bram
                when st2_read =>
                    if (cfg_ack_rise = '1') then
                        cfg_addr <= cfg_read_start_addr;
                    elsif (cfg_addr = cfg_read_end_addr) then   -- Wait for end of addr space
                        state    <= st3_write;
                        cfg_addr <= sta_write_start_addr;
                    else
                        state    <= st2_read;
                        cfg_addr <= cfg_addr + 1;
                    end if;

                when st3_write =>
                -- Continuously write status info
                    if (cfg_ack_rise = '1') then                -- Read new config data
                        state    <= st2_read;
                        cfg_addr <= cfg_read_start_addr;
                    else
                        state   <= st3_write;
                        if (cfg_addr = sta_write_end_addr) then
                            cfg_addr <= sta_write_start_addr;
                        else
                            cfg_addr <= cfg_addr + 1;
                        end if;
                    end if; 

                when others =>
            end case;
        end if;
    end if;
end process;

----------------------------------------------------------
-- Read CC configuration parameters from addr space 0-255
----------------------------------------------------------
process(mgtclk_i)
begin
if (mgtclk_i'event and mgtclk_i='1') then
    if (mgtreset_i = '1') then
        bpmid_o         <= std_logic_vector(to_unsigned(ID,NodeW));
        timeframe_dly_o <= def_TimeFrameDelay;
        timeframe_len_o <= def_TimeFrameLength;
        powerdown_o     <= (others => '0');
        loopback_o      <= (others => '0');
        coef_x_wr       <= '0';
        coef_y_wr       <= '0';
        golden_x_orb_o  <= (others => '0');
        golden_y_orb_o  <= (others => '0');
        rxpolarity_o    <= "0000";
        fai_psel_val_o  <= X"FEFEFEFE";
        fofb_dat_sel_o  <= "0000";
    else
        if (state = st2_read) then

            if (cfg_addr_prev(9 downto 8) = "00") then
                -- Node ID
                if (cfg_addr_prev(7 downto 0) = cc_cmd_bpm_id) then
                    bpmid_o <= fai_cfg_di_i(NodeW-1 downto 0);
                end if; 
                -- Time frame lenght in terms of clocks
                if (cfg_addr_prev(7 downto 0) = cc_cmd_time_frame_len) then
                    timeframe_len_o <=  fai_cfg_di_i(15 downto 0);
                end if; 
                -- MGT Powerdown
                if (cfg_addr_prev(7 downto 0) = cc_cmd_mgt_powerdown) then
                    powerdown_o <= fai_cfg_di_i(3 downto 0);
                end if; 
                -- MGT Loopback
                if (cfg_addr_prev(7 downto 0) = cc_cmd_mgt_loopback) then
                    loopback_o <= fai_cfg_di_i(7 downto 0);
                end if;
                -- Timeframe start delay in terms of clocks
                if (cfg_addr_prev(7 downto 0) = cc_cmd_time_frame_dly) then
                    timeframe_dly_o <=  fai_cfg_di_i(15 downto 0);
                end if;
                -- Golden orbit -x
                if (cfg_addr_prev(7 downto 0) = cc_cmd_golden_orb_x) then
                    golden_x_orb_o <= fai_cfg_di_i;
                end if; 
                -- Golden orbit -y
                if (cfg_addr_prev(7 downto 0) = cc_cmd_golden_orb_y) then
                    golden_y_orb_o <= fai_cfg_di_i;
                end if;
                -- MGT RX Polarity
                if (cfg_addr_prev(7 downto 0) = cc_cmd_rxpolarity) then
                    rxpolarity_o <= fai_cfg_di_i(3 downto 0);
                end if;
                -- FAI data stream payload selection
                if (cfg_addr_prev(7 downto 0) = cc_cmd_payloadsel) then
                    fai_psel_val_o <= fai_cfg_di_i;
                end if;
                -- FOFB data injection select
                if (cfg_addr_prev(7 downto 0) = cc_cmd_fofbdatasel) then
                    fofb_dat_sel_o <= fai_cfg_di_i(3 downto 0);
                end if;
            end if;
        end if;

        -- Read response matrix coefficients if required
        if (EXTENDED_CONF_BUF) then

            case cfg_addr(9 downto 8) is
                when "00" =>
                    coef_x_wr <= '0';
                    coef_y_wr <= '0';
                when "01" =>
                    coef_x_wr <= '1';
                    coef_y_wr <= '0';
                when "10" =>
                    coef_x_wr <= '0';
                    coef_y_wr <= '1';
                when "11" =>
                    coef_x_wr <= '0';
                    coef_y_wr <= '0';
                when others =>
            end case;
        end if;
    end if;
end if;
end process;

--------------------------------------------------------
-- Address decode logic for writing status information
-- Data is written in adc clock domain
--------------------------------------------------------
process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i='1') then
        if (mgtreset_i = '1') then
            fai_cfg_do_o <= (others => '0');
            fai_cfg_we_o <= '0';
        else
            if (state = st3_write and fai_cfg_act_part_i = '0' and cfg_addr(9 downto 8) = "11") then
                case(cfg_addr(7 downto 0)) is
                    when cc_cmd_firmware_ver    =>
                        fai_cfg_do_o <= BPMFirmwareVersion;
                        fai_cfg_we_o <= '1';
                    when cc_cmd_sys_status  => 
                        fai_cfg_do_o <= pmc_heart_beat_i;
                        fai_cfg_we_o <= '1';
                    when cc_cmd_link_partner_1  =>
                        fai_cfg_do_o <= zeros(22) & link_partners_i(0);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_link_partner_2  => 
                        fai_cfg_do_o <= zeros(22) & link_partners_i(1);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_link_partner_3  => 
                        fai_cfg_do_o <= zeros(22) & link_partners_i(2);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_link_partner_4  => 
                        fai_cfg_do_o <= zeros(22) & link_partners_i(3);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_link_up => 
                        fai_cfg_do_o <= zeros(24) & link_up_i;
                        fai_cfg_we_o <= '1';
                    when cc_cmd_time_frame_count        => 
                        fai_cfg_do_o <= zeros(16) & timeframe_cnt_i;
                        fai_cfg_we_o <= '1';
                    when cc_cmd_hard_err_cnt_1  => 
                        fai_cfg_do_o <= zeros(16) & harderror_cnt_i(0);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_hard_err_cnt_2  => 
                        fai_cfg_do_o <= zeros(16) & harderror_cnt_i(1);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_hard_err_cnt_3  => 
                        fai_cfg_do_o <= zeros(16) & harderror_cnt_i(2);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_hard_err_cnt_4  => 
                        fai_cfg_do_o <= zeros(16) & harderror_cnt_i(3);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_soft_err_cnt_1  => 
                        fai_cfg_do_o <= zeros(16) & softerror_cnt_i(0);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_soft_err_cnt_2  => 
                        fai_cfg_do_o <= zeros(16) & softerror_cnt_i(1);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_soft_err_cnt_3  => 
                        fai_cfg_do_o <= zeros(16) & softerror_cnt_i(2);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_soft_err_cnt_4  =>
                        fai_cfg_do_o <= zeros(16) & softerror_cnt_i(3);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_frame_err_cnt_1 =>
                        fai_cfg_do_o <= zeros(16) & frameerror_cnt_i(0);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_frame_err_cnt_2 =>
                        fai_cfg_do_o <= zeros(16) & frameerror_cnt_i(1);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_frame_err_cnt_3 =>
                        fai_cfg_do_o <= zeros(16) & frameerror_cnt_i(2);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_frame_err_cnt_4 =>
                        fai_cfg_do_o <= zeros(16) & frameerror_cnt_i(3);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_rx_pck_cnt_1    =>
                        fai_cfg_do_o <= zeros(16) & rxpck_cnt_i(0);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_rx_pck_cnt_2    =>
                        fai_cfg_do_o <= zeros(16) & rxpck_cnt_i(1);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_rx_pck_cnt_3    =>
                        fai_cfg_do_o <= zeros(16) & rxpck_cnt_i(2);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_rx_pck_cnt_4    =>
                        fai_cfg_do_o <= zeros(16) & rxpck_cnt_i(3);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_tx_pck_cnt_1    =>
                        fai_cfg_do_o <= zeros(16) & txpck_cnt_i(0);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_tx_pck_cnt_2    =>
                        fai_cfg_do_o <= zeros(16) & txpck_cnt_i(1);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_tx_pck_cnt_3    =>
                        fai_cfg_do_o <= zeros(16) & txpck_cnt_i(2);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_tx_pck_cnt_4    => 
                        fai_cfg_do_o <= zeros(16) & txpck_cnt_i(3);
                        fai_cfg_we_o <= '1';
                    when cc_cmd_fod_process_time    =>
                        fai_cfg_do_o <= zeros(16) & fodprocess_time_i;
                        fai_cfg_we_o <= '1';
                    when cc_cmd_bpm_count           =>
                        fai_cfg_do_o <= zeros(24) & bpmcount_i;
                        fai_cfg_we_o <= '1';
                    when cc_cmd_rx_maxcount =>
                        fai_cfg_do_o <= rx_max_data_count_i(3)&
                                        rx_max_data_count_i(2)&
                                        rx_max_data_count_i(1)&
                                        rx_max_data_count_i(0);
                        fai_cfg_we_o <= '1';
                     when cc_cmd_tx_maxcount =>
                        fai_cfg_do_o <= tx_max_data_count_i(3)&
                                        tx_max_data_count_i(2)&
                                        tx_max_data_count_i(1)&
                                        tx_max_data_count_i(0);
                        fai_cfg_we_o <= '1';
                   when others =>
                        fai_cfg_do_o <= (others => '0');
                        fai_cfg_we_o <= '0';
                end case;
            else 
                    fai_cfg_do_o <= (others => '0');
                    fai_cfg_we_o <= '0';
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------
-- extended configuration space
-- used for feedback algorithm response matrix coefficients
--------------------------------------------------------
EXT_CONF_BUF_GEN: if (EXTENDED_CONF_BUF) generate

coeff_x_buf : entity work.fofb_cc_dpbram
generic map (
    AW          => 8,
    DW          => 32
)
port map (
    addra       => std_logic_vector(cfg_addr_prev(7 downto 0)),
    addrb       => coeff_x_addr_i,
    clka        => mgtclk_i,
    clkb        => mgtclk_i,
    dina        => fai_cfg_di_i,
    dinb        => (others => '0'),
    douta       => open,
    doutb       => coeff_x_dat_o,
    wea         => coef_x_wr,
    web         => '0'
);

coeff_y_buf : entity work.fofb_cc_dpbram
generic map (
    AW          => 8,
    DW          => 32
)
port map (
    addra       => std_logic_vector(cfg_addr_prev(7 downto 0)),
    addrb       => coeff_y_addr_i,
    clka        => mgtclk_i,
    clkb        => mgtclk_i,
    dina        => fai_cfg_di_i,
    dinb        => (others => '0'),
    douta       => open,
    doutb       => coeff_y_dat_o,
    wea         => coef_y_wr,
    web         => '0'
);

end generate;

NOT_EXT_CONF_BUF_GEN: if (not EXTENDED_CONF_BUF) generate
    coeff_x_dat_o <=  (others => '0');
    coeff_y_dat_o <=  (others => '0');
end generate;

end rtl;

