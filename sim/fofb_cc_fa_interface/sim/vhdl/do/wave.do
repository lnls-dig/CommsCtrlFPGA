onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/mgt_clk
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/adc_clk
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/adc_rst
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/mgt_rst
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/timeframestart
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_fa_intf_tb/bpm_cc_xpos
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_fa_intf_tb/bpm_cc_ypos
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/uut/fa_data_valid
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_fa_intf_tb/uut/fa_data
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/uut/fa_block_start
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/uut/time_frame_start_i
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/uut/fa_pm_ena
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/uut/fa_pm_arm
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/uut/fa_pm_event
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/uut/block_start_fall
add wave -noupdate -format Literal /fofb_cc_fa_intf_tb/uut/fa_x_pos_abs
add wave -noupdate -format Literal /fofb_cc_fa_intf_tb/uut/fa_y_pos_abs
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/uut/fa_x_pm_trig
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/uut/fa_y_pm_trig
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/uut/fa_pm_arm_rise
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/uut/fa_pm_armed
add wave -noupdate -format Logic /fofb_cc_fa_intf_tb/uut/fa_pm_trig
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2603139 ps} 0}
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
WaveRestoreZoom {0 ps} {15750 ns}
