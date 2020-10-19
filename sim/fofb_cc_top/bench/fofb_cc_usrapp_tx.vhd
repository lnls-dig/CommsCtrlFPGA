LIBRARY ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.textio.all;

library modelsim_lib;
use modelsim_lib.util.all;

library work;
use work.test_interface.all;

entity fofb_cc_usrapp_tx is
    generic (
        test_selector       : in string  := String'("fofb_cc_smoke_test");
        TEST_DURATION       : integer := 5
    );
    port (
        mgtclk_i            : in  std_logic;
        mgtreset_i          : in  std_logic;

        fai_cfg_val_o       : out std_logic_vector(31 downto 0);
        cc_cfg_addr_o       : out std_logic_vector(10 downto 0);
        cc_cfg_dat_o        : out std_logic_vector(31 downto 0);
        cc_cfg_wen_o        : out std_logic;

        timeframe_start_i   : in  std_logic;
        timeframe_val_i     : in  std_logic_vector(15 downto 0);

        tx_dat_o            : out std_logic_vector(127 downto 0);
        tx_dat_val_o        : out std_logic
    );
end fofb_cc_usrapp_tx;

architecture rtl of fofb_cc_usrapp_tx is

signal  timeframenum        : integer;

begin

timeframenum <= to_integer(unsigned(timeframe_val_i));

--
-- Send user payload over TX link
--
TX_STIMULI : process
    variable seed1, seed2       : positive;
    variable rand               : real;
    variable randint            : integer;
    variable packets            : integer;
    variable bpmid              : integer;
    variable timeframe_val_i    : integer;
    variable payloadsel         : unsigned(7 downto 0) := X"76";
begin

    fai_cfg_val_o <= X"00000000";
    cc_cfg_addr_o <= "00000000000";
    cc_cfg_dat_o <= X"00000000";
    cc_cfg_wen_o <= '0';
    tx_dat_o <= (others => '0');
    tx_dat_val_o <= '0';


    -- Initialise data, this data is used in _checker module to
    -- verify correct operation of CC.
    for I in 0 to 255 loop
        sent_packets(I).id    := std_logic_vector(to_unsigned(I,8));
        sent_packets(I).x_pos := std_logic_vector(to_unsigned(I+1000,32));
        sent_packets(I).y_pos := std_logic_vector(to_unsigned(I+10000,32));
    end loop;

    wait until falling_edge(mgtreset_i);

    -- First Configure and Enable CC under test
    writeNowToScreen(String'("Configuring <fofb_cc_top> under test (ignore for pci-e test."));
    PROC_TX_CONFIGURE_CC (mgtclk_i, cc_cfg_addr_o, cc_cfg_dat_o, cc_cfg_wen_o,
    fai_cfg_val_o, 254, 8000, 0, 0, to_integer(payloadsel));
    writeNowToScreen(String'("Enabling <fofb_cc_top> under test (ignore for pci-e test.)"));
    PROC_TX_ENABLE_CC(fai_cfg_val_o);
    PROC_TX_TFSOVERRIDE(fai_cfg_val_o);

    -- TEST = fofb_cc_smoke_test
    -- Smoke Test sends random number of packets with random intervals, 
    -- and runs for TEST_DURATION
    -- time frames. It displays # of send TX packets, # of repeated 
    -- BPM packets and # of received packets
    -- For PMC Design: received packets = (tx - repeated)
    if (test_selector = String'("fofb_cc_smoke_test")) then

        writeNowToScreen(String'("Running fofb_cc_smoke_test."));
        for N in 1 to TEST_DURATION loop
            wait until (timeframe_start_i'event and timeframe_start_i = '1');
            bpmarray := (others => 0);
            bpmsent := 0;
            -- Wait until BPM-DUT to internally capture data
            PROC_TX_CLK_EAT(256, mgtclk_i);
            writeNowWithDataToScreen("TIME FRAME --> ", timeframenum);

            -- Generate random number of packets to send between [0-199]
            uniform(seed1, seed2, rand);
            packets := integer(trunc(rand * 199.0));
            writeNowWithDataToScreen("Number of packets: ", packets);

            for I in 0 to packets  loop
                PROC_TX_SEND_PACKET(mgtclk_i, tx_dat_o, tx_dat_val_o, timeframenum, sent_packets(I));
                bpmsent := bpmsent + 1;
                -- Generate random intervalof [0 31] clocks before
                -- sending next packet
                uniform(seed1, seed2, rand);
                randint := integer(trunc(rand * 31.0));
                PROC_TX_CLK_EAT(randint, mgtclk_i);
            end loop;

        end loop;

    else

      writeNowToScreen(String'("ERROR: No test has been selected"));
      FINISH_FAILURE;

    end if;   -- test selection

    PROC_TX_CLK_EAT(7500, mgtclk_i);
    FINISH;

    wait;

end process;

end rtl;
