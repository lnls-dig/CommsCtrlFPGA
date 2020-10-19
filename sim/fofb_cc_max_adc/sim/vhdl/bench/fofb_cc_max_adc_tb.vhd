LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fofb_cc_max_adc_tb_vhd IS
END fofb_cc_max_adc_tb_vhd;

ARCHITECTURE behavior OF fofb_cc_max_adc_tb_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT fofb_cc_max_adc
	PORT(
		adc_clk_i : IN std_logic;
		adc_rst_i : IN std_logic;
		adc_a_raw_i : IN std_logic_vector(15 downto 0);
		adc_b_raw_i : IN std_logic_vector(15 downto 0);
		adc_c_raw_i : IN std_logic_vector(15 downto 0);
		adc_d_raw_i : IN std_logic_vector(15 downto 0);          
		adc_max_val_o : OUT std_logic_vector(15 downto 0)
		);
	END COMPONENT;

	--Inputs
	SIGNAL adc_clk_i   :  std_logic := '0';
	SIGNAL adc_rst_i   :  std_logic := '1';
	SIGNAL adc_a_raw_i :  std_logic_vector(15 downto 0) := (others=>'0');
	SIGNAL adc_b_raw_i :  std_logic_vector(15 downto 0) := (others=>'0');
	SIGNAL adc_c_raw_i :  std_logic_vector(15 downto 0) := (others=>'0');
	SIGNAL adc_d_raw_i :  std_logic_vector(15 downto 0) := (others=>'0');

	--Outputs
	SIGNAL adc_max_val_o :  std_logic_vector(15 downto 0);

BEGIN
	
	adc_clk_i <= not adc_clk_i after 10 ns;
	adc_rst_i <= '0' after 100 ns;

	-- Instantiate the Unit Under Test (UUT)
	uut: fofb_cc_max_adc PORT MAP(
		adc_clk_i => adc_clk_i,
		adc_rst_i => adc_rst_i,
		adc_a_raw_i => adc_a_raw_i,
		adc_b_raw_i => adc_b_raw_i,
		adc_c_raw_i => adc_c_raw_i,
		adc_d_raw_i => adc_d_raw_i,
		adc_max_val_o => adc_max_val_o
	);

	tb : PROCESS
	BEGIN				
		-- Wait 100 ns for global reset to finish
		wait for 100 ns;
		adc_a_raw_i	<=	X"8210";
		adc_b_raw_i	<=	X"8211";		
		adc_c_raw_i	<=	X"8212";						
		adc_d_raw_i	<=	X"8213";											
		
		wait for 20 ns;	
		adc_a_raw_i	<=	X"8110";
		adc_b_raw_i	<=	X"8111";		
		adc_c_raw_i	<=	X"8112";						
		adc_d_raw_i	<=	X"8113";											

		wait for 20 ns;	
		adc_a_raw_i	<=	X"8010";
		adc_b_raw_i	<=	X"8011";		
		adc_c_raw_i	<=	X"8012";						
		adc_d_raw_i	<=	X"8013";											

		wait for 20 ns;	
		adc_a_raw_i	<=	X"7FFE";
		adc_b_raw_i	<=	X"7FFD";		
		adc_c_raw_i	<=	X"7FF0";						
		adc_d_raw_i	<=	X"7FF1";											
		
		wait; -- will wait forever
	END PROCESS;

END;
