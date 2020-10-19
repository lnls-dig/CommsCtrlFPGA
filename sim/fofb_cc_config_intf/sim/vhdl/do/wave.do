onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/mgt_clk
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/mgt_rst
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/adc_clk
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/adc_rst
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/fai_cfg_act_part
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/fa_data_na
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/fai_cfg_di
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/link_partner
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/link_up
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/time_frame_count
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/hard_error_cnt
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/soft_error_cnt
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/frame_error_cnt
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/rx_pck_cnt
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/tx_pck_cnt
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/bpm_count
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/fod_process_time
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/cc_test_err_stat
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/coeff_x_addr
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/coeff_y_addr
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/fai_cfg_a
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/fai_cfg_do
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/fai_cfg_we
add wave -noupdate -format Literal -radix decimal /fofb_cc_config_intf_tb_vhd/bpm_id
add wave -noupdate -format Literal -radix decimal /fofb_cc_config_intf_tb_vhd/time_frame_length
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/mgt_powerdown
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/mgt_loopback
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/clr_dly_cnt_val
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/cc_configured
add wave -noupdate -format Literal -radix decimal /fofb_cc_config_intf_tb_vhd/golden_orb_x
add wave -noupdate -format Literal -radix decimal /fofb_cc_config_intf_tb_vhd/golden_orb_y
add wave -noupdate -format Literal -radix decimal /fofb_cc_config_intf_tb_vhd/addra
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb_vhd/dina
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/wea
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/douta
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb_vhd/addrb
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb_vhd/doutb
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/dinb
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/web
add wave -noupdate -divider EXT_BUFF
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/coeff_x_out
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/coeff_y_out
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb_vhd/uut/coeff_x_addr
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb_vhd/uut/coeff_y_addr
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/uut/coef_x_wr
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/uut/coef_y_wr
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/uut/cfg_read_data
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/uut/cfg_addr_reg
add wave -noupdate -divider CFG_BRAM
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/i_fofb_cc_cfg_bram/addra
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/i_fofb_cc_cfg_bram/addrb
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/i_fofb_cc_cfg_bram/clka
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/i_fofb_cc_cfg_bram/clkb
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/i_fofb_cc_cfg_bram/dina
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/i_fofb_cc_cfg_bram/dinb
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/i_fofb_cc_cfg_bram/douta
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/i_fofb_cc_cfg_bram/doutb
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/i_fofb_cc_cfg_bram/wea
add wave -noupdate -format Logic /fofb_cc_config_intf_tb_vhd/i_fofb_cc_cfg_bram/web
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/i_fofb_cc_cfg_bram/ena_i
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/i_fofb_cc_cfg_bram/enb_i
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/i_fofb_cc_cfg_bram/douta_i
add wave -noupdate -format Literal /fofb_cc_config_intf_tb_vhd/i_fofb_cc_cfg_bram/doutb_i
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 349
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {0 ps} {21 us}
