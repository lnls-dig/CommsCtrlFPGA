-------------------------------------------------------------------------------
-- 
-- $Revision: 1.6 $
-- $Date: 2003/12/31 02:15:09 $
--
-------------------------------------------------------------------------------
-- Receive State Machine
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
-- File Name: state_machine_rx.vhd
-- Author: Nanditha Jayarajan
-- Contributors: Chris Borrelli
--
-- Description:
-- This File contains the State Machine Modules
-- for the RX CRC Module for various cases

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

ENTITY 	STATE_MACHINE_RX IS
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    residue                        :  std_logic := '1';
    stripcrc                       :  std_logic := '1';
    pipeline                       :  std_logic := '1';
    trandata                       :  std_logic := '1';
    trancrc                        :  std_logic := '1';
    compcrc                        :  std_logic := '1';
    crcinit                        :  std_logic_vector
                                   := "11111111111111111111111111111111";

    rem_width                      :  integer := 3;
    alligned_data                  :  std_logic := '0';
    residue_value                  :  std_logic_vector
                                   := "11000111000001001101110101111011";

    no_of_data_bytes               :  std_logic_vector(4 DOWNTO 0) := "00100";
    no_of_crc_bytes                :  std_logic_vector(4 DOWNTO 0) := "00100"
  );
PORT
  (
    next_state                     :  OUT t_state;
    current_state                  :  IN  t_state;
    SOF_N_US                       :  IN  std_logic;
    EOF_N_US                       :  IN  std_logic;
    EOF_N_US_i                     :  IN  std_logic;
    SRC_RDY_N_US                   :  IN  std_logic;
    SRC_RDY_N_DS_i                 :  IN  std_logic;
    DST_RDY_N_DS                   :  IN  std_logic
  );
end STATE_MACHINE_RX;

ARCHITECTURE STATE_MACHINE_RX_ARCH OF STATE_MACHINE_RX IS
begin

state_machine_al:if (residue = '1' AND (alligned_data = '1'
                  OR data_width =8 OR pipeline = '0')) generate
PROCESS (current_state, SOF_N_US, EOF_N_US, SRC_RDY_N_US, DST_RDY_N_DS)
begin
  case current_state is
    when IDLE =>
         if ((sof_n_us = '0') and (src_rdy_n_us = '0') and
            (eof_n_us = '0')) then
           next_state <= IDLE;
         elsif ((sof_n_us = '0') and (src_rdy_n_us = '0')) then
           next_state <= CALC;
         else
           next_state <= IDLE;
         end if;

    when CALC =>
         if ((eof_n_us = '0') and (src_rdy_n_us = '0') and
            (dst_rdy_n_ds = '0')) then
            next_state <= IDLE;
         else
            next_state <= CALC;
         end if;

    when others  =>
         next_state <= IDLE;

  end case;
end PROCESS;
end generate state_machine_al;

state_machine_notal : if (residue = '1' AND alligned_data = '0'
                      AND data_width /=8 AND pipeline = '1') generate
PROCESS (current_state, SOF_N_US, EOF_N_US_i, SRC_RDY_N_US,
         SRC_RDY_N_DS_i, DST_RDY_N_DS)
begin
  case current_state is
    when IDLE =>
         if ((sof_n_us = '0') and (src_rdy_n_us = '0')) then
           next_state <= CALC;
         else
           next_state <= IDLE;
         end if;

    when CALC =>
         if ((eof_n_us_i = '0') and (src_rdy_n_ds_i = '0') and
            (dst_rdy_n_ds = '0')) then
            next_state <= IDLE;
         else
            next_state <= CALC;
         end if;

    when others  =>
         next_state <= IDLE;

  end case;
end PROCESS;
end generate state_machine_notal;

end STATE_MACHINE_RX_ARCH;
---------------------------------------------------------------------
-- End of File
---------------------------------------------------------------------