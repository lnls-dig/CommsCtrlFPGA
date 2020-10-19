onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /fofb_cc_config_intf_tb/mgt_clk
add wave -noupdate -format Logic /fofb_cc_config_intf_tb/mgt_rst
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/uut/state
add wave -noupdate -format Logic /fofb_cc_config_intf_tb/fai_cfg_act_part
add wave -noupdate -format Logic /fofb_cc_config_intf_tb/fai_cfg_we
add wave -noupdate -format Literal -radix decimal /fofb_cc_config_intf_tb/fai_cfg_a
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb/fai_cfg_do
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/link_partner
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/link_up
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/time_frame_count
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb/hard_error_cnt
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb/soft_error_cnt
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb/frame_error_cnt
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb/rx_pck_cnt
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb/tx_pck_cnt
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb/bpm_count
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb/fod_process_time
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/coeff_x_addr
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/coeff_y_addr
add wave -noupdate -format Literal -radix decimal /fofb_cc_config_intf_tb/bpm_id
add wave -noupdate -format Literal -radix decimal /fofb_cc_config_intf_tb/time_frame_length
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb/mgt_powerdown
add wave -noupdate -format Literal -radix decimal /fofb_cc_config_intf_tb/mgt_loopback
add wave -noupdate -format Literal -radix decimal /fofb_cc_config_intf_tb/coeff_x_out
add wave -noupdate -format Literal -radix unsigned /fofb_cc_config_intf_tb/coeff_y_out
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/golden_orb_x
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/golden_orb_y
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/addra
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/addrb
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/dina
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/dinb
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/douta
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/doutb
add wave -noupdate -format Logic /fofb_cc_config_intf_tb/wea
add wave -noupdate -format Logic /fofb_cc_config_intf_tb/web
add wave -noupdate -format Logic /fofb_cc_config_intf_tb/fa_data_na
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb/uut/cfg_addr
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb/uut/cfg_addr_reg
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_config_intf_tb/fai_cfg_di
add wave -noupdate -format Logic /fofb_cc_config_intf_tb/uut/coef_x_wr
add wave -noupdate -format Logic /fofb_cc_config_intf_tb/uut/coef_y_wr
add wave -noupdate -format Literal -radix decimal /fofb_cc_config_intf_tb/uut/cfg_addr_reg
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/addra
add wave -noupdate -format Literal /fofb_cc_config_intf_tb/dina
add wave -noupdate -format Logic /fofb_cc_config_intf_tb/wea
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0} {{Cursor 2} {30896018 ps} 0}
configure wave -namecolwidth 283
configure wave -valuecolwidth 40
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
WaveRestoreZoom {0 ps} {52500 ns}
