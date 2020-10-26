action = "simulation"
sim_tool = "modelsim"
top_module = "fofb_cc_top_tb"
sim_top = "fofb_cc_top_tb"

# needed so we use the correct coregen modules
target = "xilinx"
syn_device = "xc6vlx240t"

modules = {
    "local" : [
        "../../..",
        "../../../sim/test_interface",
    ]
}

files = [
    "../bench/fofb_cc_v5_clk_if.vhd",
    "../bench/fofb_cc_usrapp_rx.vhd",
    "../bench/fofb_cc_usrapp_tx.vhd",
    "../bench/fofb_cc_usrapp_checker.vhd",
    "../bench/fofb_cc_top_tester.vhd",
    "../bench/sim_reset_mgt_model.vhd",
    "../bench/fofb_cc_top_tb.vhd",
]

# We can add a top-level wrapper to the compilation list if needed
#comms_cc_wrapper = ["bpm_wrapper"]
