files = []

if (target == "xilinx" and syn_device[0:4].upper()=="XC6V"):
    files.extend(["rtl/vhdl/fofb_cc_v6_clk_if.vhd"]);
elif (target == "xilinx" and syn_device[0:4].upper()=="XC5V"):
    files.extend(["rtl/vhdl/fofb_cc_v5_clk_if.vhd"]);
elif (target == "xilinx" and syn_device[0:4].upper()=="XC6S"):
    files.extend(["rtl/vhdl/fofb_cc_s6_clk_if.vhd"]);
elif (target == "xilinx" and syn_device[0:4].upper()=="XC2V"):
    files.extend(["rtl/vhdl/fofb_cc_v2p_clk_if.vhd"]);
else:
    import sys
    sys.exit("ERROR: fofb_cc_clk_if: Target/Device not supported: {}/{}".format(target, syn_device))
