#Start a simulation
vsim \
    -t ps \
    -novopt \
    +notimingchecks \
    -L unisims_ver \
    work.fofb_cc_fa_intf_tb

do wave.do

#Run the simulation
run 140 us
