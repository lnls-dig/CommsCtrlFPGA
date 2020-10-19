-------------------------------------------------------------------------------
-- 
-- $Revision: 1.4 $
-- $Date: 2003/12/31 02:15:09 $
--
-------------------------------------------------------------------------------
-- Receive CRC Example
-------------------------------------------------------------------------------
--
--     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"
--     SOLELY FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR
--     XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION
--     AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION
--     OR STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS
--     IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,
--     AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE
--     FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY
--     WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE
--     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
--     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF
--     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
--     FOR A PARTICULAR PURPOSE.
--     
--     (c) Copyright 2003 Xilinx, Inc.
--     All rights reserved.
--
---------------------------------------------------------------------
-- File Name: rx_crc_example.vhd
-- Author: Nanditha Jayarajan
-- Contributors: Chris Borrelli
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.crc_components.all;
use work.crc_functions.all;

entity top is
generic (data_width      :  integer :=64);
port
  (
  DATA_DS_TOP           : OUT std_logic_vector(data_width-1 DOWNTO 0);
  REM_DS_TOP            : OUT std_logic_vector(rem_width_calc(data_width)-1 DOWNTO 0) ;
  SOF_N_DS_TOP          : OUT std_logic;
  EOF_N_DS_TOP          : OUT std_logic;
  SRC_RDY_N_DS_TOP      : OUT std_logic;
  DST_RDY_N_US_TOP      : OUT std_logic;
  CRC_PASS_FAIL_N_TOP   : OUT std_logic;
  CRC_VALID_TOP         : OUT std_logic;
  DATA_US_TOP           : IN  std_logic_vector(data_width-1 downto 0);
  REM_US_TOP            : IN  std_logic_vector(rem_width_calc(data_width)-1 DOWNTO 0);
  SOF_N_US_TOP          : IN  std_logic;
  EOF_N_US_TOP          : IN  std_logic;
  SRC_RDY_N_US_TOP      : IN  std_logic;
  DST_RDY_N_DS_TOP      : IN  std_logic;
  RESET_TOP             : IN  std_logic;
  CLK_TOP               : IN  std_logic
);

end top;

architecture top_arch of top is

--attribute syn_noclockbuf                    : boolean;
--attribute syn_noclockbuf  of top_arch       : architecture is true;

constant crc_width     :  integer := 32;
constant poly          :  std_logic_vector(crc_width-1 downto 0) := "00000100110000010001110110110111";
constant alligned_data :  std_logic := '0';
constant insertcrc     :  std_logic := '0';
constant residue       :  std_logic := '1';
constant stripcrc      :  std_logic := '0';
constant pipeline      :  std_logic := '1';
constant back_to_back  :  std_logic := '0';
constant trandata      :  std_logic := '1';
constant trancrc       :  std_logic := '1';
constant compcrc       :  std_logic := '1';
constant crcinit       :  std_logic_vector(crc_width-1 downto 0) := "11111111111111111111111111111111";
constant residue_value :  std_logic_vector(crc_width-1 downto 0) := "11000111000001001101110101111011";

constant no_of_data_bytes                   :  std_logic_vector(4  DOWNTO 0)
                                            := no_of_bytes_calc(data_width);
constant no_of_crc_bytes                    :  std_logic_vector(4  DOWNTO 0)
                                            := no_of_bytes_calc(crc_width);

constant DLY                                : integer := 1;

signal   DATA_US_REG,DATA_US_REG1           : std_logic_vector(data_width-1 downto 0);
signal   REM_US_REG,REM_US_REG1             : std_logic_vector(rem_width_calc(data_width)-1 downto 0);
signal   SOF_N_US_REG,SOF_N_US_REG1         : std_logic;
signal   EOF_N_US_REG,EOF_N_US_REG1         : std_logic;
signal   SRC_RDY_N_US_REG,SRC_RDY_N_US_REG1 : std_logic;
signal   DST_RDY_N_DS_REG,DST_RDY_N_DS_REG1 : std_logic;
signal   DATA_DS_REG,DATA_DS_REG1           : std_logic_vector(data_width-1 downto 0);
signal   REM_DS_REG,REM_DS_REG1             : std_logic_vector(rem_width_calc(data_width)-1 downto 0);
signal   SOF_N_DS_REG,SOF_N_DS_REG1         : std_logic;
signal   EOF_N_DS_REG,EOF_N_DS_REG1         : std_logic;
signal   SRC_RDY_N_DS_REG,SRC_RDY_N_DS_REG1 : std_logic;
signal   DST_RDY_N_US_REG,DST_RDY_N_US_REG1 : std_logic;
signal   CRC_PASS_FAIL_N_REG1,CRC_VALID_REG1  : std_logic;
signal   CRC_PASS_FAIL_N_REG,CRC_VALID_REG  : std_logic;

begin


  tx_crc_i : RX_CRC
  generic map
    (
      data_width       =>   data_width,
      crc_width        =>   crc_width,
      poly             =>   poly,
      alligned_data    =>   alligned_data,
      pipeline         =>   pipeline,
      back_to_back     =>   back_to_back,
      residue          =>   residue,
      stripcrc         =>   stripcrc,
      trandata         =>   trandata,
      trancrc          =>   trancrc,
      compcrc          =>   compcrc,
      crcinit          =>   crcinit,
      residue_value    =>   residue_value
    )
  port map
    (
      DATA_DS          => DATA_DS_REG,
      REM_DS           => REM_DS_REG,
      SOF_N_DS         => SOF_N_DS_REG,
      EOF_N_DS         => EOF_N_DS_REG,
      SRC_RDY_N_DS     => SRC_RDY_N_DS_REG,
      DST_RDY_N_US     => DST_RDY_N_US_REG,
      CRC_PASS_FAIL_N  => CRC_PASS_FAIL_N_REG,
      CRC_VALID        =>	CRC_VALID_REG,
      DATA_US          => DATA_US_REG,
      REM_US           => REM_US_REG,
      SOF_N_US         => SOF_N_US_REG,
      EOF_N_US         => EOF_N_US_REG,
      SRC_RDY_N_US     => SRC_RDY_N_US_REG,
      DST_RDY_N_DS     => DST_RDY_N_DS_REG,
      RESET            => RESET_TOP,
      CLK              => CLK_TOP
  );

  process (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT) then
      if (RESET_TOP = '1') then
        SOF_N_DS_REG1      <= '1';
      else
        SOF_N_DS_REG1      <=  SOF_N_DS_REG ;
      end if;
    end if;
   end process;

  process (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT) then
      if (RESET_TOP = '1') then
        SOF_N_DS_TOP      <= '1';
      else
        SOF_N_DS_TOP      <=  SOF_N_DS_REG1 ;
      end if;
    end if;
  end process;

  process  (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT ) then
      if (RESET_TOP = '1') then
        EOF_N_DS_REG1      <= '1';
      else
        EOF_N_DS_REG1      <=  EOF_N_DS_REG ;
      end if;
    end if;
  end process;

   process  (CLK_TOP)
   begin
     if (CLK_TOP = '1' and CLK_TOP 'EVENT ) then
      if (RESET_TOP = '1') then
        EOF_N_DS_TOP      <= '1';
      else
        EOF_N_DS_TOP      <=  EOF_N_DS_REG1 ;
      end if;
    end if;
  end process;

  process (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT) then
      if (RESET_TOP = '1') then
       DATA_DS_REG1      <= (others => '1');
      else
       DATA_DS_REG1      <=  DATA_DS_REG ;
      end if;
    end if;
  end process;

  process (CLK_TOP)
  begin
   if (CLK_TOP = '1' and CLK_TOP 'EVENT) then
     if (RESET_TOP = '1') then
       DATA_DS_TOP      <= (others => '1');
     else
       DATA_DS_TOP      <=  DATA_DS_REG1 ;
    end if;
  end if;
  end process;

  process (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT ) then
      if (RESET_TOP = '1') then
        SRC_RDY_N_DS_REG1      <= '1';
      else
        SRC_RDY_N_DS_REG1      <=  SRC_RDY_N_DS_REG ;
      end if;
  end if;
  end process;

  process (CLK_TOP)
    begin
      if (CLK_TOP = '1' and CLK_TOP 'EVENT ) then
        if (RESET_TOP = '1') then
          SRC_RDY_N_DS_TOP      <= '1';
        else
          SRC_RDY_N_DS_TOP      <=  SRC_RDY_N_DS_REG1 ;
        end if;
      end if;
  end process;

  process (CLK_TOP)
  begin
   if (CLK_TOP = '1' and CLK_TOP 'EVENT ) then
    if (RESET_TOP = '1') then
     DST_RDY_N_US_REG1      <= '1';
    else
     DST_RDY_N_US_REG1      <=  DST_RDY_N_US_REG ;
    end if;
  end if;
  end process;

  process (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT ) then
      if (RESET_TOP = '1') then
        DST_RDY_N_US_TOP      <= '1';
      else
        DST_RDY_N_US_TOP      <=  DST_RDY_N_US_REG1 ;
      end if;
    end if;
  end process;

  process  (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT ) then
      if (RESET_TOP = '1') then
        DATA_US_REG1      <= (others =>'1');
      else
        DATA_US_REG1      <=  DATA_US_TOP ;
      end if;
    end if;
  end process;

  process  (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT ) then
      if (RESET_TOP = '1') then
        DATA_US_REG      <= (others =>'1');
      else
        DATA_US_REG      <=  DATA_US_REG1 ;
      end if;
    end if;
  end process;


  process (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT ) then
     if (RESET_TOP = '1') then
       SOF_N_US_REG1      <= '1';
     else
       SOF_N_US_REG1      <=  SOF_N_US_TOP ;
     end if;
   end if;
  end process;

  process (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT ) then
     if (RESET_TOP = '1') then
       SOF_N_US_REG      <= '1';
     else
       SOF_N_US_REG      <=  SOF_N_US_REG1 ;
     end if;
    end if;
  end process;

  process (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT ) then
      if (RESET_TOP = '1') then
        EOF_N_US_REG1      <= '1';
      else
        EOF_N_US_REG1      <=  EOF_N_US_TOP ;
      end if;
    end if;
  end process;

  process (CLK_TOP)
    begin
      if (CLK_TOP = '1' and CLK_TOP 'EVENT ) then
       if (RESET_TOP = '1') then
         EOF_N_US_REG      <= '1';
       else
         EOF_N_US_REG      <=  EOF_N_US_REG1 ;
       end if;
     end if;
  end process;

  process (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT ) then
      if (RESET_TOP = '1') then
        SRC_RDY_N_US_REG1      <= '1';
      else
        SRC_RDY_N_US_REG1      <= SRC_RDY_N_US_TOP ;
      end if;
    end if;
  end process;

  process (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT ) then
     if (RESET_TOP = '1') then
       SRC_RDY_N_US_REG      <= '1';
     else
       SRC_RDY_N_US_REG      <= SRC_RDY_N_US_REG1 ;
     end if;
   end if;
  end process;

  process (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT) then
     if (RESET_TOP = '1') then
       DST_RDY_N_DS_REG1      <= '1';
     else
       DST_RDY_N_DS_REG1      <= DST_RDY_N_DS_TOP ;
     end if;
   end if;
  end process;

  process (CLK_TOP)
  begin
    if (CLK_TOP = '1' and CLK_TOP 'EVENT) then
     if (RESET_TOP = '1') then
       DST_RDY_N_DS_REG      <= '1';
     else
       DST_RDY_N_DS_REG      <= DST_RDY_N_DS_REG1 ;
     end if;
    end if;
  end process;

  process (CLK_TOP)
  begin
   if (CLK_TOP = '1' and CLK_TOP 'EVENT) then
    if (RESET_TOP = '1') then
      REM_US_REG1 <= (others => '1');
   else
     REM_US_REG1   <=  REM_US_TOP;
  end if;
  end if;
  end process;


  process (CLK_TOP)
  begin
   if (CLK_TOP = '1' and CLK_TOP 'EVENT) then
    if (RESET_TOP = '1') then
      REM_US_REG <= (others => '1');
    else
      REM_US_REG   <=  REM_US_REG1;
    end if;
  end if;
  end process;


  process (CLK_TOP)
  begin
   if (CLK_TOP = '1' and CLK_TOP 'EVENT) then
     if (RESET_TOP = '1') then
       REM_DS_REG1      <= (others => '1');
     else
       REM_DS_REG1      <=  REM_DS_REG ;
     end if;
   end if;
  end process;

  process (CLK_TOP)
  begin
   if (CLK_TOP = '1' and CLK_TOP 'EVENT) then
    if (RESET_TOP = '1') then
     REM_DS_TOP      <= (others => '1');
    else
      REM_DS_TOP      <=  REM_DS_REG1 ;
     end if;
   end if;
  end process;


  process (CLK_TOP)
  begin
   if (CLK_TOP = '1' and CLK_TOP 'EVENT) then
     if (RESET_TOP = '1') then
       CRC_PASS_FAIL_N_REG1    <=  '1';
     else
       CRC_PASS_FAIL_N_REG1      <=  CRC_PASS_FAIL_N_REG ;
     end if;
   end if;
  end process;

  process (CLK_TOP)
  begin
   if (CLK_TOP = '1' and CLK_TOP 'EVENT) then
    if (RESET_TOP = '1') then
     CRC_PASS_FAIL_N_TOP      <= '1';
    else
      CRC_PASS_FAIL_N_TOP      <=  CRC_PASS_FAIL_N_REG1 ;
     end if;
   end if;
  end process;

  process (CLK_TOP)
  begin
   if (CLK_TOP = '1' and CLK_TOP 'EVENT) then
     if (RESET_TOP = '1') then
       CRC_VALID_REG1    <=  '1';
     else
       CRC_VALID_REG1      <=  CRC_VALID_REG ;
     end if;
   end if;
  end process;

  process (CLK_TOP)
  begin
   if (CLK_TOP = '1' and CLK_TOP 'EVENT) then
    if (RESET_TOP = '1') then
     CRC_VALID_TOP      <= '1';
    else
      CRC_VALID_TOP      <=  CRC_VALID_REG1 ;
     end if;
   end if;
  end process;

end top_arch;
