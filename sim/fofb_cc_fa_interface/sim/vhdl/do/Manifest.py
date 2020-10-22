action = "simulation"
sim_tool = "modelsim"
top_module = "fofb_cc_fa_intf_tb"
sim_top = "fofb_cc_fa_intf_tb"

# needed so we use the correct coregen modules
target = "xilinx"
syn_device = "xc7a200t"

modules = {
    "local" : [
        "../../../../../sim/test_interface",
        "../../../../../rtl/fofb_cc_fa_if",
        "../../../../../rtl/fofb_cc_pkg",
        "../../../../../rtl/fofb_cc_sync",
    ]
}

files = ["../bench/fofb_cc_fa_intf_tb.vhd"]
