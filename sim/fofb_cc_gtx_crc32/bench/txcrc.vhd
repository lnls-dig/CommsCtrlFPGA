-------------------------------------------------------------------------------
-- 
-- $Revision: 1.10 $
-- $Date: 2003/12/31 02:15:09 $
--
-------------------------------------------------------------------------------
-- Transmit CRC Top Level
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
--     (c) Copyright 2002 Xilinx, Inc.
--     All rights reserved.
--
---------------------------------------------------------------------
-- File Name: txcrc.vhd
-- Author: Nanditha Jayarajan
-- Contributors: Chris Borrelli
--
-- Description:
-- This file is the top level entity and architecture
-- for the TX CRC Module

---------------------------------------------------------------------
-- Library Declarations
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- synthesis translate_off
library unisim;
use unisim.all;
-- synthesis translate_on

library work;
use work.crc_functions.all;
use work.crc_components.all;

 ---------------------------------------------------------------------
----port declarations
---------------------------------------------------------------------
ENTITY TX_CRC IS
GENERIC
  (
 -- Data Width  : Legal Values :  8,16,32,64
    data_width                     :  integer := 16;

 -- CRC Width   : Legal Values :  8,16.32,64
    crc_width                      :  integer := 32;

 -- CRC Polynomial : Accepted as a string
--  Please ensure that the width of the string is correct
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

-- Indicates whether the Data is always alligned
-- i.e. REM = all 1's always
-- This results in a smaller sizes for the Design
    alligned_data                  :  std_logic := '0';

-- 0 - DST_RDY_N option 1 - pad bytes option
    insertcrc                      :  std_logic := '0';

-- Option to pipeline
-- 0 - not pipelined 1 - pipeline
   pipeline                        : std_logic := '1';

-- Option to transpose Input Data
-- 0 - not transposed 1 - transposed
    trandata                       :  std_logic := '1';

-- Option to transpose final CRC before output
-- 0 - not transposed 1 - transposed
    trancrc                        :  std_logic := '1';

-- Option to complement final CRC before output
-- 0 - not complemented 1 - complemented
    compcrc                        :  std_logic := '1';

-- Initial value of CRC Register
-- Accepted as a string
    crcinit                        :  std_logic_vector
                                   := "11111111111111111111111111111111";

-- Residue Value for RX CRC comparison
-- Accepted as a string
    residue_value                  :  std_logic_vector
                                   := "11000111000001001101110101111011";
                                   
-- Compare with residue or the CRC in frame
-- 1 - Residue 0 - Incoming CRC
    residue                        :  std_logic := '1';

-- Option to strip CRC
-- 1 - Strip 0 - not stripped
    stripcrc                       :  std_logic := '0'

  );
PORT
  (
    DATA_DS                        : OUT std_logic_vector(data_width - 1 DOWNTO 0);
    REM_DS                         : OUT std_logic_vector;
    SOF_N_DS                       : OUT std_logic;
    EOF_N_DS                       : OUT std_logic;
    SRC_RDY_N_DS                   : OUT std_logic;
    DST_RDY_N_US                   : OUT std_logic;
    DATA_US                        : IN std_logic_vector(data_width - 1 DOWNTO 0);
    REM_US                         : IN std_logic_vector;
    SOF_N_US                       : IN std_logic;
    EOF_N_US                       : IN std_logic;
    SRC_RDY_N_US                   : IN std_logic;
    DST_RDY_N_DS                   : IN std_logic;
    RESET                          : IN std_logic;
    CLK                            : IN std_logic
  );
END TX_CRC;

ARCHITECTURE TX_CRC_ARCH of TX_CRC is
constant rem_width          :  integer := rem_width_calc(data_width);
constant no_of_data_bytes   :  std_logic_vector(4  DOWNTO 0)
                            := no_of_bytes_calc(data_width);
constant no_of_crc_bytes    :  std_logic_vector(4  DOWNTO 0)
                            := no_of_bytes_calc(crc_width);

constant  GLOBALDLY            : integer := 1;
-- changes for synthesis
constant  crc_bytes            : integer := conv_integer(no_of_crc_bytes);
constant  data_bytes           : integer := conv_integer(no_of_data_bytes);
--------------------------------------------------------------------------

signal    DATA                 : std_logic_vector(data_width-1 DOWNTO 0);
signal    final_crc            : std_logic_vector(crc_width-1  DOWNTO 0);
signal    next_crc             : std_logic_vector(crc_width-1  DOWNTO 0);
signal    C                    : std_logic_vector(crc_width-1  DOWNTO 0);

signal    temp_data            : std_logic_vector(data_width-1 DOWNTO 0);
signal    tem_data             : std_logic_vector(crc_width-1  DOWNTO 0);

signal    temp_data1           : std_logic_vector(data_width-1 DOWNTO 0);
signal    temp_data2           : std_logic_vector(crc_width-1  DOWNTO 0);

signal    enable               : std_logic;
signal    enable1              : std_logic;
signal    enable_state         : std_logic;
signal    enable_state_delayed : std_logic;
signal    count                : std_logic_vector(4 DOWNTO 0);
signal 	  DST_RDY_N_i          : std_logic;
signal    SOF_N_DS_i           : std_logic;
signal    SOF_N_DS_ii          : std_logic;
signal    SRC_RDY_N_DS_i       : std_logic;
signal    SRC_RDY_N_DS_ii      : std_logic;
signal    EOF_N_US_i           : std_logic;
signal    EOF_N_DS_ii          : std_logic;
signal    DATA_DS_i            : std_logic_vector(data_width-1 DOWNTO 0);
signal    DATA_DS_ii           : std_logic_vector(data_width-1 DOWNTO 0);
signal    REM_i                : std_logic_vector(rem_width-1  DOWNTO 0);
signal    REM_ii               : std_logic_vector(rem_width-1  DOWNTO 0);
signal    shift_rem            : std_logic_vector(rem_width-1  DOWNTO 0);
signal    REM_count            : std_logic_vector(rem_width-1  DOWNTO 0);
signal    REM_DS_i             : std_logic_vector(rem_width-1  DOWNTO 0);
signal    SRL_SOF_N_DS_i       : std_logic;
signal    SRL_SOF_N_DS         : std_logic;
signal    SRC_RDY_N_DS_SRL     : std_logic;
signal    SRL_EOF_N_DS_i       : std_logic;
signal    SRL_EOF_N_DS         : std_logic;
signal    SRL16_REM_OUT        : std_logic_vector(rem_width-1  DOWNTO 0);
signal    SRL16_REM_DATA       : std_logic_vector(rem_width-1  DOWNTO 0);
--signal    DATA_DS_SRL          : std_logic_vector(data_width-1 DOWNTO 0);
signal    SRL16_DATA           : std_logic_vector(data_width-1 DOWNTO 0);
signal    SRL16_OUT            : std_logic_vector(data_width-1 DOWNTO 0);
signal    GND_BUS              : std_logic_vector(data_width-1 DOWNTO 0) := (others => '0');
signal    CLOCK_EN             : std_logic;
--constant  TO_WIDTH           : integer
 --                            := conv_integer(no_of_crc_bytes)/conv_integer(no_of_data_bytes) -1;

constant  TO_WIDTH             : integer
                               := crc_bytes/data_bytes -1;

signal    WIDTH                : std_logic_vector(3 DOWNTO 0)
                               := conv_std_logic_vector(TO_WIDTH,4);

signal    WIDTH1               : std_logic_vector(3 DOWNTO 0)
                               := conv_std_logic_vector(TO_WIDTH + 1,4);

signal    WIDTH3               : std_logic_vector(3 DOWNTO 0)       := "0001";
signal    next_CRC_i           : std_logic_vector(crc_width-1 DOWNTO 0);
signal    next_CRC_ii          : std_logic_vector(crc_width-1 DOWNTO 0);
signal    switch_i             : std_logic_vector(rem_width   DOWNTO 0);
signal    mux_select           : std_logic_vector(rem_width-1 DOWNTO 0);
signal    mux_select_reg       : std_logic_vector(rem_width-1 DOWNTO 0);
signal    mux_sel              : std_logic_vector(rem_width-1 DOWNTO 0);
signal    next_crc_o           : std_logic_vector(crc_width*(2**rem_width)-1 downto 0);
signal    current_st_delayed   : std_logic;
signal    to_set               : std_logic_vector(rem_width-1 DOWNTO 0) := (others => '1');
signal    DST_RDY_N_DS_i       : std_logic;
component SRL16E
  -- synthesis translate_off
      generic (
       INIT: bit_vector:= X"0001");
  -- synthesis translate_on
  port (Q   : out STD_ULOGIC;
        A0  : in  STD_ULOGIC;
        A1  : in  STD_ULOGIC;
        A2  : in  STD_ULOGIC;
        A3  : in  STD_ULOGIC;
        CE  : in  STD_ULOGIC;
        CLK : in  STD_ULOGIC;
        D   : in  STD_ULOGIC);
end component;

component SRL16
   -- synthesis translate_off
       generic (
                INIT: bit_vector:= X"0001");
   -- synthesis translate_on
   port (Q   : out STD_ULOGIC;
         A0  : in  STD_ULOGIC;
         A1  : in  STD_ULOGIC;
         A2  : in  STD_ULOGIC;
         A3  : in  STD_ULOGIC;
         CLK : in  STD_ULOGIC;
         D   : in  STD_ULOGIC);
end component;
----------------------------------------------------------------------------
----------------------------------------------------------------------------
----State machine variable declarations
----------------------------------------------------------------------------
------------------------------------------------------
SIGNAL current_state            :  t_state;
SIGNAL next_state               :  t_state;

BEGIN
-----------------------------------------------------------------------------
--assignment to mux_select for non-pipelined Module
-----------------------------------------------------------------------------
mux_select_i : if (pipeline = '0' AND data_width /= 8) generate
PROCESS(EOF_N_US,REM_US)
begin
  if (EOF_N_US = '0') then
    mux_sel <= REM_US;
  else
    mux_sel <= mux_value_lookup(data_width,rem_width) ;
  end if;
end PROCESS;
end generate mux_select_i;

-----------------------------------------------------------------------------
--mux with value of REM_US for non-pipelined Module
-----------------------------------------------------------------------------
next_crc_i_gen_i : if (pipeline = '0' AND alligned_data = '0' AND data_width /= 8) generate
  next_CRC_ii   <= mux_param(next_crc_o,mux_sel,crc_width,data_width);
end generate next_crc_i_gen_i;

-----------------------------------------------------------------------------
-- Sequential assignment to next_CRC for cases with
-- data width = 8 or word alligned data
-----------------------------------------------------------------------------
next_crc_gen_i : if (data_width = 8 OR alligned_data = '1') generate
  next_CRC <= next_CRC_i;
end generate next_crc_gen_i;

next_crc_gen_ii : if (pipeline = '0' AND alligned_data = '0' AND data_width /=8) generate
  next_CRC <= next_CRC_ii;
end generate next_crc_gen_ii;
-----------------------------------------------------------------------------
--  DST_RDY assignment statements
--  if the User chooses the DST_RDY option for inserting the CRC,this
--  signal is used to stop packet transfer to the CRC modules while the CRC is
--  being inserted
------------------------------------------------------------------------------
dst_rdy_i_gen_0:if (insertcrc = '0') generate
  DST_RDY_N_US  <= DST_RDY_N_DS or DST_RDY_N_i;
end generate dst_rdy_i_gen_0;
-----------------------------------------------------------------------------
-- Combinational CRC calculations port mapping
-----------------------------------------------------------------------------
 tx_crc_gen_0_i : if (insertcrc = '0') generate
 tx_crc_gen_i : CRC_GEN
 generic map
   (
     data_width            => data_width,
     crc_width             => crc_width,
     alligned_data         => alligned_data,
     pipeline              => pipeline,
     poly                  => poly,
     insertcrc             => insertcrc,
     rem_width             => rem_width,
     no_of_data_bytes      => no_of_data_bytes,
     no_of_crc_bytes       => no_of_crc_bytes
   )
 port map
   (
     next_crc_o            =>  next_crc_o,
     next_CRC_i            =>  next_CRC_i,
     current_state         =>  current_state,
     SOF_N_US              =>  SOF_N_US,
     EOF_N_US              =>  EOF_N_US,
     SRC_RDY_N_US          =>  SRC_RDY_N_US,
     DST_RDY_N_DS          =>  DST_RDY_N_DS,
     REM_US                =>  REM_US,
     DATA                  =>  DATA,
     C                     =>  C,
     CLK                   =>  CLK,
     RESET                 =>  RESET,
     current_state_delayed =>  current_st_delayed
   );
 end generate tx_crc_gen_0_i;

-----------------------------------------------------------------------------
-- Shifting for data allignment
------------------------------------------------------------------------------
rem_as_pipelined_i : if (pipeline = '1') generate
  shift_rem <= REM_ii;
end generate rem_as_pipelined_i;

rem_as_not_pipelined_i :if (pipeline = '0') generate
  shift_rem <= REM_i;
end generate rem_as_not_pipelined_i;

shifting_0_d_i : if (insertcrc = '0' AND crc_width < data_width
                 AND alligned_data = '0' AND data_width /= 8) generate
PROCESS(current_state,DST_RDY_N_DS,REM_ii,final_crc,shift_rem)
  begin
    if (current_state = CRC AND DST_RDY_N_DS = '0') then
      temp_data <= bshifter_left(to_function(final_crc,data_width),shift_rem);
    else
      temp_data <= (others => '0');
    end if;
END PROCESS;
end generate shifting_0_d_i;

shifting_0_cd_i :if (insertcrc = '0' AND crc_width = data_width
                 AND alligned_data = '0' AND data_width /= 8) generate
PROCESS(current_state,DST_RDY_N_DS,shift_rem,final_crc)
  begin
    if (current_state = CRC AND DST_RDY_N_DS = '0') then
      temp_data <= bshifter_left(final_crc,shift_rem);
    else
      temp_data <= (others => '0');
    end if;
END PROCESS;
end generate shifting_0_cd_i;

shifting_0_c_i: if (insertcrc = '0' AND crc_width > data_width
                AND alligned_data = '0' AND data_width /= 8) generate
PROCESS(current_state,DST_RDY_N_DS,REM_ii,final_crc)
begin
  if (current_state = CRC AND DST_RDY_N_DS = '0') then
    tem_data <= bshifter_left(final_crc,shift_rem);
  else
    tem_data <= (others => '0');
  end if;
END PROCESS;
end generate shifting_0_c_i;

shifting_al_d_i : if (insertcrc = '0' AND (alligned_data = '1' OR data_width =8)
              AND crc_width < data_width ) generate
PROCESS(current_state,DST_RDY_N_DS,REM_ii,final_crc)
  begin
    if (current_state = CRC AND DST_RDY_N_DS = '0') then
      temp_data <= to_function(final_crc,data_width);
    else
      temp_data <= (others => '0');
    end if;
END PROCESS;
end generate shifting_al_d_i;

shifting_al_cd_i : if (insertcrc = '0' AND (alligned_data = '1' OR data_width =8)
              AND crc_width = data_width ) generate
PROCESS(current_state,DST_RDY_N_DS,REM_ii,final_crc)
  begin
    if (current_state = CRC AND DST_RDY_N_DS = '0') then
      temp_data <= final_crc;
    else
      temp_data <= (others => '0');
    end if;
END PROCESS;
end generate shifting_al_cd_i;

shifting_al_c_i : if (insertcrc = '0' AND (alligned_data = '1' OR data_width =8)
              AND crc_width > data_width ) generate
PROCESS(current_state,DST_RDY_N_DS,REM_ii,final_crc)
  begin
    if (current_state = CRC AND DST_RDY_N_DS = '0') then
      tem_data <= final_crc;
    else
      tem_data <= (others => '0');
    end if;
END PROCESS;
end generate shifting_al_c_i;

-----------------------------------------------------------------------------
-- Implementation of trandata
-- legal values :
         --1 - data transposed
         --0 - data not transposed
------------------------------------------------------------------------------

data_01_i: if(insertcrc = '0' AND trandata = '1') generate
  DATA <= transpose_input(DATA_US);
end generate data_01_i;

data_00_i: if (insertcrc = '0' AND trandata = '0') generate
  DATA <= DATA_US;
end generate data_00_i;

--------------------------------------------------------------------------
-- Implementation of trancrc and compcrc
-- compcrc legal values :
         --1 - crc complemented
         --0 - crc not complemented

-- trancrc legal values :
         --1 - crc transposed
         --0 - crc not transposed
--------------------------------------------------------------------------
finalcrc_11_i : if (trancrc = '1' AND compcrc = '1') generate
  final_crc <= NOT transpose_input(C);
end generate finalcrc_11_i;

finalcrc_10_i : if (trancrc = '1' AND compcrc = '0') generate
  final_crc <= transpose_input(C);
end generate finalcrc_10_i;

finalcrc_00_i : if (trancrc = '0' AND compcrc = '0') generate
 final_crc <= C ;
end generate finalcrc_00_i;

finalcrc_01_i : if (trancrc = '0' AND compcrc = '1') generate
  final_crc <= NOT C ;
end generate finalcrc_01_i;

--------------------------------------------------------------------------
-- Driving DATA_DS
--------------------------------------------------------------------------
data_ds_driv_dst_i : DATA_DS_DRIV_DST
generic map
  (
    data_width       =>   data_width,
    crc_width        =>   crc_width,
    poly             =>   poly,
    insertcrc        =>   insertcrc,
    pipeline         =>   pipeline,
    rem_width        =>   rem_width,
    alligned_data    =>   alligned_data,
    no_of_data_bytes =>   no_of_data_bytes,
    no_of_crc_bytes  =>   no_of_crc_bytes
  )
port map
  (
    DATA_DS          =>   DATA_DS,
    DATA_US          =>   DATA_US,
    temp_data        =>   temp_data,
    tem_data         =>   tem_data,
    current_state    =>   current_state,
    REM_i            =>   REM_i,
    REM_ii           =>   REM_ii,
    DST_RDY_N_DS     =>   DST_RDY_N_DS,
    final_crc        =>   final_crc,
    DST_RDY_N_i      =>   DST_RDY_N_i,
    CLK              =>   CLK,
    RESET            =>   RESET
  );

--------------------------------------------------------------------------
-- Generating SOF_N_DS
--------------------------------------------------------------------------
sof_n_ds_0_i : if (insertcrc = '0' AND alligned_data = '0' AND data_width /= 8
               AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      SOF_N_DS     <= '1';
      SOF_N_DS_ii  <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SOF_N_DS_ii  <= SOF_N_DS_i;
      SOF_N_DS     <= SOF_N_DS_ii;
    end if;
  end if;
END PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SOF_N_DS_i     <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SOF_N_DS_i   <= SOF_N_US;
    end if;
  end if;
end PROCESS;


end generate sof_n_ds_0_i;

sof_n_ds_1_i : if (insertcrc = '0' AND (alligned_data = '1' OR data_width = 8
               OR pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      SOF_N_DS   <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SOF_N_DS   <= SOF_N_DS_i;
    end if;
  end if;
END PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      SOF_N_DS_i   <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SOF_N_DS_i <= SOF_N_US;
    end if;
  end if;
END PROCESS;
end generate sof_n_ds_1_i;

--------------------------------------------------------------------------
-- Generating SRC_RDY_N_DS
--------------------------------------------------------------------------

src_rdy_n_ds_0_d_i : if (insertcrc = '0' AND alligned_data = '0' AND data_width /= 8
                     AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      SRC_RDY_N_DS    <= '1';
      SRC_RDY_N_DS_ii <= '1';
    elsif(((current_state = CRC) OR (current_state = CRC1)) AND (DST_RDY_N_DS = '0')) then
     SRC_RDY_N_DS    <= '0';
     SRC_RDY_N_DS_ii <= SRC_RDY_N_DS_i;
    elsif (DST_RDY_N_DS = '0') then
     SRC_RDY_N_DS_ii <= SRC_RDY_N_DS_i;
     SRC_RDY_N_DS    <= SRC_RDY_N_DS_ii;
    end if;
  end if;
END PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      SRC_RDY_N_DS_i   <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SRC_RDY_N_DS_i  <= SRC_RDY_N_US;
    end if;
  end if;
END PROCESS;
end generate src_rdy_n_ds_0_d_i;

src_rdy_n_ds_1_d_i : if (insertcrc = '0' AND (alligned_data = '1' OR data_width = 8
                     OR pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      SRC_RDY_N_DS    <= '1';
    elsif(((current_state = CRC) OR (current_state = CRC1)) AND (DST_RDY_N_DS = '0') ) then
     SRC_RDY_N_DS    <= '0';
    elsif (DST_RDY_N_DS = '0') then
     SRC_RDY_N_DS    <= SRC_RDY_N_DS_i;
    end if;
  end if;
END PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if(RESET = '1') then
      SRC_RDY_N_DS_i   <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SRC_RDY_N_DS_i  <= SRC_RDY_N_US;
    end if;
  end if;
END PROCESS;
end generate src_rdy_n_ds_1_d_i;

--------------------------------------------------------------------------
-- Generating REM_DS
--------------------------------------------------------------------------

rem_ds_driv_dst_c_i : REM_DS_DRIV_DST
generic map
  (
    data_width       =>     data_width,
    crc_width        =>     crc_width,
    poly             =>     poly,
    insertcrc        =>     insertcrc,
    pipeline         =>     pipeline,
    alligned_data    =>     alligned_data,
    rem_width        =>     rem_width,
    no_of_data_bytes =>     no_of_data_bytes,
    no_of_crc_bytes  =>     no_of_crc_bytes
  )
port map
 (
    REM_DS           =>     REM_DS,
    REM_i            =>     REM_i,
    REM_ii           =>     REM_ii,
    REM_US           =>     REM_US,
    current_state    =>     current_state,
    EOF_N_US         =>     EOF_N_US,
    DST_RDY_N_DS     =>     DST_RDY_N_DS,
    DST_RDY_N_i      =>     DST_RDY_N_i,
    SRC_RDY_N_US     =>     SRC_RDY_N_US,
    enable           =>     enable,
    count            =>     count,
    CLK              =>     CLK,
    RESET            =>     RESET
  );

--------------------------------------------------------------------------
-- Generating EOF_N_DS
--------------------------------------------------------------------------
eof_n_ds_0_d_i: if (insertcrc = '0' AND crc_width <= data_width) generate
PROCESS(CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      EOF_N_DS      <= '1';
    elsif ((current_state = CRC) AND (enable = '1') AND (DST_RDY_N_DS = '0')) then
      EOF_N_DS      <= '0';
    elsif ((current_state = CRC1) AND (DST_RDY_N_DS = '0')) then
      EOF_N_DS <= '0';
     else
       EOF_N_DS <= '1';
    end if;
  end if;
END PROCESS;

PROCESS(CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      EOF_N_US_i <= '1';
    elsif (DST_RDY_N_DS = '0') then
      EOF_N_US_i <= EOF_N_US;
    end if;
  end if;
END PROCESS;
end generate eof_n_ds_0_d_i;

eof_n_ds_0_c_i : if (insertcrc = '0' AND crc_width > data_width) generate
PROCESS(CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      EOF_N_DS <= '1';
    elsif ((current_state = CRC1) AND (enable = '1') AND (DST_RDY_N_DS = '0')) then
      EOF_N_DS <= '0';
    else
      EOF_N_DS <= '1';
    end if;
  end if;
end PROCESS;

PROCESS(CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      EOF_N_US_i <= '1';
    elsif (DST_RDY_N_DS = '0') then
      EOF_N_US_i <= EOF_N_US;
    end if;
  end if;
END PROCESS;

end generate eof_n_ds_0_c_i;

--------------------------------------------------------------------------
-- Generating enables
--------------------------------------------------------------------------
enable_0_d_i : if (insertcrc = '0' AND crc_width <= data_width
               AND alligned_data = '0' AND data_width /=8) generate
PROCESS(CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      enable <= '0';
    elsif ((current_state = CALC) AND (EOF_N_US = '0') AND (SRC_RDY_N_US ='0') AND (DST_RDY_N_DS='0')) then
      if (conv_integer(no_of_crc_bytes) <= conv_integer(no_of_data_bytes - REM_US - 1)) then
        enable <= '1';
      else
        enable <= '0';
      end if;
    elsif (current_state = IDLE) then
      enable <= '0';
    end if;
  end if;
 END PROCESS;
end generate enable_0_d_i;

enable_al : if ((insertcrc = '0' AND crc_width <= data_width
            AND alligned_data = '1')) generate
  enable <= '0';
end generate enable_al;

enable_0_c_i : if (insertcrc = '0' AND crc_width >data_width AND alligned_data = '0') generate
PROCESS(CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      enable <= '0';
    elsif(((current_state = CRC) AND (DST_RDY_N_DS = '0')) OR ((current_state = CRC1) AND (DST_RDY_N_DS = '0'))) then
      if (conv_integer(no_of_crc_bytes - count ) <= conv_integer(no_of_data_bytes)) then
        enable <= '1';
      else
        enable <= '0';
      end if;
    end if;
  end if;
end PROCESS;
end generate enable_0_c_i;
--------------------------------------------------------------------------
-- Generating count
--------------------------------------------------------------------------
count_0_c_i : if (insertcrc = '0' AND crc_width > data_width) generate
PROCESS(CLK)
begin
  if(CLK'EVENT AND CLK = '1') then
    if (current_state = IDLE) then
      count <= "00000";
    elsif((current_state = CALC) AND (EOF_N_US = '0') AND  (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')) then
      count <= no_of_data_bytes - REM_count - 1;
    elsif (((current_state = CRC) AND (DST_RDY_N_DS = '0')) OR ((current_state = CRC1) AND (DST_RDY_N_DS = '0'))) then
       if ((no_of_crc_bytes-count) > no_of_data_bytes) then
            count <= no_of_data_bytes + count;
        end if;
    end if;
  end if;
end PROCESS;
end generate count_0_c_i;

count_8 : if (data_width = 8) generate
  REM_count <= (others => '0');
end generate count_8;

count_al : if (alligned_data = '1' AND data_width /= 8) generate
  REM_count <= (others => '1');
end generate count_al;

count_notal : if (alligned_data = '0' AND data_width /= 8) generate
  REM_count <= REM_US;
end generate count_notal;
--------------------------------------------------------------------------
-- Generating mux_select signal for registering combn. CRC
--------------------------------------------------------------------------
switch_i <= EOF_N_US & REM_US;

PROCESS(CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      mux_select_reg <= (others => '1');
    else
      mux_select_reg <= mux_select;
    end if;
  end if;
end PROCESS;

PROCESS(EOF_N_US,REM_US)
begin
  if (EOF_N_US = '0') then
    mux_select <= REM_US;
  else
    mux_select <= mux_value_lookup(data_width,rem_width);
  end if;
end PROCESS;

--------------------------------------------------------------------------
--  State Machine port mapping
--------------------------------------------------------------------------
PROCESS(CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      current_state <= IDLE;
    else
      current_state <= next_state;
    end if;
  end if;
end process;


state_machine_dst_d_i :STATE_MACHINE_DST
generic map
  (
    data_width       =>   data_width,
    crc_width        =>   crc_width,
    poly             =>   poly,
    insertcrc        =>   insertcrc,
    pipeline         =>   pipeline,
    rem_width        =>   rem_width,
    alligned_data    =>   alligned_data,
    no_of_data_bytes =>   no_of_data_bytes,
    no_of_crc_bytes  =>   no_of_crc_bytes
  )
port map
  (
    next_state       =>   next_state,
    current_state    =>   current_state,
    SOF_N_US         =>   SOF_N_US,
    EOF_N_US         =>   EOF_N_US,
    EOF_N_US_i       =>   EOF_N_US_i,
    SRC_RDY_N_US     =>   SRC_RDY_N_US,
    SRC_RDY_N_DS_i   =>   SRC_RDY_N_DS_i,
    DST_RDY_N_DS     =>   DST_RDY_N_DS,
    REM_i            =>   REM_i,
    enable           =>   enable
  );

--------------------------------------------------------------------------
--  Mux of Combinational CRC
--------------------------------------------------------------------------
mux_notal : if (alligned_data = '0' AND data_width /= 8 AND pipeline = '1') generate
PROCESS(next_crc_o,mux_select_reg)
begin
  next_CRC <= mux_param(next_crc_o,mux_select_reg,crc_width,data_width);
END PROCESS;
end generate mux_notal;
--------------------------------------------------------------------------
--  Registering CRC
--------------------------------------------------------------------------
c_reg_i_0 : if ( insertcrc = '0' AND alligned_data = '0' AND data_width /= 8 AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if ((RESET = '1') OR (current_state = CRC)) then
      C <= crcinit;
    else
      C <=  next_CRC;
    end if;
  end if;
END PROCESS;
end generate c_reg_i_0;

c_reg_i_1 : if ( insertcrc = '0' AND (alligned_data = '1' OR data_width = 8 OR pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if ((RESET = '1') OR (current_state = CRC)) then
      C <= crcinit;
    elsif(((current_state = CALC) AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')
         AND (EOF_N_US = '1')) OR (current_state = IDLE AND (SOF_N_US = '0') AND
         (DST_RDY_N_DS = '0') AND (SRC_RDY_N_US = '0')) OR ((EOF_N_US = '0') AND
         (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0'))) then
      C <=  next_CRC;
    end if;
  end if;
END PROCESS;
end generate c_reg_i_1;

--------------------------------------------------------------------------
-- generating DST_RDY_N_US for DST_RDY_N option to stop transfer
-- of data to CRC module while CRC is being inserted at downstream interface
--------------------------------------------------------------------------

dst_rdy_n_i_0_d_i : if (insertcrc = '0' AND crc_width <= data_width) generate
PROCESS(CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      DST_RDY_N_i  <= '0';
    elsif ((EOF_N_US = '0') AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')) then
      DST_RDY_N_i  <= '1' ;
    elsif((current_state = CRC) AND (enable = '1') AND (DST_RDY_N_DS = '0')) then
      DST_RDY_N_i  <= '0';
    elsif (current_state = CRC1) then
      DST_RDY_N_i  <= '0';
    end if;
  end if;
END PROCESS;
end generate dst_rdy_n_i_0_d_i;

dst_rdy_n_i_0_c_i : if (insertcrc = '0' AND crc_width > data_width) generate
PROCESS(CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      DST_RDY_N_i <= '0';
    elsif ((EOF_N_US = '0') AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')) then
      DST_RDY_N_i <= '1';
    elsif ((current_state = CRC1) AND (enable = '1')) then
      DST_RDY_N_i <= '0';
    end if;
  end if;
end PROCESS;
end generate dst_rdy_n_i_0_c_i;

END TX_CRC_ARCH;