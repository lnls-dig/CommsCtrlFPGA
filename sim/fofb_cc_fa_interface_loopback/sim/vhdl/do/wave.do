onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /fofb_cc_fa_intf_loopback_tb/mgt_clk
add wave -noupdate -format Logic /fofb_cc_fa_intf_loopback_tb/adc_clk
add wave -noupdate -format Logic /fofb_cc_fa_intf_loopback_tb/adc_rst
add wave -noupdate -format Logic /fofb_cc_fa_intf_loopback_tb/mgt_rst
add wave -noupdate -format Logic /fofb_cc_fa_intf_loopback_tb/blockstart
add wave -noupdate -format Logic /fofb_cc_fa_intf_loopback_tb/datavalid
add wave -noupdate -format Literal -radix unsigned /fofb_cc_fa_intf_loopback_tb/fadata
add wave -noupdate -format Logic /fofb_cc_fa_intf_loopback_tb/timeframestart
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_fa_intf_loopback_tb/pos_dout
add wave -noupdate -format Logic -radix hexadecimal /fofb_cc_fa_intf_loopback_tb/pos_wen
add wave -noupdate -format Logic /fofb_cc_fa_intf_loopback_tb/timeframestart_i
add wave -noupdate -format Literal -radix unsigned /fofb_cc_fa_intf_loopback_tb/uut/addra_i
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_fa_intf_loopback_tb/uut/addrb_i
add wave -noupdate -format Literal /fofb_cc_fa_intf_loopback_tb/uut/doutb_i
add wave -noupdate -format Logic /fofb_cc_fa_intf_loopback_tb/uut/block_start_fall
add wave -noupdate -format Literal /fofb_cc_fa_intf_loopback_tb/uut/fa_data_reg
add wave -noupdate -format Logic /fofb_cc_fa_intf_loopback_tb/uut/fa_wea_i
add wave -noupdate -format Literal -radix unsigned /fofb_cc_fa_intf_loopback_tb/emulator/cnt
add wave -noupdate -format Logic /fofb_cc_fa_intf_loopback_tb/emulator/cnt_en
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 248
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
WaveRestoreZoom {579193 ps} {610666 ps}
