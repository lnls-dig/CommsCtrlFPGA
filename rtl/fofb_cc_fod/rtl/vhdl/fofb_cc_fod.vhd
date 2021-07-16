----------------------------------------------------------------------------
--  Project      : Diamond FOFB Communication Controller
--  Filename     : fofb_cc_fod.vhd
--  Purpose      : CC Forward or Discard Module
--  Author       : Isa S. Uzun
----------------------------------------------------------------------------
--  Copyright (c) 2007 Diamond Light Source Ltd.
--  All rights reserved.
----------------------------------------------------------------------------
--  Description: This block implements the CC  Forward Or Discard module.
--  It accepts incoming packets along with fod_idat_val_prev signal and
--  forwards or discards it
----------------------------------------------------------------------------
--  Limitations & Assumptions:
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.fofb_cc_pkg.all;           -- Diamond FOFB package

-----------------------------------------------
--  Entity declaration
-----------------------------------------------
entity fofb_cc_fod is
    generic (
        -- Design Configuration Options
        BPMS                    : integer  := 1;
        DEVICE                  : device_t := BPM;
        INTERLEAVED             : boolean  :=false;
        LaneCount               : integer  := 4
    );
    port (
        mgtclk_i                : in  std_logic;
        sysclk_i                : in  std_logic;
        mgtreset_i              : in  std_logic;
        -- Frame start (1cc long)
        timeframe_valid_i       : in  std_logic;
        timeframe_start_i       : in  std_logic;
        timeframe_end_i         : in  std_logic;
        timeframe_dly_i         : in  std_logic_vector(15 downto 0);
        -- Channel up between channels
        linksup_i               : in  std_logic_vector(LaneCount-1 downto 0);
        -- Incoming data for arbmux to be Forwarded or Discarded
        fod_dat_i               : in  std_logic_vector((PacketSize*32-1) downto 0);
        fod_dat_val_i           : in  std_logic;
        -- Injected or Forwarded Data
        fod_dat_o               : out std_logic_vector((PacketSize*32-1) downto 0);
        fod_dat_val_o           : out std_logic_vector(LaneCount-1 downto 0);
        -- Frame status data
        timeframe_cntr_i        : in  std_logic_vector(31 downto 0);
        timestamp_val_i         : in  std_logic_vector(31 downto 0);
        -- Packet information coming from Libera interface
        bpm_x_pos_i             : in  std_logic_2d_32(BPMS-1 downto 0);
        bpm_y_pos_i             : in  std_logic_2d_32(BPMS-1 downto 0);
        -- Dummy/Real position data select
        pos_datsel_i            : in  std_logic_vector(BPMS-1 downto 0);
        -- TX FIFO full status
        txf_full_i              : in  std_logic_vector(LaneCount-1 downto 0);
        -- CC Configuration registers
        bpmid_i                 : in  std_logic_vector(NodeW-1 downto 0);
        -- X and Y pos out to CEP and PMC Interface
        xy_buf_dout_o           : out std_logic_vector(63 downto 0);
        xy_buf_addr_i           : in  std_logic_vector(NodeW downto 0);
        xy_buf_rstb_i           : in  std_logic;
        xy_buf_long_en_i        : in  std_logic;
        -- status info
        fodprocess_time_o       : out std_logic_vector(15 downto 0);
        bpm_count_o             : out std_logic_vector(7 downto 0);
        -- golden orbit
        golden_orb_x_i          : in  std_logic_vector(31 downto 0);
        golden_orb_y_i          : in  std_logic_vector(31 downto 0);
        -- fofb system heartbeat and event (go, stop) signals
        fofb_watchdog_i         : in  std_logic_vector(31 downto 0);     -- FOFB Watchdog
        fofb_event_i            : in  std_logic_vector(31 downto 0);     -- FOFB Go
        -- PMC-CPU DMA handshake interface
        fofb_dma_ok_i           : in std_logic;
        -- Received node mask (Not used in BPMs)
        fofb_node_mask_o        : out  std_logic_vector(NodeNum-1 downto 0);
        -- Time of arrival buffer read interface
        toa_rstb_i              : in  std_logic;
        toa_rden_i              : in  std_logic;
        toa_dat_o               : out std_logic_vector(31 downto 0);
        -- Receive count buffer read interface
        rcb_rstb_i              : in  std_logic;
        rcb_rden_i              : in  std_logic;
        rcb_dat_o               : out std_logic_vector(31 downto 0)
);
end entity;

-----------------------------------------------
--  Architecture declaration
-----------------------------------------------
architecture rtl of fofb_cc_fod is

------------------------------------------------------------------
--  Signal declarations
-------------------------------------------------------------------
signal pload_header                 : std_logic_vector(31 downto 0);
signal bpm_cnt                      : unsigned(7 downto 0);
signal timeframe_start              : std_logic_vector(BPMS-1 downto 0) := (others
=> '0');
signal timeframe_valid              : std_logic;
signal bpm_xpos_val                 : std_logic_vector(31 downto 0);
signal bpm_ypos_val                 : std_logic_vector(31 downto 0);
signal pmc_xpos_val                 : std_logic_vector(31 downto 0);
signal pmc_ypos_val                 : std_logic_vector(31 downto 0);
-- input connections
signal fod_idat                     : std_logic_vector((PacketSize*32-1) downto 0);
-- position memory connections
signal time_stamp_cnt               : unsigned(15 downto 0);
signal fod_completed                : std_logic;
signal fod_completed_prev           : std_logic;
signal fod_idat_val                 : std_logic;
signal fod_odat                     : std_logic_vector((PacketSize*32-1) downto 0);
signal fod_odat_val                 : std_logic;
signal posmem_wea_prev              : std_logic;
signal posmem_addra_prev            : std_logic_vector(NodeW downto 0);

signal buffer_write_sw              : std_logic := '0';
signal buffer_read_sw               : std_logic := '1';
signal xpos_to_read                 : std_logic_vector(31 downto 0);
signal ypos_to_read                 : std_logic_vector(31 downto 0);
signal own_packet_to_inject         : std_logic_vector(127 downto 0);
signal own_xpos_to_store            : std_logic_vector(31 downto 0);
signal own_ypos_to_store            : std_logic_vector(31 downto 0);
signal xpos_to_store                : std_logic_vector(31 downto 0);
signal ypos_to_store                : std_logic_vector(31 downto 0);
signal xy_buf_addr                  : std_logic_vector(NodeW-1 downto 0);
signal xy_buf_addr_intrlvd          : std_logic_vector(NodeW-1 downto 0);
signal fofb_nodemask                : std_logic_vector(NodeNum-1 downto 0):= (others => '0');
signal fofb_nodemask_sys            : std_logic_vector(NodeNum-1 downto 0):= (others => '0');
signal posmem_wea                   : std_logic;
signal posmem_addra                 : std_logic_vector(NodeW downto 0);
signal posmem_addrb                 : std_logic_vector(NodeW downto 0);
signal bpmid                        : unsigned(NodeW-1 downto 0);
signal fod_id                       : std_logic_vector(NodeW-1 downto 0);
signal fod_xpos                     : std_logic_vector(31 downto 0);
signal fod_ypos                     : std_logic_vector(31 downto 0);
signal xy_buf_dout                  : std_logic_vector(63 downto 0);
signal xy_buf_dout_intrlvd          : std_logic_vector(63 downto 0);

signal bpm_count_prev               : unsigned(7 downto 0);

signal maskmem_sw                   : std_logic;
signal maskmemA_addra               : std_logic_vector(NodeW-1 downto 0);
signal maskmemA_addrb               : std_logic_vector(NodeW-1 downto 0);
signal maskmemA_dina                : std_logic_vector(1 downto 0);
signal maskmemA_doutb               : std_logic_vector(1 downto 0);
signal maskmemA_wea                 : std_logic;
signal maskmemB_addra               : std_logic_vector(NodeW-1 downto 0);
signal maskmemB_addrb               : std_logic_vector(NodeW-1 downto 0);
signal maskmemB_dina                : std_logic_vector(1 downto 0);
signal maskmemB_doutb               : std_logic_vector(1 downto 0);
signal maskmemB_wea                 : std_logic;
signal maskmem_clear                : std_logic;
signal maskmem_clear_cnt            : unsigned(NodeW downto 0);
signal fod_ok_n                     : std_logic;
signal timeframe_end_sys            : std_logic;
signal timeframe_cnt                : unsigned(15 downto 0);
signal timeframe_inject             : std_logic;
signal posmem_xweb                  : std_logic;
signal posmem_yweb                  : std_logic;

signal toa_min_val                  : unsigned(15 downto 0);
signal toa_max_val                  : unsigned(15 downto 0);
signal toa_min_wr                   : std_logic;
signal toa_max_wr                   : std_logic;
signal toamem_wea                   : std_logic;
signal toamem_web                   : std_logic;
signal toamem_addra                 : std_logic_vector(NodeW-1 downto 0);
signal toamem_addrb                 : std_logic_vector(NodeW-1 downto 0);
signal toamem_dina                  : std_logic_vector(31 downto 0);
signal toamem_dinb                  : std_logic_vector(31 downto 0);
signal toamem_doutb                 : std_logic_vector(31 downto 0);
signal toa_min_new                  : unsigned(15 downto 0);
signal toa_max_new                  : unsigned(15 downto 0);
signal toa_rden                     : std_logic;
signal toa_rden_prev                : std_logic;
signal toa_rden_rise                : std_logic;
signal toa_addr                     : unsigned(NodeW-1 downto 0);

signal rcb_val                      : unsigned(31 downto 0);
signal rcb_val_wr                   : std_logic;
signal rcbmem_wea                   : std_logic;
signal rcbmem_web                   : std_logic;
signal rcbmem_addra                 : std_logic_vector(NodeW-1 downto 0);
signal rcbmem_addrb                 : std_logic_vector(NodeW-1 downto 0);
signal rcbmem_dina                  : std_logic_vector(31 downto 0);
signal rcbmem_dinb                  : std_logic_vector(31 downto 0);
signal rcbmem_doutb                 : std_logic_vector(31 downto 0);
signal rcb_val_new                  : unsigned(31 downto 0);
signal rcb_rden                     : std_logic;
signal rcb_rden_prev                : std_logic;
signal rcb_rden_rise                : std_logic;
signal rcb_addr                     : unsigned(NodeW-1 downto 0);

signal xy_buf_rd_sw                 : std_logic;
signal xy_buf_rd_sw_prev            : std_logic;

begin

fofb_node_mask_o <= fofb_nodemask_sys;

-- Sniffer device does not inject and forwards any packets to the network
process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        fod_dat_o <= fod_odat;
        -- If Sniffer, disable data out valid
        if (DEVICE = SNIFFER) then
            fod_dat_val_o <= (others => '0');
        else
            fod_dat_val_o <= (LaneCount-1 downto 0 => fod_odat_val) and  not txf_full_i and linksup_i;
        end if;
    end if;
end process;

-- Register input data when it is valid
process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        fod_idat <= fod_dat_i;
        fod_idat_val <= fod_dat_val_i;
    end if;
end process;

-- Extract information needed from incoming packet
fod_id <= fod_idat(NodeW+95 downto 96);
fod_xpos <= fod_idat(95 downto 64);
fod_ypos <= fod_idat(63 downto 32);

-- Create a BPMS-bit shift register. This is used to shift timeframe_inject
-- pulse in order to keep track of payload data injected on the the network.
process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i='1') then
        for I in 0 to BPMS-1 loop
            if (I=0) then
                timeframe_start(0) <= timeframe_inject;
            else
                timeframe_start <= timeframe_start(BPMS-2 downto 0) & timeframe_inject;
            end if;
        end loop;
    end if;
end process;

--
-- Position data to be injected can be synthetic or real data
--
process(pos_datsel_i, bpm_x_pos_i, bpm_y_pos_i, timeframe_start,
            fofb_watchdog_i, fofb_event_i)
begin
    -- BPM data is muxed for the # of BPMS being served
    for I in 0 to BPMS-1 loop
        if (timeframe_start(I) = '1') then
            if (pos_datsel_i(I) = '0') then
                bpm_xpos_val <= std_logic_vector(signed(bpm_x_pos_i(I)) - signed(golden_orb_x_i));
                bpm_ypos_val <= std_logic_vector(signed(bpm_y_pos_i(I)) - signed(golden_orb_y_i));
            else
                bpm_xpos_val <= timeframe_cntr_i;
                bpm_ypos_val <= timeframe_cntr_i;
            end if;
        end if;
    end loop;

    -- Data for PMC module
    pmc_xpos_val <= fofb_watchdog_i;
    pmc_ypos_val <= fofb_event_i;
end process;

--
-- BPM/PMC Header Data (32 bits)
--
process(timeframe_start)
    variable result       : std_logic;
begin
    result := '0';
    for i in timeframe_start'range loop
        result := result or timeframe_start(i);
    end loop;

    timeframe_valid <= result;
end process;

process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i='1') then
        if (timeframe_inject = '1') then
            bpmid <= unsigned(bpmid_i);
        elsif (timeframe_valid = '1') then
            bpmid <= bpmid + 1;
        end if;
    end if;
end process;

-- When DEVICE=BPM, a time frame start bit is placed onto
-- payload header bit15
pload_header(NodeW-1 downto 0) <= std_logic_vector(bpmid);
pload_header(14 downto NodeW) <= (others=>'0');
pload_header(15) <= '1' when (DEVICE = BPM) else '0';
pload_header(31 downto 16) <= timeframe_cntr_i(15 downto 0);

--
-- Device dependent compile-time assignments
--  1/ own data packet (4 x 32-bit words)
--  2/ positions to store for processing
--
process(timeframe_cntr_i, bpm_ypos_val, bpm_xpos_val, pload_header, pmc_xpos_val, pmc_ypos_val,timestamp_val_i)
begin
    case DEVICE is
        when BPM => -- and PBPM
            own_packet_to_inject <= pload_header & bpm_xpos_val & bpm_ypos_val & timeframe_cntr_i;
            own_xpos_to_store   <= bpm_xpos_val;
            own_ypos_to_store   <= bpm_ypos_val;
        when PMC =>
            own_packet_to_inject <= pload_header & pmc_xpos_val & pmc_ypos_val & timeframe_cntr_i;
            own_xpos_to_store   <= pmc_xpos_val;
            own_ypos_to_store   <= pmc_ypos_val;
        when PMCEVR =>
            own_packet_to_inject <= pload_header & pmc_xpos_val & pmc_ypos_val & timeframe_cntr_i;
            own_xpos_to_store   <= pmc_xpos_val;
            own_ypos_to_store   <= pmc_ypos_val;
        when PMCSFPEVR =>
            own_packet_to_inject <= pload_header & pmc_xpos_val & pmc_ypos_val & timeframe_cntr_i;
            own_xpos_to_store   <= pmc_xpos_val;
            own_ypos_to_store   <= pmc_ypos_val;
        when SNIFFER =>
            own_packet_to_inject <= pload_header & X"00000000" & X"00000000" & timeframe_cntr_i;
            own_xpos_to_store   <= timestamp_val_i;
            own_ypos_to_store   <= timestamp_val_i;
        -- DISTRIBUTOR does not inject, just pass data forward
        when DISTRIBUTOR =>
            own_packet_to_inject <= (others => '0');
            own_xpos_to_store   <= (others => '0');
            own_ypos_to_store   <= (others => '0');
        when others =>
    end case;
end process;

--
-- Bit Mask for received nodes are stored using double buffered memory
-- Pure logic implementation is possible, however costly especially for
-- 512 nodes.
--

FodMaskMemA : entity work.fofb_cc_sdpbram
generic map (
    AW          => NodeW,
    DW          => 2
)
port map (
    addra       => maskmemA_addra,
    addrb       => maskmemA_addrb,
    clka        => mgtclk_i,
    clkb        => mgtclk_i,
    dina        => maskmemA_dina,
    doutb       => maskmemA_doutb,
    wea         => maskmemA_wea
);

FodMaskMemB : entity work.fofb_cc_sdpbram
generic map (
    AW          => NodeW,
    DW          => 2
)
port map (
    addra       => maskmemB_addra,
    addrb       => maskmemB_addrb,
    clka        => mgtclk_i,
    clkb        => mgtclk_i,
    dina        => maskmemB_dina,
    doutb       => maskmemB_doutb,
    wea         => maskmemB_wea
);

-- While one memory is used to keep track of incoming nodes,
-- the other one is cleared on time frame start.
process(mgtclk_i)
begin
    if rising_edge(mgtclk_i) then
        if (mgtreset_i = '1') then
            maskmem_clear_cnt <= (others => '1');
        else
            -- Start clearing unused Mask Memory on frame start
            if (timeframe_start_i = '1') then
                maskmem_clear_cnt <= (others => '0');
            elsif (maskmem_clear_cnt(NodeW) = '0') then
                maskmem_clear_cnt <= maskmem_clear_cnt + 1;
            end if;
        end if;
    end if;
end process;

maskmem_clear <= not maskmem_clear_cnt(NodeW);

-- Mask Mem is double buffered, and control lines are multiplexed accordingly
maskmemA_addra <= posmem_addra(NodeW-1 downto 0) when (maskmem_sw = '0')
                  else std_logic_vector(maskmem_clear_cnt(NodeW-1 downto 0));
maskmemA_dina <= "01" when (maskmem_sw = '0') else "00";
maskmemA_wea   <= posmem_wea when (maskmem_sw = '0')
                  else maskmem_clear;
maskmemA_addrb <= fod_dat_i(NodeW+95 downto 96);

maskmemB_addra <= posmem_addra(NodeW-1 downto 0) when (maskmem_sw = '1')
                  else std_logic_vector(maskmem_clear_cnt(NodeW-1 downto 0));
maskmemB_dina <= "01" when (maskmem_sw = '1') else "00";
maskmemB_wea   <= posmem_wea when (maskmem_sw = '1')
                  else maskmem_clear;
maskmemB_addrb <= fod_dat_i(NodeW+95 downto 96);

-- Check if data from a node has been received
fod_ok_n <= maskmemA_doutb(0) when (maskmem_sw = '0') else maskmemB_doutb(0);

-- Time delayed timeframe_start pulse
-- For DEVICE = DISTRIBUTOR, nothing is injected, data is passed along,
-- as timeframe_inject = '0' -> timeframe_start = '0' -> timeframe_valid = '0'
-- and, so nothing from ourselves is injected onto the network, which is
-- what we want in the case of a DISTRIBUTOR
timeframe_inject <= '1' when (timeframe_cnt = unsigned(timeframe_dly_i) and
                    timeframe_valid_i = '1') and DEVICE /= DISTRIBUTOR else '0';

FodProcess : process(mgtclk_i)
begin
if (mgtclk_i'event and mgtclk_i = '1') then
    if (mgtreset_i = '1') then
        bpm_cnt <= (others => '0');
        maskmem_sw <= '0';
        timeframe_cnt <= (others=> '0');
        fofb_nodemask <= (others => '0');
        posmem_wea_prev <= '0';
        posmem_addra_prev <= (others => '0');
    else
        -- Double-buffering switch for received mask memory
        if (timeframe_end_i = '1') then
            maskmem_sw <= not maskmem_sw;
        end if;

        -- Tick counter within a timeframe
        if (timeframe_valid_i = '1') then
            timeframe_cnt <= timeframe_cnt + 1;
        else
            timeframe_cnt <= (others=> '0');
        end if;

        -- Keep track of # of nodes received and bitmask array
        if (timeframe_start_i = '1') then
            bpm_cnt <= (others => '0');
            fofb_nodemask <= (others => '0');
        elsif (timeframe_valid = '1') then
            fofb_nodemask(to_integer(bpmid)) <= '1';
            bpm_cnt <= bpm_cnt + 1;
        elsif (fod_idat_val = '1') then
            -- Forward only once
            if (fod_ok_n = '0') then
                bpm_cnt <= bpm_cnt + 1;
                fofb_nodemask(to_integer(unsigned(fod_id))) <= '1';
            end if;
        end if;

        -- Registered signals
        posmem_wea_prev <= posmem_wea;
        posmem_addra_prev <= posmem_addra;

    end if;
end if;
end process;

-- Forwarded data along with strobe
fod_odat_val <= timeframe_valid or (fod_idat_val and not fod_ok_n);

fod_odat <= own_packet_to_inject when (timeframe_valid = '1') else
            fod_idat(127 downto 112) & '0' & fod_idat(110 downto 0);

-- X and Y position data to be stored from received nodes
posmem_addra <= buffer_write_sw & std_logic_vector(bpmid)
                when (timeframe_valid = '1')
                else buffer_write_sw & fod_id;

posmem_wea <= timeframe_valid or (fod_idat_val and not fod_ok_n);

xpos_to_store <= own_xpos_to_store when (timeframe_valid = '1')
                 else fod_xpos;

ypos_to_store <= own_ypos_to_store when (timeframe_valid = '1')
                 else fod_ypos;

-------------------------------------------------------------------
-- SYS Clock Domain:
--      At the end of each time frame, switch for writing is toggled
--      in mgtclk_i domain (if previoud dma is completed succesfully).
--      timeframe_end signal is synced to sysclk, and then used
--      to switch reading.
--      timeframe_end_sys is also used to generate IRQ on the
--      PMC.
-------------------------------------------------------------------
fofb_cc_p2p_inst : entity work.fofb_cc_p2p
port map (
    in_clk              => mgtclk_i,
    out_clk             => sysclk_i,
    rst                 => '0',
    pulsein             => timeframe_end_i,
    inbusy              => open,
    pulseout            => timeframe_end_sys
);

-------------------------------------------------
-- Double Buffering for FoD control
-- buffer_write_sw = '0'    => Lower is used
-- buffer_write_sw = '1'    => Upper is used
-------------------------------------------------
process(sysclk_i)
begin
    if (sysclk_i'event and sysclk_i = '1') then
        -- buffer_read_sw is used to switch double buffers for DMA to PMC.
        if (timeframe_end_sys = '1' and fofb_dma_ok_i = '1') then
            buffer_write_sw <= not buffer_write_sw;
            buffer_read_sw  <= not buffer_read_sw;
        end if;

        if (timeframe_end_sys = '1' and fofb_dma_ok_i = '1') then
            fofb_nodemask_sys <= fofb_nodemask;
        end if;

        xy_buf_rd_sw_prev <= xy_buf_rd_sw;
    end if;
end process;

--
-- Each X/Y Position Data Store Buffer implements a double buffer
-- by switching between lower and upper part of the memory
--
XPosMem : entity work.fofb_cc_dpbram
    generic map (
        AW          => (NodeW+1),
        DW          => 32
    )
    port map (
        addra       => posmem_addra,
        addrb       => posmem_addrb,
        clka        => mgtclk_i,
        clkb        => sysclk_i,
        dina        => xpos_to_store,
        dinb        => X"0000_0000",
        douta       => open,
        doutb       => xpos_to_read,
        wea         => posmem_wea,
        web         => posmem_xweb
    );

YPosMem : entity work.fofb_cc_dpbram
    generic map (
        AW          => (NodeW+1),
        DW          => 32
    )
    port map (
        addra       => posmem_addra,
        addrb       => posmem_addrb,
        clka        => mgtclk_i,
        clkb        => sysclk_i,
        dina        => ypos_to_store,
        dinb        => X"0000_0000",
        douta       => open,
        doutb       => ypos_to_read,
        wea         => posmem_wea,
        web         => posmem_yweb
    );

---------------------------------------------------------------------
-- Following handles X/Y Position Data readout:
-- Data Read Out:
--    Regular: x0,x1,...xn-1,y0,y1,.....yn-1, or
--    Interleaved: x0,y0,x1,y1,........xn-1,yn-1
-- Data Bus:
--    PMC module has 32-bit regular readout
--    V5 Sniffer has 64-bit interleaved readout
--    SPEC has 32-bit interleaved readout
-- Readback runs in 256 or 512-nodes mode depending on
-- long flag.
---------------------------------------------------------------------
--Determine address bit number to be used for muxing between X and Y
--based on 256/512-node operation
xy_buf_rd_sw <= xy_buf_addr_i(NodeW) when (xy_buf_long_en_i = '1')
                else xy_buf_addr_i(NodeW-1);

xy_buf_addr <= xy_buf_addr_i(Nodew-1 downto 0) when (xy_buf_long_en_i = '1')
               else '0' & xy_buf_addr_i(NodeW-2 downto 0);

xy_buf_addr_intrlvd <= xy_buf_addr_i(Nodew downto 1);

posmem_addrb <= buffer_read_sw & xy_buf_addr when (INTERLEAVED = false)
                else buffer_read_sw & xy_buf_addr_intrlvd;

-- X/Y pos is multiplexed on delayed sw flag due to 1 clock
-- latency of BRAM.
xy_buf_dout <= X"00000000" & xpos_to_read when (xy_buf_rd_sw_prev = '0')
               else X"00000000" & ypos_to_read;
xy_buf_dout_intrlvd <= X"00000000" & xpos_to_read when (xy_buf_addr(0) = '1')
                       else X"00000000" & ypos_to_read;

xy_buf_dout_o <= xy_buf_dout_intrlvd when (INTERLEAVED = true) else
                 ypos_to_read & xpos_to_read when (DEVICE = SNIFFER) else
                 xy_buf_dout;

-- Clear memory on readback
posmem_xweb <= xy_buf_rstb_i and not xy_buf_rd_sw when (INTERLEAVED = false)
               else xy_buf_rstb_i and not xy_buf_addr(0);
posmem_yweb <= xy_buf_rstb_i and xy_buf_rd_sw when (INTERLEAVED = false)
               else xy_buf_rstb_i and xy_buf_addr(0);

---------------------------------------------------------------------
--  Time Stamp Counter
---------------------------------------------------------------------
process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then
        if (mgtreset_i = '1') then
            time_stamp_cnt <= (others => '0');
        else
            if (timeframe_start_i = '1') then
                time_stamp_cnt <= (others => '0');
            else
                time_stamp_cnt <= time_stamp_cnt + 1;
            end if;
        end if;
    end if;
end process;

---------------------------------------------------------------------
-- Fod process is finished in the TimeFrame
---------------------------------------------------------------------
bpm_count_o <= std_logic_vector(bpm_count_prev);

FodCompletedGen: process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then
        if (mgtreset_i = '1') then
            fodprocess_time_o <= (others => '0');
            bpm_count_prev <= X"01";
            fod_completed <= '0';
            fod_completed_prev <= '0';
        else
            -- Update bpm_count_o in each time frame
            if (timeframe_end_i = '1') then
                bpm_count_prev <= bpm_cnt;
            end if;

            -- fod process finished
            if (timeframe_start_i = '1') then
                fod_completed <= '0';
            elsif (bpm_cnt = bpm_count_prev and timeframe_valid_i = '1') then
                fod_completed <= '1';
            elsif (fod_completed = '0' and timeframe_end_i = '1') then
                fod_completed <= '1';
            end if;

            -- Latch current fod time
            fod_completed_prev <= fod_completed;
            if ((fod_completed and not fod_completed_prev) = '1') then
                fodprocess_time_o  <= std_logic_vector(time_stamp_cnt);
            end if;

        end if;
    end if;
end process;

---------------------------------------------------------------------
-- Arrival time buffer : keeps track of min and max of arrival time
-- from each node ID. Single BRAM is used to store min and max values.
-- It is clocked in mgt clock domain, and readback via SBC is controlled
-- by toa_rden flag.
---------------------------------------------------------------------
process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then
        if (mgtreset_i = '1') then
            toa_rden <= '0';
            toa_max_wr <= '0';
            toa_min_wr <= '0';
            toa_addr <= (others => '0');
            toamem_addra <= (others => '0');
        else
            -- Look for min and max values, comparison is done on
            -- posmem_wea signal.
            toa_max_wr <= '0';
            toa_min_wr <= '0';

            if (toa_max_val <  time_stamp_cnt and posmem_wea_prev = '1') then
                toa_max_new <= time_stamp_cnt;
                toa_max_wr <= '1';
            else
                toa_max_new <= toa_max_val;
            end if;

            if (toa_min_val > time_stamp_cnt and posmem_wea_prev = '1') then
                toa_min_new <= time_stamp_cnt;
                toa_min_wr <= '1';
            else
                toa_min_new <= toa_min_val;
            end if;

            toamem_addra <= posmem_addra_prev(NodeW-1 downto 0);

            -- Read Enable flag is used to switch Port-B to SBC interface
            -- During this period, no minmax calculation takes place.
            -- On readback, it clears read address counter which is then
            -- incremented on each read strobe.
            if (timeframe_end_i = '1') then
                toa_rden <= toa_rden_i;
            end if;
            toa_rden_prev <= toa_rden;
            toa_rden_rise <= toa_rden and not toa_rden_prev;

            if (toa_rden_rise = '1') then
                toa_addr <= (others => '0');
            elsif (toa_rstb_i = '1') then
                toa_addr <= toa_addr + 1;
            end if;
        end if;
    end if;
end process;

-- Fetch previous min/max value on on Port-B
toa_min_val <= unsigned(toamem_doutb(15 downto 0));
toa_max_val <= unsigned(toamem_doutb(31 downto 16));

-- Port-A is used to write new minmax values back to the memory
toamem_dina <= std_logic_vector(toa_max_new & toa_min_new);
toamem_wea <= (toa_max_wr or toa_min_wr) and not toa_rden;

-- Port-B is used to clear memory on read strobes, and to readback
-- minmax values via SBC interface
toamem_addrb <= posmem_addra(NodeW-1 downto 0) when (toa_rden = '0') else
                std_logic_vector(toa_addr);
toamem_dinb <= X"0000_FFFF";
toamem_web <= toa_rstb_i and toa_rden;

toa_dat_o <= toamem_doutb;

-- Time Of Arrival memory
toa_mem : entity work.fofb_cc_dpbram
    generic map (
        AW          => NodeW,
        DW          => 32,
        INIT        => X"0000_FFFF"
    )
    port map (
        addra       => toamem_addra,
        addrb       => toamem_addrb,
        clka        => mgtclk_i,
        clkb        => mgtclk_i,
        dina        => toamem_dina,
        dinb        => toamem_dinb,
        douta       => open,
        doutb       => toamem_doutb,
        wea         => toamem_wea,
        web         => toamem_web
    );

---------------------------------------------------------------------
-- Receive Count Buffer : keeps track of receive count for each node.
-- Single BRAM is used to store the count values.
-- It is clocked in mgt clock domain, and readback via SBC is controlled
-- by rcb_rden flag.
---------------------------------------------------------------------
process(mgtclk_i)
begin
    if (mgtclk_i'event and mgtclk_i = '1') then
        if (mgtreset_i = '1') then
            rcb_rden <= '0';
            rcb_val_wr <= '0';
            rcb_addr <= (others => '0');
            rcbmem_addra <= (others => '0');
        else
            -- Look for min and max values, comparison is done on
            -- posmem_wea signal
            rcb_val_wr <= '0';

            if (posmem_wea_prev = '1') then
                rcb_val_new <= rcb_val + 1;
                rcb_val_wr <= '1';
            end if;

            rcbmem_addra <= posmem_addra_prev(NodeW-1 downto 0);

            -- Read Enable flag is used to switch Port-B to SBC interface
            -- During this period, no minmax calculation takes place.
            -- On readback, it clears read address counter which is then
            -- incremented on each read strobe.
            if (timeframe_end_i = '1') then
                rcb_rden <= rcb_rden_i;
            end if;
            rcb_rden_prev <= rcb_rden;
            rcb_rden_rise <= rcb_rden and not rcb_rden_prev;

            if (rcb_rden_rise = '1') then
                rcb_addr <= (others => '0');
            elsif (rcb_rstb_i = '1') then
                rcb_addr <= rcb_addr + 1;
            end if;
        end if;
    end if;
end process;

-- Min and max values are stored together, and read on Port-B
rcb_val <= unsigned(rcbmem_doutb);

-- Port-A is used to write new minmax values back to the memory
rcbmem_dina <= std_logic_vector(rcb_val_new);
rcbmem_wea <= rcb_val_wr and not rcb_rden;

-- Port-B is used to clear memory on read strobes, and to readback
-- minmax values via SBC interface
rcbmem_addrb <= posmem_addra(NodeW-1 downto 0) when (rcb_rden = '0') else
                std_logic_vector(rcb_addr);
rcbmem_dinb <= X"0000_0000";
rcbmem_web <= rcb_rstb_i and rcb_rden;

rcb_dat_o <= rcbmem_doutb;

-- Time Of Arrival memory
rcbmem : entity work.fofb_cc_dpbram
    generic map (
        AW          => NodeW,
        DW          => 32,
        INIT        => X"0000_0000"
    )
    port map (
        addra       => rcbmem_addra,
        addrb       => rcbmem_addrb,
        clka        => mgtclk_i,
        clkb        => mgtclk_i,
        dina        => rcbmem_dina,
        dinb        => rcbmem_dinb,
        douta       => open,
        doutb       => rcbmem_doutb,
        wea         => rcbmem_wea,
        web         => rcbmem_web
    );

end rtl;
