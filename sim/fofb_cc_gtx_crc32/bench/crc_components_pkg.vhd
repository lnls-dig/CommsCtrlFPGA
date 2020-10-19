-------------------------------------------------------------------------------
-- 
-- $Revision: 1.9 $
-- $Date: 2003/12/31 02:15:09 $
--
-------------------------------------------------------------------------------
-- CRC Components Package
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
-- File Name: crc_components_pkg.vhd
-- Author: Nanditha Jayarajan
-- Contributors: Chris Borrelli
--
-- Description:
-- This package contains all the component declarations

---------------------------------------------------------------------
-- Library Declarations
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use ieee.numeric_bit.all;

---------------------------------------------------------------------
-- Start of Package
---------------------------------------------------------------------

package crc_components is

TYPE t_state  is  (IDLE,CALC,CRC,CRC1);

component TX_CRC
GENERIC
  (
 -- Data Width  : Legal Values :  8,16,32,64
    data_width                     :  integer := 16;

 -- CRC Width   : Legal Values :  8,16.32,64
    crc_width                      :  integer := 32;

 -- REM Width   : Calculated from data_width
 --  rem_width                      :  integer := rem_width_calc(data_width);

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
END component;

component RX_CRC
GENERIC
  (
  -- Data Width  : Legal Values    :  8,16,32,64
    data_width                   :  integer := 16;

  -- CRC Width   : Legal Values   :  8,16.32,64
    crc_width                    :  integer := 32;

  -- REM Width   : Calculated from data_width
  -- rem_width                    :  integer := rem_width_calc(data_width);

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

  -- Number of Data Bytes : This value is calculated
  -- from the Data Width
 --   no_of_data_bytes             :  std_logic_vector(4  DOWNTO 0)
--                                 := no_of_bytes_calc(data_width);

  -- Number of CRC Bytes : This value is calculated
  -- from the CRC Width
  --  no_of_crc_bytes              :  std_logic_vector(4  DOWNTO 0)
  --                               := no_of_bytes_calc(crc_width);

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
END component;

component DATA_DS_DRIV_DST
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
end component;


component CRC_GEN
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
end component;

component TX_CRC_GEN_1
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    insertcrc                      :  std_logic := '0';
    alligned_data                  :  std_logic := '1';
    trandata                       :  std_logic := '1';
    trancrc                        :  std_logic := '1';
    compcrc                        :  std_logic := '1';
    crcinit                        :  std_logic_vector
                                   := "11111111111111111111111111111111";

    rem_width                      :  integer := 3;
    residue_value                  :  std_logic_vector
                                   := "11000111000001001101110101111011";

    no_of_data_bytes               :  std_logic_vector(4 DOWNTO 0)
                                   := "01000";

    no_of_crc_bytes                :  std_logic_vector(4 DOWNTO 0)
                                   := "00100");
PORT
  (
    next_CRC                       :  OUT std_logic_vector(crc_width-1  DOWNTO 0);
    current_state                  :  IN t_state;
    EOF_N_US                       :  IN std_logic;
    SRC_RDY_N_US                   :  IN std_logic;
    SRC_RDY_N_DS_i                 :  IN std_logic;
    DST_RDY_N_DS                   :  IN std_logic;
    REM_US                         :  IN std_logic_vector(rem_width-1   DOWNTO 0);
    REM_i                          :  IN std_logic_vector(rem_width-1   DOWNTO 0);
    DATA                           :  IN std_logic_vector(data_width-1  DOWNTO 0);
    C                              :  IN std_logic_vector(crc_width-1   DOWNTO 0);
    enable                         :  IN std_logic;
    enable1                        :  IN std_logic
  );
end component;

component RX_CRC_GEN
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    alligned_data                  :  std_logic := '1';
    residue                        :  std_logic := '1';
    stripcrc                       :  std_logic := '1';
    trandata                       :  std_logic := '1';
    trancrc                        :  std_logic := '1';
    compcrc                        :  std_logic := '1';
    crcinit                        :  std_logic_vector
                                   := "11111111111111111111111111111111";

    rem_width                      :  integer := 3;
    residue_value                  :  std_logic_vector(31 DOWNTO 0)
                                   := "11000111000001001101110101111011";

    no_of_data_bytes               :  std_logic_vector(4 DOWNTO 0)
                                   := "00100";

    no_of_crc_bytes                :  std_logic_vector(4 DOWNTO 0)
                                   := "00100"
  );
PORT
  (
    next_CRC_00 		   :  OUT std_logic_vector(crc_width-1  DOWNTO 0);
    next_CRC_01 		   :  OUT std_logic_vector(crc_width-1  DOWNTO 0);
    next_CRC_10 		   :  OUT std_logic_vector(crc_width-1  DOWNTO 0);
    next_CRC_11 		   :  OUT std_logic_vector(crc_width-1  DOWNTO 0);
    next_CRC_100                   :  OUT std_logic_vector(crc_width-1  DOWNTO 0);
    next_CRC_101                   :  OUT std_logic_vector(crc_width-1  DOWNTO 0);
    next_CRC_110                   :  OUT std_logic_vector(crc_width-1  DOWNTO 0);
    next_CRC_111                   :  OUT std_logic_vector(crc_width-1  DOWNTO 0);
    next_CRC_i                     :  OUT std_logic_vector(crc_width-1  DOWNTO 0);
    current_state                  :  IN t_state;
    SOF_N_US                       :  IN std_logic;
    EOF_N_US                       :  IN std_logic;
    SRC_RDY_N_US                   :  IN std_logic;
    DST_RDY_N_DS                   :  IN std_logic;
    REM_US                         :  IN std_logic_vector(rem_width-1   DOWNTO 0);
    DATA                           :  IN std_logic_vector(data_width-1 DOWNTO 0);
    C                              :  IN std_logic_vector(crc_width-1 DOWNTO 0);
    CLK                            :  IN std_logic;
    current_state_delayed          :  IN std_logic;
    RESET                          :  IN std_logic
  );
end component;

component RX_CRC_GEN_1
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    alligned_data                  :  std_logic := '1';
    residue                        :  std_logic := '1';
    stripcrc                       :  std_logic := '1';
    trandata                       :  std_logic := '1';
    trancrc                        :  std_logic := '1';
    compcrc                        :  std_logic := '1';
    crcinit                        :  std_logic_vector
                                   := "11111111111111111111111111111111";

    rem_width                      :  integer := 3;
    residue_value                  :  std_logic_vector
                                   := "11000111000001001101110101111011";

    no_of_data_bytes               :  std_logic_vector(4 DOWNTO 0)
                                   := "01000";

    no_of_crc_bytes                :  std_logic_vector(4 DOWNTO 0)
                                   := "00100");
PORT
  (
    next_CRC                       :  OUT std_logic_vector(crc_width-1  DOWNTO 0);
    current_state                  :  IN t_state;
    EOF_N_US                       :  IN std_logic;
    SRC_RDY_N_US                   :  IN std_logic;
    SRC_RDY_N_DS_i                 :  IN std_logic;
    DST_RDY_N_DS                   :  IN std_logic;
    REM_US                         :  IN std_logic_vector(rem_width-1   DOWNTO 0);
    DATA                           :  IN std_logic_vector(data_width-1 DOWNTO 0);
    C                              :  IN std_logic_vector(crc_width-1 DOWNTO 0)
  );
end component;

component STATE_MACHINE_DST_D
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    insertcrc                      :  std_logic := '1';
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
    next_state                     :  OUT t_state;
    current_state                  :  IN  t_state;
    SOF_N_US                       :  IN  std_logic;
    EOF_N_US                       :  IN  std_logic;
    SRC_RDY_N_US                   :  IN  std_logic;
    DST_RDY_N_DS                   :  IN  std_logic;
    REM_i                          :  IN  std_logic_vector(rem_width-1   DOWNTO 0);
    enable                         :  IN  std_logic
  );
end component;

component STATE_MACHINE_DST_C
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    insertcrc                      :  std_logic := '1';
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
                                   := "00100");
PORT
  (
    next_state                     :  OUT t_state;
    current_state                  :  IN  t_state;
    SOF_N_US                       :  IN  std_logic;
    EOF_N_US                       :  IN  std_logic;
    SRC_RDY_N_US                   :  IN  std_logic;
    DST_RDY_N_DS                   :  IN  std_logic;
    REM_i                          :  IN  std_logic_vector(rem_width-1   DOWNTO 0);
    enable                         :  IN  std_logic
  );
end component;


component STATE_MACHINE_PAD_D
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    insertcrc                      :  std_logic := '1';
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
                                   := "00100");
PORT
  (
    next_state                     :  OUT t_state;
    current_state                  :  IN  t_state;
    SOF_N_DS_i                     :  IN  std_logic;
    EOF_N_US                       :  IN  std_logic;
    SRC_RDY_N_US                   :  IN  std_logic;
    SRC_RDY_N_DS_i                 :  IN  std_logic;
    DST_RDY_N_DS                   :  IN  std_logic;
    REM_i                          :  IN  std_logic_vector(rem_width-1   DOWNTO 0);
    enable                         :  IN  std_logic
  );
end component;

component STATE_MACHINE_PAD_C
GENERIC
  (
     data_width                     :  integer := 32;
     crc_width                      :  integer := 32;
     poly                           :  std_logic_vector
                                    := "00000100110000010001110110110111";

     insertcrc                      :  std_logic := '1';
     trandata                       :  std_logic := '1';
     trancrc                        :  std_logic := '1';
     compcrc                        :  std_logic := '1';
     crcinit                        :  std_logic_vector
                                    := "11111111111111111111111111111111";

     rem_width                      :  integer := 2;
     residue_value                  :  std_logic_vector
                                    := "11000111000001001101110101111011";

     no_of_data_bytes               :  std_logic_vector(4 DOWNTO 0)
                                    := "00100";

     no_of_crc_bytes                :  std_logic_vector(4 DOWNTO 0)
                                    := "00100");
 PORT
   (
     next_state                     :  OUT t_state;
     current_state                  :  IN  t_state;
     SOF_N_DS_i                     :  IN  std_logic;
     EOF_N_US                       :  IN  std_logic;
     SRC_RDY_N_US                   :  IN  std_logic;
     SRC_RDY_N_DS_i                 :  IN  std_logic;
     DST_RDY_N_DS                   :  IN  std_logic;
     REM_i                          :  IN  std_logic_vector(rem_width-1   DOWNTO 0);
     enable                         :  IN  std_logic
   );
 end component;

 component STATE_MACHINE_DST_D_LAT3
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    insertcrc                      :  std_logic := '1';
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
    next_state                     :  OUT t_state;
    current_state                  :  IN  t_state;
    SOF_N_US                       :  IN  std_logic;
    EOF_N_US_i                     :  IN  std_logic;
    SRC_RDY_N_US                   :  IN  std_logic;
    SRC_RDY_N_DS_i                 :  IN  std_logic;
    DST_RDY_N_DS                   :  IN  std_logic;
    REM_i                          :  IN  std_logic_vector(rem_width-1   DOWNTO 0);
    enable                         :  IN  std_logic
  );
  end component;

component STATE_MACHINE_DST_C_LAT3
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    insertcrc                      :  std_logic := '1';
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
    next_state                     :  OUT t_state;
    current_state                  :  IN  t_state;
    SOF_N_US                       :  IN  std_logic;
    EOF_N_US_i                     :  IN  std_logic;
    SRC_RDY_N_US                   :  IN  std_logic;
    SRC_RDY_N_DS_i                 :  IN  std_logic;
    DST_RDY_N_DS                   :  IN  std_logic;
    REM_i                          :  IN  std_logic_vector(rem_width-1   DOWNTO 0);
    enable                         :  IN  std_logic
  );
end component;

component STATE_MACHINE_DST
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
end component;

component REM_DS_DRIV_DST
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
                                 := "00100");
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
end component;

component STATE_MACHINE_RES
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    residue                        :  std_logic := '1';
    stripcrc                       :  std_logic := '1';
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
    next_state                     :  OUT t_state;
    current_state                  :  IN  t_state;
    SOF_N_US                       :  IN  std_logic;
    EOF_N_US                       :  IN  std_logic;
    SRC_RDY_N_US                   :  IN  std_logic;
    DST_RDY_N_DS                   :  IN  std_logic
  );
end component;

component STATE_MACHINE_RES_S_D
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    residue                        :  std_logic := '1';
    stripcrc                       :  std_logic := '1';
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
    next_state                     :  OUT t_state;
    current_state                  :  IN  t_state;
    SOF_N_US                       :  IN  std_logic;
    EOF_N_US                       :  IN  std_logic;
    SRC_RDY_N_US                   :  IN  std_logic;
    DST_RDY_N_DS                   :  IN  std_logic
  );
end component;

component STATE_MACHINE_RES_S_C
GENERIC
  (
     data_width                     :  integer := 64;
     crc_width                      :  integer := 32;
     poly                           :  std_logic_vector
                                    := "00000100110000010001110110110111";

     residue                        :  std_logic := '1';
     stripcrc                       :  std_logic := '1';
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
 next_state                     :  OUT t_state;
 current_state                  :  IN  t_state;
 SOF_N_US                       :  IN  std_logic;
 EOF_N_US                       :  IN  std_logic;
 SRC_RDY_N_US                   :  IN  std_logic;
 DST_RDY_N_DS                   :  IN  std_logic
   );
 end component;

 component STATE_MACHINE_NORES_S_C
 generic
   (
     data_width                     :  integer := 64;
     crc_width                      :  integer := 32;
     poly                           :  std_logic_vector
                                    := "00000100110000010001110110110111";

     residue                        :  std_logic := '1';
     stripcrc                       :  std_logic := '1';
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
 port
   (
     next_state                     :  OUT t_state;
     current_state                  :  IN  t_state;
     SOF_N_DS_SRL                   :  IN  std_logic;
     EOF_N_US                       :  IN  std_logic;
     SRC_RDY_N_US                   :  IN  std_logic;
     SRC_RDY_N_DS_SRL               :  IN  std_logic;
     DST_RDY_N_DS                   :  IN  std_logic;
     enable1                        :  IN  std_logic
   );
end component;

component STATE_MACHINE_NORES_S_D
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    residue                        :  std_logic := '1';
    stripcrc                       :  std_logic := '1';
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
    next_state                     :  OUT t_state;
    current_state                  :  IN  t_state;
    SOF_N_DS_i                     :  IN  std_logic;
    EOF_N_US                       :  IN  std_logic;
    SRC_RDY_N_DS_i                 :  IN  std_logic;
    SRC_RDY_N_US                   :  IN  std_logic;
    DST_RDY_N_DS                   :  IN  std_logic
  );
end component;


component STATE_MACHINE_NORES_NS_C
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    residue                        :  std_logic := '1';
    stripcrc                       :  std_logic := '1';
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
    next_state                     :  OUT t_state;
    current_state                  :  IN  t_state;
    SOF_N_DS_SRL                   :  IN  std_logic;
    EOF_N_US                       :  IN  std_logic;
    SRC_RDY_N_US                   :  IN  std_logic;
    SRC_RDY_N_DS_SRL               :  IN  std_logic;
    DST_RDY_N_DS                   :  IN  std_logic;
    enable1                        :  IN  std_logic
  );
end component;



component CRC_VALID_GEN_RES_NSANDS_CD
generic
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

    no_of_data_bytes               :  std_logic_vector(4 DOWNTO 0)
                                   := "00100";

    no_of_crc_bytes                :  std_logic_vector(4 DOWNTO 0)
                                   := "00100"
  );
port
  (
    CRC_PASS_FAIL_N    : OUT std_logic;
    CRC_VALID          : OUT std_logic;
    current_state      : IN  t_state;
    current_st_delayed : IN std_logic;
    C                  : IN  std_logic_vector(crc_width-1 downto 0);
    CLK                : IN  std_logic;
    RESET              : IN std_logic
  );
end component;

component CRC_VALID_GEN_NORES_S_D
generic
  (
    data_width                     :  integer := 32;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    insertcrc                      :  std_logic := '1';
    trandata                       :  std_logic := '1';
    trancrc                        :  std_logic := '1';
    compcrc                        :  std_logic := '1';
    crcinit                        :  std_logic_vector
                                   := "11111111111111111111111111111111";

    rem_width                      :  integer := 2;
    residue_value                  :  std_logic_vector
                                   := "11000111000001001101110101111011";

    no_of_data_bytes               :  std_logic_vector(4 DOWNTO 0)
                                   := "00100";

    no_of_crc_bytes                :  std_logic_vector(4 DOWNTO 0)
                                   := "00100"
  );
port
  (
    CRC_PASS_FAIL_N  : OUT std_logic;
    CRC_VALID        : OUT std_logic;
    current_state    : IN  t_state;
    enable           : IN  std_logic;
    enable1          : IN  std_logic;
    REM_i            : IN  std_logic_vector(rem_width-1 downto 0);
    REM_DS           : IN  std_logic_vector(rem_width-1 downto 0);
    final_crc        : IN  std_logic_vector(crc_width-1 downto 0);
    CHECK_CRC        : IN  std_logic_vector(crc_width-1 downto 0);
    DATA_DS          : IN  std_logic_Vector(data_width-1 downto 0);
    CLK              : IN  std_logic;
    RESET            : IN  std_logic
  );
end component;

component CRC_VALID_GEN_NORES_S_C
generic
  (
    data_width                     :  integer := 32;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    insertcrc                      :  std_logic := '1';
    trandata                       :  std_logic := '1';
    trancrc                        :  std_logic := '1';
    compcrc                        :  std_logic := '1';
    crcinit                        :  std_logic_vector
                                   := "11111111111111111111111111111111";

    rem_width                      :  integer := 2;
    residue_value                  :  std_logic_vector
                                   := "11000111000001001101110101111011";

    no_of_data_bytes               :  std_logic_vector(4 DOWNTO 0)
                                   := "00100";

    no_of_crc_bytes                :  std_logic_vector(4 DOWNTO 0)
                                   := "00100"
  );
port
  (
    CRC_PASS_FAIL_N  : OUT std_logic;
    CRC_VALID        : OUT std_logic;
    current_state    : IN  t_state;
    final_crc        : IN  std_logic_vector(crc_width-1 downto 0);
    CHECK_CRC        : IN  std_logic_vector(crc_width-1 downto 0);
    enable3          : IN  std_logic;
    CLK              : IN  std_logic;
    RESET            : IN  std_logic
  );
END component;

component CRC_VALID_GEN_NORES_NS_C
GENERIC
  (
    data_width                     :  integer := 32;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    insertcrc                      :  std_logic := '1';
    trandata                       :  std_logic := '1';
    trancrc                        :  std_logic := '1';
    compcrc                        :  std_logic := '1';
    crcinit                        :  std_logic_vector
                                   := "11111111111111111111111111111111";

    rem_width                      :  integer := 2;
    residue_value                  :  std_logic_vector
                                   := "11000111000001001101110101111011";

    no_of_data_bytes               :  std_logic_vector(4 DOWNTO 0)
                                   := "00100";

    no_of_crc_bytes                :  std_logic_vector(4 DOWNTO 0)
                                   := "00100"
  );
PORT
  (
    CRC_PASS_FAIL_N  : OUT std_logic;
    CRC_VALID        : OUT std_logic;
    current_state    : IN  t_state;
    final_crc        : IN  std_logic_vector(crc_width-1 downto 0);
    CHECK_CRC        : IN  std_logic_vector(crc_width-1 downto 0);
    CLK              : IN  std_logic;
    RESET            : IN  std_logic
  );
END component;

component RX_CRC_GEN_2
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    alligned_data                  :  std_logic := '0';
    residue                        :  std_logic := '0';
    stripcrc                       :  std_logic := '0';
    trandata                       :  std_logic := '1';
    trancrc                        :  std_logic := '1';
    compcrc                        :  std_logic := '1';
    crcinit                        :  std_logic_vector
                                   := "11111111111111111111111111111111";

    rem_width                      :  integer := 3;
    residue_value                  :  std_logic_vector
                                   := "11000111000001001101110101111011";

    no_of_data_bytes               :  std_logic_vector(4 DOWNTO 0)
                                   := "01000";

    no_of_crc_bytes                :  std_logic_vector(4 DOWNTO 0)
                                   := "00100"
  );
PORT
  (
    next_CRC                       :  OUT std_logic_vector(crc_width-1  DOWNTO 0);
    current_state                  :  IN t_state;
    EOF_N_US                       :  IN std_logic;
    SRC_RDY_N_US                   :  IN std_logic;
    SRC_RDY_N_DS_i                 :  IN std_logic;
    DST_RDY_N_DS                   :  IN std_logic;
    REM_US                         :  IN std_logic_vector(rem_width-1   DOWNTO 0);
    REM_i                          :  IN std_logic_vector(rem_width-1   DOWNTO 0);
    DATA                           :  IN std_logic_vector(data_width-1  DOWNTO 0);
    C                              :  IN std_logic_vector(crc_width-1   DOWNTO 0);
    enable                         :  IN std_logic
);
end component;

component STATE_MACHINE_RES_NOT_AL
GENERIC
  (
    data_width                     :  integer := 64;
    crc_width                      :  integer := 32;
    poly                           :  std_logic_vector
                                   := "00000100110000010001110110110111";

    residue                        :  std_logic := '1';
    stripcrc                       :  std_logic := '1';
    trandata                       :  std_logic := '1';
    trancrc                        :  std_logic := '1';
    compcrc                        :  std_logic := '1';
    crcinit                        :  std_logic_vector
                                   := "11111111111111111111111111111111";

    rem_width                      :  integer := 3;
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
    EOF_N_US_i                     :  IN  std_logic;
    SRC_RDY_N_US                   :  IN  std_logic;
    SRC_RDY_N_DS_i                 :  IN  std_logic;
    DST_RDY_N_DS                   :  IN  std_logic
  );
end component;

component STATE_MACHINE_RX
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
end component;

---------------------------------------------------------------------
-- End of Package
---------------------------------------------------------------------

end crc_components;
