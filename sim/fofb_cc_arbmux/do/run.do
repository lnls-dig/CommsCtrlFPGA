#Start a simulation
vsim \
    -t ps \
    -novopt \
    +notimingchecks \
    -L unisims_ver \
    work.fofb_cc_arbmux_tb

view wave

add wave sim:/fofb_cc_arbmux_tb/uut/*
add wave -group "FIFO" sim:/fofb_cc_arbmux_tb/RX_FIFO_GEN(0)/fofb_cc_rx_buffer_inst/*

#Run the simulation
run 140 us
