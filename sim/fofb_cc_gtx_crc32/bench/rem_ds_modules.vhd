-------------------------------------------------------------------------------
-- 
-- $Revision: 1.6 $
-- $Date: 2003/12/31 02:15:09 $
--
-------------------------------------------------------------------------------
-- Downstream REM Generation
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
-- File Name: rem_ds_modules.vhd
-- Author: Nanditha Jayarajan
-- Contributors: Chris Borrelli
--
-- Description:
-- This package contains all the component declarations
-- for driving REM_DS for all cases

---------------------------------------------------------------------
-- Library Declarations
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.numeric_bit.all;

library work;
use work.crc_components.all;

---------------------------------------------------------------------
-- Library Declarations
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.crc_components.all;

ENTITY 	REM_DS_DRIV_DST IS
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    insertcrc                      :  std_logic := '1';
    pipeline                       :  std_logic := '1';
    alligned_data                  :  std_logic := '0';
    trandata                       :  std_logic := '1';
    trancrc                        :  std_logic := '1';
    compcrc                        :  std_logic := '1';
    crcinit                        :  std_logic_vector
                                   := "11111111111111111111111111111111";

    rem_width                      :  integer := 3;
    residue_value                  :  std_logic_vector
                                   := "11000111000001001101110101111011";

    no_of_data_bytes               :  std_logic_vector(4 DOWNTO 0)
                                   := "00100";

    no_of_crc_bytes                :  std_logic_vector(4 DOWNTO 0)
                                   := "00100"
  );
PORT
  (
    REM_DS                         :  OUT std_logic_vector(rem_width-1   DOWNTO 0);
    REM_i                          :  OUT std_logic_vector(rem_width-1   DOWNTO 0);
    REM_ii                         :  OUT std_logic_vector(rem_width-1   DOWNTO 0);
    REM_US                         :  IN std_logic_vector(rem_width-1   DOWNTO 0);
    current_state                  :  IN t_state;
    EOF_N_US                       :  IN std_logic;
    DST_RDY_N_DS                   :  IN std_logic;
    DST_RDY_N_i                    :  IN std_logic;
    SRC_RDY_N_US                   :  IN std_logic;
    enable                         :  IN std_logic;
    count                          :  IN std_logic_vector(4 DOWNTO 0);
    CLK                            :  IN std_logic;
    RESET                          :  IN std_logic
  );
end REM_DS_DRIV_DST;



ARCHITECTURE REM_DS_DRIV_DST_ARCH of REM_DS_DRIV_DST is
signal REM_iii : std_logic_vector(rem_width-1 DOWNTO 0);
begin
--------------------------------------------------------------------------
--Module declarations for DST_RDY_N option with data_width >= crc_width
--------------------------------------------------------------------------
rem_ds_gen_d : if (insertcrc = '0' and crc_width <= data_width
               AND alligned_data = '0') generate
PROCESS ( CLK)
variable REM_int : std_logic_vector(rem_width-1 DOWNTO 0);
variable REM_size : std_logic_vector(4 DOWNTO 0);
begin
  if (CLK = '1' and CLK'EVENT) then
    if (RESET = '1') then
      REM_DS   <= (others => '1');
      REM_ii   <= (others => '1');
    elsif ((EOF_N_US = '0') AND (SRC_RDY_N_US = '0')
           AND (DST_RDY_N_DS = '0')) then
      REM_ii   <= REM_iii;
      REM_int  := REM_US;
      REM_DS   <= (others => '1');
    elsif ((current_state = CRC) AND (enable = '1')
           AND (DST_RDY_N_DS = '0')) then
      REM_size := REM_int + no_of_crc_bytes;
      REM_DS   <= REM_size(rem_width-1 DOWNTO 0);
    elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
      REM_size := no_of_crc_bytes - no_of_data_bytes + REM_int;
      REM_DS   <= REM_size(rem_width-1 DOWNTO 0);
    elsif (DST_RDY_N_DS = '0') then
      REM_DS   <= (others => '1');
      REM_ii   <= REM_iii;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      REM_i    <= (others => '1');
      REM_iii   <= (others => '1');
    elsif (DST_RDY_N_DS = '0') then
      REM_i    <= REM_US;
      REM_iii  <= REM_US;
    end if;
  end if;
end PROCESS;
end generate rem_ds_gen_d;

rem_ds_al : if (insertcrc = '0' and crc_width <= data_width
               AND alligned_data = '1') generate
PROCESS ( CLK)
variable REM_size : std_logic_vector(4 DOWNTO 0);
begin
  if (CLK = '1' and CLK'EVENT) then
    if (RESET = '1') then
      REM_DS   <= (others => '1');
      REM_i    <= (others => '1');
      REM_ii   <= (others => '1');
    elsif ((EOF_N_US = '0') AND (SRC_RDY_N_US = '0')
           AND (DST_RDY_N_DS = '0')) then
      REM_i    <= REM_US;
      REM_DS   <= (others => '1');
    elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
      REM_size := no_of_crc_bytes-1;
      REM_DS   <= REM_size(rem_width-1 DOWNTO 0);
    elsif (DST_RDY_N_DS = '0') then
      REM_DS   <= (others => '1');
      REM_i    <= REM_US;
    end if;
  end if;
end PROCESS;
end generate rem_ds_al;
--------------------------------------------------------------------------
--Module declarations for DST_RDY_N option with data_width < crc_width
--------------------------------------------------------------------------
rem_ds_gen_c : if (insertcrc = '0' and crc_width > data_width) generate
PROCESS ( CLK)
variable REM_int  : std_logic_vector(rem_width-1 DOWNTO 0);
variable REM_temp : std_logic_vector(4 DOWNTO 0);
begin
  if (CLK = '1' and CLK'EVENT) then
    if (RESET = '1') then
      REM_DS   <= (others => '0');
      REM_ii   <= (others => '0');
    elsif ((EOF_N_US = '0') AND (SRC_RDY_N_US = '0')
          AND (DST_RDY_N_DS = '0')) then
      REM_ii   <= REM_iii;
      REM_int  := REM_US;
      REM_DS   <= (others => '1');
    elsif ((current_state = CRC) AND (enable = '1')
          AND (DST_RDY_N_DS = '0')) then
      REM_temp := REM_int + no_of_crc_bytes;
      REM_DS   <= REM_temp(rem_width-1 DOWNTO 0);
    elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
      REM_temp := no_of_crc_bytes - count -1;
      REM_DS   <= REM_temp(rem_width-1 DOWNTO 0);
    elsif (DST_RDY_N_DS = '0') then
      REM_DS   <= (others => '1');
      REM_ii   <= REM_iii;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      REM_i    <= (others => '1');
      REM_iii   <= (others => '1');
    elsif (DST_RDY_N_DS = '0') then
      REM_i    <= REM_US;
      REM_iii  <= REM_US;
    end if;
  end if;
end PROCESS;
end generate rem_ds_gen_c;
--------------------------------------------------------------------------
--End of File
--------------------------------------------------------------------------
end REM_DS_DRIV_DST_ARCH;

