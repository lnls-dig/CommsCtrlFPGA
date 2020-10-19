vlib work
vdel -all -lib work
vlib work
vmap work work

# Compile testbench sources
vcom -work work ../../../rtl/fofb_cc_pkg/rtl/vhdl/fofb_cc_version.vhd
vcom -work work ../../../rtl/fofb_cc_pkg/rtl/vhdl/fofb_cc_pkg.vhd
vcom -work work ../../../rtl/fofb_cc_arbmux/rtl/vhdl/fofb_cc_arbmux.vhd
vcom -work work ../../../rtl/fofb_cc_frame_cntrl/rtl/vhdl/fofb_cc_frame_cntrl.vhd
vcom -work work ../../../rtl/fofb_cc_rx_fifo/coregen/virtex2pro/fofb_cc_rx_fifo.vhd
vcom -work work ../../../rtl/fofb_cc_rx_fifo/rtl/vhdl/fofb_cc_rx_buffer.vhd
vcom -work work ../bench/fofb_cc_arbmux_tb.vhd

#Start a simulation
vsim -t ps -novopt +notimingchecks -L unisims_ver work.fofb_cc_arbmux_tb

view wave

add wave sim:/fofb_cc_arbmux_tb/uut/*
add wave -group "FIFO" sim:/fofb_cc_arbmux_tb/RX_FIFO_GEN(0)/fofb_cc_rx_buffer_inst/*

#Run the simulation
run 140 us
