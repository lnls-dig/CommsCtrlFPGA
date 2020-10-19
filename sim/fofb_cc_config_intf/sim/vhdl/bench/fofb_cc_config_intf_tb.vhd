LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;

use work.fofb_cc_pkg.all;		-- Diamond FFS Package

ENTITY fofb_cc_config_intf_tb IS
END fofb_cc_config_intf_tb;

library UNISIM;
use UNISIM.Vcomponents.ALL;

ARCHITECTURE behavior OF fofb_cc_config_intf_tb IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT fofb_cc_config_intf
	PORT(
		mgt_clk : IN std_logic;
		mgt_rst : IN std_logic;
		fai_cfg_act_part : IN std_logic;
		fai_cfg_di : IN std_logic_vector(31 downto 0);
		link_partner : IN std_logic_2d_10(3 downto 0);
		link_up : IN std_logic_vector(7 downto 0);
		time_frame_count : IN std_logic_vector(15 downto 0);
		hard_error_cnt : IN std_logic_2d_16(3 downto 0);
		soft_error_cnt : IN std_logic_2d_16(3 downto 0);
		frame_error_cnt : IN std_logic_2d_16(3 downto 0);
		rx_pck_cnt : IN std_logic_2d_16(3 downto 0);
		tx_pck_cnt : IN std_logic_2d_16(3 downto 0);
		bpm_count : IN std_logic_vector(7 downto 0);
		fa_data_na : IN std_logic;
		fod_process_time : IN std_logic_vector(15 downto 0);
		coeff_x_addr : IN std_logic_vector(7 downto 0);
		coeff_y_addr : IN std_logic_vector(7 downto 0);          
		fai_cfg_a : OUT std_logic_vector(10 downto 0);
		fai_cfg_do : OUT std_logic_vector(15 downto 0);
		fai_cfg_we : OUT std_logic;
		bpm_id : OUT std_logic_vector(9 downto 0);
		time_frame_length : OUT std_logic_vector(15 downto 0);
		mgt_powerdown : OUT std_logic_vector(3 downto 0);
		mgt_loopback : OUT std_logic_vector(7 downto 0);
		coeff_x_out : OUT std_logic_vector(31 downto 0);
		coeff_y_out : OUT std_logic_vector(31 downto 0);
		golden_orb_x : OUT std_logic_vector(31 downto 0);
		golden_orb_y : OUT std_logic_vector(31 downto 0)
		);
	END COMPONENT;

	COMPONENT fofb_cc_cfg_bram
	port (
		addra: IN std_logic_VECTOR(10 downto 0);
		addrb: IN std_logic_VECTOR(10 downto 0);
		clka: IN std_logic;
		clkb: IN std_logic;
		dina: IN std_logic_VECTOR(31 downto 0);
		dinb: IN std_logic_VECTOR(31 downto 0);
		douta: OUT std_logic_VECTOR(31 downto 0);
		doutb: OUT std_logic_VECTOR(31 downto 0);
		wea: IN std_logic;
		web: IN std_logic
		);
	END COMPONENT;

	--Inputs
	SIGNAL mgt_clk :  std_logic := '0';
	SIGNAL mgt_rst :  std_logic := '1';
	SIGNAL fai_cfg_act_part :  std_logic := '0';
	SIGNAL fa_data_na :  std_logic := '0';
	SIGNAL fai_cfg_di :  std_logic_vector(31 downto 0) := (others=>'0');
	SIGNAL link_partner :  std_logic_2d_10(3 downto 0) := ("0000000001","0000000010", "0000000011", "0000000100");
	SIGNAL link_up :  std_logic_vector(7 downto 0) := "00000101";
	SIGNAL time_frame_count :  std_logic_vector(15 downto 0) := X"0006";
	SIGNAL hard_error_cnt :  std_logic_2d_16(3 downto 0) := (X"0007", X"0008", X"0009", X"000A");
	SIGNAL soft_error_cnt :  std_logic_2d_16(3 downto 0) := (X"000B", X"000C", X"000D", X"000E");
	SIGNAL frame_error_cnt : std_logic_2d_16(3 downto 0) := (X"0010", X"0011", X"0012", X"0013");
	SIGNAL rx_pck_cnt :  std_logic_2d_16(3 downto 0) := (X"0014", X"0015", X"0016", X"0017");
	SIGNAL tx_pck_cnt :  std_logic_2d_16(3 downto 0) := (X"0018", X"0019", X"0020", X"0021");
	SIGNAL bpm_count :  std_logic_vector(7 downto 0) := X"22";
	SIGNAL fod_process_time :  std_logic_vector(15 downto 0) := X"0023";
	SIGNAL coeff_x_addr :  std_logic_vector(7 downto 0) := (others=>'1');
	SIGNAL coeff_y_addr :  std_logic_vector(7 downto 0) := (others=>'1');

	--Outputs
	SIGNAL fai_cfg_a :  std_logic_vector(10 downto 0);
	SIGNAL fai_cfg_do :  std_logic_vector(15 downto 0);
	SIGNAL fai_cfg_we :  std_logic;
	SIGNAL bpm_id :  std_logic_vector(9 downto 0);
	SIGNAL time_frame_length :  std_logic_vector(15 downto 0);
	SIGNAL mgt_powerdown :  std_logic_vector(3 downto 0);
	SIGNAL mgt_loopback :  std_logic_vector(7 downto 0);
	SIGNAL coeff_x_out :  std_logic_vector(31 downto 0);
	SIGNAL coeff_y_out :  std_logic_vector(31 downto 0);
	SIGNAL golden_orb_x :  std_logic_vector(31 downto 0);
	SIGNAL golden_orb_y :  std_logic_vector(31 downto 0);

	SIGNAL	addra	: std_logic_VECTOR(10 downto 0) := (others => '0');
	SIGNAL	addrb	: std_logic_VECTOR(10 downto 0) := (others => '0');
	SIGNAL	dina	: std_logic_VECTOR(31 downto 0) := X"00000034";
	SIGNAL	dinb	: std_logic_VECTOR(31 downto 0) := (others => '0');
	SIGNAL	douta	: std_logic_VECTOR(31 downto 0);
	SIGNAL	doutb	: std_logic_VECTOR(31 downto 0);
	SIGNAL	wea	: std_logic := '0';
	SIGNAL	web	: std_logic := '0';
	
BEGIN

	mgt_clk	<=	not mgt_clk	after	4.5 ns;
	mgt_rst	<= '0' after 200 ns;
	
	-- Instantiate the Unit Under Test (UUT)
	uut: fofb_cc_config_intf PORT MAP(
		mgt_clk => mgt_clk,
		mgt_rst => mgt_rst,
		fai_cfg_act_part => fai_cfg_act_part,
		fai_cfg_a => fai_cfg_a,
		fai_cfg_do => fai_cfg_do,
		fai_cfg_di => fai_cfg_di,
		fai_cfg_we => fai_cfg_we,
		bpm_id => bpm_id,
		time_frame_length => time_frame_length,
		mgt_powerdown => mgt_powerdown,
		mgt_loopback => mgt_loopback,
		link_partner => link_partner,
		link_up => link_up,
		time_frame_count => time_frame_count,
		hard_error_cnt => hard_error_cnt,
		soft_error_cnt => soft_error_cnt,
		frame_error_cnt => frame_error_cnt,
		rx_pck_cnt => rx_pck_cnt,
		tx_pck_cnt => tx_pck_cnt,
		bpm_count => bpm_count,
		fa_data_na => fa_data_na,
		fod_process_time => fod_process_time,
		coeff_x_addr => coeff_x_addr,
		coeff_x_out => coeff_x_out,
		coeff_y_addr => coeff_y_addr,
		coeff_y_out => coeff_y_out,
		golden_orb_x => golden_orb_x,
		golden_orb_y => golden_orb_y
	);

dinb			<= (X"0000" & fai_cfg_do);
addrb			<= fai_cfg_a;
fai_cfg_di	<= doutb;
web			<= fai_cfg_we;

i_fofb_cc_cfg_bram : fofb_cc_cfg_bram
	port map(
		addra	=> addra,
		addrb	=> addrb,
		clka	=> mgt_clk,
		clkb	=> mgt_clk,
		dina	=> dina,
		dinb	=> dinb,
		douta	=> douta,
		doutb	=> doutb,
		wea	=> wea,
		web	=> web
		);

tb : PROCESS
	BEGIN
		-- Wait 100 ns for global reset to finish
		wait for 505 ns;
		
			for I in 0 to 767 loop
				wea	<= '1';
				wait for 9 ns;		
				addra <= addra + 1;
				dina	<= dina  + 2;							
			end loop;					
			wea	<= '0';		
			addra	<= (others => '0');		
		
		wait for 505 ns;					
		
		for I in 0 to 100000 loop
			fai_cfg_act_part	<= '1';
				wait for 107 ns;			
			fai_cfg_act_part	<= '0';			
				wait for 500 ns * I;
		end loop;

--		wait for 10000 ns;					
			for I in 0 to 255 loop
				coeff_x_addr <= coeff_x_addr + 1;
				coeff_y_addr <= coeff_y_addr + 1;
				wait for 9 ns;		
			end loop;					
			
		wait; -- will wait forever
	END PROCESS;

END;
