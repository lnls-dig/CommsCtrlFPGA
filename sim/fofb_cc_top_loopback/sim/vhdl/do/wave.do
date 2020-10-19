onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /fofb_cc_top_loopback_tb/adc_clk
add wave -noupdate -format Logic /fofb_cc_top_loopback_tb/adc_rst
add wave -noupdate -format Logic /fofb_cc_top_loopback_tb/fai_fa_block_start
add wave -noupdate -format Logic /fofb_cc_top_loopback_tb/fai_fa_data_valid
add wave -noupdate -format Literal -radix decimal /fofb_cc_top_loopback_tb/fai_fa_d
add wave -noupdate -format Literal /fofb_cc_top_loopback_tb/fai_cfg_di
add wave -noupdate -format Literal /fofb_cc_top_loopback_tb/fai_cfg_val
add wave -noupdate -format Literal /fofb_cc_top_loopback_tb/fai_cfg_a
add wave -noupdate -format Literal /fofb_cc_top_loopback_tb/fai_cfg_do
add wave -noupdate -format Logic /fofb_cc_top_loopback_tb/fai_cfg_we
add wave -noupdate -format Logic /fofb_cc_top_loopback_tb/fai_cfg_clk
add wave -noupdate -format Logic /fofb_cc_top_loopback_tb/timeframestart_i
add wave -noupdate -format Logic /fofb_cc_top_loopback_tb/uut/fai_ack
add wave -noupdate -format Logic /fofb_cc_top_loopback_tb/uut/fai_ack_reg
add wave -noupdate -format Logic /fofb_cc_top_loopback_tb/uut/fai_ack_rise
add wave -noupdate -format Logic /fofb_cc_top_loopback_tb/uut/fai_fa_block_start_reg
add wave -noupdate -format Literal /fofb_cc_top_loopback_tb/uut/fa_data
add wave -noupdate -format Literal /fofb_cc_top_loopback_tb/uut/fa_data_a
add wave -noupdate -format Logic /fofb_cc_top_loopback_tb/uut/fa_data_wen
add wave -noupdate -format Literal /fofb_cc_top_loopback_tb/uut/fa_data_addr
add wave -noupdate -format Literal /fofb_cc_top_loopback_tb/uut/addr
add wave -noupdate -format Literal /fofb_cc_top_loopback_tb/uut/fa_limit
add wave -noupdate -format Logic /fofb_cc_top_loopback_tb/uut/fa_acq_ena
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 321
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
WaveRestoreZoom {0 ps} {10500 ns}
