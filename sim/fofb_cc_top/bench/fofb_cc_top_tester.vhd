library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- synthesis translate_off
library unisim;
use unisim.all;
-- synthesis translate_on

library work;
use work.fofb_cc_pkg.all;
use work.test_interface.all;

entity fofb_cc_top_tester is
    generic (
        test_selector       : in string  := String'("fofb_cc_smoke_test");
        DEVICE              : device_t := PBPM;
        TX_IDLE_NUM         : natural := 18;
        RX_IDLE_NUM         : natural := 12;
        SEND_ID_NUM         : natural := 16;

        BPMS                : integer := 1;
        FAI_DW              : integer := 16;
        DMUX                : integer := 2;

        TEST_DURATION       : integer := 5
    );
    port (
        refclk_i            : in  std_logic;
        sysclk_i            : in  std_logic;
        userclk_i           : in  std_logic;
        userclk_2x_i        : in  std_logic;

        txoutclk_o          : out std_logic;
        plllkdet_o          : out std_logic;

        gtreset_i           : in  std_logic;
        mgtreset_i          : in  std_logic;
        adcclk_i            : in  std_logic;

        fai_cfg_a_i         : in  std_logic_vector(10 downto 0);
        fai_cfg_do_i        : in  std_logic_vector(31 downto 0);
        fai_cfg_di_o        : out std_logic_vector(31 downto 0);
        fai_cfg_we_i        : in  std_logic;
        fai_cfg_clk_i       : in  std_logic;
        fai_cfg_val_o       : out std_logic_vector(31 downto 0);

        fai_fa_block_start_o: out std_logic;
        fai_fa_data_valid_o : out std_logic;
        fai_fa_d_o          : out std_logic_vector(FAI_DW-1 downto 0);

        xy_buf_addr_o       : out  std_logic_vector(NodeW downto 0);
        xy_buf_dat_i        : in   std_logic_vector(63 downto 0);
        xy_buf_rstb_o       : out  std_logic;
        timeframe_start_i   : in   std_logic;
        timeframe_end_i     : in   std_logic;

        rxn_i               : in  std_logic;
        rxp_i               : in  std_logic;
        txn_o               : out std_logic;
        txp_o               : out std_logic
    );
end fofb_cc_top_tester;

ARCHITECTURE behavior OF fofb_cc_top_tester IS

-----------------------------------------------
-- Signal declaration
-----------------------------------------------
signal GND4             : std_logic_vector (15 downto 0);
signal float2_0         : std_logic_vector(1 downto 0);
signal float2_1         : std_logic_vector(1 downto 0);
signal float2_2         : std_logic_vector(1 downto 0);
signal float2_3         : std_logic_vector(1 downto 0);
signal float16          : std_logic_vector(15 downto 0);
signal time_frame_end   : std_logic := '0';
signal time_frame_cnt   : std_logic_vector(15 downto 0) := (others => '0');
signal cc_cfg_wen       : std_logic;
signal cc_cfg_addr      : std_logic_vector(10 downto 0);
signal cc_cfg_dat       : std_logic_vector(31 downto 0);
signal fai_cfg_do       : std_logic_vector(31 downto 0);
signal txf_din          : std_logic_vector(127 downto 0);
signal txf_wr_en        : std_logic;
signal txf_dout         : std_logic_vector(15 downto 0);
signal txf_rd_en        : std_logic;
signal txf_empty        : std_logic;
signal userclk          : std_logic;
signal timeframe_start  : std_logic;
signal timeframe_val    : unsigned(15 downto 0);
signal timeframe_valid  : std_logic;
signal rx_dat           : std_logic_vector(15 downto 0);
signal rx_dat_val       : std_logic;
signal rx_dat_val_prev  : std_logic;

begin

userclk <= userclk_i;

------------------------------------------------------------------
-- Virtex-5 GTP Interface
------------------------------------------------------------------
fofb_cc_gtp_if : entity work.fofb_cc_gtp_if
generic map (
    LaneCount               => 1,
    TX_IDLE_NUM             => TX_IDLE_NUM,
    RX_IDLE_NUM             => RX_IDLE_NUM,
    SEND_ID_NUM             => SEND_ID_NUM,
    SIM_GTPRESET_SPEEDUP    => 1
)
port map (
    refclk_i                => refclk_i,
    mgtreset_i              => mgtreset_i,
    initclk_i               => '0',
    gtreset_i               => gtreset_i,
    txoutclk_o              => txoutclk_o,
    plllkdet_o              => plllkdet_o,
    userclk_i               => userclk_i,
    userclk_2x_i            => userclk_2x_i,

    rxn_i(0)                => rxn_i,
    rxp_i(0)                => rxp_i,
    txn_o(0)                => txn_o,
    txp_o(0)                => txp_o,

    timeframe_start_i       => timeframe_start,
    timeframe_valid_i       => timeframe_valid,
    timeframe_cntr_i        => std_logic_vector(timeframe_val),
    bpmid_i                 => "0111111111",

    powerdown_i             => (others => '0'),
    loopback_i              => (others => '0'),
    linksup_o               => open,
    harderror_cnt_o         => open,
    softerror_cnt_o         => open,
    frameerror_cnt_o        => open,

    tx_sm_busy_o            => open,
    rx_sm_busy_o            => open,

    tfs_bit_o               => open,
    link_partner_o          => open,
    pmc_timeframe_val_o     => open,
    pmc_timestamp_val_o     => open,

    txpck_cnt_o             => open,
    rxpck_cnt_o             => open,

    tx_dat_i(0)             => txf_dout,
    txf_empty_i(0)          => txf_empty,
    txf_rd_en_o(0)          => txf_rd_en,

    rxf_full_i              => (others => '0'),
    rx_dat_o(0)             => rx_dat,
    rx_dat_val_o(0)         => rx_dat_val
);

------------------------------------------------------------------
-- Configuration Interface for DUT
------------------------------------------------------------------
fai_cfg_do <= fai_cfg_do_i;

cc_conf_bram : entity work.fofb_cc_dpbram
    generic map(
        AW          => 11,
        DW          => 32
    )
    port map (
        addra       => cc_cfg_addr,
        addrb       => fai_cfg_a_i,
        clka        => userclk,
        clkb        => fai_cfg_clk_i,
        dina        => cc_cfg_dat,
        dinb        => fai_cfg_do,
        douta       => open,
        doutb       => fai_cfg_di_o,
        wea         => cc_cfg_wen,
        web         => fai_cfg_we_i
    );

--
-- Time frame start pulse generator.
-- All communications are synced to this signal
--
process
    variable timeframe_counter   : integer;
begin
    timeframe_start <= '0';
    timeframe_valid <= '0';
    timeframe_counter := 0;
    timeframe_val <= (others => '0');

    PROC_TX_CLK_EAT(10000, userclk);

    FOREVER : loop
        wait until (userclk'event and userclk = '1');
        if (timeframe_counter = 0) then
            timeframe_start <= '1';
            timeframe_valid <= '1';
            timeframe_counter := 10071;
            timeframe_val <= timeframe_val + 1;
        elsif (timeframe_counter = 2000) then
            timeframe_valid <= '0';
            timeframe_counter := timeframe_counter - 1;
        else
            timeframe_start <= '0';
            timeframe_counter := timeframe_counter - 1;
        end if;

    end loop;
end process;

--
-- Depending on the how CC is configured (BPM or PMC) in the Generics
-- we have to generate relevant interface signals accordingly
--
BPM_TEST : if (DEVICE = BPM) generate
    -- Fai datastream input to CC
    FAI_DATA : process
        variable fa_dat : unsigned(FAI_DW-1 downto 0);
    begin
        fai_fa_block_start_o <= '0';
        fai_fa_data_valid_o <= '0';
        fai_fa_d_o <= (others=>'0');
        fa_dat := (others => '0');

        for I in 1 to TEST_DURATION loop
            wait until rising_edge(timeframe_start);
            PROC_TX_CLK_EAT(1, adcclk_i);
            for N in 0 to (BPMS*DMUX*16-1) loop
                fai_fa_block_start_o <= '1';
                fai_fa_data_valid_o <= '1';
                fa_dat := fa_dat + 1;
                fai_fa_d_o <= std_logic_vector(fa_dat);
                PROC_TX_CLK_EAT(1, adcclk_i);
                fai_fa_block_start_o <= '0';
                fai_fa_data_valid_o <= '0';
            end loop;
            fai_fa_d_o <= (others => '0');
        end loop;

        wait;
    end process;
end generate;

------------------------------------------------------------------
-- TX user application
------------------------------------------------------------------
tx_usrapp : entity work.fofb_cc_usrapp_tx
    generic map (
        test_selector       => test_selector,
        TEST_DURATION       => TEST_DURATION
    )
    port map (
        mgtclk_i            => userclk,
        mgtreset_i          => mgtreset_i,
        -- CC configuration BRAM interface
        fai_cfg_val_o       => fai_cfg_val_o,
        cc_cfg_addr_o       => cc_cfg_addr,
        cc_cfg_dat_o        => cc_cfg_dat,
        cc_cfg_wen_o        => cc_cfg_wen,
        --
        timeframe_start_i   => timeframe_start,
        timeframe_val_i     => std_logic_vector(timeframe_val),
        -- Tx fifo interface
        tx_dat_o            => txf_din,
        tx_dat_val_o        => txf_wr_en
    );

fofb_cc_tx_fifo : entity work.fofb_cc_tx_fifo
    port map (
        din                 => txf_din,
        wr_clk              => userclk,
        rd_clk              => userclk,
        rd_en               => txf_rd_en,
        rst                 => '0',
        wr_en               => txf_wr_en,
        dout                => txf_dout,
        empty               => txf_empty,
        full                => open
    );

----------------------------------------------------------------------
------ RX user application
----------------------------------------------------------------------
--rx_usrapp : entity work.fofb_cc_usrapp_rx
--    port map (--
--        mgtclk_i            => userclk,
--        mgtreset_i          => mgtreset_i,
--        rxreset_o           => rxreset,
--        --
--        rxdata_i            => rxdata,
--        rxcharisk_i         => rxcharisk,
--        rxcheckingcrc_i     => rxcheckingcrc,
--        rxcrcerr_i          => rxcrcerr,
--
--        timeframe_end_i     => timeframe_end
--    );


process (userclk)
begin
    if rising_edge(userclk) then
        rx_dat_val_prev <= rx_dat_val;
        if (timeframe_start = '1') then
            bpmreceived := 0;
        elsif (rx_dat_val = '1' and  rx_dat_val_prev = '0') then
            bpmreceived := bpmreceived + 1;
        end if;
    end if;
end process;

fofb_cc_usrapp_checker : entity work.fofb_cc_usrapp_checker
    generic map (
        BPMS                => BPMS,
        test_selector       => test_selector
    )
    port map (
        mgtclk_i            => userclk,
        timeframe_valid_i   => timeframe_valid,
        --
        sysclk_i            => sysclk_i,
        xy_buf_addr_o       => xy_buf_addr_o,
        xy_buf_dat_i        => xy_buf_dat_i,
        xy_buf_rstb_o       => xy_buf_rstb_o,
        timeframe_start_i   => timeframe_start_i,
        timeframe_end_i     => timeframe_end_i
    );

end;
