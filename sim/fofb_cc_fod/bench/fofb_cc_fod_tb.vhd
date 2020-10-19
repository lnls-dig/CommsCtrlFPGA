LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.fofb_cc_pkg.all;   -- Diamond FOFB package

USE std.textio.all;
USE work.io_utils.all;

entity fofb_cc_fod_tb is
generic (
    BPMS        : integer := 4
);
end fofb_cc_fod_tb;

ARCHITECTURE behavior OF fofb_cc_fod_tb IS 

procedure PROC_TX_CLK_EAT  (
    clock_count             : in integer;
    signal trn_clk          : in std_logic
) is
    variable i  : integer;
begin
    for i in 0 to (clock_count - 1) loop
        wait until (trn_clk'event and trn_clk = '1');
    end loop;
end PROC_TX_CLK_EAT;

procedure PROC_SEND_DATA  (
    id                      : in  integer;
    xpos                    : in  integer;
    ypos                    : in  integer;
    signal clk              : in  std_logic;
    signal fod_dat          : out std_logic_vector(127 downto 0);
    signal fod_val          : out std_logic
) is
begin
    fod_dat(NodeW+95 downto 96) <= std_logic_vector(to_unsigned(id,
NodeW));
    fod_dat(95 downto 64) <= std_logic_vector(to_unsigned(xpos,32));
    fod_dat(63 downto 32) <= std_logic_vector(to_unsigned(ypos,32));
    fod_val <= '1';
    PROC_TX_CLK_EAT(1, clk);
    fod_dat <= (others => '0');
    fod_val <= '0';
    PROC_TX_CLK_EAT(1, clk);
end PROC_SEND_DATA;

signal mgtclk_i             : std_logic := '0';
signal sysclk_i             : std_logic := '0';
signal mgtreset_i           : std_logic := '1';
signal timeframe_valid      : std_logic := '0';
signal timeframe_start      : std_logic := '0';
signal timeframe_end        : std_logic := '0';
signal linksup_i            : std_logic_vector(3 downto 0) := (others => '1');
signal fod_dat_i            : std_logic_vector(127 downto 0) := (others => '0');
signal fod_dat_val_i        : std_logic := '0';
signal timeframe_val_i      : std_logic_vector(31 downto 0) := (others => '0');
signal timestamp_val_i      : std_logic_vector(31 downto 0) := (others => '0');
signal bpm_x_pos_i          : std_logic_2d_32(BPMS-1 downto 0);
signal bpm_y_pos_i          : std_logic_2d_32(BPMS-1 downto 0);
signal pos_datsel_i         : std_logic := '0';
signal txf_full_i           : std_logic_vector(3 downto 0) := (others => '0');
signal bpmid_i              : std_logic_vector(9 downto 0);
signal xy_buf_addr_i        : std_logic_vector(NodeW downto 0) := (others => '0');
signal golden_orb_x_i       : std_logic_vector(31 downto 0) := (others => '0');
signal golden_orb_y_i       : std_logic_vector(31 downto 0) := (others => '0');
signal fofb_watchdog_i      : std_logic_vector(31 downto 0) := (others => '0');
signal fofb_event_i         : std_logic_vector(31 downto 0) := (others => '1');
signal fofb_dma_ok_i        : std_logic := '1';

signal fod_dat_o            : std_logic_vector(127 downto 0);
signal fod_dat_val_o        : std_logic_vector(3 downto 0);
signal timeframe_end_rise_o : std_logic;
signal xy_buf_dout_o        : std_logic_vector(63 downto 0);
signal fodprocess_time_o    : std_logic_vector(15 downto 0);
signal bpm_count_o          : std_logic_vector(7 downto 0);
signal fofb_node_mask_o     : std_logic_vector(NodeNum-1 downto 0);

signal bpm_timeframe_start  : std_logic := '0';
signal timeframe_count      : std_logic_vector(31 downto 0) := (others=>'0');

signal id                   : unsigned(NodeW-1 downto 0);
signal xpos                 : unsigned(31 downto 0);
signal ypos                 : unsigned(31 downto 0);

signal id_out               : std_logic_vector(NodeW-1 downto 0);
signal xpos_out             : std_logic_vector(31 downto 0);
signal ypos_out             : std_logic_vector(31 downto 0);

signal toa_addr             : std_logic_vector(NodeW-1 downto 0) := (others =>
    '0');
signal toa_dat              : std_logic_vector(31 downto 0);
signal toa_rstb             : std_logic := '0';
signal toa_rden             : std_logic := '0';
signal rcb_addr             : std_logic_vector(NodeW-1 downto 0) := (others =>
    '0');
signal rcb_dat              : std_logic_vector(31 downto 0);
signal rcb_rstb             : std_logic := '0';
signal rcb_rden             : std_logic := '0';

BEGIN
mgtclk_i <= not mgtclk_i after 4 ns;
sysclk_i <= not sysclk_i after 8 ns;
mgtreset_i <= '0' after 100 ns;

-- Static BPM ID
bpmid_i <= std_logic_vector(to_unsigned(100,10));

bpm_x_pos_i(0) <= X"11111111";
bpm_y_pos_i(0) <= X"10101010";
bpm_x_pos_i(1) <= X"22222222";
bpm_y_pos_i(1) <= X"20202020";
bpm_x_pos_i(2) <= X"33333333";
bpm_y_pos_i(2) <= X"10101010";
bpm_x_pos_i(3) <= X"44444444";
bpm_y_pos_i(3) <= X"20202020";

uut: entity work.fofb_cc_fod
GENERIC MAP (
    BPMS                 => BPMS,
    DEVICE               => BPM
)
PORT MAP (
    mgtclk_i             => mgtclk_i,
    sysclk_i             => sysclk_i,
    mgtreset_i           => mgtreset_i,
    timeframe_valid_i    => timeframe_valid,
    timeframe_start_i    => timeframe_start,
    timeframe_end_i      => timeframe_end,
    timeframe_dly_i      => X"0000",

    linksup_i            => linksup_i,
    fod_dat_i            => fod_dat_i,
    fod_dat_val_i        => fod_dat_val_i,
    fod_dat_o            => fod_dat_o,
    fod_dat_val_o        => fod_dat_val_o,

    timeframe_cntr_i     => timeframe_count,
    timestamp_val_i      => (others => '0'),

    bpm_x_pos_i          => bpm_x_pos_i,
    bpm_y_pos_i          => bpm_y_pos_i,
    pos_datsel_i         => pos_datsel_i,
    txf_full_i           => txf_full_i,
    bpmid_i              => bpmid_i,
    xy_buf_dout_o        => xy_buf_dout_o,
    xy_buf_addr_i        => xy_buf_addr_i,
    xy_buf_rstb_i        => '0',
    fodprocess_time_o    => fodprocess_time_o,
    bpm_count_o          => bpm_count_o,
    golden_orb_x_i       => golden_orb_x_i,
    golden_orb_y_i       => golden_orb_y_i,
    fofb_watchdog_i      => fofb_watchdog_i,
    fofb_event_i         => fofb_event_i,
    fofb_dma_ok_i        => fofb_dma_ok_i,
    fofb_node_mask_o     => fofb_node_mask_o,
    toa_dat_o            => toa_dat,
    toa_rstb_i           => toa_rstb,
    toa_rden_i           => toa_rden,
    rcb_dat_o            => rcb_dat,
    rcb_rstb_i           => rcb_rstb,
    rcb_rden_i           => rcb_rden
);

-- Generate frame timing signals
-- It uses CC frame control module which is fed by
-- 10usec BPM start pulse
bpm_start : process
begin
    PROC_TX_CLK_EAT(100, mgtclk_i);

    for I in 1 to 5 loop
        bpm_timeframe_start <= '1';
        PROC_TX_CLK_EAT(1, mgtclk_i);
        bpm_timeframe_start <= '0';
        PROC_TX_CLK_EAT(9999, mgtclk_i);
    end loop;
end process;

fofb_cc_frame_cntrl : entity work.fofb_cc_frame_cntrl
generic map (
    DEVICE                  => BPM,
    LaneCount               => 4
)
port map(
    mgtclk_i                => mgtclk_i,
    mgtreset_i              => mgtreset_i,

    tfs_bpm_i               => bpm_timeframe_start,
    tfs_pmc_i               => "0000",

    timeframe_len_i         => X"2000",
    timeframe_start_o       => timeframe_start,
    timeframe_end_o         => timeframe_end,
    timeframe_valid_o       => timeframe_valid,

    pmc_timeframe_cntr_i    => (others => (others => '0')),
    pmc_timestamp_val_i     => (others => (others => '0')),

    timeframe_cntr_o        => open,
    timestamp_value_o       => open
);


--
-- Generate Stimuli
--
data_generator: process
begin
    id     <= to_unsigned(5, NodeW);
    xpos   <= (others => '0');
    ypos   <= (others => '0');


    -- Test for flipping BPM on the network
    wait until rising_edge(timeframe_start);
    PROC_TX_CLK_EAT(10, mgtclk_i);
    PROC_SEND_DATA(2,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(3,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(4,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(5,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(6,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(7,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(200,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);

    wait until rising_edge(timeframe_start);
    PROC_TX_CLK_EAT(15, mgtclk_i);
    PROC_SEND_DATA(2,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(3,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(4,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(5,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(6,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(7,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);

    wait until rising_edge(timeframe_start);
    PROC_TX_CLK_EAT(5, mgtclk_i);
    PROC_SEND_DATA(2,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(3,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(4,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(5,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(6,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(7,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);
--    PROC_SEND_DATA(200,10,20,mgtclk_i,fod_dat_i,fod_dat_val_i);

    wait;
end process;


id_out   <= fod_dat_o(NodeW+95 downto 96);
xpos_out <= fod_dat_o(95 downto 64);
ypos_out <= fod_dat_o(63 downto 32);


read_toa: process
    file toa            : text;
    variable textline   : line;
    variable toadat     : integer;
begin

    file_open(toa, "toa.out", write_mode);
    PROC_TX_CLK_EAT(7500, sysclk_i);

    toa_rden  <= '1';
    PROC_TX_CLK_EAT(10000, mgtclk_i);

    for I in 0 to 255 loop
        toa_addr <= std_logic_vector(to_unsigned(I,NODEW));
        toa_rstb <= '1';
        PROC_TX_CLK_EAT(1, mgtclk_i);
        toa_rstb <= '0';
        toadat := to_integer(signed(toa_dat));
        write(textline,toadat);
        writeline(toa, textline);
        PROC_TX_CLK_EAT(10, mgtclk_i);
    end loop;

    file_close(toa);

    wait;
end process;

read_rcb: process
    file toa            : text;
    variable textline   : line;
    variable toadat     : integer;
begin

    file_open(toa, "rcb.out", write_mode);
    PROC_TX_CLK_EAT(10000, mgtclk_i);

    rcb_rden  <= '1';
    PROC_TX_CLK_EAT(10000, mgtclk_i);

    for I in 0 to 255 loop
        rcb_addr <= std_logic_vector(to_unsigned(I,NODEW));
        rcb_rstb <= '1';
        PROC_TX_CLK_EAT(1, mgtclk_i);
        rcb_rstb <= '0';
        toadat := to_integer(signed(rcb_dat));
        write(textline,toadat);
        writeline(toa, textline);
        PROC_TX_CLK_EAT(10, mgtclk_i);
    end loop;

    file_close(toa);

    wait;
end process;

END;
