LIBRARY ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.textio.all;

library modelsim_lib;
use modelsim_lib.util.all;

library work;
use work.test_interface.all;

entity fofb_cc_usrapp_checker is
    generic (
        BPMS                : integer := 1;
        test_selector       : in string  := String'("fofb_cc_smoke_test")
    );
    port (
        mgtclk_i            : in  std_logic;
        timeframe_valid_i   : in  std_logic;

        sysclk_i            : in  std_logic;
        xy_buf_addr_o       : out std_logic_vector(9 downto 0);
        xy_buf_dat_i        : in  std_logic_vector(63 downto 0);
        xy_buf_rstb_o       : out std_logic;
        timeframe_start_i   : in  std_logic;
        timeframe_end_i     : in  std_logic
    );
end fofb_cc_usrapp_checker;

architecture rtl of fofb_cc_usrapp_checker is

file fadata     : TEXT open write_mode is "faout.dat";

begin

--
-- Send user payload over TX link
--
NODES_CHECKER : process
    variable textline   : line;
    variable o          : integer;
    variable space      : character;
    variable sw         : std_logic;
    variable addr       : unsigned(7 downto 0);
begin
--    if (test_selector = String'("fofb_cc_smoke_test")) then
--
--        -- Check # of sent and received (from tester poing of view)
--        -- packets. This makes sure that the fofb_cc_top design
--        -- receives/transmits (especially FOD module).
--        FOREVER : loop
--            xy_buf_addr_o <= (others => '0');
--            xy_buf_rstb_o <= '0';
--            sw := '0';
--            addr := (others => '0');
--            wait until falling_edge(timeframe_end_i);
--            -- Print shared variables
--            writeDecToScreen("Number of packets sent     : ", bpmsent);
--            writeDecToScreen("Number of repeated Bpms    : ", bpmrepeated);
--            writeDecToScreen("Number of packets received : ", bpmreceived);
--            if ((bpmsent - bpmrepeated) = bpmreceived-BPMS) then
--                assert false report "NODES COUNT PASSED." severity note;
--            else
--                assert false report "NODES COUNT FAILED." severity error;
--                FINISH_FAILURE;
--            end if;
--
--            PROC_TX_CLK_EAT(10, sysclk_i);
--            -- Start reading stored BPM X/Y data and compare with the
--            -- sent values. X Data starts from 100, and Y start 1000.
--            for N in 0 to bpmsent-1 loop
--                xy_buf_addr_o <= std_logic_vector(to_unsigned(N, 10));
--                xy_buf_rstb_o <= '1';
--                PROC_TX_CLK_EAT(1, sysclk_i);
--                wait for 1 ns;
--
--                if (to_integer(signed(xy_buf_dat_i)) /= (N + 100)) then
--                    assert false report "DATA X FAILED!" severity error;
--                    FINISH_FAILURE;
--                end if;
--            end loop;
--
--            PROC_TX_CLK_EAT(10, sysclk_i);
--            for N in 0 to bpmsent-1 loop
--                xy_buf_addr_o <= std_logic_vector(to_unsigned(N+256, 10));
--                xy_buf_rstb_o <= '1';
--                PROC_TX_CLK_EAT(1, sysclk_i);
--                wait for 1 ns;
--
--                if (to_integer(signed(xy_buf_dat_i)) /= (N + 1000)) then
--                    assert false report "DATA Y FAILED!" severity error;
--                    FINISH_FAILURE;
--                end if;
--            end loop;
--
--            writeNowToScreen(String'("DATA X/Y PASSED."));
--
--            -- clear internal variable for the next time frame
--            bpmarray := (others => 0);
--            bpmrepeated := 0;
--        end loop;
--    end if;
    wait;
end process;

--DATA_CHECKER : process
--    variable textline   : line;
--    variable o          : integer;
--    variable space      : character;
--    variable sw         : std_logic;
--    variable addr       : unsigned(7 downto 0);
--
--begin
--    xy_buf_addr_o <= (others => '0');
--    xy_buf_rstb_o <= '0';
--    sw := '0';
--    addr := (others => '0');
--
--    if (test_selector = String'("fofb_cc_smoke_test")) then
--        -- Check # of sent and received (from tester poing of view)
--        -- packets. This makes sure that the fofb_cc_top design
--        -- receives/transmits (especially FOD module).
--        FOREVER : loop
--            xy_buf_addr_o <= (others => '0');
--            xy_buf_rstb_o <= '0';
--            sw := '0';
--            addr := (others => '0');
--            wait until falling_edge(timeframe_end_i);
--            writeNowToScreen(String'("Frame Ended, Reading Data."));
--            PROC_TX_CLK_EAT(10, sysclk_i);
--            for N in 0 to 511 loop
--                xy_buf_addr_o <= '0' & sw & std_logic_vector(addr);
--                xy_buf_rstb_o <= '1';
--                PROC_TX_CLK_EAT(1, sysclk_i);
--                wait for 1 ns;
--                -- Write data into file in a column
--                --writeHexToScreen("data", xy_buf_dat_i);
--                o := to_integer(signed(xy_buf_dat_i));
--                if (sw = '0') then
--                    write(textline,o);
--                else
--                    write(textline,HT);
--                    write(textline,o);
--                    writeline(fadata,textline);
--                end if;
--                -- Switch between lower and upper address space, and
--                -- keep incrementing
--                if (sw = '1') then
--                    addr := addr + 1;   -- Increment for the next cycle
--                end if;
--                sw := not sw;           -- Switch upper addree space
--            end loop;
--        end loop;
--    end if;
--    wait;
--end process;

end rtl;

