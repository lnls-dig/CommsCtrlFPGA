action = "simulation"
sim_tool = "modelsim"
top_module = "fofb_cc_gtx_crc32_tb"
sim_top = "fofb_cc_gtx_crc32_tb"

# needed so we use the correct coregen modules
target = "xilinx"
syn_device = "xc6vlx240t"

modules = {
    "local" : [
        "../../../rtl/fofb_cc_gtx_if",
        "../../../rtl/fofb_cc_pkg",
    ]
}

files = [
    "../bench/crc_components_pkg.vhd",
    "../bench/crc_functions_pkg.vhd",
    "../bench/crc_gen.vhd",
    "../bench/crc.v",
    "../bench/crc_valid_gen_rx.vhd",
    "../bench/crc.vhd",
    "../bench/data_ds_modules.vhd",
    "../bench/fofb_cc_gtx_crc32_tb.vhd",
    "../bench/rem_ds_modules.vhd",
    "../bench/rxcrc.vhd",
    "../bench/state_machine_rx.vhd",
    "../bench/state_machine_tx.vhd",
    "../bench/txcrc.vhd",
    "../bench/ucrc_par.vhd",
]
