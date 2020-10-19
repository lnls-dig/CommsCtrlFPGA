onerror resume
onbreak resume
onElabError resume

view wave

add wave -group "CC TOP" -radix Hexadecimal /fofb_cc_top_tb/i_fofb_cc_top/*

add wave -group "CC CFG IF" -radix Hexadecimal /fofb_cc_top_tb/i_fofb_cc_top/fofb_cc_cfg_if/*

add wave -group "CC FOD" -radix Hexadecimal /fofb_cc_top_tb/i_fofb_cc_top/fofb_cc_fod/*

add wave -group "CLK IF" -radix Hexadecimal /fofb_cc_top_tb/i_fofb_cc_top/fofb_cc_clk_if/*

add wave -group "GT_IF"  -radix Hexadecimal /fofb_cc_top_tb/i_fofb_cc_top/gt_if/*

add wave -group "FAI_IF" -radix Hexadecimal sim:/fofb_cc_top_tb/i_fofb_cc_top/fofb_cc_fa_if/*

add wave -group "FRAME" -radix Hexadecimal sim:/fofb_cc_top_tb/i_fofb_cc_top/fofb_cc_frame_cntrl/*

add wave -noupdate -divider {TESTER}

add wave -group "Tester Top" -radix Hexadecimal  /fofb_cc_top_tb/tester/*

add wave -group "CLK_IF" /fofb_cc_top_tb/tester_clkgen/*

add wave -group "Tester GTP" -radix Hexadecimal /fofb_cc_top_tb/tester/fofb_cc_gtp_if/*

add wave -group "Tester TX_LL" -radix Hexadecimal /fofb_cc_top_tb/tester/fofb_cc_gtp_if/gtp_lane_gen(0)/lanes/tx_ll/*

add wave -group "Tester RX_LL" -radix Hexadecimal /fofb_cc_top_tb/tester/fofb_cc_gtp_if/gtp_lane_gen(0)/lanes/rx_ll/*

add wave -group "Tester RX_CRC" -radix Hexadecimal /fofb_cc_top_tb/tester/fofb_cc_gtp_if/gtp_lane_gen(0)/lanes/rx_ll/rx_crc/*

add wave -group "TX USRAPP" -radix Hexadecimal  /fofb_cc_top_tb/tester/tx_usrapp/*

add wave -group "RX USRAPP" -radix Hexadecimal  /fofb_cc_top_tb/tester/rx_usrapp/*

add wave -group "CHECKER"   -radix Hexadecimal  /fofb_cc_top_tb/tester/fofb_cc_usrapp_checker/*

configure wave -signalnamewidth 1

run -all
