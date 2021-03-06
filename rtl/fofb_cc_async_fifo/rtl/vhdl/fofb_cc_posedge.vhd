--------------------------------------------------------------------------------
-- CERN BE-CO-HT
-- General Cores Library
-- https://www.ohwr.org/projects/general-cores
--------------------------------------------------------------------------------
--
-- unit name:   gc_posedge
--
-- description: Simple rising edge detector.  Combinatorial.
--
--------------------------------------------------------------------------------
-- Copyright CERN 2020
--------------------------------------------------------------------------------
-- Copyright and related rights are licensed under the Solderpad Hardware
-- License, Version 2.0 (the "License"); you may not use this file except
-- in compliance with the License. You may obtain a copy of the License at
-- http://solderpad.org/licenses/SHL-2.0.
-- Unless required by applicable law or agreed to in writing, software,
-- hardware and materials distributed under this License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
-- or implied. See the License for the specific language governing permissions
-- and limitations under the License.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity fofb_cc_posedge is
  port(
    clk_i   : in  std_logic;   -- clock
    rst_n_i : in  std_logic;   -- reset
    data_i  : in  std_logic;   -- input
    pulse_o : out std_logic);  -- positive edge detect output
end entity fofb_cc_posedge;

architecture arch of fofb_cc_posedge is
  signal dff : std_logic;
begin
  pulse_o <= data_i and not dff;

  process (clk_i)
  begin
    if rising_edge (clk_i) then
      if rst_n_i = '0' then
        dff <= '0';
      else
        dff <= data_i;
      end if;
    end if;
  end process;
end arch;
