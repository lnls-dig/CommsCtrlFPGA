#Start a simulation
vsim \
    -t ps \
    -novopt \
    +notimingchecks \
    -L unisims_ver \
    work.fofb_cc_fod_tb

do wave.do

#Run the simulation
run 1000 us
