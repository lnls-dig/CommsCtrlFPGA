-------------------------------------------------------------------------------
-- 
-- $Revision: 1.8 $
-- $Date: 2003/12/31 02:15:09 $
--
-------------------------------------------------------------------------------
-- Downstream Data Generation
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
-- File Name: data_ds.vhd
-- Author: Nanditha Jayarajan
-- Contributors: Chris Borrelli
--
-- Description:
-- This package contains all the components for driving DATA_DS
-- for various cases of parameters

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

ENTITY 	DATA_DS_DRIV_DST IS
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    alligned_data                  :  std_logic := '0';
    insertcrc                      :  std_logic := '1';
    pipeline                       :  std_logic := '1';
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
    DATA_DS                        :  OUT std_logic_vector(data_width-1 DOWNTO 0);
    DATA_US                        :  IN  std_logic_vector(data_width-1 DOWNTO 0);
    temp_data                      :  IN  std_logic_vector(data_width-1   DOWNTO 0);
    tem_data                       :  IN  std_logic_vector(crc_width-1   DOWNTO 0);
    current_state                  :  IN  t_state;
    REM_i                          :  IN  std_logic_vector(rem_width-1   DOWNTO 0);
    REM_ii                         :  IN  std_logic_vector(rem_width-1   DOWNTO 0);
    DST_RDY_N_DS                   :  IN  std_logic;
    final_crc                      :  IN  std_logic_vector(crc_width-1   DOWNTO 0);
    DST_RDY_N_i                    :  IN  std_logic;
    CLK                            :  IN  std_logic;
    RESET                          :  IN  std_logic
  );
end DATA_DS_DRIV_DST;


ARCHITECTURE DATA_DS_DRIV_DST_ARCH of DATA_DS_DRIV_DST is
signal DATA_DS_i   : std_logic_vector(data_width-1 DOWNTO 0);
signal DATA_DS_ii  : std_logic_vector(data_width-1 DOWNTO 0);
signal temp_data1  : std_logic_vector(data_width-1 DOWNTO 0);
signal tem_data1   : std_logic_vector(crc_width-1  DOWNTO 0);

begin
--------------------------------------------------------------------------
--Module for DST_RDY_N option with crc_width <= data_width for unaligned data
--------------------------------------------------------------------------
data_ds_driv_d_al : if (insertcrc = '0' AND (data_width = 8
                    OR pipeline = '0' OR alligned_data = '1') AND data_width >= crc_width)  generate

data_al : if (alligned_data = '1' OR data_width = 8) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      DATA_DS    <= (others => '0');
    elsif ((current_state = CRC) AND (DST_RDY_N_DS = '0')) then
      DATA_DS    <=  DATA_DS_i;
    elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
      DATA_DS    <=  temp_data1;
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS    <=  DATA_DS_i;
    end if;
  end if;
end PROCESS;
end generate data_al;

data_notal : if (alligned_data = '0' AND data_width /= 8) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      DATA_DS        <= (others => '0');
    elsif ((current_state = CRC) AND (DST_RDY_N_DS = '0')) then
      for i in (data_width-1) downto 0 loop
 	if((data_width -1 -i) < (conv_integer(REM_i)+1)*8) then
	  DATA_DS(i) <= DATA_DS_i(i);
	else
	  DATA_DS(i) <= temp_data(i);
	end if;
      end loop;
    elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
      DATA_DS        <=  temp_data1;
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS        <=  DATA_DS_i;
    end if;
  end if ;
end PROCESS;
end generate data_notal;


PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
       DATA_DS_i  <= (others => '0');
 --   elsif ((current_state = CRC) AND (DST_RDY_N_DS = '0')) then
 --     DATA_DS_i  <=  DATA_US;
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS_i <=  DATA_US;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if ((current_state = CRC) AND (DST_RDY_N_DS = '0')) then
      temp_data1 <=  temp_data;
    end if;
  end if;
end PROCESS;

end generate data_ds_driv_d_al;
--------------------------------------------------------------------------
--Module for DST_RDY_N option with crc_width > data_width for unaligned data
--------------------------------------------------------------------------
data_ds_driv_c_al : if (insertcrc = '0' AND (data_width = 8 OR pipeline = '0'
                    OR alligned_data = '1') AND data_width < crc_width ) generate

 PROCESS (CLK)
 begin
   if (CLK'EVENT AND CLK = '1') then
     if(RESET = '1') then
       DATA_DS_i <= (others => '0');
     elsif ((current_state = CRC) AND (DST_RDY_N_DS = '0')) then
       DATA_DS_i  <=  DATA_US;
     elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
       DATA_DS_i  <=  DATA_US;
     elsif (DST_RDY_N_DS = '0') then
       DATA_DS_i <=  DATA_US;
      end if;
    end if;
 end process;

data_ds_c_al: if (alligned_data = '1' OR data_width = 8) generate
PROCESS (CLK)
 begin
   if (CLK'EVENT AND CLK = '1') then
     if(RESET = '1') then
       DATA_DS   <= (others => '0');
     elsif ((current_state = CRC) AND (DST_RDY_N_DS = '0')) then
       DATA_DS   <=  DATA_DS_i;
     elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
       for p in data_width downto 1 loop
         DATA_DS(data_width-p)   <= tem_data1(crc_width-p);
       end loop;
     elsif (DST_RDY_N_DS = '0') then
       DATA_DS   <=  DATA_DS_i;
     end if;
   end if;
end PROCESS;
end generate data_ds_c_al;

data_ds_c_notal : if (alligned_data = '0' AND data_width /= 8) generate
PROCESS (CLK)
 begin
   if (CLK'EVENT AND CLK = '1') then
     if(RESET = '1') then
       DATA_DS   <= (others => '0');
     elsif ((current_state = CRC) AND (DST_RDY_N_DS = '0')) then
       for i in 0 to data_width-1 loop
         if(i < (conv_integer(REM_i)+1)*8) then
           DATA_DS(data_width-1-i) <= DATA_DS_i(data_width-1-i);
         else
           DATA_DS(data_width-1-i) <= tem_data(crc_width-1- i);
         end if;
       end loop;
     elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
       for p in data_width downto 1 loop
         DATA_DS(data_width-p)   <= tem_data1(crc_width-p);
       end loop;
     elsif (DST_RDY_N_DS = '0') then
       DATA_DS   <=  DATA_DS_i;
     end if;
   end if;
end PROCESS;
end generate data_ds_c_notal;

temp_data_notal : if (alligned_data = '0' AND data_width /= 8) generate
PROCESS (CLK)
variable no_of_data_bytes_less1 : std_logic_vector(4 DOWNTO 0);
begin
  if (CLK'EVENT AND CLK = '1') then
    if ((current_state = CRC) AND (DST_RDY_N_DS = '0')) then
      no_of_data_bytes_less1 := no_of_data_bytes-1;
      tem_data1  <=  bshifter_right(tem_data,no_of_data_bytes_less1);
    elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
      no_of_data_bytes_less1 := no_of_data_bytes-1;
      tem_data1  <= bshifter_right(tem_data1,no_of_data_bytes_less1);
    end if;
  end if;
end PROCESS;
end generate temp_data_notal;

temp_data_al : if (alligned_data = '1' AND data_width /= 8) generate
PROCESS (CLK)
variable no_of_data_bytes_less1 : std_logic_vector(4 DOWNTO 0);
begin
  if (CLK'EVENT AND CLK = '1') then
    if ((current_state = CRC) AND (DST_RDY_N_DS = '0')) then
      tem_data1  <=  tem_data;
    elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
      no_of_data_bytes_less1 := no_of_data_bytes-1;
      tem_data1  <= bshifter_left(tem_data1,no_of_data_bytes_less1);
    end if;
  end if;
end PROCESS;
end generate temp_data_al;

temp_data_8 : if (data_width = 8) generate
PROCESS (CLK)
variable no_of_data_bytes_less1 : std_logic_vector(4 DOWNTO 0);
begin
  if (CLK'EVENT AND CLK = '1') then
    if ((current_state = CRC) AND (DST_RDY_N_DS = '0')) then
      tem_data1  <=  tem_data;
    elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
      no_of_data_bytes_less1 := no_of_data_bytes-1;
      tem_data1  <= bshifter_right(tem_data1,no_of_data_bytes_less1);
    end if;
  end if;
end PROCESS;
end generate temp_data_8;

end generate data_ds_driv_c_al;
--------------------------------------------------------------------------
--Module for DST_RDY_N option with data_width >= crc_width for unalligned data
--------------------------------------------------------------------------
data_ds_driv_d_notal : if (insertcrc = '0' AND alligned_data = '0' AND
                        data_width >=  crc_width  AND data_width /= 8
                        AND pipeline = '1') generate

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      DATA_DS    <= (others => '0');
    elsif ((current_state = CRC) AND (DST_RDY_N_DS = '0')) then
      for i in (data_width-1) downto 0 loop
        if((data_width -1 -i) < (conv_integer(REM_ii)+1)*8) then
          DATA_DS(i) <= DATA_DS_ii(i);
        else
          DATA_DS(i) <= temp_data(i);
        end if;
      end loop;
    elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
      DATA_DS    <=  temp_data1;
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS    <=  DATA_DS_ii;
    end if;
  end if;
end process;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      DATA_DS_i  <= (others => '0');
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS_i  <=  DATA_US;
    end if;
  end if;
end PROCESS;


PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      DATA_DS_ii <= (others => '0');
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS_ii <= DATA_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
   if ((current_state = CRC) AND (DST_RDY_N_DS = '0')) then
     temp_data1 <=  temp_data;
   end if;
 end if;
end PROCESS;

end generate data_ds_driv_d_notal;

----------------------------------------------------------------------------
--Module for DST_RDY_N option with data_width >= crc_width for unalligned data
--------------------------------------------------------------------------
data_ds_driv_c_notal : if (insertcrc = '0' AND alligned_data = '0' AND
                        crc_width > data_width  AND data_width /= 8
                        AND pipeline = '1') generate

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      DATA_DS    <= (others => '0');
    elsif ((current_state = CRC) AND (DST_RDY_N_DS = '0')) then
      for i in 0 to data_width-1 loop
        if(i < (conv_integer(REM_ii)+1)*8) then
          DATA_DS(data_width-1-i) <= DATA_DS_ii(data_width-1-i);
        else
          DATA_DS(data_width-1-i) <= tem_data(crc_width-1- i);
        end if;
      end loop;
    elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
     for p in data_width downto 1 loop
       DATA_DS(data_width-p)   <= tem_data1(crc_width-p);
     end loop;
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS    <=  DATA_DS_ii;
    end if;
  end if;
end process;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      DATA_DS_i  <= (others => '0');
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS_i  <=  DATA_US;
    end if;
  end if;
end PROCESS;


PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      DATA_DS_ii <= (others => '0');
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS_ii <= DATA_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
   if ((current_state = CRC) AND (DST_RDY_N_DS = '0')) then
    tem_data1 <=  bshifter_right(tem_data,(no_of_data_bytes-1));
   elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
    tem_data1 <= bshifter_right(tem_data1,(no_of_data_bytes-1));
   end if;
 end if;
end PROCESS;
end generate data_ds_driv_c_notal;
----------------------------------------------------------------------------
--End of File
--------------------------------------------------------------------------
end DATA_DS_DRIV_DST_ARCH;