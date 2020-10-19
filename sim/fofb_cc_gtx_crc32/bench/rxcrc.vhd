-------------------------------------------------------------------------------
-- 
-- $Revision: 1.11 $
-- $Date: 2003/12/31 02:15:09 $
--
-------------------------------------------------------------------------------
-- Receive CRC Top Level
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
-- File Name: rxcrc.vhd
-- Author: Nanditha Jayarajan
-- Contributors: Chris Borrelli
--
-- Description:
-- This file is the top level entity and architecture
-- for the RX CRC Module

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
ENTITY RX_CRC IS
GENERIC
  (
  -- Data Width  : Legal Values    :  8,16,32,64
    data_width                   :  integer := 16;

  -- CRC Width   : Legal Values   :  8,16.32,64
    crc_width                    :  integer := 32;

  -- CRC Polynomial : Accepted as a string
  --  Please ensure that the width of the string is correct
    poly                         :  std_logic_vector
                                 := "00000100110000010001110110110111";

  -- Indicates whether the Data is always alligned
  -- i.e. REM = all 1's always
  -- This results in a smaller sizes for the Design
    alligned_data                :  std_logic := '0';


  -- Option to pipeline
  -- 0 - not pipelined 1 - pipeline
    pipeline                     : std_logic := '1';

  -- Option to accept back_to_back transfers. This option is available
  -- only for the non-pipelined version
    back_to_back                 : std_logic := '0';

  -- Option to transpose Input Data
  -- 0 - not transposed 1 - transposed
    trandata                     :  std_logic := '1';

  -- Option to transpose final CRC before output
  -- 0 - not transposed 1 - transposed
    trancrc                      :  std_logic := '1';

  -- Option to complement final CRC before output
  -- 0 - not complemented 1 - complemented
    compcrc                      :  std_logic := '1';

  -- Initial value of CRC Register
  -- Accepted as a string
    crcinit                      :  std_logic_vector
                                 := "11111111111111111111111111111111";

  -- Residue Value for RX CRC comparison
  -- Accepted as a string
    residue_value                :  std_logic_vector
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
    DATA_DS                        :  OUT std_logic_vector(data_width - 1 DOWNTO 0);
    REM_DS                         :  OUT std_logic_vector;
    SOF_N_DS                       :  OUT std_logic;
    EOF_N_DS                       :  OUT std_logic;
    SRC_RDY_N_DS                   :  OUT std_logic;
    DST_RDY_N_US                   :  OUT std_logic;
    CRC_PASS_FAIL_N                :  OUT std_logic;
    CRC_VALID                      :  OUT std_logic;
    DATA_US                        :  IN std_logic_vector(data_width - 1 DOWNTO 0);
    REM_US                         :  IN std_logic_vector;
    SOF_N_US                       :  IN std_logic;
    EOF_N_US                       :  IN std_logic;
    SRC_RDY_N_US                   :  IN std_logic;
    DST_RDY_N_DS                   :  IN std_logic;
    RESET                          :  IN std_logic;
    CLK                            :  IN std_logic
  );
END RX_CRC;

ARCHITECTURE RX_CRC_ARCH of RX_CRC is
-- changes for synthesis
constant rem_width          :  integer := rem_width_calc(data_width);
constant no_of_data_bytes   :  std_logic_vector(4  DOWNTO 0)
                            := no_of_bytes_calc(data_width);
constant no_of_crc_bytes    :  std_logic_vector(4  DOWNTO 0)
                            := no_of_bytes_calc(crc_width);

constant  crc_bytes         : integer := conv_integer(no_of_crc_bytes);
constant  data_bytes        : integer := conv_integer(no_of_data_bytes);

constant TO_WIDTH           : integer
                            := crc_bytes mod data_bytes -1;

constant TO_WIDTH1          : integer
                            := crc_bytes / data_bytes-1;

signal WIDTH                : std_logic_vector(3 DOWNTO 0)
                            :=  conv_std_logic_vector(TO_WIDTH1-1,4);

signal WIDTH3               : std_logic_vector(3 DOWNTO 0)
                            :=  conv_std_logic_vector(TO_WIDTH,4);

signal WIDTH1               : std_logic_vector(3 DOWNTO 0)
                            :=  conv_std_logic_vector(TO_WIDTH-1,4);

signal WIDTH_NR_NS          : std_logic_vector(3 DOWNTO 0)
                            := conv_std_logic_vector(TO_WIDTH,4);

signal WIDTH_NR_S_D         : std_logic_vector(3 DOWNTO 0) := "0001";
signal WIDTH_S_C            : std_logic_vector(3 DOWNTO 0)
                            := conv_std_logic_vector(TO_WIDTH+1,4);

signal WIDTH_NS_RES         : std_logic_vector(3 DOWNTO 0) := "0010";
signal DATA                 : std_logic_vector(data_width-1 DOWNTO 0);
signal DATA_DS_i            : std_logic_vector(data_width-1 DOWNTO 0);
signal DATA_DS_ii           : std_logic_vector(data_width-1 DOWNTO 0);
signal SRL_DATA             : std_logic_vector(data_width-1 DOWNTO 0);
signal SRL16_DATA           : std_logic_vector(data_width-1 DOWNTO 0);
signal SRL16_OUT            : std_logic_vector(data_width-1 DOWNTO 0);
signal DATA_CRC_VALID       : std_logic_vector(data_width-1 DOWNTO 0);
signal SRL_SOF_N_DS_i       : std_logic;
signal SRL_SRC_RDY_N_DS_i   : std_logic;
signal SRL_SRC_RDY_N_DS     : std_logic;
signal SOF_N_DS_i           : std_logic;
signal SOF_N_DS_ii          : std_logic;
signal EOF_N_DS_i           : std_logic;
signal SRC_RDY_N_DS_i       : std_logic;
signal SRC_RDY_N_DS_ii      : std_logic;
signal SRL_EOF_N_DS         : std_logic;
signal SRL_EOF_N_DS_i       : std_logic;
signal REM_i                : std_logic_vector(rem_width-1 DOWNTO 0);
signal REM_ii               : std_logic_vector(rem_width-1 DOWNTO 0);
signal REM_int              : std_logic_vector(rem_width-1 DOWNTO 0);
signal REM_SRL              : std_logic_vector(rem_width-1 DOWNTO 0);
signal REM_CRC_VALID        : std_logic_vector(rem_width-1 DOWNTO 0);
signal enable               : std_logic;
signal enable1              : std_logic;
signal enable2              : std_logic;
signal enable3              : std_logic;
signal current_st_delayed   : std_logic;
signal CHECK_CRC            : std_logic_vector(crc_width-1 DOWNTO 0);
signal final_CRC            : std_logic_vector(crc_width-1 DOWNTO 0);
signal next_CRC             : std_logic_vector(crc_width-1 DOWNTO 0);
signal next_CRC_ii          : std_logic_vector(crc_width-1 DOWNTO 0);
signal C                    : std_logic_vector(crc_width-1 DOWNTO 0);
signal C_compare            : std_logic_vector(crc_width-1 DOWNTO 0);
signal C_check              : std_logic_vector(crc_width-1 DOWNTO 0);
signal count                : std_logic_vector(4 downto 0);
signal SRL_SOF_N_DS_SRL     : std_logic;
signal SRL_SOF_N_DS         : std_logic;
signal SRL_SRC_RDY_N_DS_SRL : std_logic;
signal CLOCK_EN             : std_logic;
signal GND_BUS              : std_logic_vector(data_width-1 downto 0) := (others => '0');
signal next_CRC_00          : std_logic_vector(crc_width-1 DOWNTO 0);
signal next_CRC_01          : std_logic_vector(crc_width-1 DOWNTO 0);
signal next_CRC_10          : std_logic_vector(crc_width-1 DOWNTO 0);
signal next_CRC_11          : std_logic_vector(crc_width-1 DOWNTO 0);
signal next_CRC_100         : std_logic_vector(crc_width-1 DOWNTO 0);
signal next_CRC_101         : std_logic_vector(crc_width-1 DOWNTO 0);
signal next_CRC_110         : std_logic_vector(crc_width-1 DOWNTO 0);
signal next_CRC_111         : std_logic_vector(crc_width-1 DOWNTO 0);
signal next_CRC_i           : std_logic_vector(crc_width-1 DOWNTO 0);
signal switch_i             : std_logic_vector(rem_width   DOWNTO 0);
signal mux_select           : std_logic_vector(rem_width-1   DOWNTO 0);
signal mux_sel              : std_logic_vector(rem_width-1   DOWNTO 0);
signal mux_select_reg       : std_logic_vector(rem_width-1   DOWNTO 0);
signal next_crc_o           : std_logic_vector(crc_width*(2**rem_width)-1 downto 0);
signal to_set               : std_logic_vector(rem_width-1 DOWNTO 0) := (others => '1');
signal DST_RDY_N_i          : std_logic;
----------------------------------------------------------------------------
-- SRL -16 COMPONENT INSTANTIATION
----------------------------------------------------------------------------

component srl16e
  -- synthesis translate_off
      generic (
       INIT: bit_vector:= X"0001");
  -- synthesis translate_on
  port (Q   : out STD_ULOGIC;
        A0  : in STD_ULOGIC;
        A1  : in STD_ULOGIC;
        A2  : in STD_ULOGIC;
        A3  : in STD_ULOGIC;
        CE  : in STD_ULOGIC;
        CLK : in STD_ULOGIC;
        D   : in STD_ULOGIC);
end component;

component SRL16
   -- synthesis translate_off
       generic (
                INIT: bit_vector:= X"0001");
   -- synthesis translate_on
   port (Q   : out STD_ULOGIC;
         A0  : in STD_ULOGIC;
         A1  : in STD_ULOGIC;
         A2  : in STD_ULOGIC;
         A3  : in STD_ULOGIC;
         CLK : in STD_ULOGIC;
         D   : in STD_ULOGIC);
end component;

----------------------------------------------------------------------------
----State machine variable declarations
----------------------------------------------------------------------------

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
    mux_sel <= mux_value_lookup(data_width,rem_width);
  end if;
end PROCESS;
end generate mux_select_i;

-----------------------------------------------------------------------------
--mux with value of REM_US for non-pipelined Module
-----------------------------------------------------------------------------
next_crc_i_gen_i : if (pipeline = '0' AND alligned_data = '0') generate
  next_CRC_ii   <= mux_param(next_crc_o,mux_sel,crc_width,data_width);
end generate next_crc_i_gen_i;

-----------------------------------------------------------------------------
-- Sequential assignment to next_CRC for cases with
-- data width = 8 or word alligned data
-----------------------------------------------------------------------------

next_crc_gen_i : if (data_width = 8 or alligned_data = '1') generate
  next_CRC <= next_CRC_i;
end generate next_crc_gen_i;

next_crc_gen_ii : if (pipeline = '0' AND alligned_data = '0' AND data_width /=8) generate
  next_CRC <= next_CRC_ii;
end generate next_crc_gen_ii;
--------------------------------------------------------------------------
-- Current_state assignments to enable the RX CRC Module
-- to accept one byte and also to accept back_to_back frames
--------------------------------------------------------------------------
current_st_gen_al : if (data_width = 8 or alligned_data = '1' or pipeline = '0') generate
PROCESS(CLK)
begin
  if (CLK'EVENT  AND CLK = '1') then
    if (RESET = '1') then
      current_st_delayed <= '0';
    elsif ((EOF_N_US = '0') and (SRC_RDY_N_US = '0') and (DST_RDY_N_DS = '0')) then
      current_st_delayed <= '1';
    else
      current_st_delayed <= '0';
    end if;
  end if;
end PROCESS;
end generate current_st_gen_al;

current_st_notal : if (alligned_data = '0' AND data_width /= 8 AND pipeline = '1') generate
PROCESS(CLK)
begin
  if (CLK'EVENT  AND CLK = '1') then
    if (RESET = '1') then
      current_st_delayed <= '0';
    elsif ((EOF_N_DS_i = '0') and (SRC_RDY_N_DS_i = '0')
          and (DST_RDY_N_DS = '0')) then
      current_st_delayed <= '1';
    else
      current_st_delayed <= '0';
    end if;
  end if;
end PROCESS;
end generate current_st_notal;

--------------------------------------------------------------------------
--DST_RDY_N_US assignments
--------------------------------------------------------------------------
dst_rdy_us_notb2b : if (back_to_back = '0') generate
DST_RDY_N_US  <= DST_RDY_N_DS or DST_RDY_N_i;
end generate dst_rdy_us_notb2b;

dst_rdy_us_b2b: if (back_to_back = '1') generate
  DST_RDY_N_US <= DST_RDY_N_DS ;
end generate dst_rdy_us_b2b;

-----------------------------------------------------------------------------
-- Implementation of trandata
-- legal values :
  --1 - data transposed
  --0 - data not transposed
-----------------------------------------------------------------------------

data_11_i: if(residue = '1' AND trandata = '1') generate
  DATA <= transpose_input(DATA_US);
end generate data_11_i;

data_10_i: if (residue = '1' AND trandata = '0') generate
  DATA <= DATA_US;
end generate data_10_i;

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
-------------------------------------------------------------------------
-- Assignment to width of SRL 16 in pipelined case
-------------------------------------------------------------------------
width_gen_i :if (residue = '1' AND stripcrc = '1' AND crc_width > data_width
            AND pipeline = '1') generate
  WIDTH <= conv_std_logic_vector(TO_WIDTH1,4);
end generate width_gen_i;
--------------------------------------------------------------------------
-- SRL - 16 instantiations
--------------------------------------------------------------------------

srl16_instant_11_c_i : if (residue = '1' AND stripcrc = '1' AND crc_width > data_width) generate
DATA_DS_i      <= SRL16_OUT;
SOF_N_DS_i     <= SRL_SOF_N_DS_i;
SRC_RDY_N_DS_i <= SRL_SRC_RDY_N_DS;

PROCESS (SRL_SRC_RDY_N_DS,current_state)
  begin
    if ((current_st_delayed = '1') OR (SRL_SRC_RDY_N_DS = '0')) then
      CLOCK_EN <= '1' after 1 ns;
    else
      CLOCK_EN <= '0' after 1 ns;
    end if;
end PROCESS;

srl16_11_c_i : for i in 0 to data_width-1 generate
  srl_16_data : srl16e
  -- synthesis translate_off
       generic map (INIT => X"ffff")
  -- synthesis translate_on
       port map (Q   => SRL16_OUT(i),
                 A0  => WIDTH(0),
                 A1  => WIDTH(1),
                 A2  => WIDTH(2),
                 A3  => WIDTH(3),
                 CE  => CLOCK_EN,
                 CLK => CLK,
                 D   => SRL16_DATA(i));
end generate srl16_11_c_i;

srl_16_sof : srl16e
  -- synthesis translate_off
     generic map (INIT => X"ffff")
  -- synthesis translate_on
     port map (Q   => SRL_SOF_N_DS_i,
               A0  => WIDTH(0),
               A1  => WIDTH(1),
               A2  => WIDTH(2),
               A3  => WIDTH(3),
               CE  => CLOCK_EN,
               CLK => CLK,
               D   => SRL_SOF_N_DS);

end generate srl16_instant_11_c_i;

--------------------------------------------------------------------------
--Combinational CRC instantiations
--------------------------------------------------------------------------

rx_crc_gen_1_i : if (residue  = '1') generate
rx_crc_gen_i : CRC_GEN
generic map
  (
     data_width           =>   data_width,
     crc_width            =>   crc_width,
     poly                 =>   poly,
     alligned_data        =>   alligned_data,
     residue              =>   residue,
     stripcrc             =>   stripcrc,
     pipeline             =>   pipeline,
     rem_width            =>   rem_width,
     no_of_data_bytes     =>   no_of_data_bytes,
     no_of_crc_bytes      =>   no_of_crc_bytes
  )
port map
  (
     next_CRC_o            =>  next_CRC_o,
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
 end generate rx_crc_gen_1_i;

--------------------------------------------------------------------------
--Driving DATA_DS
--------------------------------------------------------------------------

data_ds_10 : if (residue = '1' AND stripcrc = '0' AND
             (alligned_data = '1' OR data_width = 8 OR
             pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      DATA_DS <= (others => '0');
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS <= DATA_US;
    end if;
  end if;
end PROCESS;
end generate data_ds_10;

data_ds_11_d : if (residue = '1' AND stripcrc = '1' AND crc_width <= data_width
               AND (alligned_data = '1' OR data_width = 8
               OR pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      DATA_DS   <= (others => '0');
     elsif (DST_RDY_N_DS = '0') then
      DATA_DS   <= DATA_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      DATA_DS_i <= (others => '0');
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS_i <= DATA_US;
    end if;
  end if;
end PROCESS;
end generate data_ds_11_d;

data_ds_11_c : if (residue = '1' AND stripcrc = '1' AND crc_width > data_width
               AND (alligned_data = '1' OR data_width = 8 OR
               pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      DATA_DS <= (others => '0');
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS <= DATA_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SRL16_DATA <= (others => '0');
    elsif (DST_RDY_N_DS = '0') then
      SRL16_DATA <= DATA_US;
    end if;
  end if;
end PROCESS;
end generate data_ds_11_c;

data_ds_10_notal : if (residue = '1' AND stripcrc = '0'
             AND alligned_data = '0' AND data_width /= 8
             AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      DATA_DS   <= (others => '0');
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS   <= DATA_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      DATA_DS_i <= (others => '0');
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS_i <= DATA_US;
    end if;
  end if;
end PROCESS;
end generate data_ds_10_notal;

data_ds_11_d_notal : if (residue = '1' AND stripcrc = '1'
                     AND crc_width <= data_width AND
                     alligned_data = '0' AND data_width /= 8
                     AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      DATA_DS     <= (others => '0');
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS_ii <= DATA_DS_i;
      DATA_DS    <= DATA_DS_ii;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      DATA_DS_i <= (others => '0');
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS_i <= DATA_US;
    end if;
  end if;
end PROCESS;
end generate data_ds_11_d_notal;

data_ds_11_c_notal : if (residue = '1' AND stripcrc = '1'
                     AND crc_width > data_width AND alligned_data = '0'
                     AND data_width /= 8 AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      DATA_DS <= (others => '0');
    elsif (DST_RDY_N_DS = '0') then
      DATA_DS <= DATA_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SRL16_DATA <= (others => '0');
    elsif (DST_RDY_N_DS = '0') then
      SRL16_DATA <= DATA_US;
    end if;
  end if;
end PROCESS;
end generate data_ds_11_c_notal;

--------------------------------------------------------------------------
--Driving SOF_N_DS
--------------------------------------------------------------------------

sof_n_ds_10 : if (residue = '1' AND stripcrc = '0'
              AND (alligned_data = '1' OR data_width = 8
              OR pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SOF_N_DS <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SOF_N_DS <= SOF_N_US;
    end if;
  end if;
end PROCESS;
end generate sof_n_ds_10;

sof_n_ds_10_notal : if (residue = '1' AND stripcrc = '0'
                    AND alligned_data = '0' AND data_width /=8
                    AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SOF_N_DS   <= '1';
     elsif (DST_RDY_N_DS = '0') then
      SOF_N_DS   <= SOF_N_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SOF_N_DS_i <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SOF_N_DS_i <= SOF_N_US;
    end if;
  end if;
end PROCESS;
end generate sof_n_ds_10_notal;

sof_n_ds_11_d : if (residue = '1' AND stripcrc = '1' AND
                crc_width <= data_width AND (alligned_data = '1' OR
                data_width = 8 OR pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SOF_N_DS      <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SOF_N_DS        <=  SOF_N_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SOF_N_DS_i <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SOF_N_DS_i <= SOF_N_US;
    end if;
  end if;
end PROCESS;
end generate sof_n_ds_11_d;

sof_n_ds_11_d_notal : if (residue = '1' AND stripcrc = '1' AND
                      crc_width <= data_width AND alligned_data = '0'
                      AND data_width /= 8 AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SOF_N_DS        <= '1';
      SOF_N_DS_ii     <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SOF_N_DS_ii     <=  SOF_N_DS_i;
      SOF_N_DS        <=  SOF_N_DS_ii;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SOF_N_DS_i <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SOF_N_DS_i <= SOF_N_US;
    end if;
  end if;
end PROCESS;
end generate sof_n_ds_11_d_notal;

sof_n_ds_11_c : if (residue = '1' AND stripcrc = '1' AND
                crc_width > data_width AND (alligned_data = '1' OR
                data_width = 8 OR pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SOF_N_DS <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SOF_N_DS <= SOF_N_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SRL_SOF_N_DS <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SRL_SOF_N_DS <= SOF_N_US;
    end if;
  end if;
end PROCESS;
end generate sof_n_ds_11_c;

sof_n_ds_11_c_notal : if (residue = '1' AND stripcrc = '1' AND
                      crc_width > data_width AND alligned_data = '0'
                      AND data_width /= 8 AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SOF_N_DS <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SOF_N_DS <= SOF_N_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SRL_SOF_N_DS <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SRL_SOF_N_DS <= SOF_N_US;
    end if;
  end if;
end PROCESS;
end generate sof_n_ds_11_c_notal;

--------------------------------------------------------------------------
--Driving SRC_RDY_N_DS
--------------------------------------------------------------------------

src_rdy_10 : if (residue = '1' AND stripcrc = '0'
             AND (alligned_data = '1' OR data_width = 8
             OR pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SRC_RDY_N_DS    <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SRC_RDY_N_DS    <= SRC_RDY_N_US;
    end if;
  end if;
end PROCESS;
end generate src_rdy_10;

src_rdy_10_notal : if (residue = '1' AND stripcrc = '0'
                   AND alligned_data = '0' AND data_width /= 8
                   AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SRC_RDY_N_DS    <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SRC_RDY_N_DS    <= SRC_RDY_N_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
     SRC_RDY_N_DS_i  <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SRC_RDY_N_DS_i  <= SRC_RDY_N_US;
    end if;
  end if;
end PROCESS;
end generate src_rdy_10_notal;

src_rdy_11_d : if (residue = '1' AND stripcrc = '1' AND
               crc_width <= data_width AND (alligned_data = '1' OR
               data_width =8 OR pipeline = '0' )) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SRC_RDY_N_DS    <= '1';
     elsif (DST_RDY_N_DS = '0') then
      SRC_RDY_N_DS    <= SRC_RDY_N_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
     SRC_RDY_N_DS_i  <= '1';
    elsif (DST_RDY_N_i = '0' AND DST_RDY_N_DS = '0') then
      SRC_RDY_N_DS_i  <= SRC_RDY_N_US;
    end if;
  end if;
end PROCESS;
end generate src_rdy_11_d;

src_rdy_11_d_notal : if (residue = '1' AND stripcrc = '1' AND
                     crc_width <= data_width AND alligned_data = '0'
                     AND data_width /= 8 AND pipeline = '1')  generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SRC_RDY_N_DS    <= '1';
      SRC_RDY_N_DS_ii <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SRC_RDY_N_DS_ii <= SRC_RDY_N_DS_i;
      SRC_RDY_N_DS    <= SRC_RDY_N_DS_ii;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
     SRC_RDY_N_DS_i  <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SRC_RDY_N_DS_i  <= SRC_RDY_N_US;
    end if;
  end if;
end PROCESS;
end generate src_rdy_11_d_notal;

src_rdy_11_c : if (residue = '1' AND stripcrc = '1' AND
               crc_width > data_width AND (alligned_data = '1' OR
               data_width = 8 OR pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SRC_RDY_N_DS <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SRC_RDY_N_DS <= SRC_RDY_N_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SRL_SRC_RDY_N_DS <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SRL_SRC_RDY_N_DS <= SRC_RDY_N_US;
    end if;
  end if;
end PROCESS;
end generate src_rdy_11_c;

src_rdy_11_c_notal : if (residue = '1' AND stripcrc = '1'
                     AND crc_width > data_width AND alligned_data = '0'
                     AND data_width /= 8 AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SRC_RDY_N_DS <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SRC_RDY_N_DS <= SRC_RDY_N_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      SRL_SRC_RDY_N_DS <= '1';
    elsif (DST_RDY_N_DS = '0') then
      SRL_SRC_RDY_N_DS <= SRC_RDY_N_US;
    end if;
  end if;
end PROCESS;
end generate src_rdy_11_c_notal;

--------------------------------------------------------------------------
--Driving REM_DS
--------------------------------------------------------------------------

rem_ds_10 : if (residue = '1' AND stripcrc = '0'
            AND (alligned_data = '1' OR data_width = 8 OR pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    REM_DS <= REM_US;
  end if;
end PROCESS;
end generate rem_ds_10;

rem_ds_10_notal : if (residue = '1' AND stripcrc = '0'
                  AND alligned_data = '0' AND data_width /= 8 AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      REM_DS <= to_set(rem_width-1 DOWNTO 0);
    elsif (DST_RDY_N_DS = '0') then
       REM_DS <= REM_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      REM_i  <= (others => '1');
    elsif (DST_RDY_N_DS = '0') then
      REM_i  <= REM_US;
    end if;
  end if;
end PROCESS;

end generate rem_ds_10_notal;

rem_ds_11_d : if (residue = '1' AND stripcrc = '1' AND
              crc_width <= data_width AND (alligned_data = '1'
              OR data_width = 8 OR pipeline = '0')) generate
PROCESS (CLK)
variable REM_int : std_logic_vector(4 downto 0);
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      REM_DS <= to_set(rem_width-1 downto 0);
    elsif ((EOF_N_US = '0') AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')) then
      REM_i <= REM_US;
      if ((REM_US +1) < no_of_crc_bytes) then
        REM_int := no_of_data_bytes - no_of_crc_bytes + REM_US;
        REM_DS  <= REM_int(rem_width-1 downto 0);
      end if;
    elsif (current_st_delayed = '1' AND (DST_RDY_N_DS = '0')) then
      if (enable = '1') then
        REM_DS <=  to_set(rem_width-1 downto 0);
      else
        REM_int := REM_i - no_of_crc_bytes;
        REM_DS  <= REM_int(rem_width-1 downto 0);
      end if;
    end if;
  end if;
end PROCESS;
end generate rem_ds_11_d;

rem_ds_11_d_notal : if (residue = '1' AND stripcrc = '1' AND
              crc_width <= data_width AND alligned_data = '0'
              AND data_width /= 8 AND pipeline = '1') generate
PROCESS (CLK)
variable REM_int : std_logic_vector(4 downto 0);
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
        REM_DS <= to_set(rem_width-1 downto 0);
    elsif ((EOF_N_US = '0') AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')) then
      REM_i <= REM_US;
    elsif ((EOF_N_DS_i = '0') AND (SRC_RDY_N_DS_i = '0') AND (DST_RDY_N_DS = '0')) then
      if ((REM_i +1) < no_of_crc_bytes) then
        REM_int := no_of_data_bytes - no_of_crc_bytes + REM_i;
        REM_DS  <= REM_int(rem_width-1 downto 0);
      end if;
    elsif (current_st_delayed = '1' AND (DST_RDY_N_DS = '0')) then
      if (enable = '1') then
        REM_DS <= to_set(rem_width-1 downto 0);
      else
        REM_int := REM_i - no_of_crc_bytes;
        REM_DS  <= REM_int(rem_width-1 downto 0);
      end if;
    end if;
  end if;
end PROCESS;
end generate rem_ds_11_d_notal;

rem_ds_11_c_mod : if (residue = '1' AND stripcrc = '1' AND
                  crc_width > data_width AND (alligned_data = '1' OR
                  data_width = 8 OR pipeline = '0')) generate
PROCESS (CLK)
variable rem_int : std_logic_vector(4 downto 0);
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      REM_DS <= to_set(rem_width-1 downto 0);
    elsif ((EOF_N_US = '0') AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')) then
      REM_i  <= REM_US;
      REM_DS <= REM_US;
    elsif (current_st_delayed = '1' AND (DST_RDY_N_DS = '0')) then
      REM_DS <= to_set(rem_width-1 downto 0);
    end if;
  end if;
end PROCESS;
end generate rem_ds_11_c_mod;

rem_ds_11_c_mod_notal : if (residue = '1' AND stripcrc = '1' AND
                        crc_width > data_width AND alligned_data = '0'
                        AND data_width /= 8 AND pipeline = '1') generate
PROCESS (CLK)
variable rem_int : std_logic_vector(4 downto 0);
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      REM_DS <= to_set(rem_width-1 downto 0);
    elsif ((EOF_N_US = '0') AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')) then
      REM_i  <= REM_US;
    elsif ((EOF_N_DS_i = '0') AND (SRC_RDY_N_DS_i = '0') AND (DST_RDY_N_DS = '0')) then
      REM_DS <= REM_i;
    elsif (current_st_delayed = '1' AND (DST_RDY_N_DS = '0')) then
      REM_DS <= to_set(rem_width-1 downto 0);
    end if;
  end if;
end PROCESS;
end generate rem_ds_11_c_mod_notal;

--------------------------------------------------------------------------
--Driving EOF_N_DS
--------------------------------------------------------------------------

eof_n_ds_10 : if (residue = '1' AND stripcrc = '0'
              AND (alligned_data = '1' OR data_width = 8 OR pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      EOF_N_DS <= '1';
    elsif (DST_RDY_N_DS = '0') then
      EOF_N_DS <= EOF_N_US;
    end if;
  end if;
end PROCESS;
end generate eof_n_ds_10;

eof_n_ds_10_notal : if (residue = '1' AND stripcrc = '0'
                    AND alligned_data = '0' AND data_width /= 8 AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      EOF_N_DS   <= '1';
    elsif (DST_RDY_N_DS = '0') then
      EOF_N_DS   <= EOF_N_DS_i;
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
     EOF_N_DS_i  <= '1';
    elsif (DST_RDY_N_DS = '0') then
      EOF_N_DS_i  <= EOF_N_US;
    end if;
  end if;
end PROCESS;
end generate eof_n_ds_10_notal;

eof_n_ds_11_d : if (residue = '1' AND stripcrc = '1' AND
                crc_width <= data_width AND (alligned_data = '1' OR
                      data_width = 8 OR pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      EOF_N_DS <= '1';
    elsif ((EOF_N_US = '0') AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')) then
      if ((REM_US + 1) <= no_of_crc_bytes) then
        EOF_N_DS <= '0';
      end if;
    elsif (current_st_delayed = '1' AND (DST_RDY_N_DS = '0')) then
      if (enable = '1') then
        EOF_N_DS <= '1';
      else
        EOF_N_DS <= '0';
      end if;
    elsif (current_state = IDLE) then
      EOF_N_DS <= '1';
    end if;
  end if;
end PROCESS;
end generate eof_n_ds_11_d;

eof_n_ds_11_d_notal : if (residue = '1' AND stripcrc = '1' AND
                      crc_width <= data_width AND alligned_data = '0' AND
                      data_width /= 8 AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      EOF_N_DS <= '1';
    elsif ((EOF_N_DS_i = '0') AND (SRC_RDY_N_DS_i = '0') AND (DST_RDY_N_DS = '0')) then
      if ((REM_i + 1) <= no_of_crc_bytes) then
        EOF_N_DS <= '0';
      end if;
    elsif (current_st_delayed = '1' AND (DST_RDY_N_DS = '0')) then
      if (enable = '1') then
        EOF_N_DS <= '1';
      else
        EOF_N_DS <= '0';
      end if;
    elsif (current_state = IDLE) then
      EOF_N_DS <= '1';
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      EOF_N_DS_i <= '1';
    else
      EOF_N_DS_i <= EOF_N_US;
    end if;
  end if;
end PROCESS;

end generate eof_n_ds_11_d_notal;

eof_n_ds_11_c : if (residue = '1' AND stripcrc = '1'
                    AND crc_width > data_width AND (alligned_data = '1' OR
                    data_width = 8 OR pipeline = '0')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      EOF_N_DS <= '1';
    elsif ((EOF_N_US = '0') AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')) then
      EOF_N_DS <= '0';
    elsif (current_st_delayed = '1' AND (DST_RDY_N_DS = '0')) then
      EOF_N_DS <= '1';
    end if;
  end if;
end PROCESS;
end generate eof_n_ds_11_c;

eof_n_ds_11_c_notal : if (residue = '1' AND stripcrc = '1'
                          AND crc_width > data_width AND alligned_data = '0'
                          AND data_width /= 8 AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      EOF_N_DS <= '1';
    elsif ((EOF_N_DS_i = '0') AND (SRC_RDY_N_DS_i = '0') AND (DST_RDY_N_DS = '0')) then
      EOF_N_DS <= '0';
    elsif (current_st_delayed = '1' AND (DST_RDY_N_DS = '0')) then
      EOF_N_DS <= '1';
    end if;
  end if;
end PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      EOF_N_DS_i <= '1';
    else
      EOF_N_DS_i <= EOF_N_US;
    end if;
  end if;
end PROCESS;
end generate eof_n_ds_11_c_notal;

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

PROCESS(switch_i,REM_US,EOF_N_US)
begin
  if (EOF_N_US = '0') then
    mux_select <= REM_US;
  else
    mux_select <= mux_value_lookup(data_width,rem_width);
  end if;
end PROCESS;

--------------------------------------------------------------------------
--Driving CRC_VALID and CRC_PASS_FAIL_N
--------------------------------------------------------------------------

crc_valid_gen_res_i : if (residue = '1') generate
crc_valid_gen_res_nsands_cd_i : CRC_VALID_GEN_RES_NSANDS_CD
generic map (
data_width               => data_width,
crc_width                => crc_width,
rem_width                => rem_width,
no_of_crc_bytes          => no_of_crc_bytes,
no_of_data_bytes         => no_of_data_bytes,
pipeline                 => pipeline,
residue_value            => residue_value
)
port map (
CRC_PASS_FAIL_N          => CRC_PASS_FAIL_N,
CRC_VALID                => CRC_VALID,
current_state            => current_state,
current_st_delayed       => current_st_delayed,
C                        => C_check,
CLK                      => CLK,
RESET                    => RESET
);
end generate crc_valid_gen_res_i;

to_compare_b2b : if (pipeline = '0' AND back_to_back = '1') generate
  C_check <= C_compare;
end generate to_compare_b2b;

to_compare_notb2b: if (back_to_back = '0') generate
  C_check <= C;
end generate to_compare_notb2b;
--------------------------------------------------------------------------
--  Mux of Combinational CRC
--------------------------------------------------------------------------
mux_notal_i : if (alligned_data = '0' AND data_width /= 8 AND
              pipeline = '1') generate
PROCESS(next_crc_o,mux_select_reg)
begin
  next_CRC <= mux_param(next_crc_o,mux_select_reg,
                        crc_width,data_width);
END PROCESS;
end generate mux_notal_i;

--------------------------------------------------------------------------
--STATE MACHINE MODULES PORTMAPPING
--------------------------------------------------------------------------

PROCESS (CLK)
  begin
    if (CLK'EVENT AND CLK = '1') then
      if (RESET = '1') then
        current_state <= IDLE;
      else
        current_state <= next_state;
      end if;
    end if;
end process;

state_machine_res_ns_notal_i :STATE_MACHINE_RX
generic map (
data_width       =>   data_width,
crc_width        =>   crc_width,
poly             =>   poly,
rem_width        =>   rem_width,
residue          =>   residue,
alligned_data    =>   alligned_data,
pipeline         =>   pipeline,
no_of_data_bytes =>   no_of_data_bytes,
no_of_crc_bytes  =>   no_of_crc_bytes)
port map(
next_state       =>   next_state,
current_state    =>   current_state,
SOF_N_US         =>   SOF_N_US,
EOF_N_US         =>   EOF_N_US,
EOF_N_US_i       =>   EOF_N_DS_i,
SRC_RDY_N_US     =>   SRC_RDY_N_US,
SRC_RDY_N_DS_i   =>   SRC_RDY_N_DS_i,
DST_RDY_N_DS     =>   DST_RDY_N_DS
);

--------------------------------------------------------------------------
--  Registering CRC
--------------------------------------------------------------------------

c_reg_i_0 : if (alligned_data = '0' AND data_width /= 8 AND pipeline = '1') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if ((RESET = '1') OR (current_st_delayed = '1')) then
      C <= crcinit;
    else
      C <=  next_CRC;
    end if;
  end if;
END PROCESS;
end generate c_reg_i_0;

c_reg_i_1 : if (data_width = 8 OR (back_to_back = '0' AND pipeline = '0')
            OR (pipeline = '1' AND alligned_data = '1')) generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if ((RESET = '1') OR (current_st_delayed = '1')) then
      C <= crcinit;
    elsif(((current_state = CALC) AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')
    AND (EOF_N_US = '1')) OR (current_state = IDLE AND (SOF_N_US = '0') AND
    (DST_RDY_N_DS = '0') AND (SRC_RDY_N_US = '0')) OR ((EOF_N_US = '0')
    AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0'))) then
      C <=  next_CRC;
    end if;
  end if;
END PROCESS;
end generate c_reg_i_1;

c_reg_i_2 : if ((back_to_back = '1' AND pipeline = '0'))generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if ((RESET = '1') OR (current_st_delayed = '1')) then
      C_compare <= crcinit;
    elsif(((current_state = CALC) AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')
    AND (EOF_N_US = '1')) OR ((current_state = IDLE) AND (SOF_N_US = '0') AND
    (DST_RDY_N_DS = '0') AND (SRC_RDY_N_US = '0')) OR ((EOF_N_US = '0') AND
    (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0'))) then
      C_compare <=  next_CRC;
    end if;
  end if;
END PROCESS;

PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if ((RESET = '1') OR (current_st_delayed = '1')) then
      C <= crcinit;
    elsif(((current_state = CALC) AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')
    AND (EOF_N_US = '1')) OR ((current_state = IDLE) AND (SOF_N_US = '0') AND
    (DST_RDY_N_DS = '0') AND (SRC_RDY_N_US = '0'))) then
      C <= next_CRC;
    elsif((EOF_N_US = '0') AND (SRC_RDY_N_US = '0') AND (DST_RDY_N_DS = '0')) then
      C <=  crcinit;
    end if;
  end if;
END PROCESS;
end generate c_reg_i_2;

--------------------------------------------------------------------------
--GENERATING ENABLES
--------------------------------------------------------------------------

enable_11_d_i : if (residue = '1' AND stripcrc = '1' AND
                data_width >= crc_width) generate
  PROCESS (CLK)
    begin
      if (CLK'EVENT AND CLK = '1') then
        if (RESET = '1') then
          enable <= '0';
        elsif ((EOF_N_US = '0') AND (SRC_RDY_N_US = '0') AND
              (DST_RDY_N_DS = '0')) then
          if ((REM_US + 1) <= no_of_crc_bytes) then
            enable <= '1';
          else
            enable <= '0';
          end if;
        elsif (current_state = CRC1) then
          enable <= '0';
        end if;
      end if;
  end PROCESS;
end generate enable_11_d_i;

enable_11_c_i : if (residue = '1' AND stripcrc = '1' AND
                data_width < crc_width) generate
  PROCESS (CLK)
    begin
      if (CLK'EVENT AND CLK = '1') then
        if (RESET = '1') then
          enable <= '0';
        elsif ((EOF_N_US = '0') AND (SRC_RDY_N_US = '0') AND
              (DST_RDY_N_DS = '0')) then
          if (no_of_data_bytes = (no_of_crc_bytes - REM_US - 1)) then
            enable <= '1';
          else
            enable <= '0';
          end if;
        elsif (current_st_delayed = '1' AND (DST_RDY_N_DS = '0')) then
          enable <= '0';
        end if;
      end if;
  end PROCESS;
end generate enable_11_c_i;

--------------------------------------------------------------------------
-- DST_RDY_US generation
--------------------------------------------------------------------------
dst_rdy_n_i_gen : if (back_to_back = '0') generate
PROCESS (CLK)
begin
  if (CLK'EVENT AND CLK = '1') then
    if (RESET = '1') then
      DST_RDY_N_i <= '0';
    elsif ((EOF_N_US = '0') AND (SRC_RDY_N_US = '0') AND
              (DST_RDY_N_DS = '0')) then
      DST_RDY_N_i <= '1';
    elsif (current_st_delayed = '1') then
      DST_RDY_N_i <= '0';
    end if;
  end if;
end PROCESS;
end generate dst_rdy_n_i_gen;

dst_rdy_n_b2b : if (back_to_back = '1') generate
  DST_RDY_N_i <= '0';
end generate dst_rdy_n_b2b;

--------------------------------------------------------------------------
--  End of File
--------------------------------------------------------------------------
END RX_CRC_ARCH;
