#
# Create work library
#
vlib work
#
# Compile sources
#
vcom -explicit  -93 /dls_sw/apps/FPGA/Questa/10.1/questasim/examples/vhdl/io_utils/io_utils.vhd
vcom -explicit  -93 "../../../rtl/fofb_cc_pkg/rtl/vhdl/fofb_cc_version.vhd"
vcom -explicit  -93 "../../../rtl/fofb_cc_sync/rtl/vhdl/fofb_cc_p2p.vhd"
vcom -explicit  -93 "../../../rtl/fofb_cc_pkg/rtl/vhdl/fofb_cc_pkg.vhd"
vcom -explicit  -93 "../../../rtl/fofb_cc_dpbram/rtl/vhdl/fofb_cc_sdpbram.vhd"
vcom -explicit  -93 "../../../rtl/fofb_cc_dpbram/rtl/vhdl/fofb_cc_dpbram.vhd"
vcom -explicit  -93 "../../../rtl/fofb_cc_fod/rtl/vhdl/fofb_cc_fod.vhd"
vcom -work work -93 "../../../rtl/fofb_cc_frame_cntrl/rtl/vhdl/fofb_cc_frame_cntrl.vhd"
vcom -explicit  -93 "../bench/fofb_cc_fod_tb.vhd"
#
# Call vsim to invoke simulator
#
vsim -novopt -t 1ns  -lib work work.fofb_cc_fod_tb

view wave

add wave -group "TESTBENCH"  sim:/fofb_cc_fod_tb/*
add wave -group "FOD" -radix hexadecimal sim:/fofb_cc_fod_tb/uut/*
#add wave -group "FODMASK" -radix Unsigned sim:/fofb_cc_fod_tb/uut/FodMaskMem/*
add wave -group "FRAME_CTRL" sim:/fofb_cc_fod_tb/fofb_cc_frame_cntrl/*


add wave sim:/fofb_cc_fod_tb/uut/timeframe_valid_i
add wave sim:/fofb_cc_fod_tb/uut/timeframe_start_i
add wave sim:/fofb_cc_fod_tb/uut/timeframe_inject
add wave sim:/fofb_cc_fod_tb/uut/timeframe_start
add wave sim:/fofb_cc_fod_tb/uut/timeframe_valid
add wave sim:/fofb_cc_fod_tb/uut/bpmid
add wave sim:/fofb_cc_fod_tb/uut/bpm_x_pos_i(0)
add wave sim:/fofb_cc_fod_tb/uut/bpm_xpos_val
add wave sim:/fofb_cc_fod_tb/uut/pload_header
add wave sim:/fofb_cc_fod_tb/uut/fod_dat_o
add wave sim:/fofb_cc_fod_tb/uut/fod_dat_val_o(0)
add wave sim:/fofb_cc_fod_tb/uut/posmem_addra
add wave sim:/fofb_cc_fod_tb/uut/xpos_to_store
add wave sim:/fofb_cc_fod_tb/uut/posmem_wea

run 100 us

