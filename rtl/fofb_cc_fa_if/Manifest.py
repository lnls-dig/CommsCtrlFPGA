files = [
    "rtl/vhdl/fofb_cc_fa_if.vhd",
]

# Does the RAMB16_S18_S36 primitive even worked for Virtex5/Sparan6 FPGAs?
if (target == "xilinx"):
    files.extend(["rtl/vhdl/fofb_cc_fa_if_bram.vhd"]);
else:
    import sys
    sys.exit("ERROR: fofb_cc_fa_if: Target/Device not supported: {}/{}".format(target, syn_device))
