LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

ENTITY fofb_cc_top_loopback_tb IS
END fofb_cc_top_loopback_tb;

ARCHITECTURE behavior OF fofb_cc_top_loopback_tb IS 

-- Component Declaration for the Unit Under Test (UUT)
COMPONENT fofb_cc_top_loopback
PORT(
	adc_clk : IN std_logic;
	adc_rst : IN std_logic;
	fai_fa_block_start : IN std_logic;
	fai_fa_data_valid : IN std_logic;
	fai_fa_d : IN std_logic_vector(15 downto 0);
	fai_cfg_di : IN std_logic_vector(31 downto 0);
	fai_cfg_val : IN std_logic_vector(31 downto 0);          
	fai_cfg_a : OUT std_logic_vector(10 downto 0);
	fai_cfg_do : OUT std_logic_vector(31 downto 0);
	fai_cfg_we : OUT std_logic;
	fai_cfg_clk : OUT std_logic
	);
END COMPONENT;

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
	SIGNAL adc_clk :  std_logic := '0';
	SIGNAL adc_rst :  std_logic := '1';
	SIGNAL fai_fa_block_start :  std_logic := '0';
	SIGNAL fai_fa_data_valid :  std_logic := '0';
	SIGNAL fai_fa_d :  std_logic_vector(15 downto 0) := (others=>'0');
	SIGNAL fai_cfg_di :  std_logic_vector(31 downto 0) := (others=>'0');
	SIGNAL fai_cfg_val :  std_logic_vector(31 downto 0) := X"00000000";

	--Outputs
	SIGNAL fai_cfg_a :  std_logic_vector(10 downto 0);
	SIGNAL fai_cfg_do :  std_logic_vector(31 downto 0);
	SIGNAL fai_cfg_we :  std_logic;
	SIGNAL fai_cfg_clk :  std_logic;
	
	SIGNAL TimeFrameStart_i : std_logic := '0';

BEGIN

	adc_clk	<= not adc_clk after 4 ns;
	adc_rst	<= '0' after 100 ns;
	
	-- Instantiate the Unit Under Test (UUT)
	uut: fofb_cc_top_loopback PORT MAP(
		adc_clk 					=> adc_clk,
		adc_rst 					=> adc_rst,
		fai_fa_block_start 	=> fai_fa_block_start,
		fai_fa_data_valid 	=> fai_fa_data_valid,
		fai_fa_d 				=> fai_fa_d,
		fai_cfg_a 				=> fai_cfg_a,
		fai_cfg_do 				=> fai_cfg_do,
		fai_cfg_di 				=> fai_cfg_di,
		fai_cfg_we 				=> fai_cfg_we,
		fai_cfg_clk 			=> fai_cfg_clk,
		fai_cfg_val 			=> fai_cfg_val
	);


  emulator : fai_emulator
  PORT MAP (
	  	ClkADC			   => adc_clk,
   	Reset					=> adc_rst,
		TimeFrameStart 	=> TimeFrameStart_i,
 		BlockStart 	 	 	=> fai_fa_block_start,
 		DataValid 		   => fai_fa_data_valid,
 		FAData 			   => fai_fa_d
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
