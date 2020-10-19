-------------------------------------------------------------------------------
-- 
-- $Revision: 1.5 $
-- $Date: 2003/12/31 02:15:09 $
--
-------------------------------------------------------------------------------
-- Transmit State Machine
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
-- File Name: state_machine_tx.vhd
-- Author: Nanditha Jayarajan
-- Contributors: Chris Borrelli
--
-- Description:
-- This File contains the State Machine Modules
-- for the TX CRC Module for various cases

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
-- Entity and Architecture
---------------------------------------------------------------------
ENTITY 	STATE_MACHINE_DST IS
GENERIC
  (
    data_width                     :  integer := 64;
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

    rem_width                      :  integer := 3;
    alligned_data                  :  std_logic := '0';
    residue_value                  :  std_logic_vector
                                   := "11000111000001001101110101111011";

    no_of_data_bytes               :  std_logic_vector(4 DOWNTO 0)
                                   := "00100";

    no_of_crc_bytes                :  std_logic_vector(4 DOWNTO 0)
                                   := "00100"
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
    DST_RDY_N_DS                   :  IN  std_logic;
    REM_i                          :  IN  std_logic_vector(rem_width-1   DOWNTO 0);
    enable                         :  IN  std_logic
  );
end STATE_MACHINE_DST;

ARCHITECTURE STATE_MACHINE_DST_ARCH OF STATE_MACHINE_DST IS
begin
---------------------------------------------------------------------
-- Module for DST_RDY_N option and data_width < crc_width
-- alligned_data = '0' and data_width /= 8
---------------------------------------------------------------------
state_machine_c_notal : if (insertcrc = '0' AND alligned_data = '0'
                        AND data_width /= 8 AND crc_width > data_width AND
                        pipeline = '1') generate
PROCESS (current_state, SOF_N_US, EOF_N_US_i, SRC_RDY_N_US,SRC_RDY_N_DS_i,
        DST_RDY_N_DS, enable)
  begin
    case current_state is
       when IDLE =>
                if ((sof_n_us = '0')  and (src_rdy_n_us = '0')
                and (dst_rdy_n_ds = '0') and (EOF_N_US_i = '0')) then
                  next_state <= CRC;

                elsif (sof_n_us = '0' and (src_rdy_n_us = '0')
                and (dst_rdy_n_ds = '0') ) then
                   next_state <= CALC;

                else
                   next_state <= IDLE;
                end if;

       when CALC =>
              if ((eof_n_us_i = '0') and (src_rdy_n_ds_i = '0')
              and (dst_rdy_n_ds = '0')) then
                 next_state <= CRC;

              else
                 next_state <= CALC;
              end if;

       when CRC =>
              if (dst_rdy_n_ds = '0') then
                 next_state <= CRC1;
              end if;

       when CRC1 =>
              if (enable = '1' and dst_rdy_n_ds = '0') then
                next_state <= IDLE;
              else
                next_state <= CRC1;
              end if;

       when others  =>
              next_state <= IDLE;

  end case;
end PROCESS;
end generate state_machine_c_notal;

---------------------------------------------------------------------
-- Module for DST_RDY_N option and crc_width <= data_width
-- alligned_data = '0' and data_width /= 8
---------------------------------------------------------------------
state_machine_d_notal : if (insertcrc = '0' AND alligned_data = '0'
                        AND data_width /= 8 AND crc_width <= data_width AND
                        pipeline = '1') generate
PROCESS (current_state, SOF_N_US, EOF_N_US_i, SRC_RDY_N_US,SRC_RDY_N_DS_i,
         DST_RDY_N_DS, enable)
begin
  case current_state is
     when IDLE =>
              if ((sof_n_us = '0')  and (src_rdy_n_us = '0')
              and (dst_rdy_n_ds = '0') and (EOF_N_US_i = '0')) then
                next_state <= CRC;

              elsif (sof_n_us = '0' and (src_rdy_n_us = '0')
              and (dst_rdy_n_ds = '0')) then
                 next_state <= CALC;

              else
                 next_state <= IDLE;
              end if;

     when CALC =>
            if ((eof_n_us_i = '0') and (src_rdy_n_ds_i = '0')
            and (dst_rdy_n_ds = '0')) then
               next_state <= CRC;

            else
               next_state <= CALC;
            end if;

     when CRC =>
            if (enable = '1' and (DST_RDY_N_DS = '0')) then
               next_state <= IDLE;
            elsif (enable = '0' and DST_RDY_N_DS = '0') then
               next_state <= CRC1;
            else
               next_state <= CRC;
            end if;

     when CRC1 =>
            next_state <= IDLE;

     when others  =>
            next_state <= IDLE;

   end case;
end PROCESS;
end generate state_machine_d_notal;

---------------------------------------------------------------------
-- Module for DST_RDY_N option and data_width < crc_width and
-- alligned_data = '1' or data_width = 8
---------------------------------------------------------------------
state_machine_c_al : if (insertcrc = '0' AND (alligned_data = '1' OR data_width = 8
                     OR pipeline = '0') AND data_width < crc_width) generate
PROCESS (current_state, SOF_N_US, EOF_N_US, SRC_RDY_N_US, DST_RDY_N_DS, enable)
  begin
    case current_state is
       when IDLE =>
                if ((sof_n_us = '0')  and (src_rdy_n_us = '0')
                and (dst_rdy_n_ds = '0') and (eof_n_us = '0')) then
                  next_state <= CRC;

                elsif (sof_n_us = '0' and (src_rdy_n_us = '0')
                and (dst_rdy_n_ds = '0') ) then
                   next_state <= CALC;

                else
                   next_state <= IDLE;
                end if;

       when CALC =>
              if ((eof_n_us = '0') and (src_rdy_n_us = '0')
              and (dst_rdy_n_ds = '0')) then
                 next_state <= CRC;

              else
                 next_state <= CALC;
              end if;

       when CRC =>
              if (DST_RDY_N_DS = '0') then
                 next_state <= CRC1;
              end if;

       when CRC1 =>
              if (enable = '1' and DST_RDY_N_DS = '0') then
                next_state <= IDLE;
              else
                next_state <= CRC1;
              end if;

       when others  =>
              next_state <= IDLE;

  end case;
end PROCESS;
end generate state_machine_c_al;

---------------------------------------------------------------------
-- Module for DST_RDY_N option and crc_width <= data_width and
-- alligned_data = '1' or data_width = 8
---------------------------------------------------------------------
state_machine_d_al : if (insertcrc = '0' AND (alligned_data = '1' OR data_width = 8
                     OR pipeline = '0') AND data_width >= crc_width) generate

PROCESS (current_state, SOF_N_US, EOF_N_US, SRC_RDY_N_US, DST_RDY_N_DS, enable)
begin
  case current_state is
     when IDLE =>
              if ((sof_n_us = '0')  and (src_rdy_n_us = '0')
              and (dst_rdy_n_ds = '0') and (eof_n_us = '0')) then
                next_state <= CRC;

              elsif (sof_n_us = '0' and (src_rdy_n_us = '0')
              and (dst_rdy_n_ds = '0')) then
                 next_state <= CALC;

              else
                 next_state <= IDLE;
              end if;

     when CALC =>
            if ((eof_n_us = '0') and (src_rdy_n_us = '0')
            and (dst_rdy_n_ds = '0')) then
               next_state <= CRC;

            else
               next_state <= CALC;
            end if;

     when CRC =>
            if (enable = '1' and (DST_RDY_N_DS = '0')) then
               next_state <= IDLE;
            elsif (enable = '0' and DST_RDY_N_DS = '0') then
               next_state <= CRC1;
            else
               next_state <= CRC;
            end if;

     when CRC1 =>
            next_state <= IDLE;

     when others  =>
            next_state <= IDLE;

   end case;
end PROCESS;
end generate state_machine_d_al;

end STATE_MACHINE_DST_ARCH;

--------------------------------------------------------------------------
--  End of File
--------------------------------------------------------------------------
