--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   21:20:47 02/10/2006
-- Design Name:   fofb_cc_fa_intf
-- Module Name:   FastFeedbackFPGA_v1_00\sim\fofb_cc_fa_interface\sim\vhdl\bench\fofb_cc_fa_intf_tb.vhd
-- Project Name:  fai
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fofb_cc_fa_intf
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

ENTITY fofb_cc_fa_intf_loopback_tb IS
END fofb_cc_fa_intf_loopback_tb;

ARCHITECTURE behavior OF fofb_cc_fa_intf_loopback_tb IS 

-- Component Declaration for the Unit Under Test (UUT)
component fofb_cc_top_loopback is
   port (
		adc_clk					: in std_logic;						
		adc_rst					: in std_logic;

		fai_fa_block_start	: in std_logic; 
		fai_fa_data_valid		: in std_logic;
		fai_fa_d					: in std_logic_vector(15 downto 0); 
		
		fai_cfg_a				: out std_logic_vector(10 downto 0); 		
		fai_cfg_do				: out std_logic_vector(31 downto 0); 		
		fai_cfg_di				: in  std_logic_vector(31 downto 0); 		
		fai_cfg_we				: out std_logic;									
		fai_cfg_clk				: out std_logic;  								
		fai_cfg_val				: in  std_logic_vector(31 downto 0)
);
end component;

component fai_emulator
port ( 
	ClkADC			: in std_logic;
	Reset				: in std_logic;
	TimeFrameStart : in std_logic;
	BlockStart 	 	: out std_logic;
	DataValid 		: out std_logic;
	FAData 		 	: out std_logic_vector(15 downto 0)
);
end component; 

	--Inputs
	SIGNAL adc_clk 	:  std_logic := '0';
	SIGNAL adc_rst 	:  std_logic := '1';
	SIGNAL BlockStart :  std_logic := '0';
	SIGNAL DataValid 	:  std_logic := '0';
	SIGNAL FAData 		:  std_logic_vector(15 downto 0) := (others=>'0');

	--Outputs
	SIGNAL TimeFrameStart 	:  std_logic;
	SIGNAL pos_wen	 		:  std_logic;
	SIGNAL pos_dout		 	:  std_logic_vector(31 downto 0);
	SIGNAL TimeFrameStart_i : std_logic := '0';

BEGIN
	
	mgt_clk	<= not mgt_clk after 5 ns;
	adc_clk	<= not adc_clk after 4 ns;
	adc_rst	<= '0' after 100 ns;

	-- Instantiate the Unit Under Test (UUT)
	uut: fofb_cc_fa_intf_loopback 
	
	PORT MAP(
		mgt_clk 			=> mgt_clk,
		adc_clk 			=> adc_clk,
		adc_rst 			=> adc_rst,
		mgt_rst 			=> mgt_rst,
		BlockStart 		=> BlockStart,
		DataValid 		=> DataValid,
		FAData 			=> FAData,
		TimeFrameStart => TimeFrameStart,
		pos_dout			=> pos_dout,
		pos_wen			=> pos_wen
	);

  emulator : fai_emulator
  PORT MAP (
	  	ClkADC			   => adc_clk,
   	Reset					=> adc_rst,
		TimeFrameStart 	=> TimeFrameStart_i,
 		BlockStart 	 	 	=> BlockStart,
 		DataValid 		   => DataValid,
 		FAData 			   => FAData
  );

	tb : PROCESS
	BEGIN
		wait for 300 ns;
			TimeFrameStart_i <= '1';
		wait for 100 ns;
			TimeFrameStart_i <= '0';
		wait for 3000 ns;
			TimeFrameStart_i <= '1';
		wait for 100 ns;
			TimeFrameStart_i <= '0';

		wait; -- will wait forever
	END PROCESS;

END;
