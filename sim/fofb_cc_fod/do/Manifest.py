action = "simulation"
sim_tool = "modelsim"
top_module = "fofb_cc_fod_tb"
sim_top = "fofb_cc_fod_tb"

# needed so we use the correct coregen modules
target = "xilinx"
syn_device = "xc7a200t"

modules = {
    "local" : [
        "../../../rtl/fofb_cc_fod",
        "../../../rtl/fofb_cc_dpbram",
        "../../../rtl/fofb_cc_sync",
        "../../../rtl/fofb_cc_frame_cntrl",
        "../../../rtl/fofb_cc_pkg",
    ]
}

files = ["../bench/fofb_cc_fod_tb.vhd", "../bench/io_utils.vhd"]
