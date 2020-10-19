onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_top_tb/tester/tx_usrapp/txdata_o
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_top_tb/tester/tx_usrapp/txcharisk_o
add wave -noupdate -format Logic -radix hexadecimal /fofb_cc_top_tb/tester/tx_usrapp/insertcrcerr_o
add wave -noupdate -format Logic -radix hexadecimal /fofb_cc_top_tb/i_fofb_cc_top/mgt_if_gen/mgt_lane_gen__0/mgt_lane/rxcrcerr
add wave -noupdate -format Logic -radix hexadecimal /fofb_cc_top_tb/i_fofb_cc_top/mgt_if_gen/mgt_lane_gen__0/mgt_lane/rxcheckingcrc_reg
add wave -noupdate -format Logic -radix hexadecimal /fofb_cc_top_tb/i_fofb_cc_top/mgt_if_gen/mgt_lane_gen__0/mgt_lane/rxcheckingcrc
add wave -noupdate -format Literal -radix hexadecimal /fofb_cc_top_tb/i_fofb_cc_top/mgt_if_gen/mgt_lane_gen__0/mgt_lane/i_mgt/rxclkcorcnt
add wave -noupdate -format Logic /fofb_cc_top_tb/i_fofb_cc_top/mgt_if_gen/mgt_lane_gen__0/mgt_lane/softerror_reset
add wave -noupdate -format Logic /fofb_cc_top_tb/i_fofb_cc_top/mgt_if_gen/mgt_lane_gen__0/mgt_lane/softerror_o
add wave -noupdate -format Literal /fofb_cc_top_tb/i_fofb_cc_top/mgt_if_gen/mgt_lane_gen__0/mgt_lane/softerror_cnt
add wave -noupdate -format Logic /fofb_cc_top_tb/i_fofb_cc_top/mgt_if_gen/mgt_lane_gen__0/mgt_lane/frameerror_o
add wave -noupdate -format Logic /fofb_cc_top_tb/i_fofb_cc_top/mgt_if_gen/mgt_lane_gen__0/mgt_lane/rxf_full_i
add wave -noupdate -format Logic /fofb_cc_top_tb/i_fofb_cc_top/mgt_if_gen/mgt_lane_gen__0/mgt_lane/rx_dat_val_o
add wave -noupdate -format Literal /fofb_cc_top_tb/i_fofb_cc_top/mgt_if_gen/mgt_lane_gen__0/mgt_lane/rx_dat_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {28254121 ps} 0}
configure wave -namecolwidth 203
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {4045170 ps} {7972080 ps}
