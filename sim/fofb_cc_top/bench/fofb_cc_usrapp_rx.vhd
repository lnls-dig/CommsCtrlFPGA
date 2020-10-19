library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

library work;
use work.test_interface.all;

-----------------------------------------------
--  Entity declaration
-----------------------------------------------
entity fofb_cc_usrapp_rx is
    generic (
        RX_IDLE_NUM     : natural := 13    --4095 cc
    );
    port (
        -- clocks and resets
        mgtclk_i            : in  std_logic;
        mgtreset_i          : in  std_logic;
        rxreset_o           : out std_logic;
        --
        rxdata_i            : in  std_logic_vector(15 downto 0);
        rxcharisk_i         : in  std_logic_vector(1 downto 0);
        rxcheckingcrc_i     : in  std_logic;
        rxcrcerr_i          : in  std_logic;

        timeframe_end_i     : in  std_logic
    );
end fofb_cc_usrapp_rx;

architecture rtl of fofb_cc_usrapp_rx is

type rx_state_type is (rx_idle, rx_getdata, rx_waitfor_crc);
signal rx_state             : rx_state_type;

signal rxlinkup             : std_logic;
signal rxcheckingcrc_reg    : std_logic;
signal rxcheckingcrc_rise   : std_logic;
signal timeframe_end_reg    : std_logic;
signal timeframe_end_rise   : std_logic;

procedure READ_RX_DATA (

    variable rxdata       : in std_logic_vector(127 downto 0)

) is

begin

    writeHexToScreen("Data received from BPM ", rxdata(27 downto 16));

end;

-- Initialise RX link
begin
TX_INIT : process
    variable sendid_counter : integer;
    variable rxcounter      : integer;
begin
        rxreset_o <= '1';
        rxlinkup <= '0';
        wait until falling_edge(mgtreset_i);

        -- Reset RX MGT link for 8 clock cycles
        for I in 0 to 7 loop
            rxreset_o <= '1';
            PROC_TX_CLK_EAT(1, mgtclk_i);
        end loop;

        rxreset_o <= '0';
        PROC_TX_CLK_EAT(1, mgtclk_i);

        -- Receive certain number of IDLE chars consecutevly
        -- to asser rx link up flag
        while (rxcounter < (2**(RX_IDLE_NUM-1))) loop
            wait until (mgtclk_i'event and mgtclk_i = '1');
            if (rxdata_i = IDLE and rxcharisk_i = "10") then
                rxcounter := rxcounter + 1;
            else
                rxcounter := 0;
            end if;
        end loop;

        PROC_TX_CLK_EAT(1, mgtclk_i);
        rxlinkup <= '1';

        writeNowToScreen(String'("RX Link is up."));

        wait;
end process;

rxcheckingcrc_rise <= rxcheckingcrc_i and not rxcheckingcrc_reg;
timeframe_end_rise <= timeframe_end_i and not timeframe_end_reg;

RX : process(mgtclk_i)

    variable rxdata         : std_logic_vector(127 downto 0);
    variable rxdatacounter  : integer;

begin
    if (mgtclk_i'event and mgtclk_i='1') then
        if (mgtreset_i = '1' or rxlinkup = '0') then
            rxdata := (others => '0');
            rxdatacounter := 8;
            bpmreceived := 0;
            rx_state <= rx_idle;
            rxcheckingcrc_reg <= '0';
            timeframe_end_reg <= '0';
        else
            rxcheckingcrc_reg <= rxcheckingcrc_i;
            timeframe_end_reg <= timeframe_end_i;

            case (rx_state) is

                when rx_idle =>
                    if (rxdata_i = SOP and rxcharisk_i = "11" and timeframe_end_i = '0') then
                        rx_state <= rx_getdata;
                    end if;

                when rx_getdata =>
                    rxdata := rxdata_i & rxdata(127 downto 16);
                    rxdatacounter := rxdatacounter - 1;
                    if (rxdatacounter = 0) then
                        rxdatacounter := 8;
                        rx_state <= rx_idle;
                    end if;

                when others =>

            end case;

            if (rxcheckingcrc_rise = '1' and timeframe_end_i = '0') then
                if (rxcrcerr_i = '0') then
--                    READ_RX_DATA(rxdata);
                    bpmreceived := bpmreceived + 1;
                else
                    assert(false)
                    report "CRC error detected."
                        severity failure;
                end if;
            end if;

            if (timeframe_end_rise = '1') then
--                writeDecToScreen("Number of packets received : ", bpmreceived);
                bpmreceived := 0;
            end if;

        end if;

    end if;

end process;

end rtl;


