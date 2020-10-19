-------------------------------------------------------------------------------
-- 
-- $Revision: 1.3 $
-- $Date: 2003/12/31 02:15:09 $
--
-------------------------------------------------------------------------------
-- CRC Generation
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
-- File Name: crc_gen.vhd
-- Author: Nanditha Jayarajan
-- Contributors: Chris Borrelli
--
-- Description:
-- This package contains all the functions that are used in
-- the CRC Modules

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
use work.crc_functions.all;

--------------------------------------------------------------------------
-- Entity and Architecture Declarations
-------------------------------------------------------------------------
ENTITY  CRC_GEN IS
GENERIC
  (
    data_width                      :  integer := 64;
    crc_width                       :  integer := 32;
    poly                            :  std_logic_vector
                                    := "00000100110000010001110110110111";

    insertcrc                       :  std_logic := '0';
    alligned_data                   :  std_logic := '1';
    pipeline                        :  std_logic := '1';
    trandata                        :  std_logic := '1';
    trancrc                         :  std_logic := '1';
    compcrc                         :  std_logic := '1';
    crcinit                         :  std_logic_vector
                                    := "11111111111111111111111111111111";

    rem_width                       :  integer := 3;
    residue                         :  std_logic := '1';
    stripcrc                        :  std_logic := '0';
    residue_value                   :  std_logic_vector
                                    := "11000111000001001101110101111011";

    no_of_data_bytes                :  std_logic_vector(4 DOWNTO 0)
                                    := "01000";

    no_of_crc_bytes                 :  std_logic_vector(4 DOWNTO 0)
                                    := "00100"
  );
PORT
  (
    next_crc_o                      :  OUT std_logic_vector((crc_width*(2**rem_width))-1 downto 0);
    next_CRC_i                      :  OUT std_logic_vector(crc_width-1  DOWNTO 0);
    current_state                   :  IN t_state;
    SOF_N_US                        :  IN std_logic;
    EOF_N_US                        :  IN std_logic;
    SRC_RDY_N_US                    :  IN std_logic;
    DST_RDY_N_DS                    :  IN std_logic;
    REM_US                          :  IN std_logic_vector(rem_width-1   DOWNTO 0);
    DATA                            :  IN std_logic_vector(data_width-1  DOWNTO 0);
    C                               :  IN std_logic_vector(crc_width-1   DOWNTO 0);
    CLK                             :  IN std_logic;
    RESET                           :  IN std_logic;
    current_state_delayed           :  IN std_logic
  );
end CRC_GEN;

-----------------------------------------------------------------------------
-- Combinational CRC Computation
-----------------------------------------------------------------------------
ARCHITECTURE CRC_GEN_ARCH of CRC_GEN is

signal next_crc_o_i   : std_logic_vector((crc_width*(2**rem_width))-1 downto 0);
signal next_crc_o_reg : std_logic_vector((crc_width*(2**rem_width))-1 downto 0);
begin

port_assignment_notal: if ((insertcrc = '0' OR residue = '1')  AND alligned_data = '0'
                           AND data_width /= 8 AND pipeline = '1') generate
  next_crc_o <= next_crc_o_reg;
end generate port_assignment_notal;

port_assignment_nopipeline : if ((insertcrc = '0' OR residue = '1')  AND alligned_data = '0'
                           AND data_width /= 8 AND pipeline = '0') generate
  next_crc_o <= next_crc_o_i;
end generate port_assignment_nopipeline;


port_assignment_al : if ((insertcrc = '0' OR residue = '1') AND (alligned_data = '1'
                         OR data_width = 8) ) generate
  next_CRC_i <= next_crc_data(C,DATA,poly);
end generate port_assignment_al;

next_crc_gen : if ((insertcrc = '0' OR residue = '1') AND alligned_data = '0'
                   AND data_width /= 8 AND pipeline = '1') generate
  PROCESS (DATA,next_crc_o_reg,next_crc_o_i)
  begin
    next_crc_o_i(crc_width*data_width/8-1 downto 0) <=
         next_crc_data_be(next_crc_o_reg(crc_width*data_width/8-1 downto
                                         crc_width*data_width/8-crc_width),DATA,poly);
  end PROCESS;

  PROCESS(CLK)
  begin
    if (CLK'EVENT AND CLK = '1') then
      if ((RESET = '1') OR (current_state = CRC) OR (current_state_delayed = '1')) then
        next_crc_o_reg <= (others => '1');
      elsif(((current_state = CALC) AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')
      AND (EOF_N_US = '1')) OR (current_state = IDLE AND (SOF_N_US = '0') AND
      (DST_RDY_N_DS = '0') AND (SRC_RDY_N_US = '0')) OR ((EOF_N_US = '0') AND
      (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0'))) then
        next_crc_o_reg <= next_crc_o_i;
      end if;
    end if;
  end PROCESS;
end generate next_crc_gen;

next_crc_gen_notpipelined : if ((insertcrc = '0' OR residue = '1') AND alligned_data = '0'
                            AND data_width /= 8 AND pipeline = '0') generate
PROCESS(C,DATA)
begin
next_crc_o_i(crc_width*data_width/8-1 downto 0) <=
         next_crc_data_be(C,DATA,poly);
end PROCESS;
end generate next_crc_gen_notpipelined;

--------------------------------------------------------------------------
--End of File
--------------------------------------------------------------------------

end CRC_GEN_ARCH;
