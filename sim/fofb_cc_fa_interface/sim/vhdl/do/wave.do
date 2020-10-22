onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /fofb_cc_fa_intf_tb/uut/BLK_DW
add wave -noupdate /fofb_cc_fa_intf_tb/uut/BLK_SIZE
add wave -noupdate /fofb_cc_fa_intf_tb/uut/BPMS
add wave -noupdate /fofb_cc_fa_intf_tb/uut/DMUX
add wave -noupdate /fofb_cc_fa_intf_tb/uut/mgtclk_i
add wave -noupdate /fofb_cc_fa_intf_tb/uut/mgtreset_i
add wave -noupdate /fofb_cc_fa_intf_tb/uut/adcclk_i
add wave -noupdate /fofb_cc_fa_intf_tb/uut/adcreset_i
add wave -noupdate /fofb_cc_fa_intf_tb/uut/fa_block_start_i
add wave -noupdate /fofb_cc_fa_intf_tb/uut/fa_data_valid_i
add wave -noupdate /fofb_cc_fa_intf_tb/uut/fa_dat_i
add wave -noupdate /fofb_cc_fa_intf_tb/uut/fa_psel_i
add wave -noupdate /fofb_cc_fa_intf_tb/uut/timeframe_start_o
add wave -noupdate /fofb_cc_fa_intf_tb/uut/bpm_cc_xpos_o
add wave -noupdate /fofb_cc_fa_intf_tb/uut/bpm_cc_ypos_o
add wave -noupdate /fofb_cc_fa_intf_tb/uut/addra
add wave -noupdate /fofb_cc_fa_intf_tb/uut/addrb
add wave -noupdate /fofb_cc_fa_intf_tb/uut/read_addr
add wave -noupdate /fofb_cc_fa_intf_tb/uut/doutb
add wave -noupdate /fofb_cc_fa_intf_tb/uut/block_start
add wave -noupdate /fofb_cc_fa_intf_tb/uut/block_start_prev
add wave -noupdate /fofb_cc_fa_intf_tb/uut/block_start_fall
add wave -noupdate /fofb_cc_fa_intf_tb/uut/addrb_cnt_en
add wave -noupdate /fofb_cc_fa_intf_tb/uut/bpm_cc_xpos
add wave -noupdate /fofb_cc_fa_intf_tb/uut/bpm_cc_ypos
add wave -noupdate /fofb_cc_fa_intf_tb/uut/WR_SIZE
add wave -noupdate /fofb_cc_fa_intf_tb/uut/WR_AW
add wave -noupdate /fofb_cc_fa_intf_tb/uut/RD_SIZE
add wave -noupdate /fofb_cc_fa_intf_tb/uut/RD_AW
add wave -noupdate /fofb_cc_fa_intf_tb/uut/BLK_AW
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2603139 ps} 0}
quietly wave cursor active 0
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
configure wave -timelineunits ps
update
WaveRestoreZoom {125037500 ps} {140787500 ps}
