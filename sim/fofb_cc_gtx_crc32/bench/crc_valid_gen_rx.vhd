-------------------------------------------------------------------------------
-- 
-- $Revision: 1.6 $
-- $Date: 2003/12/31 02:15:09 $
--
-------------------------------------------------------------------------------
-- CRC Valid and Pass/Fail Generation
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
-- File Name: crc_valid_gen_rx.vhd
-- Author: Nanditha Jayarajan
-- Contributors: Chris Borrelli
--
-- Description:
-- This file contains the Modules for driving CRC_VALID
-- and CRC_PASS_FAIL_N for all the cases

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

--------------------------------------------------------------------------
-- module declarations for Residue option with crc not stripped
-- as well as crc stripped for all cases
-------------------------------------------------------------------------
ENTITY 	CRC_VALID_GEN_RES_NSANDS_CD IS
GENERIC
  (
data_width                     :  integer := 32;
crc_width                      :  integer := 32;
poly                           :  std_logic_vector
                               := "00000100110000010001110110110111";

insertcrc                      :  std_logic := '1';
pipeline                       :  std_logic := '1';
trandata                       :  std_logic := '1';
trancrc                        :  std_logic := '1';
compcrc                        :  std_logic := '1';
crcinit                        :  std_logic_vector
                               := "11111111111111111111111111111111";

rem_width                      :  integer := 2;
residue_value                  :  std_logic_vector
                               := "11000111000001001101110101111011";

no_of_data_bytes               :  std_logic_vector(4 DOWNTO 0) := "00100";
no_of_crc_bytes                :  std_logic_vector(4 DOWNTO 0) := "00100"
  );
PORT
  (
CRC_PASS_FAIL_N    : OUT std_logic;
CRC_VALID          : OUT std_logic;
current_state      : IN  t_state;
current_st_delayed : IN  std_logic;
C                  : IN  std_logic_vector(crc_width-1 downto 0);
CLK                : IN  std_logic;
RESET              : IN  std_logic
  );
END CRC_VALID_GEN_RES_NSANDS_CD;

Architecture CRC_VALID_GEN_RES_NSANDS_CD_ARCH of CRC_VALID_GEN_RES_NSANDS_CD is
begin
  PROCESS (CLK)
    begin
      if (CLK'EVENT AND CLK = '1') then
        if (RESET = '1') then
          CRC_PASS_FAIL_N <= '0';
          CRC_VALID       <= '0';
        elsif (current_st_delayed = '1') then
          if (C = residue_value) then
            CRC_PASS_FAIL_N <= '1';
            CRC_VALID       <= '1';
          else
            CRC_PASS_FAIL_N <= '0';
            CRC_VALID       <= '1';
          end if;
        elsif((current_state = IDLE) OR (current_st_delayed = '0')) then
          CRC_PASS_FAIL_N <= '0';
          CRC_VALID       <= '0';
        end if;
      end if;
    end PROCESS;
end CRC_VALID_GEN_RES_NSANDS_CD_ARCH;
--------------------------------------------------------------------------
--------------------------------------------------------------------------
--END OF FILE
--------------------------------------------------------------------------
--------------------------------------------------------------------------
