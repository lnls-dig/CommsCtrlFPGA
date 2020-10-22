action = "simulation"
sim_tool = "modelsim"
top_module = "fofb_cc_arbmux_tb"
sim_top = "fofb_cc_arbmux_tb"

# needed so we use the correct coregen modules
target = "xilinx"
syn_device = "xc7a200t"

modules = {
    "local" : [
        "../../../rtl/fofb_cc_arbmux",
        "../../../rtl/fofb_cc_frame_cntrl",
        "../../../rtl/fofb_cc_rx_fifo",
        "../../../rtl/fofb_cc_pkg",
    ]
}

files = ["../bench/fofb_cc_arbmux_tb.vhd"]

sim_post_cmd = "vsim -do run.do"
