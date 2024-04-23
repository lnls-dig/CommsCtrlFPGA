files = [
    "rtl/vhdl/fofb_cc_fa_if.vhd",
]

import sys

if (target == "xilinx"):
    if(syn_device[0:4].upper()=="XC7A"):
        if (action == "simulation"):
            if (sim_tool != "ghdl" and sim_tool != "nvc"):
                files.extend(["coregen/artix7/fofb_cc_fa_if_bram_16_to_32/fofb_cc_fa_if_bram_16_to_32_sim_netlist.vhdl"]);
                files.extend(["coregen/artix7/fofb_cc_fa_if_bram_32_to_32/fofb_cc_fa_if_bram_32_to_32_sim_netlist.vhdl"]);
        elif (action == "synthesis"):
            files.extend(["coregen/artix7/fofb_cc_fa_if_bram_16_to_32/fofb_cc_fa_if_bram_16_to_32.xci"]);
            files.extend(["coregen/artix7/fofb_cc_fa_if_bram_32_to_32/fofb_cc_fa_if_bram_32_to_32.xci"]);
        else:
            sys.exit("ERROR: fofb_cc_fa_if: Action not supported: {}".format(action))

        files.extend(["rtl/vhdl/artix7/fofb_cc_fa_if_bram.vhd"]);
    # Does the RAMB16_S18_S36 primitive even worked for Virtex5/Sparan6 FPGAs?
    else:
        files.extend(["rtl/vhdl/fofb_cc_fa_if_bram.vhd"]);
else:
    import sys
    sys.exit("ERROR: fofb_cc_fa_if: Target/Device not supported: {}/{}".format(target, syn_device))
