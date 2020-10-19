LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;

library work;
use work.fofb_cc_pkg.all;   -- Diamond FOFB package


ENTITY fofb_cc_arbmux_tb IS
END fofb_cc_arbmux_tb;

ARCHITECTURE behavior OF fofb_cc_arbmux_tb IS

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

constant LaneCount              : integer := 4;

signal mgt_clk                  : std_logic := '0';
signal mgt_rst                  : std_logic := '1';
signal data_in                  : std_logic_2d_128(LaneCount-1 downto 0);
signal data_out                 : std_logic_vector((32*PacketSize-1) downto 0);
signal data_out_rdy             : std_logic;

signal rxf_din                  : std_logic_2d_16(LaneCount-1 downto 0);
signal rxf_dout                 : std_logic_2d_128(LaneCount-1 downto 0);
signal rxf_wr_en                : std_logic_vector(LaneCount-1 downto 0);
signal rxf_rd_en                : std_logic_vector(LaneCount-1 downto 0);
signal rxf_empty                : std_logic_vector(LaneCount-1 downto 0);
signal rxf_empty_n              : std_logic_vector(LaneCount-1 downto 0);
signal rxf_full                 : std_logic_vector(LaneCount-1 downto 0);
signal timeframe_end            : std_logic;
signal timeframe_end_n          : std_logic;
signal timeframe_count          : std_logic_vector(31 downto 0) := (others=>'0');
signal bpm_timeframe_start      : std_logic := '0';
signal timeframe_start          : std_logic := '0';
signal timeframe_valid          : std_logic;

begin

mgt_clk <= not mgt_clk after 5 ns;
mgt_rst <= '0' after 100 ns;

rxf_empty_n <= not rxf_empty;
timeframe_end_n <= not timeframe_end;

uut: entity work.fofb_cc_arbmux
PORT MAP (
    mgt_clk                 => mgt_clk,
    mgt_rst                 => mgt_rst,
    data_in                 => rxf_dout,
    data_in_rdy             => rxf_empty_n,
    rx_fifo_rd_en           => rxf_rd_en,
    channel_up              => "1111",
    data_out                => data_out,
    data_out_rdy            => data_out_rdy,
    timeframe_valid_i       => timeframe_valid
);

RX_FIFO_GEN: for N in 0 to (LaneCount - 1) generate
fofb_cc_rx_buffer_inst : entity work.fofb_cc_rx_buffer
port map (
    rd_en                   => rxf_rd_en(N),
    wr_en                   => rxf_wr_en(N),
    full                    => rxf_full(N),
    empty                   => rxf_empty(N),
    wr_clk                  => mgt_clk,
    rst                     => mgt_rst,
    rd_clk                  => mgt_clk,
    dout                    => rxf_dout(N),
    din                     => rxf_din(N),
    reset                   => '0',
    timeframe_valid_i       => timeframe_valid,
    max_data_count          => open
);
end generate;

fofb_cc_frame_cntrl : entity work.fofb_cc_frame_cntrl
generic map (
    DEVICE                  => BPM,
    LaneCount               => 4
)
port map(
    mgtclk_i                => mgt_clk,
    mgtreset_i              => mgt_rst,

    tfs_bpm_i               => bpm_timeframe_start,
    tfs_pmc_i               => "0000",

    timeframe_len_i         => X"2000",
    timeframe_start_o       => timeframe_start,
    timeframe_end_o         => timeframe_end,
    timeframe_valid_o       => timeframe_valid,

    pmc_timeframe_cntr_i    => (others => (others => '0')),
    pmc_timestamp_val_i     => (others => (others => '0')),

    timeframe_cntr_o        => timeframe_count,
    timestamp_value_o       => open
);

-- Stimulus process
stim_proc: process
begin
    rxf_wr_en(0) <= '0';
    rxf_din(0) <= (others => '0');
    -- hold reset state for 100 ns.
    PROC_TX_CLK_EAT(1000, mgt_clk);

    for N in 1 to 9 loop
        for I in 1 to 8 loop
            rxf_wr_en(0) <= '1';
            if (I = 8) then
                rxf_din(0) <= rxf_din(0) + N;
            else
                rxf_din(0) <= (others => '0');
            end if;
            PROC_TX_CLK_EAT(1, mgt_clk);
            rxf_wr_en(0) <= '0';
        end loop;
    end loop;

    wait for 1000 ns;

    bpm_timeframe_start <= '1';
    PROC_TX_CLK_EAT(1, mgt_clk);
    bpm_timeframe_start <= '0';


   -- insert stimulus here 

   wait;
end process;

rxf_din(1) <= rxf_din(0);
rxf_din(2) <= rxf_din(0);
rxf_din(3) <= rxf_din(0);

rxf_wr_en(1) <= rxf_wr_en(0);
rxf_wr_en(2) <= rxf_wr_en(0);
rxf_wr_en(3) <= rxf_wr_en(0);

END;
