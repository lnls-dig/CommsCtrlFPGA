-------------------------------------------------------------------------------
-- 
-- $Revision: 1.9 $
-- $Date: 2003/12/31 02:15:09 $
--
-------------------------------------------------------------------------------
-- CRC Utility Functions Package
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
-- File Name: crc_functions_pkg.vhd
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

---------------------------------------------------------------------
-- Start of Package
---------------------------------------------------------------------

package crc_functions is
----------------------------------------------------------------------
-- Function Declarations
----------------------------------------------------------------------

---------------------------------------------------------------------
-- Functions to calculate
-- 1. rem width from data_width
-- 2. no. of data and crc bytes
-- 3. value of mux for default cases
---------------------------------------------------------------------
function rem_width_calc (
         data_width_in : integer)
         return integer;

function no_of_bytes_calc (
         width_in : integer)
         return std_logic_vector;

function mux_value_lookup(
         data_width_in : integer;
         rwidth        : integer)
         return std_logic_vector;

-- Function to transpose CRC & Data
function transpose_input (
         inp : std_logic_vector)
         return std_logic_vector;

-- Byte Shifter for Data allignment
function bshifter_left (
         din        : std_logic_vector;
         shift_by   : std_logic_vector)
         return std_logic_vector;

-- Byte Shifter for Data allignment
function bshifter_right (
         din        : std_logic_vector;
         shift_by   : std_logic_vector)
         return std_logic_vector;

-- CRC Calculation Function
function next_crc32_data1_crc (
         C1   : std_logic_vector;
         B    : std_logic;
         poly : std_logic_vector)
         return std_logic_vector;

-- CRC Calcalation for all-valid Data
function next_crc_data (
         C2    : std_logic_vector;
         DATA2 : std_logic_vector;
         poly  : std_logic_vector)
         return std_logic_vector;

function next_crc_data_be (
         CRC  : std_logic_vector;
         DATA : std_logic_vector;
         poly : std_logic_vector)
         return std_logic_vector;

function mux_param (
          mux_in  : std_logic_vector;
          mux_sel : std_logic_vector;
          CWIDTH  : integer;
          DWIDTH  : integer)
          return std_logic_vector;

-- Function to append zeros
function to_function  (
         crc : std_logic_vector;
         dwidth : integer)
         return std_logic_vector;

end crc_functions;

----------------------------------------------------------------------
-- Package Body
----------------------------------------------------------------------


package body crc_functions is

---------------------------------------------------------------------
-- Functions to calculate  rem width from data_width
---------------------------------------------------------------------
function rem_width_calc (
         data_width_in : integer)
         return integer is
variable rem_width  : integer;
begin
  case data_width_in is
    when 128 =>
           rem_width := 4;

    when 120 =>
           rem_width := 4;

    when 112 =>
           rem_width := 4;

    when 104 =>
           rem_width := 4;

    when 96 =>
           rem_width := 4;

    when 88 =>
           rem_width := 4;

    when 80 =>
           rem_width := 4;

    when 72 =>
           rem_width := 4;

    when 64 =>
           rem_width := 3;

    when 56 =>
           rem_width := 3;

    when 48 =>
           rem_width := 3;

    when 40 =>
           rem_width := 3;

    when 32 =>
           rem_width := 2;

    when 24 =>
           rem_width := 2;

    when 16 =>
           rem_width := 1;

    when 8 =>
           rem_width := 1;

    when others =>
             NULL;

   end case;
   return(rem_width);
 end rem_width_calc;

---------------------------------------------------------------------
-- Functions to calculate  rem width from data_width
---------------------------------------------------------------------
 function no_of_bytes_calc (
           width_in : integer)
           return std_logic_vector is
 variable no_of_bytes : std_logic_vector(4 downto 0);
 begin
   case width_in is
     when 128 =>
             no_of_bytes := "10000";

     when 120 =>
             no_of_bytes := "01111";

     when 112 =>
             no_of_bytes := "01110";

     when 104 =>
             no_of_bytes := "01101";

     when 96 =>
             no_of_bytes := "01100";

     when 88 =>
             no_of_bytes := "01011";

     when 80 =>
             no_of_bytes := "01010";

     when 72 =>
             no_of_bytes := "01001";

     when 64 =>
             no_of_bytes := "01000";

     when 56 =>
             no_of_bytes := "00111";

     when 48 =>
             no_of_bytes := "00110";

     when 40 =>
             no_of_bytes := "00101";

     when 32 =>
             no_of_bytes := "00100";

     when 24 =>
             no_of_bytes := "00011";

     when 16 =>
             no_of_bytes := "00010";

     when 8  =>
             no_of_bytes := "00001";

     when others =>
             NULL;
    end case;
    return(no_of_bytes);
  end no_of_bytes_calc;

---------------------------------------------------------------------
-- Functions to look up  default value of mux
---------------------------------------------------------------------

  function mux_value_lookup(
         data_width_in : integer;
         rwidth        : integer)
         return std_logic_vector is
  variable mux_value : std_logic_vector(rwidth-1 DOWNTO 0);
  begin
    case data_width_in is
    when 8|16|32|64|128 =>
            mux_value := (others => '1');

    when 120 =>
            mux_value := "1110";

    when 112 =>
            mux_value := "1101";

    when 104 =>
            mux_value := "1100";

    when 96 =>
            mux_value := "1011";

    when 88 =>
            mux_value := "1010";

    when 80 =>
            mux_value := "1001";

    when 72 =>
            mux_value := "1000";

    when 56 =>
            mux_value := "110";

    when 48 =>
            mux_value := "101";

    when 40 =>
            mux_value := "100";

    when 24 =>
            mux_value := "10";

    when others =>
            NULL;
    end case;
    return(mux_value);
  end mux_value_lookup;

----------------------------------------------------------------------
-- Function for Transposing
----------------------------------------------------------------------

function transpose_input (
         inp : std_logic_vector)
         return std_logic_vector is
constant width       : integer := inp'length;
variable transpose   : std_logic_vector(width - 1 downto 0);
begin
  for n in 0 to ((width/8) - 1) loop
    for l in 0 to 7 loop
      transpose((8*n) + 7 - l) := inp((n*8) + l);
    end loop;
  end loop;
  return(transpose);
end transpose_input;

----------------------------------------------------------------------
-- Functions for Data Allignment
----------------------------------------------------------------------

function bshifter_left (
         din        : std_logic_vector;
         shift_by   : std_logic_vector)
         return std_logic_vector is

  constant shift_size           :  integer := 8;
  constant width                :  integer := din'length;
  variable barrel_shifter_next  :  std_logic_vector(width - 1 downto 0);
  variable barrel_shifter       :  std_logic_vector(width - 1 downto 0);
begin
  for k in 0 to (width - 1) loop
    barrel_shifter_next(k) :=
      din((k +  (conv_integer(shift_by)+1)*shift_size) mod (width));
  end loop;
  return(barrel_shifter_next);
end bshifter_left;

function bshifter_right (
         din        : std_logic_vector;
         shift_by   : std_logic_vector)
         return std_logic_vector is

  constant shift_size           :  integer := 8;
  constant width                :  integer := din'length;
  variable barrel_shifter_next  :  std_logic_vector(width - 1 downto 0);
  variable barrel_shifter       :  std_logic_vector(width - 1 downto 0);
begin
  for k in 0 to (width - 1) loop
    barrel_shifter_next((k + (conv_integer(shift_by)+1)*shift_size) mod (width))
      := din(k);
  end loop;
  return(barrel_shifter_next);
end bshifter_right;

----------------------------------------------------------------------
-- Functions for CRC Calculation
----------------------------------------------------------------------

function next_crc32_data1_crc (
         C1   : std_logic_vector;
         B    : std_logic;
         poly : std_logic_vector)
         return std_logic_vector is --remainder of m(x)*x^32/p(x)
constant cwidth           : integer := C1'length;
variable next_crc32_data1 : std_logic_vector(cwidth-1 DOWNTO 0); -- previous crc value
variable temp_crc         : std_logic_vector(cwidth-1 DOWNTO 0); -- input data bit (msb first)
begin
  temp_crc         := (others => ((C1(C1'left))xor B));
  next_crc32_data1 :=
  ((C1( (C1'left)-1 DOWNTO C1'right)) & '0') xor (temp_crc AND poly);
  return(next_crc32_data1);
end next_crc32_data1_crc;

-- Function for CRC Calculation	for all-valid Data
function next_crc_data (
         C2    : std_logic_vector;
         DATA2 : std_logic_vector;
         poly  : std_logic_vector)
         return std_logic_vector is
constant cwidth            : integer :=  C2'length;
constant dwidth            : integer :=  DATA2'length;
variable next_crc32_data32 : std_logic_vector(cwidth-1 DOWNTO 0);
begin
  next_crc32_data32 :=  C2;
  for i in 0 to dwidth-1 loop
    next_crc32_data32 :=
       next_crc32_data1_crc(next_crc32_data32,DATA2(dwidth-1-i),poly);
  end loop;
  return (next_crc32_data32);
end next_crc_data;

-- Function for CRC Calculation
function next_crc_data_be (
         CRC  : std_logic_vector;
         DATA : std_logic_vector;
         poly : std_logic_vector)
         return std_logic_vector is

  constant dwidth   : integer   := DATA'length;
  constant cwidth   : integer   := CRC'length;
  variable next_crc : std_logic_vector(cwidth*dwidth/8-1 DOWNTO 0);

begin
  for i in 0 to (next_crc'length)-1 loop
    next_crc(i) := CRC( (i mod cwidth) + CRC'right);
  end loop;

  for i in 0 to (DATA'length)/8 - 1 loop
    for j in 0 to ((i+1)*8)-1 loop
      next_crc((i+1)*cwidth-1 downto i*cwidth) := next_crc32_data1_crc(next_crc((i+1)*cwidth-1 downto i*cwidth),DATA(dwidth-1-j),poly);
    end loop;
  end loop;
 return (next_crc);
end next_crc_data_be;

function mux_param (
          mux_in  : std_logic_vector;
          mux_sel : std_logic_vector;
          CWIDTH  : integer;
          DWIDTH  : integer)
          return std_logic_vector is
  variable mux_out : std_logic_vector(CWIDTH-1 downto 0);
begin
  for i in 0 to CWIDTH-1 loop
    mux_out(i) := mux_in(CWIDTH * conv_integer(mux_sel) + i);
  end loop;
  return (mux_out);
end mux_param;

----------------------------------------------------------------------
-- Other Functions
----------------------------------------------------------------------

function to_function (
         crc    : std_logic_vector;
         dwidth : integer)
         return std_logic_vector is
constant cwidth      : integer := crc'length;
variable to_function        : std_logic_vector(dwidth - 1 downto 0);
variable gnd_bus  : std_logic_vector(dwidth-1 downto 0) := (others => '0');
begin
  to_function := crc(cwidth-1 downto 0) & gnd_bus(dwidth-1 downto cwidth);
  return(to_function);
end to_function;

----------------------------------------------------------------------
-- End of Package
----------------------------------------------------------------------

end crc_functions;
